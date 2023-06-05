--------------------------------------------------------------------------------
--  Trivadis - Part of Accenture, Platform Factory - Data Platforms
--  Saegereistrasse 29, 8152 Glattbrugg, Switzerland
--------------------------------------------------------------------------------
--  Name......: au_enable_audit_policies_loc.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
--  Editor....: Stefan Oehrli
--  Date......: 2023.04.28
--  Usage.....: 
--  Purpose...: Enable custom local audit policies
--  Notes.....: 
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- setup SQLPlus environment
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200
COL policy_name FOR A40
COL entity_name FOR A30
COL comments FOR A80

-- enable default Oracle policies
-- AUDIT POLICY ora_logon_failures WHENEVER NOT SUCCESSFUL;
-- AUDIT POLICY ora_secureconfig;
-- AUDIT POLICY ora_account_mgmt;
-- AUDIT POLICY ora_database_parameter;
-- AUDIT POLICY ora_cis_recommendations;

-- enable SecBench specific audit policies
AUDIT POLICY sb_loc_all_logon_events;
AUDIT POLICY sb_loc_all_act_priv_usr BY SYS, SYSKM, SYSRAC, PUBLIC;
AUDIT POLICY sb_loc_all_act_priv_usr BY USERS WITH GRANTED ROLES dba,datapump_exp_full_database, imp_full_database, exp_full_database, datapump_imp_full_database;
AUDIT POLICY sb_loc_all_act_proxy_usr;
-- AUDIT POLICY sb_loc_all_act_direct_acc;
-- AUDIT POLICY sb_loc_all_act_direct_acc_stm;
-- AUDIT POLICY sb_loc_all_act_named_usr;
-- AUDIT POLICY sb_loc_all_act_named_usr BY SOE;
AUDIT POLICY sb_loc_all_dp_events;
AUDIT POLICY sb_loc_dir_acc;
AUDIT POLICY sb_loc_acc_mgmt;
AUDIT POLICY sb_loc_critical_db_act;
AUDIT POLICY sb_loc_db_schema_changes;
AUDIT POLICY sb_loc_secure_config;

-- List enabled audit policies
SELECT * FROM audit_unified_enabled_policies;
-- EOF -------------------------------------------------------------------------