--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: csenc_swkeystore.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.08.30
--  Revision..:  
--  Purpose...: Create TDE software keystore and master encryption key in CDB$ROOT
--              in the WALLET_ROOT directory.
--  Notes.....:  
--  Reference.: Requires SYS, SYSDBA or SYSKM privilege
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET FEEDBACK OFF
SET VERIFY OFF
-- define default values
COLUMN def_wallet_pwd NEW_VALUE def_wallet_pwd NOPRINT
COLUMN wallet_root NEW_VALUE wallet_root NOPRINT
-- generate random password
SELECT dbms_random.string('X', 20) def_wallet_pwd FROM dual;

-- get wallet root from v$parameter with pdb guid if we are in a pdb
SELECT trim(trailing '/' FROM value||'/'||nvl((SELECT rawtohex(guid) FROM v$pdbs WHERE con_id=sys_context('userenv','con_id')),'')) wallet_root 
FROM v$parameter WHERE name = 'wallet_root';

-- assign default value for parameter if argument 1 is empty
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE wallet_pwd          = &1 &def_wallet_pwd
COLUMN wallet_pwd NEW_VALUE wallet_pwd NOPRINT

-- format SQLPlus output and behavior
SET LINESIZE 160 PAGESIZE 200
SET FEEDBACK ON

COLUMN wrl_type         FORMAT A8
COLUMN wrl_parameter    FORMAT A75
COLUMN status           FORMAT A18
COLUMN wallet_type      FORMAT A15
COLUMN con_id           FORMAT 99999

-- start to spool
SPOOL csenc_swkeystore.log

-- create the wallet folder
host mkdir -p &wallet_root
host mkdir -p &wallet_root/tde_seps

-- store wallet password
PROMPT == Store the wallet password in &wallet_root/wallet_pwd.txt
HOST test ! -e &wallet_root/wallet_pwd.txt || cp &wallet_root/wallet_pwd.txt &wallet_root/wallet_pwd_$(date +"%Y%m%d%-H%M").bck
HOST echo &wallet_pwd > &wallet_root/wallet_pwd.txt
HOST chmod 600 &wallet_root/wallet_pwd.txt

PROMPT == Configure the software keystore ======================================
-- config TDE_CONFIGURATION
ALTER SYSTEM SET TDE_CONFIGURATION='KEYSTORE_CONFIGURATION=FILE' scope=both;

-- create software keystore in WALLET_ROOT
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "&wallet_pwd";

-- create an external keystore password store in WALLET_ROOT
ADMINISTER KEY MANAGEMENT ADD SECRET '&wallet_pwd' FOR CLIENT 'TDE_WALLET' TO LOCAL AUTO_LOGIN KEYSTORE '&wallet_root/tde_seps';
         
-- open the software keystore
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN FORCE KEYSTORE IDENTIFIED BY EXTERNAL STORE;

-- create local auto-login software keystore from the existing software keystore
ADMINISTER KEY MANAGEMENT CREATE LOCAL AUTO_LOGIN KEYSTORE FROM KEYSTORE '&wallet_root/tde' IDENTIFIED BY "&wallet_pwd";

-- list wallet information
PROMPT == Encryption wallet information from v$encryption_wallet ===============
SELECT * FROM v$encryption_wallet;

SPOOL OFF
-- EOF -------------------------------------------------------------------------