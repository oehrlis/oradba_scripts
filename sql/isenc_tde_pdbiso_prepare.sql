--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: isenc_tde_pdbiso.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.08.29
--  Revision..:  
--  Purpose...: Prepare TDE in a PDB in isolation mode i.e., with a dedicated
--              wallet in WALLET_ROOT for this pdb. Whereby this just prepare
--              the steps as SYSDBA. The software keystore itself will be
--              created by SYSKM
--
--              The following steps are performed:
--              - set init.ora parameter
--              - create directory
--              - ssenc_info.sql        show current TDE configuration
--  Notes.....:  
--  Reference.: Requires SYS, SYSDBA or SYSKM privilege
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET FEEDBACK OFF
SET VERIFY OFF
-- define default values
COLUMN wallet_root NEW_VALUE wallet_root NOPRINT

-- get wallet root from v$parameter with pdb guid if we are in a pdb
SELECT trim(trailing '/' FROM value||'/'||nvl((SELECT rawtohex(guid) FROM v$pdbs WHERE con_id=sys_context('userenv','con_id')),'')) wallet_root 
FROM v$parameter WHERE name = 'wallet_root';

-- format SQLPlus output and behavior
SET LINESIZE 160 PAGESIZE 200
SET FEEDBACK ON

COLUMN wrl_type         FORMAT A8
COLUMN wrl_parameter    FORMAT A75
COLUMN status           FORMAT A18
COLUMN wallet_type      FORMAT A15
COLUMN con_id           FORMAT 99999

-- start to spool
SPOOL isenc_tde_pdbiso_prepare.log

-- create the wallet folder
host mkdir -p &wallet_root
host mkdir -p &wallet_root/tde_seps

PROMPT == Configure the init.ora parameter ======================================
-- config TDE_CONFIGURATION
ALTER SYSTEM SET TDE_CONFIGURATION='KEYSTORE_CONFIGURATION=FILE' scope=both;

-- extend privileges for SYSKM
GRANT SELECT ON v_$pdbs TO syskm;
GRANT SELECT ON v_$parameter TO syskm;

-- display information
@ssenc_info.sql

SPOOL OFF
-- EOF -------------------------------------------------------------------------