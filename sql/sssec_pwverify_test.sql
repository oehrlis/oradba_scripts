--------------------------------------------------------------------------------
-- Accenture, Data Platforms
-- Saegereistrasse 29, 8152 Glattbrugg, Switzerland
--------------------------------------------------------------------------------
-- Name......: sssec_pwverify_test.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
-- Editor....: Stefan Oehrli
-- Date......: 2023.12.12
-- Usage.....: 
-- Purpose...: Test the password verify function
-- Notes.....: 
-- Reference.: 
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- create a temporary type
CREATE OR REPLACE TYPE table_varchar AS
    TABLE OF VARCHAR2(128)
/
 
--------------------------------------------------------------------------------
-- Anonymous PL/SQL Block to test the password function
DECLARE
    username VARCHAR2(100)          := 'john_doe';
    old_password VARCHAR2(100)      := 'OldPass123';
    test_passwords table_varchar    := table_varchar(
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
    FOR i IN 1..test_passwords.COUNT LOOP
        BEGIN
            result := oradba_verify_function(username, test_passwords(i), old_password);
            IF result THEN
                DBMS_OUTPUT.PUT_LINE('Password "' || test_passwords(i) || '" is valid.');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Password "' || test_passwords(i) || '" is invalid.');
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error with password "' || test_passwords(i) || '": ' || SQLERRM);
        END;
    END LOOP;
END;
/

--------------------------------------------------------------------------------
-- drop temporary created type
DROP TYPE table_varchar
/
-- EOF -------------------------------------------------------------------------
