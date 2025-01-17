--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: spsec_usrinf.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2024.08.21
--  Revision..:  
--  Purpose...: Show session information of current user
--  Notes.....: Requires access to V$SESSION
--  Reference.: Inspired by TVD-BasEnv sql sousrinf.sql
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET ECHO OFF
SET serveroutput ON SIZE 10000
DECLARE
  vSessionRec  v$session%ROWTYPE;
BEGIN
  SELECT * INTO vSessionRec
    FROM v$session
    WHERE audsid=USERENV('sessionid') AND type='USER' AND rownum<2;
 
  dbms_output.put_line('Database Information');
  dbms_output.put_line('--------------------');
  dbms_output.put_line('- DB_NAME               : '||sys_context('userenv','DB_NAME'));
  dbms_output.put_line('- DB_DOMAIN             : '||sys_context('userenv','DB_DOMAIN'));
  dbms_output.put_line('- INSTANCE              : '||sys_context('userenv','INSTANCE'));
  dbms_output.put_line('- INSTANCE_NAME         : '||sys_context('userenv','INSTANCE_NAME'));
  dbms_output.put_line('- SERVER_HOST           : '||sys_context('userenv','SERVER_HOST'));
  dbms_output.put_line('-');
 
  dbms_output.put_line('Authentication Information');
  dbms_output.put_line('----------------------------');
  dbms_output.put_line('- SESSION_USER          : '||sys_context('userenv','SESSION_USER'));
  dbms_output.put_line('- PROXY_USER            : '||sys_context('userenv','PROXY_USER'));
  dbms_output.put_line('- AUTHENTICATION_METHOD : '||sys_context('userenv','AUTHENTICATION_METHOD'));
  dbms_output.put_line('- IDENTIFICATION_TYPE   : '||sys_context('userenv','IDENTIFICATION_TYPE'));
  dbms_output.put_line('- NETWORK_PROTOCOL      : '||sys_context('userenv','NETWORK_PROTOCOL'));
  dbms_output.put_line('- OS_USER               : '||sys_context('userenv','OS_USER'));
  dbms_output.put_line('- AUTHENTICATED_IDENTITY: '||sys_context('userenv','AUTHENTICATED_IDENTITY'));
  dbms_output.put_line('- ENTERPRISE_IDENTITY   : '||sys_context('userenv','ENTERPRISE_IDENTITY'));
  dbms_output.put_line('-');
 
  dbms_output.put_line('Other Information');
  dbms_output.put_line('-----------------');
  dbms_output.put_line('- ISDBA                 : '||sys_context('userenv','ISDBA'));
  dbms_output.put_line('- CLIENT_INFO           : '||sys_context('userenv','CLIENT_INFO'));
  dbms_output.put_line('- PROGRAM               : '||vSessionRec.program);
  dbms_output.put_line('- MODULE                : '||vSessionRec.module);
  dbms_output.put_line('- IP_ADDRESS            : '||sys_context('userenv','IP_ADDRESS'));
  dbms_output.put_line('- SID                   : '||vSessionRec.sid);
  dbms_output.put_line('- SERIAL#               : '||vSessionRec.serial#);
  dbms_output.put_line('- SERVER                : '||vSessionRec.server);
  dbms_output.put_line('- TERMINAL              : '||sys_context('userenv','TERMINAL'));
END;
/
-- - EOF -----------------------------------------------------------------------