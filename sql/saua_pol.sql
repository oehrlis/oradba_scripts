--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: saua_pol.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
--  Editor....: Stefan Oehrli
--  Date......: 2023.07.06
--  Usage.....: 
--  Purpose...: Show local audit policies policies  
--  Notes.....: 
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- setup SQLPlus environment
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200

COLUMN policy_name          FORMAT A40 WRAP HEADING "Policy Name"
COLUMN entity_name          FORMAT A20 WRAP HEADING "Entry Name"
COLUMN audit_condition      FORMAT A50 WRAP HEADING "Policy Condition"
COLUMN comments             FORMAT A60 WRAP HEADING "Comment"
COLUMN common               FORMAT A10 WRAP HEADING "Common"
COLUMN inherited            FORMAT A10 WRAP HEADING "Inherited"
COLUMN oracle_supplied      FORMAT A10 WRAP HEADING "Oracle"
COLUMN condition_eval_opt   FORMAT A9 WRAP HEADING "Evaluated"
COLUMN audit_only_toplevel  FORMAT A9 WRAP HEADING "Top Level"

SELECT
    u.policy_name,
    nvl((
        SELECT
            'YES'
        FROM
            audit_unified_enabled_policies a
        WHERE
            a.policy_name = u.policy_name
        GROUP BY
            a.policy_name
    ), 'NO') active,
    u.condition_eval_opt,
    u.common,
    u.inherited,
    u.audit_only_toplevel,
    u.oracle_supplied,
    u.audit_condition
FROM
    audit_unified_policies u
GROUP BY
    u.policy_name,
    u.condition_eval_opt,
    u.common,
    u.inherited,
    u.audit_only_toplevel,
    u.oracle_supplied,
    u.audit_condition
ORDER BY
    u.policy_name;
-- EOF -------------------------------------------------------------------------