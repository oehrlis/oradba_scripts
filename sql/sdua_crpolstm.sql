--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: sdua_crpolstm.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.06.05
--  Revision..:  
--  Purpose...: Generate statements to create all audit policies as currently set
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
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';
COLUMN code             FORMAT A160 WRAP HEADING "Code"

exec DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);

SELECT
    '-- Create statement for audit policy '
    || policy_name
    || CHR(10)
    || TRIM(TRAILING CHR(10) FROM TRIM(TRIM(CHR(10) FROM command)))
    || ';'
    || CHR(10)
    || CHR(10) AS code
FROM
    (
        SELECT
            dbms_metadata.get_ddl('AUDIT_POLICY', policy_name) AS command,
            policy_name
        FROM
            audit_unified_policies
        WHERE
            oracle_supplied = 'NO'
        GROUP BY
            policy_name
        UNION ALL
        SELECT
            to_clob('COMMENT ON '
                    || policy_name
                    || ' IS '
                    || comments) AS command,
            policy_name
        FROM
            audit_unified_policy_comments
    );
-- EOF -------------------------------------------------------------------------
