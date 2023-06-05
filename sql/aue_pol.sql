--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: aue_pol.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.10.24
--  Revision..:  
--  Purpose...: Top unified audit events by unified_audit_policies for all DBID
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Licensed under the Universal Permissive License v 1.0 as 
--              shown at http://oss.oracle.com/licenses/upl.
--------------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
--------------------------------------------------------------------------------
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';
COLUMN unified_audit_policies   FORMAT A60 WRAP HEADING "Audit Policy"
COLUMN events                   FORMAT 9,999,999,999 heading "Audit Events"

SELECT
    nvl(unified_audit_policies, 'n/a') unified_audit_policies,
    COUNT(*)                events
FROM
    unified_audit_trail
GROUP BY
    unified_audit_policies
ORDER BY
    events DESC;
-- EOF -------------------------------------------------------------------------
