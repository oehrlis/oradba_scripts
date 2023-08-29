--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: idenc_wroot.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.08.29
--  Revision..:  
--  Purpose...: Initialize init.ora parameter WALLET_ROOT for TDE with software
--              keystore. This script should run in CDB$ROOT. A manual restart
--              of the database is mandatory to activate WALLET_ROOT
--  Notes.....:  
--  Reference.: Requires SYS or DBA privilege
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET LINESIZE 160 PAGESIZE 66
SET HEADING ON
SET FEEDBACK OFF
SET VERIFY OFF

COLUMN admin_path NEW_VALUE admin_path NOPRINT
COLUMN name             FORMAT A25
COLUMN value            FORMAT A60

-- get the admin directory from audit_file_dest
SELECT
    substr(value, 1, instr(value, '/', - 1, 1) - 1) admin_path
FROM
    v$parameter
WHERE
    name = 'audit_file_dest';
SPOOL idenc_wroot.log

-- create the wallet folder
HOST mkdir -p &admin_path/wallet
host mkdir -p &admin_path/wallet/tde
host mkdir -p &admin_path/wallet/tde_seps

-- list init.ora parameter for TDE information in SPFile
PROMPT 
PROMPT Current setting of WALLET_ROOT in SPFILE
SELECT name,value FROM v$spparameter
WHERE name IN ('wallet_root','tde_configuration') 
ORDER BY name;

-- set the WALLET ROOT parameter
ALTER SYSTEM SET wallet_root='&admin_path/wallet' SCOPE=SPFILE;
PROMPT 
-- list init.ora parameter for TDE information in SPFile
PROMPT New setting of WALLET_ROOT in SPFILE
SELECT name,value FROM v$spparameter
WHERE name IN ('wallet_root','tde_configuration') 
ORDER BY name;

PROMPT 
PROMPT Please restart the database to apply the changes on WALLET_ROOT.
PROMPT

SPOOL off
-- EOF -------------------------------------------------------------------------