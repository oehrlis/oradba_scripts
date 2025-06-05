--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: idenc_tde_user.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.12.19
--  Usage.....: SQL*Plus script to configure Transparent Data Encryption (TDE) settings 
--              and create TDE administration user and role in Oracle 19c and newer.
--  Purpose...: Automates the setup of TDE in Oracle databases, including the creation
--              of necessary roles and users, setting TDE-specific initialization parameters,
--              and granting necessary privileges.
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

SPOOL idenc_tde_user.log

--------------------------------------------------------------------------------
-- Anonymous PL/SQL Block to configure TDE parameter and admin user
-- This block performs the following actions:
--   1. Determines if the database is a Container Database (CDB) and sets relevant variables.
--   2. Sets TDE-specific initialization parameters using ALTER SYSTEM.
--   3. Creates a TDE admin role with required system and object privileges.
--   4. Creates a TDE admin user and grants necessary roles and privileges.
--   5. Handles exceptions and outputs relevant information and error messages.
--------------------------------------------------------------------------------
DECLARE

    -- Types
    SUBTYPE text_type IS VARCHAR2(512 CHAR); -- NOSONAR G-2120 keep function independent
    TYPE t_table_varchar_type IS TABLE OF text_type;

--------------------------------------------------------------------------------
-- Begin of Customization ------------------------------------------------------
--------------------------------------------------------------------------------
    -- table with system privieges granted to TDE admin
    t_system_privileges t_table_varchar_type := t_table_varchar_type(
        'CREATE SESSION',
        'ADMINISTER KEY MANAGEMENT',
        'CREATE JOB');
    -- table with table / view privieges granted to TDE admin
    t_table_privileges t_table_varchar_type := t_table_varchar_type(
        'gv_$wallet','v_$wallet',
        'v_$encryption_wallet',
        'gv_$encryption_wallet',
        'v_$encrypted_tablespaces',
        'gv_$encrypted_tablespaces',
        'v_$database_key_info',
        'gv_$database_key_info',
        'v_$encryption_keys',
        'gv_$encryption_keys',
        'v_$client_secrets',
        'gv_$client_secrets',
        'dba_encrypted_columns',
        'v_$parameter',
        'gv_$parameter',
        'v_$parameter',
        'gv_$parameter');
--------------------------------------------------------------------------------
-- End of Customization --------------------------------------------------------
--------------------------------------------------------------------------------

    -- Local variables
    l_tda_admin_role        dbms_id :='&tde_admin_role';  -- TDE admin role
    l_tde_admin_user        dbms_id :='&tde_admin_user';  -- TDE admin username

    l_cdb                   v$database.cdb%type;    -- variable to check the status of the CDB architecture
    l_common_user_prefix    v$parameter.value%type; -- common_user_prefix
    l_container_stm         text_type;              -- container statement create statements IMMEDIATE
    l_sql                   text_type;              -- sql used in EXECUTE IMMEDIATE
    l_counter               INTEGER;                -- FOR LOOP counter
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
            l_container_stm:='CONTAINER=ALL';
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
        sys.dbms_output.put_line('Info : Set parameter tde_configuration to KEYSTORE_CONFIGURATION=FILE');
        l_sql:=q'(ALTER SYSTEM SET tde_configuration='KEYSTORE_CONFIGURATION=FILE' scope=both)';
        EXECUTE IMMEDIATE l_sql;
    EXCEPTION
        WHEN e_insufficient_privileges THEN
            sys.dbms_output.put_line('Error: Changing parameter' || sqlerrm || ' - Backtrace: ' || sys.dbms_utility.format_error_backtrace );
    END set_tde_parameter;
    
    -- Create TDE admin role
    <<create_tde_admin_role>>
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
            sys.dbms_output.put_line('Info : TDE admin role '||l_tda_admin_role||' already exists');
        ELSE
            sys.dbms_output.put_line('Info : Create TDE admin role '||l_tda_admin_role);
            l_sql := 'CREATE ROLE ' || sys.dbms_assert.enquote_name(l_tda_admin_role) || ' ' || l_container_stm;
            EXECUTE IMMEDIATE l_sql; 
            
        END IF;
    END create_tde_admin_role;
    
    -- grant sys and object privileges to role
    sys.dbms_output.put_line('Info : Grant system privileges to admin role '||l_tda_admin_role);
    -- loop to the list of defined system privileges and grant them
    <<grant_system_privileges>>
    FOR l_counter IN 1..t_system_privileges.COUNT LOOP
        l_sql:='GRANT '||t_system_privileges(l_counter)||' TO ' || sys.dbms_assert.enquote_name(l_tda_admin_role)  || ' ' || l_container_stm;
        --sys.dbms_output.put_line('Info : '||l_sql);
        EXECUTE IMMEDIATE l_sql; 
    END LOOP grant_system_privileges;
    
    sys.dbms_output.put_line('Info : Grant object privileges to admin role '||l_tda_admin_role);
    -- loop to the list of defined object privileges and grant them
    <<grant_object_privileges>>
    FOR l_counter IN 1..t_table_privileges.COUNT LOOP
        l_sql:='GRANT SELECT ON '||sys.dbms_assert.enquote_name(t_table_privileges(l_counter))||' TO ' || sys.dbms_assert.enquote_name(l_tda_admin_role)  || ' ' || l_container_stm;
        --sys.dbms_output.put_line('Info : '||l_sql);
        EXECUTE IMMEDIATE l_sql; 
    END LOOP grant_object_privileges;

    -- Create TDE admin user
    <<create_tde_admin_user>>
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
            sys.dbms_output.put_line('Info : TDE admin user '||l_tde_admin_user||' already exists');
        ELSE
            sys.dbms_output.put_line('Info : Create TDE admin user '||l_tde_admin_user);
            l_sql := 'CREATE USER ' || sys.dbms_assert.enquote_name(l_tde_admin_user) || ' NO AUTHENTICATION ' || l_container_stm;
            EXECUTE IMMEDIATE l_sql; 
        END IF;
    END create_tde_admin_user;

    -- alter the user if we do have a CDB
    IF l_cdb = 'YES' THEN
        l_sql := 'ALTER USER ' || sys.dbms_assert.enquote_name(l_tde_admin_user) || ' SET CONTAINER_DATA=ALL CONTAINER=CURRENT';
--        sys.dbms_output.put_line('Info : '||l_sql);
        EXECUTE IMMEDIATE l_sql;
    END IF;
    sys.dbms_output.put_line('Info : Grant role privileges to admin user '||l_tde_admin_user);

    -- grant roles to tde admin user
    l_sql := 'GRANT ' || sys.dbms_assert.enquote_name(l_tda_admin_role) || ' TO '|| sys.dbms_assert.enquote_name(l_tde_admin_user) || ' '|| l_container_stm;
--    sys.dbms_output.put_line('Info : '||l_sql);
    EXECUTE IMMEDIATE l_sql;
    l_sql := 'GRANT syskm TO '|| sys.dbms_assert.enquote_name(l_tde_admin_user) || ' '|| l_container_stm;
--    sys.dbms_output.put_line('Info : '||l_sql);
    EXECUTE IMMEDIATE l_sql;
END;
/

SPOOL OFF
-- EOF -------------------------------------------------------------------------