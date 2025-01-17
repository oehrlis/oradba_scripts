--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: ddenc_tde_user.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
--  Editor....: Stefan Oehrli
--  Date......: 2023.12.19
--  Usage.....: SQL*Plus script to delete Transparent Data Encryption (TDE) settings 
--              and drop TDE administration user and role in Oracle 19c and newer.
--  Purpose...: Automates the decommissioning of TDE in Oracle databases, including the deletion
--              of necessary roles and users, resetting TDE-specific initialization parameters.
--  Notes.....: Ensure that Oracle Wallet or Keystore is properly configured before running
--              this script. The script should be executed by a user with SYSDBA privileges.
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
-- define default values
DEFINE _def_tde_admin_role   = 'TDE_ADMIN'
DEFINE _def_tde_admin_user   = 'SEC_ADMIN'

-- assign default value for parameter if argument 1 and 2 if one is empty
SET FEEDBACK OFF
SET VERIFY OFF
-- Assign default value for parameter 1 _def_tde_admin_role
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT NULL "1" FROM dual WHERE ROWNUM = 0;
DEFINE tde_admin_role     = &1 &_def_tde_admin_role

-- Assign default value for parameter 1 _def_tde_admin_user
COLUMN 2 NEW_VALUE 2 NOPRINT
SELECT NULL "2" FROM dual WHERE ROWNUM = 0;
DEFINE tde_admin_user     = &2 &_def_tde_admin_user

SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200
SET FEEDBACK ON
SET VERIFY ON

SPOOL ddenc_tde_user.log
--------------------------------------------------------------------------------
-- Anonymous PL/SQL Block to reset TDE parameter and delete the admin user
-- This block performs the following actions:
--   1. Determines if the database is a Container Database (CDB) and sets relevant variables.
--   2. Resets TDE-specific initialization parameters using ALTER SYSTEM.
--   3. Drop a TDE admin role.
--   4. Drop a TDE admin user.
--   5. Handles exceptions and outputs relevant information and error messages.
--------------------------------------------------------------------------------
DECLARE
    -- Types
    SUBTYPE text_type IS VARCHAR2(512 CHAR); -- NOSONAR G-2120 keep function independent

    -- Local variables
    l_tda_admin_role        dbms_id :='&tde_admin_role';  -- TDE admin role
    l_tde_admin_user        dbms_id :='&tde_admin_user';  -- TDE admin username

    l_cdb                   v$database.cdb%type;    -- variable to check the status of the CDB architecture
    l_common_user_prefix    v$parameter.value%type; -- common_user_prefix
    l_sql                   text_type;              -- sql used in EXECUTE IMMEDIATE
    l_user_exists           INTEGER;                -- used to check if user does exists
    l_role_exists           INTEGER;                -- used to check if user does exists
    
    e_insufficient_privileges EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_insufficient_privileges, -1031); -- ORA-01031: insufficient privileges
    
BEGIN
    l_tde_admin_user := upper(l_tde_admin_user);
    l_tda_admin_role := upper(l_tda_admin_role);
    -- retrive Information from v$database
    <<get_db_arch>>
    BEGIN
        SELECT cdb INTO l_cdb FROM v$database;
    EXCEPTION
        WHEN no_data_found OR too_many_rows THEN
            sys.dbms_output.put_line('Error: Unable to retrieve CDB information from v$database.');
    END get_db_arch;        
    -- Set prefix / information base on DB architecture    
    IF l_cdb = 'YES' THEN
        BEGIN
--            sys.dbms_output.put_line('Info : The database is a Container Database (CDB).');
            SELECT value INTO l_common_user_prefix FROM v$parameter WHERE name='common_user_prefix';
            l_tde_admin_user:=l_common_user_prefix||l_tde_admin_user;   -- add the common user prefix to the username
            l_tda_admin_role:=l_common_user_prefix||l_tda_admin_role;   -- add the common user prefix to the role
--            sys.dbms_output.put_line('Info : Set the admin user ID to '||l_tde_admin_user);
--            sys.dbms_output.put_line('Info : Set the admin role ID to '||l_tda_admin_role);
        EXCEPTION
            WHEN no_data_found OR too_many_rows THEN
                sys.dbms_output.put_line('Error: Unable to retrieve common_user_prefix information from v$parameter.');
        END;
    ELSE
        sys.dbms_output.put_line('Info : The database is not a Container Database (CDB).');
    END IF;

    -- set init.ora parameter
    <<set_tde_parameter>>
    BEGIN
        sys.dbms_output.put_line('Info : Reset parameter tde_configuration');
        l_sql:=q'(ALTER SYSTEM RESET tde_configuration scope=both)';
        EXECUTE IMMEDIATE l_sql;
    EXCEPTION
        WHEN e_insufficient_privileges THEN
            sys.dbms_output.put_line('Error: Changing parameter' || sqlerrm || ' - Backtrace: ' || sys.dbms_utility.format_error_backtrace );
    END set_tde_parameter;
    
    -- Drop TDE admin role
    <<drop_tde_admin_role>>
    BEGIN
        -- Check if role exists
        <<check_tde_admin_role>>
        BEGIN
            SELECT COUNT(*) INTO l_role_exists FROM dba_roles WHERE role = UPPER(l_tda_admin_role);
        EXCEPTION
            WHEN no_data_found OR too_many_rows THEN
                sys.dbms_output.put_line('Error: Unable to retrieve role information information from dba_roles.');
        END check_tde_admin_role;
        
        IF l_role_exists > 0 THEN
            sys.dbms_output.put_line('Info : TDE admin role '||l_tda_admin_role||' does exists');
            sys.dbms_output.put_line('Info : Drop TDE admin role '||l_tda_admin_role);
            l_sql := 'DROP ROLE ' || sys.dbms_assert.enquote_name(l_tda_admin_role);
            EXECUTE IMMEDIATE l_sql; 
        END IF;
    END drop_tde_admin_role;

    -- Drop TDE admin user
    <<drop_tde_admin_user>>
    BEGIN
        -- Check if user exists
        <<check_tde_admin_user>>
        BEGIN
            SELECT COUNT(*) INTO l_user_exists FROM dba_users WHERE username = UPPER(l_tde_admin_user);
        EXCEPTION
            WHEN no_data_found OR too_many_rows THEN
                sys.dbms_output.put_line('Error: Unable to retrieve user information information from dba_users.');
        END check_tde_admin_user;
        
        IF l_user_exists > 0 THEN
            sys.dbms_output.put_line('Info : TDE admin user '||l_tde_admin_user||' does exists');
            sys.dbms_output.put_line('Info : Create TDE admin user '||l_tde_admin_user);
            l_sql := 'DROP USER ' || sys.dbms_assert.enquote_name(l_tde_admin_user);
            EXECUTE IMMEDIATE l_sql; 
        END IF;
    END drop_tde_admin_user;
END;
/

SPOOL OFF
-- EOF -------------------------------------------------------------------------