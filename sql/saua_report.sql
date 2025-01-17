--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: saua_report.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
--  Editor....: Stefan Oehrli
--  Date......: 2023.12.13
--  Usage.....: 
--  Purpose...: Run a couple of audit report queries  
--  Notes.....: 
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- setup SQLPlus environment
SET SERVEROUTPUT ON
SET LINESIZE 200 PAGESIZE 200
SPOOL saua_report.log

PROMPT
PROMPT ================================================================================
PROMPT = Show information about the audit trails
PROMPT ================================================================================
@saua_info.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show local audit policies policies. A join of the views AUDIT_UNIFIED_POLICIES
PROMPT = and AUDIT_UNIFIED_ENABLED_POLICIES
PROMPT ================================================================================
@saua_pol.sql 

PROMPT
PROMPT ================================================================================
PROMPT = Show Unified Audit trail storage usage
PROMPT ================================================================================
@sdua_usage.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show Unified Audit trail table and partition size
PROMPT ================================================================================
@saua_tabsize.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by action for current DBID
PROMPT ================================================================================
@saua_teact.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by client_program_name for current DBID
PROMPT ================================================================================
@saua_tecli.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by DBID
PROMPT ================================================================================
@saua_tedbid.sql

PROMPT
PROMPT ================================================================================
PROMPT = 
PROMPT ================================================================================
@saua_teusr.sql Show top unified audit events by dbusername for current DBID

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by object_name for current DBID
PROMPT ================================================================================
@saua_teobj.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by Object Name without Oracle maintained schemas
PROMPT = for current DBID
PROMPT ================================================================================
@saua_teobjusr.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by object_schema for current DBID
PROMPT ================================================================================
@saua_teown.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by os_username for current DBID
PROMPT ================================================================================
@saua_teosusr.sql 

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by unified_audit_policies for current DBID
PROMPT ================================================================================
@saua_tepol.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by unified_audit_policies, dbusername, action
PROMPT = for current DBID
PROMPT ================================================================================
@saua_tepoldet.sql

PROMPT
PROMPT ================================================================================
PROMPT = Show top unified audit events by userhost for current DBID
PROMPT ================================================================================
@saua_tehost.sql
