--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
-- Name......: cssec_pwverify.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2023.12.12
-- Usage.....: 
-- Purpose...: Create custom password verify function. Configurable by internal
--             variables / constants
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
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION oradba_verify_function( -- NOSONAR G-7410 false positive as this function must be standalone
    in_username     IN VARCHAR2,
    in_password     IN VARCHAR2,
    in_old_password IN VARCHAR2
) RETURN BOOLEAN
    DETERMINISTIC
IS
    --------------------------------------------------------------------------------
    -- Begin of Customization ------------------------------------------------------
    --------------------------------------------------------------------------------
    -- Constants for Password Policy
    co_cust_differ        CONSTANT INTEGER                          := 5;      -- The minimum number of different characters required between the old and new passwords.
    co_cust_chars_min     CONSTANT INTEGER                          := 12;     -- The minimum length of the password.
    co_cust_chars_max     CONSTANT INTEGER                          := 0;      -- The maximum length of the password. By default this should be set to 0 i.e. unlimited
    co_cust_letter        CONSTANT INTEGER                          := 1;      -- The required number of letters in the password.
    co_cust_uppercase     CONSTANT INTEGER                          := 1;      -- The required number of uppercase letters in the password.
    co_cust_lowercase     CONSTANT INTEGER                          := 1;      -- The required number of lowercase letters in the password.
    co_cust_digit         CONSTANT INTEGER                          := 1;      -- The required number of digits in the password.
    co_cust_special       CONSTANT INTEGER                          := 0;      -- null or more characters, default 1
    co_check_alphanumeric CONSTANT BOOLEAN                          := FALSE;  -- Controls whether to check for alphanumeric-only passwords. Valid only if co_cust_special is 0.
    --------------------------------------------------------------------------------
    -- End of Customization --------------------------------------------------------
    --------------------------------------------------------------------------------
 
    -- Error Codes
    co_err_default_code   CONSTANT INTEGER                          := -20000; -- Error code for generic password error with specific message from utl_lms.get_message
    co_err_too_long       CONSTANT INTEGER                          := -20001; -- Error code for Password must not be longer than
    co_err_special_char   CONSTANT INTEGER                          := -20002; -- Error code for Password must not contain special characters
    
    -- Asserted parameters
    co_username           CONSTANT dbms_quoted_id NOT NULL          := in_username;
    co_password           CONSTANT dba_users.password%TYPE NOT NULL := in_password;
    co_old_password       CONSTANT dba_users.password%TYPE NOT NULL := in_old_password;
    
    -- Types
    SUBTYPE text_type IS VARCHAR2(512 CHAR); -- NOSONAR G-2120 keep function independent

    PROCEDURE raise_error_with_message(in_message_code IN INTEGER) IS
        l_lang    text_type;    
        l_message text_type; -- message text retrieved with sys.utl_lms.get_message
    BEGIN
        -- Get the cur context lang and use utl_lms for messages- Bug 22730089
        l_lang := sys_context('userenv', 'lang');
        l_lang := substr(l_lang, 1, instr(l_lang, '_') - 1);

        IF sys.utl_lms.get_message(in_message_code, 'RDBMS', 'ORA', l_lang, l_message) = 0 THEN
            raise_application_error(co_err_default_code, l_message);
        ELSE
            -- Raise a generic error with the default message
            raise_application_error(co_err_default_code, 'Unable to get error message using ' || in_message_code);
        END IF;
    END raise_error_with_message;

    FUNCTION contains(
        in_text IN VARCHAR2,
        in_what IN VARCHAR2
    ) RETURN BOOLEAN
        DETERMINISTIC
    IS
    BEGIN
        RETURN regexp_instr(in_text, in_what, 1, 1, 0, 'i') > 0; -- NOSONAR G-7430 false positive
    END contains;

    PROCEDURE password_length_check IS
    BEGIN
        IF co_cust_chars_max > 0 THEN
            IF length(co_password) > co_cust_chars_max THEN
                raise_application_error(co_err_too_long, 'Password must not be longer than ' || co_cust_chars_max);
            END IF;
        END IF;
    END password_length_check;

    PROCEDURE alphanumeric_check IS
    BEGIN
        IF co_check_alphanumeric AND co_cust_special = 0 THEN
            IF NOT regexp_like(co_password, '^[A-Za-z0-9]+$') THEN
                raise_application_error(co_err_special_char, 'Password must not contain special characters');
            END IF;
        END IF;
    END alphanumeric_check;

    FUNCTION canon_username RETURN VARCHAR2
        DETERMINISTIC
    IS
        l_sql            text_type;
        l_canon_username dbms_id := co_username;
    BEGIN
        -- Bug 22369990: Dbms_Utility may not be available at this point, so switch
        -- to dynamic SQL to execute canonicalize procedure.
        IF (substr(co_username, 1, 1) = '"') THEN
            l_sql := 'begin dbms_utility.canonicalize(:p1, :p2, 128); end;';
            EXECUTE IMMEDIATE l_sql USING IN co_username, OUT l_canon_username; -- NOSONAR G-6020 false positive
        END IF;
        RETURN l_canon_username; -- NOSONAR G-7430 false positive
    END canon_username;

    PROCEDURE complexity_checks IS

    BEGIN
        IF ora_complexity_check( -- NOSONAR G-2135 function fails or returns true, we can ignore the return value
                password  => co_password,
                chars     => co_cust_chars_min,
                letter    => co_cust_letter,
                uppercase => co_cust_uppercase,
                lowercase => co_cust_lowercase,
                digit     => co_cust_digit,
                special   => co_cust_special
            )
        THEN
            NULL; -- success, throws an exception if the check fails
        END IF;
    END complexity_checks;

    PROCEDURE username_inclusion_check IS
    BEGIN
        IF contains(co_password, canon_username) THEN
            raise_error_with_message(28207);
        END IF;
    END username_inclusion_check;

    PROCEDURE reverse_username_inclusion_check IS
        l_reverse_user dbms_id; -- user name in reverse order
    BEGIN
        -- alternative for reverse function which works with single byte character sets only
        <<process_chars_in_username>>
        FOR l_counter IN REVERSE 1..length(canon_username)
        LOOP
            l_reverse_user := l_reverse_user || substr(canon_username, l_counter, 1);
        END LOOP process_chars_in_username;

        IF contains(co_password, l_reverse_user) THEN
            raise_error_with_message(28208);
        END IF;
    END reverse_username_inclusion_check;

    PROCEDURE server_name_inclusion_check IS
        l_db_name v$database.name%TYPE;
    BEGIN
        SELECT name
          INTO l_db_name
          FROM v$database;

        IF contains(co_password, l_db_name) THEN
            raise_error_with_message(28209);
        END IF;
    EXCEPTION
        WHEN no_data_found OR too_many_rows THEN
            RAISE; -- should never happen, maybe should raise an explicit error
    END server_name_inclusion_check;

    PROCEDURE restricted_keywords_check IS
    BEGIN
        IF contains(co_password, 'oracle') THEN
            raise_error_with_message(28210);
        END IF;
    END restricted_keywords_check;

    PROCEDURE difference_from_old_password_check IS
    BEGIN
        IF co_old_password IS NOT NULL THEN
            IF ora_string_distance(co_old_password, co_password) < co_cust_differ THEN
                raise_error_with_message(28211);
            END IF;
        END IF;
    END difference_from_old_password_check;
BEGIN
    -- main
    password_length_check;
    alphanumeric_check;
    complexity_checks;
    username_inclusion_check;
    reverse_username_inclusion_check;
    server_name_inclusion_check;
    restricted_keywords_check;
    difference_from_old_password_check;
    RETURN TRUE; -- NOSONAR G-7430 false positive
END oradba_verify_function;
/
-- EOF -------------------------------------------------------------------------