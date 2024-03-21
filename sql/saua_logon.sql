--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: saua_logon.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.12.14
--  Revision..:  
--  Purpose...: Show logins
--  Notes.....:  
--  Reference.: Requires AUDIT_VIEWER or AUDIT_ADMIN role
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- define default values
DEFINE _days    = 1
-- assinge default values
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE days     = &1 &_days
SET FEEDBACK ON
SET VERIFY ON

-- start to spool
SPOOL saua_logfail.log

-- format SQLPlus output and behavior
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET LINESIZE 180
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

COLUMN event_timestamp          FORMAT A20 WRAP HEADING "Session Start"
COLUMN dbusername               FORMAT A12 WRAP HEADING "DB User"
COLUMN userhost                 FORMAT A25 heading "User Host"
COLUMN terminal                 FORMAT A8 heading "Terminal"
COLUMN external_userid          FORMAT A25 heading "External User"
COLUMN global_userid            FORMAT A25 heading "Global User"
COLUMN return_code              FORMAT 99999 heading "Error"
COLUMN unified_audit_policies   FORMAT A50 WRAP HEADING "Policies"
 
TTITLE  'Logins'
SELECT
    event_timestamp,
    dbusername,
    userhost,
    terminal,
    external_userid,
    global_userid,
    return_code
    ,unified_audit_policies
    --,sql_text
FROM
    unified_audit_trail
WHERE
    ( '&days' IS NULL OR event_timestamp >= sysdate - &days ) AND
    action_name='LOGON'
ORDER BY
    event_timestamp ASC,
    entry_id ASC;

UNDEFINE def_sessionid sessionid
UNDEFINE 1
TTITLE OFF

SPOOL OFF
-- EOF -------------------------------------------------------------------------