--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: sdua_prgstm.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.07.06
--  Revision..:  
--  Purpose...: Generate Unified Audit trail storage purge statements
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
            1          AS id,
            '-- Purge audit trail using last archive timestamp for current DBID ('
            || con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
            || ')'
            || CHR(10) AS code
        FROM
            dual
        UNION
        SELECT
            2          AS id,
            'BEGIN'
            || CHR(10)
            || '  dbms_audit_mgmt.clean_audit_trail('
            || CHR(10)
            || '    audit_trail_type         =>  dbms_audit_mgmt.audit_trail_unified,'
            || CHR(10)
            || '    use_last_arch_timestamp  =>  TRUE);'
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
            3          AS id,
            '-- Purge all audit trail for current DBID ('
            || con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
            || ')'
            || CHR(10) AS code
        FROM
            dual
        UNION
        SELECT
            4          AS id,
            'BEGIN'
            || CHR(10)
            || '  dbms_audit_mgmt.clean_audit_trail('
            || CHR(10)
            || '    audit_trail_type         =>  dbms_audit_mgmt.audit_trail_unified,'
            || CHR(10)
            || '    use_last_arch_timestamp  =>  FALSE);'
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
            5                                                      AS id,
            '-- Purge all audit trail for foreign DBID' || CHR(10) AS code
        FROM
            dual
        UNION
        SELECT
            *
        FROM
            (
                SELECT
                    6          AS id,
                    'BEGIN'
                    || CHR(10)
                    || '  dbms_audit_mgmt.clean_audit_trail('
                    || CHR(10)
                    || '    audit_trail_type         =>  dbms_audit_mgmt.audit_trail_unified,'
                    || CHR(10)
                    || '    use_last_arch_timestamp  =>  FALSE,'
                    || CHR(10)
                    || '    database_id              =>  '
                    || dbid
                    || ');'
                    || CHR(10)
                    || 'END;'
                    || CHR(10)
                    || '/'
                    || CHR(10)
                    || CHR(10) AS code
                FROM
                    unified_audit_trail
                WHERE
                    dbid <> con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
                GROUP BY
                    dbid
            )
        WHERE
            code IS NOT NULL
        UNION
        SELECT
            10                                         AS id,
            '-- Set last archive timestamp' || CHR(10) AS code
        FROM
            dual
        UNION
        SELECT
            11         AS id,
            'BEGIN'
            || CHR(10)
            || '  dbms_audit_mgmt.set_last_archive_timestamp('
            || CHR(10)
            || '    audit_trail_type         =>  dbms_audit_mgmt.audit_trail_unified,'
            || CHR(10)
            || '    last_archive_time        =>  to_timestamp('''
            || to_char(sysdate - 1 / 12, 'DD.MM.YYYY HH24:MI:SS')
            || ''',''DD.MM.YYYY HH24:MI:SS''));'
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
            12                                           AS id,
            '-- Clear last archive timestamp' || CHR(10) AS code
        FROM
            dual
        UNION
        SELECT
            13         AS id,
            'BEGIN'
            || CHR(10)
            || '  dbms_audit_mgmt.clear_last_archive_timestamp('
            || CHR(10)
            || '    audit_trail_type         =>  dbms_audit_mgmt.audit_trail_unified);'
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
