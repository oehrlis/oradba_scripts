--------------------------------------------------------------------------------
--  Trivadis - Part of Accenture, Platform Factory - Data Platforms
--  Saegereistrasse 29, 8152 Glattbrugg, Switzerland
--------------------------------------------------------------------------------
--  Name......: au_disable_audit_policies.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
--  Editor....: Stefan Oehrli
--  Date......: 2023.03.06
--  Usage.....: 
--  Purpose...: Initialize Audit environment
--  Notes.....: 
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200

SHOW con_name

-- List enabled audit policies
SELECT * FROM audit_unified_enabled_policies;

DECLARE
    v_sql       VARCHAR2(4000);
BEGIN
    FOR r_audit_unified_enabled_policies IN (SELECT policy_name,entity_name,entity_type FROM audit_unified_enabled_policies) LOOP    
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

-- List audit policies not maintained by Oracle
SELECT policy_name, common, oracle_supplied FROM audit_unified_policies
WHERE oracle_supplied<>'YES' GROUP BY policy_name, common, oracle_supplied ORDER BY 1;

-- List Oracle maintained audit policies
SELECT policy_name, common, oracle_supplied FROM audit_unified_policies
GROUP BY policy_name, common, oracle_supplied ORDER BY 1;

-- List enabled audit policies
SELECT * FROM audit_unified_enabled_policies ORDER BY 1;
-- EOF -------------------------------------------------------------------------