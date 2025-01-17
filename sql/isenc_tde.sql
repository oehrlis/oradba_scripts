--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: isenc_tde.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.08.29
--  Revision..:  
--  Purpose...: Initialize TDE for a single tenant or container database. This
--              scripts does use several other scripts to enable TDE and it
--              also includes restart of the database. 
--
--              The following steps are performed:
--              - idenc_wroot.sql       set init.ora parameter for TDE
--              - restart database
--              - csenc_swkeystore.sql  create and configure software keystore
--              - csenc_master.sql      create master encryption key
--              - restart database
--              - ssenc_info.sql        show current TDE configuration
--  Notes.....:  
--  Reference.: Requires SYS, SYSDBA or SYSKM privilege
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET FEEDBACK OFF
SET VERIFY OFF
-- define default values for wallet password
COLUMN def_wallet_pwd           NEW_VALUE def_wallet_pwd        NOPRINT
-- generate random password
SELECT dbms_random.string('X', 20) def_wallet_pwd FROM dual;

-- assign default value for parameter if argument 1 is empty
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE wallet_pwd           = &1 &def_wallet_pwd
COLUMN wallet_pwd           NEW_VALUE wallet_pwd NOPRINT

-- define default values for wallet password
COLUMN def_wallet_root_base     NEW_VALUE def_wallet_root_base  NOPRINT
-- get the wallet root directory from audit_file_dest
SELECT
    substr(value, 1, instr(value, '/', - 1, 1) - 1) def_wallet_root_base
FROM
    v$parameter
WHERE
    name = 'audit_file_dest';

-- assign default value for parameter if argument 2 is empty
COLUMN 2 NEW_VALUE 2 NOPRINT
SELECT '' "2" FROM dual WHERE ROWNUM = 0;
DEFINE wallet_root_base     = &2 &def_wallet_root_base
COLUMN wallet_root_base     NEW_VALUE wallet_root_base NOPRINT

-- format SQLPlus output and behavior
SET LINESIZE 180 PAGESIZE 66
SET HEADING ON
SET VERIFY ON
SET FEEDBACK ON

-- start to spool
SPOOL isenc_tde.log

-- configure WALLET_ROOT parameter
@idenc_wroot.sql &wallet_root_base

PROMPT == Restart database to enable WALLET_ROOT ===============================
STARTUP FORCE;

-- configure software keystore for database / cdb
@csenc_swkeystore.sql &wallet_pwd

-- uncomment the following line if you have issues with pre-created master
-- encryption keys. e.g., because TDE wallets have been recreated
--@idenc_lostkey.sql

-- configure master encryption key
@csenc_master.sql

PROMPT == Restart database to load software keystore with new master key =======
STARTUP FORCE;

-- display information
@ssenc_info.sql

SPOOL OFF
-- EOF -------------------------------------------------------------------------