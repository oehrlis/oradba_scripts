--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: sdua_stostm.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.07.06
--  Revision..:  
--  Purpose...: Generate Unified Audit trail storage usage modification statements
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET PAGESIZE 200  HEADING ON  VERIFY OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
COLUMN code             format a80 wrap heading "Code"
SELECT
    code
FROM
    (
        SELECT
            1                                                            AS id,
            '-- Alter unified audit trail partition interval ('
            || con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
            || ')' || CHR(10) AS code
        FROM
            dual
        UNION
        SELECT
            2          AS id,
            'BEGIN'
            || CHR(10)
            || '  dbms_audit_mgmt.alter_partition_interval('
            || CHR(10)
            || '    interval_number       => 1,'
            || CHR(10)
            || '    interval_frequency    => ''DAY'');'
            || CHR(10)
            || 'END;'
            || CHR(10)
            || '/'
            || CHR(10)
            || CHR(10) AS code
        FROM
            dual
        UNION
        SELECT
            3                                                    AS id,
            '-- Alter unified audit trail tablespace' || CHR(10) AS code
        FROM
            dual
        UNION
        SELECT
            4          AS id,
            'BEGIN'
            || CHR(10)
            || '  dbms_audit_mgmt.set_audit_trail_location('
            || CHR(10)
            || '    audit_trail_type            => dbms_audit_mgmt.audit_trail_unified,'
            || CHR(10)
            || '    audit_trail_location_value  =>  ''AUDIT_DATA'');'
            || CHR(10)
            || 'END;'
            || CHR(10)
            || '/'
            || CHR(10)
            || CHR(10) AS code
        FROM
            dual
            UNION
        SELECT
            5                                                    AS id,
            '-- Load spillover OS audit files in a unified audit trail' || CHR(10) AS code
        FROM
            dual
        UNION
        SELECT
            6          AS id,
            'BEGIN'
            || CHR(10)
            || '  dbms_audit_mgmt.load_unified_audit_files();'
            || CHR(10)
            || 'END;'
            || CHR(10)
            || '/'
            || CHR(10)
            || CHR(10) AS code
        FROM
            dual
    );
-- EOF -------------------------------------------------------------------------
