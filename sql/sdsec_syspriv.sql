--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: sdsec_syspriv.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.11.29
--  Revision..:  
--  Purpose...: Show respectively create a list of granted system privileges
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- assign default value for parameter if argument 1 is empty
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN db_name NEW_VALUE db_name NOPRINT
SELECT upper(name) db_name FROM v$database;

--------------------------------------------------------------------------------
-- Define SQLPlus configuration
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200
SPOOL sdsec_syspriv_&db_name..sql

--------------------------------------------------------------------------------
-- create a temporary type
CREATE OR REPLACE TYPE table_varchar AS
    TABLE OF VARCHAR2(128)
/

--------------------------------------------------------------------------------
-- Anonymous PL/SQL Block to get system privileges
DECLARE
    -- list of known user to be excluded
    excluded_users      table_varchar := table_varchar('ZZ_SPOTLIGHT');
    TYPE t_dba_sys_privs IS
       TABLE OF dba_sys_privs%rowtype;
    r_dba_sys_privs     t_dba_sys_privs;
    v_admin_option      VARCHAR2(128) := '';
    v_common            VARCHAR2(128) := '';
    v_container         INT;

BEGIN
    -- check if we are in a multitenant DATABASE
    SELECT sys_context('userenv','con_id') INTO v_container FROM dual;
 
    -- store the information from dba_sys_privs
    SELECT
        *
    BULK COLLECT
    INTO r_dba_sys_privs
    FROM
        dba_sys_privs
    WHERE
        grantee NOT IN (
            SELECT
                username
            FROM
                dba_users
            WHERE
                oracle_maintained='Y'
                OR username IN ( SELECT * FROM TABLE ( excluded_users ) ) UNION
                SELECT
                    role
                FROM
                    dba_roles
                WHERE
                    oracle_maintained='Y'
        );
    
    -- check if we do have an empty collection
    IF r_dba_sys_privs IS NOT EMPTY THEN
        dbms_output.put_line('REM system privilege grants found');
        -- loop through the collection to create the grant statements
        FOR i IN 1..r_dba_sys_privs.last LOOP
            -- set the admin option depending on the current setting
            IF r_dba_sys_privs(i).admin_option = 'YES' THEN
                v_admin_option := ' WITH ADMIN OPTION';
            ELSE
                v_admin_option := '';
            END IF;

            -- set the container option depending on the current setting
            IF v_container = 1 AND r_dba_sys_privs(i).common = 'YES' THEN
                v_common := ' CONTAINER=ALL';
            ELSE
                v_common := '';
            END IF;

            dbms_output.put_line('GRANT '
                                    || r_dba_sys_privs(i).privilege
                                    || ' TO '
                                    || sys.dbms_assert.enquote_name(r_dba_sys_privs(i).grantee)
                                    || v_admin_option
                                    || v_common 
                                    || ';');
        END LOOP;
    ELSE
        dbms_output.put_line('REM no system privilege grants found');
    END IF;
END;
/

--------------------------------------------------------------------------------
-- drop temporary created type
DROP TYPE table_varchar
/

SPOOL off
SET FEEDBACK ON
SET VERIFY ON
-- EOF -------------------------------------------------------------------------
