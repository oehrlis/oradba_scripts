--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: user_info.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: Report on DB Users		 
--  Usage.....: @user_info
--  Notes.....: 
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
--set feedback off
col urep01_username head "NAME"  for a15
col urep01_account_status head "STATUS" for a18
col urep01_lock_date head "LOCKED" for a18
col urep01_expiry_date head "EXPIRED" for a18
col urep01_created head "CREATED" for a18
col urep01_default_tablespace head "DEFAULT TS" for a10
col urep01_temporary_tablespace head "TEMP TS" for a10
col urep01_profile head "PROFILE" for a10
col urep01_id head "ID" for 999999
-- define some colums and variable
col urep01_min_time head "Date" for a20 new_value _min_time
col urep01_max_time head "Date" for a20 new_value _max_time
col urep01_now head "Now" for a20 new_value _now
col urep01_delta head "Date" for a20 new_value _delta
col urep01_dbname head "DB Name" for a10 new_value _dbname

-- get DB Name and other stuff.....
set termout off
select name urep01_dbname from v$database;
select 
  to_char(MIN(TIMESTAMP),'DD.MM.YY') urep01_min_time, 
  to_char(MAX(TIMESTAMP),'DD.MM.YY') urep01_max_time
--  extract( DAY from (MAX(TIMESTAMP)-MIN(TIMESTAMP))) urep01_delta 
from dba_audit_session;
select to_char(sysdate,'DD.MM.YY HH24:MI:SS') urep01_now from dual;
set termout on

-- do the stuff
prompt
prompt #################################################################################################
prompt
prompt USER REPORT for &_dbname created at &_now
prompt
prompt #################################################################################################
prompt
prompt DB User
prompt =================================================================================================

select
  user_id urep01_id,
  username urep01_username,
  account_status urep01_account_status, 
  lock_date urep01_lock_date,
  expiry_date urep01_expiry_date,
  created urep01_created, 
  default_tablespace urep01_default_tablespace,
  temporary_tablespace urep01_temporary_tablespace,
  profile urep01_profile
from
  dba_users
--  where rownum <11
order by 1;

prompt DB Profiles
prompt =================================================================================================
select * from dba_profiles order by 1;

prompt DB Roles
prompt =================================================================================================
select * from  dba_roles order by 1;
prompt =================================================================================================
prompt
-- EOF ---------------------------------------------------------------------