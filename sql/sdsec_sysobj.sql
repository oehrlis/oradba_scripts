--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: sdsec_sysobj.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.11.29
--  Revision..:  
--  Purpose...: Show respectively create a list of granted SYS object privileges
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
SPOOL sdsec_sysobj_&db_name..sql

--------------------------------------------------------------------------------
-- create a temporary type
CREATE OR REPLACE TYPE table_varchar AS
    TABLE OF VARCHAR2(128)
/

--------------------------------------------------------------------------------
-- Anonymous PL/SQL Block to get system privileges
DECLARE
    -- list of known user to be excluded
    excluded_users      table_varchar := table_varchar('ZZ_SPOTLIGHT','PUBLIC');
    TYPE t_dba_tab_privs IS
       TABLE OF dba_tab_privs%rowtype;
    r_dba_tab_privs     t_dba_tab_privs;
    v_grantable         VARCHAR2(128) := '';
    v_common            VARCHAR2(128) := '';
    v_container         INT;

BEGIN
    -- check if we are in a multitenant DATABASE
    SELECT sys_context('userenv','con_id') INTO v_container FROM dual;
 
    -- store the information from dba_tab_privs
    SELECT
        *
    BULK COLLECT
    INTO r_dba_tab_privs
    FROM
        dba_tab_privs
    WHERE
        owner = 'SYS' AND
        grantee NOT IN ( 'PUBLIC' ) AND
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
    IF r_dba_tab_privs IS NOT EMPTY THEN
        dbms_output.put_line('REM SYS object grants found');
        -- loop through the collection to create the grant statements
        FOR i IN 1..r_dba_tab_privs.last LOOP
            -- set the grantable option depending on the current setting
            IF r_dba_tab_privs(i).grantable = 'YES' THEN
                v_grantable := ' WITH GRANT OPTION';
            ELSE
                v_grantable := '';
            END IF;

            -- set the container option depending on the current setting
            IF v_container = 1 AND r_dba_tab_privs(i).common = 'YES' THEN
                v_common := ' CONTAINER=ALL';
            ELSE
                v_common := '';
            END IF;

            dbms_output.put_line('GRANT '
                                    || r_dba_tab_privs(i).privilege
                                    || ' ON '
                                    || sys.dbms_assert.enquote_name(r_dba_tab_privs(i).table_name)
                                    || ' TO '
                                    || sys.dbms_assert.enquote_name(r_dba_tab_privs(i).grantee)
                                    || v_grantable
                                    || v_common 
                                    || ';');
        END LOOP;
    ELSE
        dbms_output.put_line('REM no SYS object grants found');
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
