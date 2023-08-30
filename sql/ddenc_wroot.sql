--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: ddenc_wroot.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.08.29
--  Revision..:  
--  Purpose...: Reset init.ora parameter WALLET_ROOT for TDE. This script should
--              run in CDB$ROOT. A manual restart of the database is mandatory to
--              activate WALLET_ROOT.
--  Notes.....:  
--  Reference.: Requires SYS, SYSDBA or DBA privilege
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
-- format SQLPlus output and behavior
SET LINESIZE 160 PAGESIZE 200
SET HEADING ON
SET FEEDBACK ON

COLUMN name             FORMAT A25
COLUMN value            FORMAT A60

-- start to spool
SPOOL ddenc_wroot.log

-- list init.ora parameter for TDE information in SPFile
PROMPT == Current setting of WALLET_ROOT in SPFILE =============================
SELECT name,value FROM v$spparameter
WHERE name IN ('wallet_root','tde_configuration') 
ORDER BY name;

-- set the WALLET ROOT parameter
ALTER SYSTEM RESET tde_configuration SCOPE=SPFILE;
ALTER SYSTEM RESET wallet_root SCOPE=SPFILE;

-- list init.ora parameter for TDE information in SPFile
PROMPT == New setting of WALLET_ROOT in SPFILE =================================
SELECT name,value FROM v$spparameter
WHERE name IN ('wallet_root','tde_configuration') 
ORDER BY name;

PROMPT =========================================================================
PROMPT == Please restart the database to apply the changes on WALLET_ROOT. =====
PROMPT =========================================================================

SPOOL OFF
-- EOF -------------------------------------------------------------------------