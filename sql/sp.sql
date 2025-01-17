--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: sp.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.10.24
--  Revision..:  
--  Purpose...: List user with certain system privileges granted directly or
--              through roles
--  Usage.....: @sq <SYSTEM PRIVILEGE> or %FOR all
--  Notes.....: Called as DBA or user with access to dba_ts_quotas dba_sys_privs,
--              dba_role_privs,dba_users
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
COL sp_username HEAD "User Name" FOR a20
COL sp_tablespace_name HEAD "Granted through" FOR a25
COL sp_privilege HEAD "Privilege" FOR a25
COL sp_path HEAD "Path" FOR a60

SELECT 
  grantee sp_username, 
  privilege sp_privilege, 
  granted_role,
  DECODE(p,'=>'||grantee,'direct',p) sp_path
FROM (
  SELECT 
    grantee, 
    privilege granted_role,
    (SELECT DISTINCT privilege FROM dba_sys_privs WHERE privilege LIKE UPPER('%&1%')) privilege,
    SYS_CONNECT_BY_PATH(grantee, '=>') p
  FROM (
    SELECT 
      grantee, 
      privilege
    FROM dba_sys_privs
    UNION ALL
    SELECT 
      grantee, 
      granted_role privilege
    FROM 
      dba_role_privs)
  START WITH privilege LIKE UPPER('%&1%')
  CONNECT BY PRIOR grantee = privilege )
WHERE 
-- we just whant to see the users not the roles
  (grantee in (SELECT username FROM dba_users)
  OR grantee = 'PUBLIC')
ORDER BY sp_username;
-- EOF ---------------------------------------------------------------------