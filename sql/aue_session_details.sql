--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: aue_session_details.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.10.24
--  Revision..:  
--  Purpose...: List entries of a particular audit session
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Licensed under the Universal Permissive License v 1.0 as 
--              shown at http://oss.oracle.com/licenses/upl.
--------------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
--------------------------------------------------------------------------------
-- define default values
DEFINE def_sessionid   = '1'

-- assign default value for parameter if argument 1,2 or 3 is empty
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
COLUMN def_sessionid NEW_VALUE def_sessionid NOPRINT
SELECT sys_context('userenv','unified_audit_sessionid') def_sessionid FROM dual;
DEFINE sessionid                 = &1 &def_sessionid

SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET LINESIZE 180
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

COLUMN event_timestamp          FORMAT A20 WRAP HEADING "Session Start"
COLUMN dbusername               FORMAT A12 WRAP HEADING "DB User"
COLUMN entry_id                 FORMAT 99999 heading "Entry"
COLUMN statement_id             FORMAT 99999 heading "Stmt ID"
COLUMN action_name              FORMAT A20 WRAP HEADING "Action"
COLUMN return_code              FORMAT 99999 heading "Error"
COLUMN object_schema            FORMAT A10 WRAP HEADING "Schema"
COLUMN object_name              FORMAT A25 WRAP HEADING "Object"
COLUMN unified_audit_policies   FORMAT A50 WRAP HEADING "Policies"
COLUMN sql_text                 FORMAT A50 WRAP HEADING "SQL Text"

TTITLE  'Detail for session &sessionid'
SELECT
    event_timestamp,
    dbusername,
    entry_id,
    statement_id,
    action_name,
    return_code,
    object_schema,
    object_name,
    unified_audit_policies
    --,sql_text
FROM
    unified_audit_trail
WHERE
    sessionid = &sessionid OR proxy_sessionid = &sessionid
ORDER BY
    event_timestamp ASC,
    entry_id ASC;

UNDEFINE def_sessionid sessionid
UNDEFINE 1
TTITLE
-- EOF -------------------------------------------------------------------------
