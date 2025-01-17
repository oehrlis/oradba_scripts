--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: sdua_enpolstm.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.06.05
--  Revision..:  
--  Purpose...: Generate statements to enable all audit policies as currently set
--              in AUDIT_UNIFIED_ENABLED_POLICIES.
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET PAGESIZE 2000  HEADING ON  VERIFY OFF
SET LINESIZE 160
SET SERVEROUTPUT ON
SET LONG 100000
SET LONGCHUNKSIZE 100000
SET TRIMSPOOL ON
SET WRAP OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';
COLUMN code             FORMAT A160 WRAP HEADING "Code"

SELECT code FROM(
SELECT
    'AUDIT POLICY '
    || policy_name
    || ';'
    || CHR(10) AS code
FROM
    audit_unified_enabled_policies
WHERE
        entity_name = 'ALL USERS'
    AND entity_type = 'USER'
UNION ALL
SELECT
    'AUDIT POLICY '
    || policy_name
    || ' BY USERS WITH GRANTED ROLES '
    || entity_name
    || ';'
    || CHR(10) AS code
FROM
    audit_unified_enabled_policies
WHERE
    entity_type = 'ROLE'
UNION ALL
SELECT
    'AUDIT POLICY '
    || policy_name
    || ' BY '
    || entity_name
    || ';'
    || CHR(10) AS code
FROM
    audit_unified_enabled_policies
WHERE
        entity_name <> 'ALL USERS'
    AND entity_type = 'USER'
);
-- EOF -------------------------------------------------------------------------
