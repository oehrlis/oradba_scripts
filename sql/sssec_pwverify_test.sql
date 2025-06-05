--------------------------------------------------------------------------------
-- Accenture, Data Platforms
-- Saegereistrasse 29, 8152 Glattbrugg, Switzerland
--------------------------------------------------------------------------------
-- Name......: sssec_pwverify_test.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2023.12.12
-- Usage.....: 
-- Purpose...: Test the password verify function
-- Notes.....: 
-- Reference.: 
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
set serveroutput on
--------------------------------------------------------------------------------
-- create a temporary type
CREATE OR REPLACE TYPE table_varchar AS
    TABLE OF VARCHAR2(128 char)
/
 
--------------------------------------------------------------------------------
-- Anonymous PL/SQL Block to test the password function
DECLARE
    l_username VARCHAR2(128 CHAR)       := 'john_doe';
    l_old_password VARCHAR2(128 CHAR)   := 'OldPass123';
    t_test_passwords table_varchar      := table_varchar(
        'NewPass123!', 
        'short', 
        'NewPassword12nnewpassword123',
        'newpassword12nnewpassword123',
        'NewPassword12n-dwpassword123',
        'verylongpasswordthatexceedsthemaximumlength', 
        'NoDigit123', 
        'nodigitOrSpecialChar', 
        'john_doePass');
    result BOOLEAN;
BEGIN
    <<for_loop>>
    FOR i IN 1..t_test_passwords.COUNT LOOP
        BEGIN
            result := oradba_verify_function(l_username, t_test_passwords(i), l_old_password);
            IF result THEN
                sys.dbms_output.put_line('Password "' || t_test_passwords(i) || '" is valid.');
            ELSE
                sys.dbms_output.put_line('Password "' || t_test_passwords(i) || '" is invalid.');
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                sys.dbms_output.put_line('Error with password "' || t_test_passwords(i) || '": ' || sqlerrm );
        END;
    END LOOP for_loop;
END;
/

--------------------------------------------------------------------------------
-- drop temporary created type
DROP TYPE table_varchar
/
-- EOF -------------------------------------------------------------------------
