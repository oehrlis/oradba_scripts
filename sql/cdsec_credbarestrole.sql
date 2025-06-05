--------------------------------------------------------------------------------
--  Trivadis - Part of Accenture, Platform Factory - Data Platforms
--  Saegereistrasse 29, 8152 Glattbrugg, Switzerland
--------------------------------------------------------------------------------
--  Name......: cdsec_credbarestrole.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.03.17
--  Usage.....: cdsec_credbarestrole.sql <ROLE NAME>
--  Purpose...: Script to create a restricted DBA role inlcuding re-grant to
--              existing users.
--  Notes.....: 
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- define default values
DEFINE _role_name = 'DBA_RESTRICTED'

--------------------------------------------------------------------------------
-- assign default value for parameter if argument 1 is empty
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
DEFINE role_name    = &1 &_role_name
COLUMN role_name NEW_VALUE role_name NOPRINT
SELECT upper('&role_name') role_name FROM dual;

--------------------------------------------------------------------------------
-- Define SQLPlus configuration
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200
SPOOL create_dba_restricted_role.log

--------------------------------------------------------------------------------
-- create a temporary type
CREATE OR REPLACE TYPE table_varchar AS
    TABLE OF VARCHAR2(128)
/

--------------------------------------------------------------------------------
-- Anonymous PL/SQL Block to configure restricted dba role
DECLARE
    -- black list of system privileges
    restricted_sys_privs  table_varchar := table_varchar('DROP USER', 'ALTER USER', 'CREATE USER', 'BECOME USER');
    -- black list of object privileges
    restricted_obj_privs  table_varchar := table_varchar('DBMS_SYS_SQL');
    -- black list of role privileges
    restricted_role_privs table_varchar := table_varchar('n/a');
    -- white list of system privileges
    allowed_sys_privs     table_varchar := table_varchar('CREATE ANY INDEX','DROP ANY INDEX','ADMINISTER ANY SQL TUNING SET', 'ANALYZE ANY','AUDIT ANY');
    -- white list of object privileges
    allowed_obj_privs     table_varchar := table_varchar('TOAD_TABLE_PLAN');
    -- white list of role privileges
    allowed_role_privs    table_varchar := table_varchar('AUDIT_ADMIN','AUDIT_VIEWER');
    TYPE t_dba_role_privs IS
        TABLE OF dba_role_privs%rowtype;
    r_dba_role_privs      t_dba_role_privs;
    v_ref_role            VARCHAR2(128) := 'DBA';
    v_role                VARCHAR2(128) := '&role_name';
    v_sql                 VARCHAR2(4000);
    v_admin_option        VARCHAR2(128) := '';
    v_common              VARCHAR2(128) := '';
    v_exist               INT;
    v_container           INT;

BEGIN
    -- check if we are in a multitenant DATABASE
    SELECT sys_context('userenv','con_id') INTO v_container FROM dual;

    ----------------------------------------------------------------------------
    -- check if we do have grants for the restricted DBA role
    SELECT
        COUNT(*)
    INTO v_exist
    FROM
        dba_roles
    WHERE
        role = v_role;

    IF v_exist = 1 THEN
        dbms_output.put_line('INFO : temporarly store grants for role '
                             || sys.dbms_assert.enquote_name(v_role));
        -- store the information from dba_role_privs
        SELECT
            *
        BULK COLLECT
        INTO r_dba_role_privs
        FROM
            dba_role_privs
        WHERE
            granted_role = v_role;

        FOR i IN 1..r_dba_role_privs.last LOOP
            -- set the admin option depending on the current setting
            IF r_dba_role_privs(i).admin_option = 'YES' THEN
                v_admin_option := ' WITH ADMIN OPTION';
            ELSE
                v_admin_option := '';
            END IF;

            -- set the container option depending on the current setting
            IF v_container = 1 AND r_dba_role_privs(i).common = 'YES' THEN
                v_common := ' CONTAINER=ALL';
            ELSE
                v_common := '';
            END IF;

            dbms_output.put_line('INFO : role '
                                 || sys.dbms_assert.enquote_name(v_role)
                                 || ' granted to '
                                 || sys.dbms_assert.enquote_name(r_dba_role_privs(i).grantee)
                                 || v_admin_option
                                 ||v_common );
        END LOOP;
        v_sql :='DROP ROLE ' || sys.dbms_assert.enquote_name(v_role);
        dbms_output.put_line('INFO : execute ' || v_sql);
        -- execute GRANT statement
        EXECUTE IMMEDIATE v_sql;

    END IF;
    
    ----------------------------------------------------------------------------
    -- create role restriced DBA role
    v_sql :='CREATE ROLE ' || sys.dbms_assert.enquote_name(v_role);
    dbms_output.put_line('INFO : execute ' || v_sql);
    -- execute GRANT statement
    EXECUTE IMMEDIATE v_sql;

    ----------------------------------------------------------------------------
    -- Query the current system privileges of the DBA role limited / extended the ANY and black and white list system privileges
    dbms_output.put_line('INFO : grant all sys privileges based on DBA limited / extended ANY as well black and white listed system privileges'
    );
    FOR r_dba_sys_privs IN (
        SELECT
            *
        FROM
            dba_sys_privs
        WHERE
                grantee = v_ref_role
            AND ( (     privilege NOT LIKE '%ANY%'
                    AND privilege NOT LIKE '%USER%'
                    AND privilege NOT IN ( SELECT * FROM TABLE ( restricted_sys_privs ) ) )
                  OR privilege IN ( SELECT * FROM TABLE ( allowed_sys_privs ))
                )
        ORDER BY
            privilege
    ) LOOP
        -- set the admin option depending on the current setting
        IF r_dba_sys_privs.admin_option = 'YES' AND r_dba_sys_privs.grantee = v_ref_role THEN
            v_admin_option := ' WITH ADMIN OPTION';
        ELSE
            v_admin_option := '';
        END IF;

        -- set the container option depending on the current setting
        IF v_container = 1 AND r_dba_sys_privs.common = 'YES' THEN
            v_common := ' CONTAINER=ALL';
        ELSE
            v_common := '';
        END IF;
        -- create the GRANT statement
        v_sql := 'GRANT '
                 || r_dba_sys_privs.privilege
                 || ' TO '
                 || sys.dbms_assert.enquote_name(v_role)
                 || v_admin_option
                 || v_common;
        -- display revoke statement
        dbms_output.put_line('INFO : execute ' || v_sql);
        -- execute GRANT statement
        EXECUTE IMMEDIATE v_sql;
    END LOOP;
    
    ----------------------------------------------------------------------------
    -- Query the current object privileges of the DBA role limited / extended the black and white list
    dbms_output.put_line('INFO : grant all object privileges based on DBA limited / extended by black and white listed objects');
    FOR r_dba_tab_privs IN (
        SELECT
            *
        FROM
            dba_tab_privs
        WHERE
                grantee = v_ref_role
            AND type IN ( 'TABLE', 'VIEW', 'PACKAGE', 'PROCEDURE', 'FUNCTION', 'TYPE' )
            AND privilege IN ( 'SELECT', 'READ', 'EXECUTE' )
            AND grantor = 'SYS'
            AND ( table_name NOT IN ( SELECT * FROM TABLE ( restricted_obj_privs ) )
                  OR table_name IN ( SELECT * FROM TABLE ( allowed_obj_privs ) ) )
        ORDER BY
            privilege
    ) LOOP
        -- set the admin option depending on the current setting
        IF r_dba_tab_privs.grantable = 'YES' AND r_dba_tab_privs.grantee = v_ref_role THEN
            v_admin_option := ' WITH GRANT OPTION';
        ELSE
            v_admin_option := '';
        END IF;

        -- set the container option depending on the current setting
        IF v_container = 1 AND r_dba_tab_privs.common = 'YES' THEN
            v_common := ' CONTAINER=ALL';
        ELSE
            v_common := '';
        END IF;
        -- create the GRANT statement
        v_sql := 'GRANT '
                 || r_dba_tab_privs.privilege
                 || ' ON '
                 || sys.dbms_assert.schema_name(r_dba_tab_privs.owner)
                 || '.'
                 || sys.dbms_assert.sql_object_name(r_dba_tab_privs.table_name)
                 || ' TO '
                 || sys.dbms_assert.enquote_name(v_role)
                 || v_admin_option
                 || v_common;
        -- display revoke statement
        dbms_output.put_line('INFO : execute ' || v_sql);
        -- execute GRANT statement
        EXECUTE IMMEDIATE v_sql;
    END LOOP;

    ----------------------------------------------------------------------------
    -- Query the current role privileges of the DBA role limited / extended the black and white listed roles
    dbms_output.put_line('INFO : grant all role privileges based on DBA limited / extended the black and white listed roles');
    FOR r_dba_role_privs IN (
        SELECT
            *
        FROM
            dba_role_privs
        WHERE
            (   grantee = v_ref_role
            AND granted_role NOT IN ( SELECT * FROM TABLE ( restricted_role_privs ) )
            AND granted_role NOT IN (
                SELECT DISTINCT grantee FROM dba_sys_privs WHERE
                    (   privilege LIKE '%ANY%'
                    OR  privilege LIKE '%USER%'
                    OR  privilege IN ( SELECT * FROM TABLE ( restricted_sys_privs ) ) )
                    AND privilege NOT IN ( SELECT * FROM TABLE ( allowed_sys_privs ) )
                )
            )
        OR granted_role IN ( SELECT * FROM TABLE ( allowed_role_privs ) )
            ORDER BY
                granted_role
    ) LOOP
        -- set the admin option depending on the current setting
        IF r_dba_role_privs.admin_option = 'YES' AND r_dba_role_privs.grantee = v_ref_role THEN
            v_admin_option := ' WITH ADMIN OPTION';
        ELSE
            v_admin_option := '';
        END IF;
        
        -- set the container option depending on the current setting
        IF v_container = 1 AND r_dba_role_privs.common = 'YES' THEN
            v_common := ' CONTAINER=ALL';
        ELSE
            v_common := '';
        END IF;
        -- create the GRANT statement
        v_sql := 'GRANT '
                 || r_dba_role_privs.granted_role
                 || ' TO '
                 || sys.dbms_assert.enquote_name(v_role)
                 || v_admin_option
                 || v_common;
        -- display revoke statement
        dbms_output.put_line('INFO : execute ' || v_sql);
        -- execute GRANT statement
        EXECUTE IMMEDIATE v_sql;
    END LOOP;

    ----------------------------------------------------------------------------
    -- restore GRANT for the restricted DBA role
    IF v_exist = 1 THEN
        dbms_output.put_line('INFO : recreate existing grants for role '
                             || sys.dbms_assert.enquote_name(v_role));
        FOR i IN 1..r_dba_role_privs.last LOOP
            -- set the admin option if required
            IF r_dba_role_privs(i).admin_option = 'YES' THEN
                v_admin_option := ' WITH ADMIN OPTION';
            ELSE
                v_admin_option := '';
            END IF;

            v_sql := 'GRANT '
                     || r_dba_role_privs(i).granted_role
                     || ' TO '
                     || sys.dbms_assert.enquote_name(sys.dbms_assert.schema_name(r_dba_role_privs(i).grantee))
                     || v_admin_option;
            -- display revoke statement
            dbms_output.put_line('INFO : execute ' || v_sql);
            -- execute revoke statement
            EXECUTE IMMEDIATE v_sql;
        END LOOP;

    END IF;

    dbms_output.put_line('INFO : Done updating role '
                         || sys.dbms_assert.enquote_name(v_role));
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('ERROR: executing : ' || v_sql);
END;
/

--------------------------------------------------------------------------------
-- drop temporary created type
DROP TYPE table_varchar
/

spool off
-- EOF -------------------------------------------------------------------------