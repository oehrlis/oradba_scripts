--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: ld_profiles.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2019.08.19
--  Usage.....: @ld_profiles
--  Purpose...: Displays information about lockdown profiles.
--  Notes.....: 
--  Reference.: https://oracle-base.com/dba/script?category=18c&file=lockdown_profiles.sql
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
SET LINESIZE 180 PAGESIZE 200

COLUMN con_id FORMAT 999999
COLUMN pdb_name FORMAT A10
COLUMN profile_name FORMAT A13
COLUMN rule_type FORMAT A10
COLUMN rule FORMAT A20
COLUMN clause FORMAT A20
COLUMN clause_option FORMAT A20
COLUMN option_value FORMAT A20
COLUMN min_value FORMAT A9
COLUMN max_value FORMAT A9
COLUMN list FORMAT A20

SELECT lp.con_id,
       p.pdb_name,
       lp.profile_name,
       lp.rule_type,
       lp.status,
       lp.rule,
       lp.clause,
       lp.clause_option,
       lp.option_value,
       --as of Oracle 19c lp.except_users
       lp.min_value,
       lp.max_value,
       lp.list
FROM   cdb_lockdown_profiles lp
       LEFT OUTER JOIN cdb_pdbs p ON lp.con_id = p.con_id
ORDER BY 1, 3;
-- EOF ---------------------------------------------------------------------