--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: dsenc_tde.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.08.29
--  Revision..:  
--  Purpose...: Remove TDE and software keystore configuration in a single tenant
--              or container database. This scripts does use several other scripts
--              to remove TDE and it also includes restart of the database. 
--
--              The following steps are performed:
--              - zip the current wallet directory
--              - remove the current wallet directory
--              - ddenc_wroot.sql       reset init.ora parameter for TDE
--              - restart database
--              - ssenc_info.sql        show current TDE configuration
--  Notes.....:  
--  Reference.: Requires SYS, SYSDBA or SYSKM privilege
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET FEEDBACK OFF
SET VERIFY OFF
-- define default values
COLUMN wallet_root      NEW_VALUE wallet_root       NOPRINT
COLUMN wallet_root_base NEW_VALUE wallet_root_base  NOPRINT

-- get wallet root from v$parameter with pdb guid if we are in a pdb
SELECT trim(trailing '/' FROM value||'/'||nvl((SELECT rawtohex(guid) FROM v$pdbs WHERE con_id=sys_context('userenv','con_id')),'')) wallet_root 
FROM v$parameter WHERE name = 'wallet_root';
SELECT replace('&wallet_root','/wallet') wallet_root_base FROM dual;

-- format SQLPlus output and behavior
SET LINESIZE 180 PAGESIZE 66
SET HEADING ON
SET VERIFY ON
SET FEEDBACK ON

-- start to spool
SPOOL dsenc_tde.log

-- ZIP current wallet root directory
HOST zip -r &wallet_root_base/wallet_$(date "%Y%m%d-%H%M%S").zip &wallet_root
HOST rm -rf &wallet_root

-- reset WALLET_ROOT parameter
@ddenc_wroot.sql

PROMPT == Restart database to load software keystore with new master key =======
STARTUP FORCE;

-- display information
@ssenc_info.sql

SPOOL OFF
-- EOF -------------------------------------------------------------------------