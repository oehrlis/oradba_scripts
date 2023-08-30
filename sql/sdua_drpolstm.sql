--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: sdua_drpolstm.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.06.05
--  Revision..:  
--  Purpose...: Generate statements to drop all audit policies as currently set
--              in AUDIT_UNIFIED_ENABLED_POLICIES.
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET PAGESIZE 2000  HEADING ON  VERIFY OFF
SET LINESIZE 300
SET SERVEROUTPUT ON
SET LONG 100000
SET LONGCHUNKSIZE 100000
SET TRIMSPOOL ON
SET WRAP OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
COLUMN code             FORMAT A160 WRAP HEADING "Code"

SELECT
    'DROP AUDIT POLICY '
    || policy_name
    || ';'
    || CHR(10) AS code
FROM
    audit_unified_policies
WHERE
    oracle_supplied = 'NO'
GROUP BY 
    policy_name;
-- EOF -------------------------------------------------------------------------
