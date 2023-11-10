--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: saua_pol.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
--  Editor....: Stefan Oehrli
--  Date......: 2023.07.06
--  Usage.....: 
--  Purpose...: Show local audit policies policies. A join of the views
--              AUDIT_UNIFIED_POLICIES and AUDIT_UNIFIED_ENABLED_POLICIES  
--  Notes.....: 
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- setup SQLPlus environment
SET SERVEROUTPUT ON
SET LINESIZE 170 PAGESIZE 200

COLUMN policy_name          FORMAT A30 WRAP HEADING "Policy Name"
COLUMN active               FORMAT A6 WRAP HEADING "Active"
COLUMN entity_name          FORMAT A26 WRAP HEADING "Entity Name"
COLUMN entity_type          FORMAT A5 WRAP HEADING "Type"
COLUMN enabled_option       FORMAT A16 WRAP HEADING "Option"
COLUMN audit_condition      FORMAT A50 WRAP HEADING "Policy Condition"
COLUMN comments             FORMAT A60 WRAP HEADING "Comment"
COLUMN common               FORMAT A3 WRAP HEADING "COM"
COLUMN inherited            FORMAT A3 WRAP HEADING "INH"
COLUMN oracle_supplied      FORMAT A3 WRAP HEADING "ORA"
COLUMN condition_eval_opt   FORMAT A7 WRAP HEADING "Eval"
COLUMN audit_only_toplevel  FORMAT A3 WRAP HEADING "TOP"
COLUMN success              FORMAT A3 WRAP HEADING "FAL"
COLUMN failure              FORMAT A3 WRAP HEADING "SUC"

SELECT
    nvl(u.policy_name, a.policy_name)                 AS policy_name,
    decode(a.policy_name, u.policy_name, 'YES', 'NO') AS active,
    a.enabled_option,
    a.entity_name,
    a.entity_type,
    u.condition_eval_opt,
    a.success,
    a.failure,
    u.common,
    u.inherited,
    u.audit_only_toplevel,
    u.oracle_supplied,
    u.audit_condition
FROM
    audit_unified_policies         u
    FULL JOIN audit_unified_enabled_policies a ON u.policy_name = a.policy_name
GROUP BY
    u.policy_name,
    a.policy_name,
    a.enabled_option,
    a.entity_name,
    a.entity_type,
    a.success,
    a.failure,
    u.audit_condition,
    u.condition_eval_opt,
    u.common,
    u.inherited,
    u.audit_only_toplevel,
    u.oracle_supplied
ORDER BY
    u.policy_name,
    active,
    a.enabled_option,
    a.entity_name;
-- EOF -------------------------------------------------------------------------