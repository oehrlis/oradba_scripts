--------------------------------------------------------------------------------
-- Accenture, Data Platforms
-- Saegereistrasse 29, 8152 Glattbrugg, Switzerland
--------------------------------------------------------------------------------
-- Name......: cssec_pwverify.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
-- Editor....: Stefan Oehrli
-- Date......: 2023.12.12
-- Usage.....: 
-- Purpose...: Create custom password verify function
-- Notes.....: 
-- Reference.: 
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Function..........: oradba_verify_function
-- Version...........: 1.0
-- Purpose...........: This PL/SQL function is designed to validate password 
--                     strength and complexity requirements in Oracle databases.
--                     It ensures that the provided password adheres to specific
--                     rules regarding length, character types, and differences
--                     from previous passwords. The password strength and
--                     complexity can be configured by the internal variables at
--                     create time.
--
--                     Functionality:
--                     - Password Length Check: Validates if the password length
--                       is within the specified minimum and maximum limits.
--                     - Alphanumeric Check: If enabled (v_check_alphanumeric is
--                       TRUE and v_cust_special is 0), checks if the password
--                       contains only alphanumeric characters.
--                     - Complexity Checks: Verifies if the password meets the
--                       defined complexity requirements (letters, uppercase,
--                       lowercase, digits, and special characters).
--                     - Username Inclusion Check: Ensures the password does not
--                       contain the username or its reverse.
--                     - Server Name Inclusion Check: Ensures the password does
--                       not contain the server name.
--                     - Restricted Keywords Check: Checks for the inclusion of
--                       specific restricted words (e.g., 'oracle').
--                     - Difference from Old Password: If an old password is
--                       provided, verifies that the new password is sufficiently
--                       different.
-- Usage.............: oradba_verify_function(<PARAMETER>)
-- User parameters...: username     -  username 
--                     password     -  new password 
--                     old_password -  old password 
-- Output parameters.: Returns TRUE if the password meets all the specified
--                     criteria. Raises an error with a specific message if any
--                     criteria are not met.

---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION oradba_verify_function
    (   username     varchar2,
        password     varchar2,
        old_password varchar2)
    RETURN boolean IS
        v_cust_differ           integer := 5;       -- The minimum number of different characters required between the old and new passwords.
        v_cust_chars_min        integer := 12;      -- The minimum length of the password.
        v_cust_chars_max        integer := 0;       -- The maximum length of the password.
        v_cust_letter           integer := 1;       -- The required number of letters in the password.
        v_cust_uppercase        integer := 1;       -- The required number of uppercase letters in the password.
        v_cust_lowercase        integer := 1;       -- The required number of lowercase letters in the password.
        v_cust_digit            integer := 1;       -- The required number of digits in the password.
        v_cust_special          integer := 0;       -- null or more characters, default 1
        v_check_alphanumeric    boolean := FALSE;   -- Controls whether to check for alphanumeric-only passwords. Valid only if v_cust_special is 0.
        differ                  integer; 
        db_name                 varchar2(40);
        i                       integer;
        reverse_user dbms_id;
        canon_username dbms_id := username;
        lang                varchar2(512);
        message             varchar2(512);
        ret                 number;

BEGIN
    -- set default / minimal values
    -- Removed due to customer requirement
    IF v_cust_chars_min < 12 THEN v_cust_chars_min := 12; END IF;

    -- Validates if the password length is within the specified minimum limit
    IF v_cust_chars_max > 0 THEN
        IF length(password) > v_cust_chars_max THEN
            raise_application_error(-20001, 'Password must not be longer than ' || v_cust_chars_max );
        END IF; 
    END IF;

    -- If enabled (v_check_alphanumeric is TRUE and v_cust_special is 0),
    -- checks if the password contains only alphanumeric characters.
    IF v_check_alphanumeric AND v_cust_special = 0 THEN
        IF NOT REGEXP_LIKE(password, '^[A-Za-z0-9]+$') THEN
            raise_application_error(-20002, 'Password must not contain special characters');
        END IF;
    END IF;

    -- Get the cur context lang and use utl_lms for messages- Bug 22730089
    lang := sys_context('userenv','lang');
    lang := substr(lang,1,instr(lang,'_')-1);
    -- Bug 22369990: Dbms_Utility may not be available at this point, so switch
    -- to dynamic SQL to execute canonicalize procedure.
    IF (substr(username,1,1) = '"') THEN
        execute immediate 'begin dbms_utility.canonicalize(:p1,  :p2, 128); end;'
            using IN username, OUT canon_username;
    END IF;

    -- Verifies if the password meets the defined complexity requirements
    -- (letters, uppercase, lowercase, digits, and special characters).
    IF NOT ora_complexity_check(password, 
                chars       => v_cust_chars_min, 
                letter      => v_cust_letter, 
                uppercase   => v_cust_uppercase,
                lowercase   => v_cust_lowercase,
                digit       => v_cust_digit,
                special     => v_cust_special) THEN
        RETURN(FALSE);
    END IF;

    -- Check if the password contains the username
    IF regexp_instr(password, canon_username, 1, 1, 0, 'i') > 0 THEN
        ret := utl_lms.get_message(28207, 'RDBMS', 'ORA', lang, message);
        raise_application_error(-20000, message);
    END IF;

    -- Check if the password contains the username reversed
    FOR i in REVERSE 1..length(canon_username) LOOP
        reverse_user := reverse_user || substr(canon_username, i, 1);
    END LOOP;
    IF regexp_instr(password, reverse_user, 1, 1, 0, 'i') > 0 THEN
        ret := utl_lms.get_message(28208, 'RDBMS', 'ORA', lang, message);
        raise_application_error(-20000, message);
    END IF;

    -- Check if the password contains the server name
    select name into db_name from sys.v$database;
    IF regexp_instr(password, db_name, 1, 1, 0, 'i') > 0 THEN
        ret := utl_lms.get_message(28209, 'RDBMS', 'ORA', lang, message);
        raise_application_error(-20000, message);
    END IF;

    -- Check if the password contains 'oracle'
    IF regexp_instr(password, 'oracle', 1, 1, 0, 'i') > 0 THEN
        ret := utl_lms.get_message(28210, 'RDBMS', 'ORA', lang, message);
        raise_application_error(-20000, message);
    END IF;

    -- Check if the password differs from the previous password by at least
    -- v_cust_differ characters
    IF old_password IS NOT NULL THEN
        differ := ora_string_distance(old_password, password);
        IF differ < v_cust_differ THEN
            ret := utl_lms.get_message(28211, 'RDBMS', 'ORA', lang, message);
            raise_application_error(-20000, utl_lms.format_message(message, v_cust_differ));
        END IF;
    END IF ;
    RETURN(TRUE);
END;
/
-- EOF oradba_verify_function --------------------------------------------------
-- EOF -------------------------------------------------------------------------
