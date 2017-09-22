-- -----------------------------------------------------------------------------
--                 WWW.PETEFINNIGAN.COM LIMITED
-- -----------------------------------------------------------------------------
-- Script Name : who_has_role.sql
-- Author      : Pete Finnigan
-- Date        : March 2004
-- -----------------------------------------------------------------------------
-- Description : Use this script to find which users and roles have been granted 
--               a specific role that you would like to query. The checks are 
--               done hierarchically via roles granted to roles etc.
--      
--               The output can be directed to either the screen via dbms_output
--               or to a file via utl_file. The method is decided at run time 
--               by choosing either 'S' for screen or 'F' for File. If File is
--               chosen then a filename and output directory are needed. The 
--               output directory needs to be enabled via utl_file_dir prior to
--               9iR2 and a directory object after.
-- -----------------------------------------------------------------------------
-- Maintainer  : Pete Finnigan (http://www.petefinnigan.com)
-- Copyright   : Copyright (C) 2004 PeteFinnigan.com Limited. All rights
--               reserved. All registered trademarks are the property of their
--               respective owners and are hereby acknowledged.
-- -----------------------------------------------------------------------------
-- Usage       : The script provided here is available free. You can do anything 
--               you want with it commercial or non commercial as long as the 
--               copyrights and this notice are not removed or edited in any way. 
--               The scripts cannot be posted / published / hosted or whatever 
--               anywhere else except at www.petefinnigan.com/tools.htm
-- -----------------------------------------------------------------------------
-- Version History
-- ===============
--
-- Who         version     Date      Description
-- ===         =======     ======    ======================
-- P.Finnigan  1.0         Mar 2004  First Issue.
-- P.Finnigan  1.1         Oct 2004  Added usage notes
-- P.Finnigan  1.2         Apr 2005  Added whenever sqlerror continue to stop 
--                                   subsequent errors barfing SQL*Plus. Thanks
--                                   to Norman Dunbar for the update.
-- P.Finnigan  1.3         May 2005  Added two new parameters to allow specification
--                                   of users to be ommited from the report
--                                   output.
-- -----------------------------------------------------------------------------

whenever sqlerror exit rollback
set feed on
set head on
set arraysize 1
set space 1
set verify off
set pages 25
set lines 80
set termout on
clear screen
set serveroutput on size 1000000

spool who_has_role.lis

undefine role_to_find
undefine output_method
undefine file_name
undefine output_dir
undefine skip_user
undefine user_to_skip

set feed off
col system_date  noprint new_value val_system_date
select to_char(sysdate,'Dy Mon dd hh24:mi:ss yyyy') system_date from sys.dual;
set feed on

prompt who_has_priv: Release 1.0.3.0.0 - Production on &val_system_date
prompt Copyright (c) 2004 PeteFinnigan.com Limited. All rights reserved. 
prompt 
accept role_to_find char prompt  'ROLE TO CHECK                          [DBA]: ' default DBA
accept output_method char prompt 'OUTPUT METHOD Screen/File                [S]: ' default S
accept file_name char prompt     'FILE NAME FOR OUTPUT              [priv.lst]: ' default priv.lst
accept output_dir char prompt    'OUTPUT DIRECTORY [DIRECTORY  or file (/tmp)]: ' default /tmp
accept skip_user char prompt     'EXCLUDE CERTAIN USERS                    [N]: ' default N
accept user_to_skip char prompt  'USER TO SKIP                         [TEST%]: ' default TEST%
prompt 
declare
    --
    lg_fptr utl_file.file_type;
    lv_file_or_screen varchar2(1):='S';
    --
    procedure open_file (pv_file_name in varchar2,
            pv_dir_name in varchar2) is 
    begin
        lg_fptr:=utl_file.fopen(pv_dir_name,pv_file_name,'A');
    exception
        when utl_file.invalid_path  then
            dbms_output.put_line('invalid path');
        when utl_file.invalid_mode  then
            dbms_output.put_line('invalid mode');
        when utl_file.invalid_filehandle  then
            dbms_output.put_line('invalid filehandle');
        when utl_file.invalid_operation  then
            dbms_output.put_line('invalid operation');
        when utl_file.read_error  then
            dbms_output.put_line('read error');
        when utl_file.write_error  then
            dbms_output.put_line('write error');
        when utl_file.internal_error  then
            dbms_output.put_line('internal error');
        when others then
            dbms_output.put_line('ERROR (open_file) => '||sqlcode);
            dbms_output.put_line('MSG (open_file) => '||sqlerrm);

    end open_file;
    --
    procedure close_file is
    begin
        utl_file.fclose(lg_fptr);
    exception
        when utl_file.invalid_path  then
            dbms_output.put_line('invalid path');
        when utl_file.invalid_mode  then
            dbms_output.put_line('invalid mode');
        when utl_file.invalid_filehandle  then
            dbms_output.put_line('invalid filehandle');
        when utl_file.invalid_operation  then
            dbms_output.put_line('invalid operation');
        when utl_file.read_error  then
            dbms_output.put_line('read error');
        when utl_file.write_error  then
            dbms_output.put_line('write error');
        when utl_file.internal_error  then
            dbms_output.put_line('internal error');
        when others then
            dbms_output.put_line('ERROR (close_file) => '||sqlcode);
            dbms_output.put_line('MSG (close_file) => '||sqlerrm);

    end close_file;
    --
    procedure write_op (pv_str in varchar2) is
    begin
        if lv_file_or_screen='S' then
            dbms_output.put_line(pv_str);
        else
            utl_file.put_line(lg_fptr,pv_str);
        end if;
    exception
        when utl_file.invalid_path  then
            dbms_output.put_line('invalid path');
        when utl_file.invalid_mode  then
            dbms_output.put_line('invalid mode');
        when utl_file.invalid_filehandle  then
            dbms_output.put_line('invalid filehandle');
        when utl_file.invalid_operation  then
            dbms_output.put_line('invalid operation');
        when utl_file.read_error  then
            dbms_output.put_line('read error');
        when utl_file.write_error  then
            dbms_output.put_line('write error');
        when utl_file.internal_error  then
            dbms_output.put_line('internal error');
        when others then
            dbms_output.put_line('ERROR (write_op) => '||sqlcode);
            dbms_output.put_line('MSG (write_op) => '||sqlerrm);

    end write_op;
    --
    function user_or_role(pv_grantee in dba_users.username%type) 
    return varchar2 is
        --
        cursor c_use (cp_grantee in dba_users.username%type) is
        select  'USER' userrole 
        from    dba_users u 
        where   u.username=cp_grantee 
        union 
        select  'ROLE' userrole 
        from    dba_roles r 
        where   r.role=cp_grantee;
        --
        lv_use c_use%rowtype;
        --
    begin
        open c_use(pv_grantee);
        fetch c_use into lv_use;
        close c_use;
        return lv_use.userrole;
    exception
        when others then
            dbms_output.put_line('ERROR (user_or_role) => '||sqlcode);
            dbms_output.put_line('MSG (user_or_role) => '||sqlerrm);
    end user_or_role;
    --
    function role_pwd(pv_role in dba_roles.role%type)
    return dba_roles.password_required%type is
    	--
	cursor c_role(cp_role in dba_roles.role%type) is
	select	r.password_required
	from	dba_roles r
	where	r.role=cp_role;
	--
	lv_role c_role%rowtype;
    	--
    begin
    	open c_role(pv_role);
    	fetch c_role into lv_role;
    	close c_role;
    	return lv_role.password_required;
    exception    	
        when others then
            dbms_output.put_line('ERROR (role_pwd) => '||sqlcode);
            dbms_output.put_line('MSG (role_pwd) => '||sqlerrm);
    end role_pwd;
    --
    procedure get_role (pv_role in varchar2) is
        --
        cursor c_main (cp_role in varchar2) is
	select	p.grantee,
		p.admin_option
	from	dba_role_privs p
	where	p.granted_role=cp_role;
        --
        lv_userrole dba_users.username%type;
        lv_tabstop number;
        --
        procedure get_users(pv_grantee in dba_roles.role%type,pv_tabstop in out number) is
            --
            lv_tab varchar2(50):='';
            lv_loop number;
            lv_user_or_role dba_users.username%type;
            --
            cursor c_user (cp_username in dba_role_privs.grantee%type) is
            select  d.grantee,
                    d.admin_option 
            from    dba_role_privs d
            where   d.granted_role=cp_username;
            --
        begin
            pv_tabstop:=pv_tabstop+1;
            for lv_loop in 1..pv_tabstop loop
                lv_tab:=lv_tab||chr(9);
            end loop;
            
            for lv_user in c_user(pv_grantee) loop
                lv_user_or_role:=user_or_role(lv_user.grantee);
                if lv_user_or_role = 'ROLE' then
	            if lv_user.grantee = 'PUBLIC' then
       			write_op(lv_tab||'Role => '||lv_user.grantee
       				||' (ADM = '||lv_user.admin_option
       				||'|PWD = '||role_pwd(lv_user.grantee)||')');
            	    else
       			write_op(lv_tab||'Role => '||lv_user.grantee
       				||' (ADM = '||lv_user.admin_option
      				||'|PWD = '||role_pwd(lv_user.grantee)||')'
       				||' which is granted to =>');
            	    end if;
                    get_users(lv_user.grantee,pv_tabstop);
                else
                    if upper('&&skip_user') = 'Y' and lv_user.grantee like upper('&&user_to_skip') then
                    	null;
                    else
	                write_op(lv_tab||'User => '||lv_user.grantee
                	    ||' (ADM = '||lv_user.admin_option||')');
                    end if;
                end if;
            end loop;
            pv_tabstop:=pv_tabstop-1;
            lv_tab:='';
        exception
            when others then
                dbms_output.put_line('ERROR (get_users) => '||sqlcode);
                dbms_output.put_line('MSG (get_users) => '||sqlerrm);        
        end get_users;
        --
    begin
        lv_tabstop:=1;
        for lv_main in c_main(pv_role) loop	
		lv_userrole:=user_or_role(lv_main.grantee);
		if lv_userrole='USER' then
                	if upper('&&skip_user') = 'Y' and lv_main.grantee like upper('&&user_to_skip') then
			                    	null;
                    	else
                	    write_op(chr(9)||'User => '||lv_main.grantee
                		||' (ADM = '||lv_main.admin_option||')');
			end if;
		else
            		if lv_main.grantee='PUBLIC' then
            			write_op(chr(9)||'Role => '||lv_main.grantee
            				||' (ADM = '||lv_main.admin_option
            				||'|PWD = '||role_pwd(lv_main.grantee)||')');
            		else
            			write_op(chr(9)||'Role => '||lv_main.grantee
            				||' (ADM = '||lv_main.admin_option
            				||'|PWD = '||role_pwd(lv_main.grantee)||')'
            				||' which is granted to =>');
            		end if;
                	get_users(lv_main.grantee,lv_tabstop);
		end if;
	end loop;
    exception
        when others then
            dbms_output.put_line('ERROR (get_role) => '||sqlcode);
            dbms_output.put_line('MSG (get_role) => '||sqlerrm);
    end get_role;
begin
	lv_file_or_screen:= upper('&&output_method');
	if lv_file_or_screen='F' then
        	open_file('&&file_name','&&output_dir');
	end if;
    	write_op('Investigating Role => '||upper('&&role_to_find')||' (PWD = '
    		||role_pwd(upper('&&role_to_find'))||') which is granted to =>');
    	write_op('====================================================================');
	get_role(upper('&&role_to_find'));
	if lv_file_or_screen='F' then
        	close_file;
	end if;
exception
    when others then
        dbms_output.put_line('ERROR (main) => '||sqlcode);
        dbms_output.put_line('MSG (main) => '||sqlerrm);

end;
/
prompt For updates please visit http://www.petefinnigan.com/tools.htm
prompt
spool off

whenever sqlerror continue