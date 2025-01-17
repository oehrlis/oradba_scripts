--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: saua_tepoldet.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.07.06
--  Revision..:  
--  Purpose...: Show top unified audit events by unified_audit_policies, dbusername,
--              action for current DBID
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';
COLUMN unified_audit_policies   FORMAT A60 WRAP HEADING "Policies"
COLUMN dbusername               FORMAT A25 WRAP HEADING "Policies"
COLUMN events                   FORMAT 9,999,999,999 heading "Audit Events"

SPOOL saua_tepoldet.log
SELECT
    nvl(unified_audit_policies, 'n/a') unified_audit_policies,
    nvl(dbusername, 'n/a') dbusername,
    nvl(action_name, 'n/a') action_name,
    COUNT(*)                events
FROM
    unified_audit_trail
WHERE
    dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
GROUP BY
    unified_audit_policies,
    dbusername,
    action_name
ORDER BY
    events DESC;
SPOOL OFF
-- EOF -------------------------------------------------------------------------
