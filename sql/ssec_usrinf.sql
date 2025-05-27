--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: ssec_usrinf.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2024.08.21
--  Revision..:  
--  Purpose...: Show session information of current user based on sys_context
--  Usage.....: @ssec_usrinf.sql
--  Notes.....: 
--  Reference.: Inspired by TVD-BasEnv sql sousrinf.sql
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET ECHO OFF
SET serveroutput ON SIZE 10000
SET PAGESIZE 200

SELECT '- Database Information' as TEXT FROM dual
UNION ALL SELECT '--------------------' FROM dual
UNION ALL SELECT '- DB_NAME               : ' || sys_context('userenv','DB_NAME') FROM dual
UNION ALL SELECT '- DB_DOMAIN             : ' || sys_context('userenv','DB_DOMAIN') FROM dual
UNION ALL SELECT '- INSTANCE              : ' || sys_context('userenv','INSTANCE') FROM dual
UNION ALL SELECT '- INSTANCE_NAME         : ' || sys_context('userenv','INSTANCE_NAME') FROM dual
UNION ALL SELECT '- SERVER_HOST           : ' || sys_context('userenv','SERVER_HOST') FROM dual
UNION ALL SELECT '- ' FROM dual
UNION ALL SELECT '- Authentication Information' FROM dual
UNION ALL SELECT '----------------------------' FROM dual
UNION ALL SELECT '- SESSION_USER          : ' || sys_context('userenv','SESSION_USER') FROM dual
UNION ALL SELECT '- PROXY_USER            : ' || sys_context('userenv','PROXY_USER') FROM dual
UNION ALL SELECT '- AUTHENTICATION_METHOD : ' || sys_context('userenv','AUTHENTICATION_METHOD') FROM dual
UNION ALL SELECT '- IDENTIFICATION_TYPE   : ' || sys_context('userenv','IDENTIFICATION_TYPE') FROM dual
UNION ALL SELECT '- NETWORK_PROTOCOL      : ' || sys_context('userenv','NETWORK_PROTOCOL') FROM dual
UNION ALL SELECT '- OS_USER               : ' || sys_context('userenv','OS_USER') FROM dual
UNION ALL SELECT '- AUTHENTICATED_IDENTITY: ' || sys_context('userenv','AUTHENTICATED_IDENTITY') FROM dual
UNION ALL SELECT '- ENTERPRISE_IDENTITY   : ' || sys_context('userenv','ENTERPRISE_IDENTITY') FROM dual
UNION ALL SELECT '- ' FROM dual
UNION ALL SELECT '- Other Information' FROM dual
UNION ALL SELECT '-----------------' FROM dual
UNION ALL SELECT '- ISDBA                 : ' || sys_context('userenv','ISDBA') FROM dual
UNION ALL SELECT '- CLIENT_INFO           : ' || sys_context('userenv','CLIENT_INFO') FROM dual
UNION ALL SELECT '- CLIENT_PROGRAM_NAME   : ' || sys_context('userenv','CLIENT_PROGRAM_NAME') FROM dual
UNION ALL SELECT '- CLIENT_IDENTIFIER     : ' || sys_context('userenv','CLIENT_IDENTIFIER') FROM dual
UNION ALL SELECT '- HOST                  : ' || sys_context('userenv','HOST') FROM dual
UNION ALL SELECT '- IP_ADDRESS            : ' || sys_context('userenv','IP_ADDRESS') FROM dual
UNION ALL SELECT '- TERMINAL              : ' || sys_context('userenv','TERMINAL') FROM dual;
-- - EOF -----------------------------------------------------------------------