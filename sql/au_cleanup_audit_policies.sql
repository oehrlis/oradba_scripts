--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: au_cleanup_audit_policies.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
--  Editor....: Stefan Oehrli
--  Date......: 2023.04.27
--  Usage.....: 
--  Purpose...: Disable all audit policies and drop all policies not maintained
--              by ORACLE
--  Notes.....: 
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200
COL policy_name FOR A40
COL entity_name FOR A30
COL comments FOR A80

SHOW con_name

-- List enabled audit policies
SELECT * FROM audit_unified_enabled_policies;

-- Disable all policies which are not from AVDF identified by policy name 'ORA_AV$'
DECLARE
    v_sql       VARCHAR2(4000);
BEGIN
    FOR r_audit_unified_enabled_policies IN (
            SELECT policy_name,entity_name,entity_type 
            FROM audit_unified_enabled_policies 
            WHERE policy_name NOT LIKE 'ORA_AV$%' OR entity_name IN ('SYSDG','SYSBACKUP')) LOOP    
        IF r_audit_unified_enabled_policies.entity_name='ALL USERS' THEN
            v_sql := 'NOAUDIT POLICY '
                || sys.dbms_assert.enquote_name(r_audit_unified_enabled_policies.policy_name);
        ELSIF r_audit_unified_enabled_policies.entity_type='ROLE' THEN
            v_sql := 'NOAUDIT POLICY '
                || sys.dbms_assert.enquote_name(r_audit_unified_enabled_policies.policy_name)
                || ' BY USERS WITH GRANTED ROLES '
                || sys.dbms_assert.enquote_name(r_audit_unified_enabled_policies.entity_name);
        ELSE
            v_sql := 'NOAUDIT POLICY '
                || sys.dbms_assert.enquote_name(r_audit_unified_enabled_policies.policy_name)
                || ' BY '
                || sys.dbms_assert.enquote_name(r_audit_unified_enabled_policies.entity_name);
        END IF;
        -- display NOAUDIT statement
        dbms_output.put_line('INFO : execute '||v_sql);
        --- execute NOAUDIT statement
        EXECUTE IMMEDIATE v_sql;
    END LOOP;
END;
/

-- workaround for BUG 30769454 Policy Created For Some Actions Are Not Showing In Audit_Unified_Policies
DECLARE
    v_sql       VARCHAR2(4000);
BEGIN
    FOR r_audit_unified_enabled_policies IN (
            SELECT object_name, object_type FROM dba_objects
            WHERE object_type = 'UNIFIED AUDIT POLICY' AND 
            object_name NOT IN (SELECT policy_name FROM audit_unified_enabled_policies WHERE policy_name NOT LIKE 'ORA_AV$%')
            ORDER BY object_name) LOOP    
        v_sql := 'NOAUDIT POLICY '
                || sys.dbms_assert.enquote_name(r_audit_unified_enabled_policies.object_name);
        -- display NOAUDIT statement
        dbms_output.put_line('INFO : execute '||v_sql);
        --- execute NOAUDIT statement
        EXECUTE IMMEDIATE v_sql;
    END LOOP;
END;
/

-- List enabled audit policies
SELECT * FROM audit_unified_enabled_policies;

-- List audit policies not maintained by Oracle
SELECT policy_name, common, oracle_supplied FROM audit_unified_policies
WHERE oracle_supplied<>'YES' GROUP BY policy_name, common, oracle_supplied;

-- Drop all audit policies which are not provided by Oracle. Either where
-- oracle_supplied<>'YES' AND policy_name NOT LIKE 'ORA_AV$'
DECLARE
    v_sql       VARCHAR2(4000);
BEGIN
    FOR r_audit_unified_enabled_policies IN (SELECT policy_name, common FROM audit_unified_policies WHERE oracle_supplied<>'YES' AND policy_name NOT LIKE 'ORA_AV$%' GROUP BY policy_name, common ) LOOP      
        v_sql := 'DROP AUDIT POLICY '
            || sys.dbms_assert.enquote_name(r_audit_unified_enabled_policies.policy_name);
        -- display DROP AUDIT statement
        dbms_output.put_line('INFO : execute '||v_sql);
        --- execute DROP AUDIT statement
        EXECUTE IMMEDIATE v_sql;
    END LOOP;
END;
/

-- workaround for BUG 30769454 Policy Created For Some Actions Are Not Showing In Audit_Unified_Policies
DECLARE
    v_sql       VARCHAR2(4000);
BEGIN
    FOR r_audit_unified_enabled_policies IN (
            SELECT object_name, object_type FROM dba_objects
            WHERE object_type = 'UNIFIED AUDIT POLICY' AND 
            object_name NOT IN (SELECT policy_name FROM audit_unified_policies WHERE oracle_supplied<>'YES' AND policy_name NOT LIKE 'ORA_AV$%' )
            ORDER BY object_name) LOOP    
        v_sql := 'NOAUDIT POLICY '
                || sys.dbms_assert.enquote_name(r_audit_unified_enabled_policies.object_name);
        -- display NOAUDIT statement
        dbms_output.put_line('INFO : execute '||v_sql);
        --- execute NOAUDIT statement
        EXECUTE IMMEDIATE v_sql;
    END LOOP;
END;
/

-- List audit policies not maintained by Oracle
SELECT policy_name, common, oracle_supplied FROM audit_unified_policies
WHERE oracle_supplied<>'YES' GROUP BY policy_name, common, oracle_supplied;

-- List Oracle maintained audit policies
SELECT policy_name, common, oracle_supplied FROM audit_unified_policies
WHERE oracle_supplied='YES' GROUP BY policy_name, common, oracle_supplied;
-- EOF -------------------------------------------------------------------------
