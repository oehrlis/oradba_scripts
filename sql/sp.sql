----------------------------------------------------------------------------
--     $Id: $
----------------------------------------------------------------------------
--     Trivadis AG, Infrastructure Managed Services
--     Europa-Strasse 5, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--     File-Name........:  sp.sql
--     Author...........:  Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--     Editor...........:  $LastChangedBy:   $
--     Date.............:  $LastChangedDate: $
--     Revision.........:  $LastChangedRevision: $
--     Purpose..........:  List user with certain system privileges 
--                         granted directly or through roles		 
--     Usage............:  @sq <SYSTEM PRIVILEGE> or % for all
--     Group/Privileges.:  SYS (or grant manually to a DBA)
--     Input parameters.:  System privilege or part of
--     Called by........:  as DBA or user with access to dba_ts_quotas
--                         dba_sys_privs,dba_role_privs,dba_users
--     Restrictions.....:  unknown
--     Notes............:  --
----------------------------------------------------------------------------
--     Revision history.:  
----------------------------------------------------------------------------
col sp_username head "User Name" for a20
col sp_tablespace_name head "Granted through" for a25
col sp_privilege head "Privilege" for a25
col sp_path head "Path" for a60

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
