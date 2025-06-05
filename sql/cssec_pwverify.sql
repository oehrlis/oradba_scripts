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
CREATE OR REPLACE FUNCTION oradba_verify_function ( -- NOSONAR skip G-7410 as this function must be standalone
    in_username     IN VARCHAR2,
    in_password     IN VARCHAR2,
    in_old_password IN VARCHAR2
) RETURN BOOLEAN DETERMINISTIC IS

--------------------------------------------------------------------------------
-- Begin of Customization ------------------------------------------------------
--------------------------------------------------------------------------------
    -- Constants for Password Policy
    co_cust_differ        CONSTANT INTEGER := 5;      -- The minimum number of different characters required between the old and new passwords.
    co_cust_chars_min     CONSTANT INTEGER := 12;     -- The minimum length of the password.
    co_cust_chars_max     CONSTANT INTEGER := 0;      -- The maximum length of the password. By default this should be set to 0 i.e. unlimited
    co_cust_letter        CONSTANT INTEGER := 1;      -- The required number of letters in the password.
    co_cust_uppercase     CONSTANT INTEGER := 1;      -- The required number of uppercase letters in the password.
    co_cust_lowercase     CONSTANT INTEGER := 1;      -- The required number of lowercase letters in the password.
    co_cust_digit         CONSTANT INTEGER := 1;      -- The required number of digits in the password.
    co_cust_special       CONSTANT INTEGER := 0;      -- null or more characters, default 1
    co_check_alphanumeric CONSTANT BOOLEAN := FALSE;  -- Controls whether to check for alphanumeric-only passwords. Valid only if co_cust_special is 0.
--------------------------------------------------------------------------------
-- End of Customization --------------------------------------------------------
--------------------------------------------------------------------------------
 
    -- Constants for misc literals
    co_regex_nocase       CONSTANT VARCHAR2(1 CHAR) := 'i';       -- case-insensitive regex NOSONAR
    co_product            CONSTANT VARCHAR2(5 CHAR) := 'RDBMS';   -- product family used in utl_lms.get_message NOSONAR
    co_facility           CONSTANT VARCHAR2(5 CHAR) := 'ORA';     -- facility used in utl_lms.get_message NOSONAR

    -- Error Codes
    co_err_too_long       CONSTANT INTEGER := -20001; -- Error code for Password must not be longer than
    co_err_special_char   CONSTANT INTEGER := -20002; -- Error code for Password must not contain special characters
    
    -- Local variables
    l_username            dbms_quoted_id NOT NULL       := in_username;     -- local variable for username
    l_password            VARCHAR2(1024 BYTE) NOT NULL  := in_password;     -- local variable for new password NOSONAR
    l_old_password        VARCHAR2(1024 BYTE) NOT NULL  := in_old_password; -- local variable for old password NOSONAR
    l_ret                 BOOLEAN;                                          -- return value
    l_differ              INTEGER;                                          -- local variable for minimum number of different characters required between the old and new passwords.
    l_db_name             v$database.name%TYPE;                             -- local variable used to get / store the DB name
    l_counter             INTEGER;                                          -- local variable used as FOR LOOP counter
    l_reverse_user        dbms_id;                                          -- local variable to store the user name in reverse order
    l_canon_username      dbms_id := l_username;                            -- local variable for the canonicalize user name
    l_lang                VARCHAR2(512 CHAR);                               -- local variable for error message language NOSONAR
    l_sql                 VARCHAR2(512 CHAR);                               -- local variable for sql used in EXECUTE IMMEDIATE NOSONAR

    --------------------------------------------------------------------------------
    -- Procedure.....: raise_error_with_message
    -- Purpose.......: This procedure attempts to retrieve a custom error message
    --                 using the sys.utl_lms.get_message function. If successful,
    --                 it raises an application error with the retrieved message.
    --                 If it fails to retrieve the message, it raises a generic 
    --                 error with a default message.
    --
    -- Parameters....:
    --   in_message_code - The message code to retrieve the error message from utl_lms.get_message.
    --   in_product      - The product component for the error message.
    --   in_facility     - The facility component for the error message.
    --   in_lang         - The language in which the error message is requested.
    --
    -- Behavior......:
    --   - If the message is successfully retrieved, raise an application error with the retrieved message.
    --   - If the message retrieval fails, raise an application error with a generic default message.
    --
    -- Constants.....:
    --   co_err_default_code - The default error code used when raising an application error.
    --   co_err_default_msg  - The default error message used when the specific error message cannot be retrieved.
    ----------------------------------------------------------------------------
    PROCEDURE raise_error_with_message (
        in_message_code IN INTEGER,
        in_product      IN VARCHAR2,
        in_facility     IN VARCHAR2,
        in_lang         IN VARCHAR2
    ) IS

        l_message           VARCHAR2(512 CHAR);     -- local variable for message text retrieved with sys.utl_lms.get_message NOSONAR
        l_get_message_ret   INTEGER;
        
        -- Error Codes
        co_err_default_code CONSTANT INTEGER := -20000; -- Error code for generic password error with specific message from utl_lms.get_message
        co_err_default_msg  CONSTANT VARCHAR2(128 CHAR) := 'Unable to get error message using ' || in_message_code; -- default error message NOSONAR
    BEGIN
        l_get_message_ret := sys.utl_lms.get_message(in_message_code, in_product, in_facility, in_lang, l_message);

        IF l_get_message_ret = 0 THEN
            raise_application_error(co_err_default_code, l_message);
        ELSE
            -- Raise a generic error with the default message
            raise_application_error(co_err_default_code, co_err_default_msg);
        END IF;

    END raise_error_with_message;
    -- EOF raise_error_with_message --------------------------------------------
BEGIN
    -- if co_cust_chars_max is defined, validates if the password length is within
    -- the specified maximum limit
    IF co_cust_chars_max > 0 THEN
        IF length(l_password) > co_cust_chars_max THEN
            raise_application_error(co_err_too_long, 'Password must not be longer than ' || co_cust_chars_max);
        END IF;
    END IF;

    -- If enabled (co_check_alphanumeric is TRUE and co_cust_special is 0),
    -- checks if the password contains only alphanumeric characters.
    IF
        co_check_alphanumeric
        AND co_cust_special = 0
    THEN
        IF NOT regexp_like(l_password, '^[A-Za-z0-9]+$') THEN
            raise_application_error(co_err_special_char, 'Password must not contain special characters');
        END IF;

    END IF;

    -- Get the cur context lang and use utl_lms for messages- Bug 22730089
    l_lang := sys_context('userenv', 'lang');
    l_lang := substr(l_lang, 1, instr(l_lang, '_') - 1);
    -- Bug 22369990: Dbms_Utility may not be available at this point, so switch
    -- to dynamic SQL to execute canonicalize procedure.
    IF ( substr(l_username, 1, 1) = '"' ) THEN
        l_sql := 'begin dbms_utility.canonicalize(:p1, :p2, 128); end;';
        EXECUTE IMMEDIATE l_sql USING IN l_username, OUT l_canon_username; -- Execute canonicalize procedure NOSONAR to ignore G-6020
    END IF;

    -- Verifies if the password meets the defined complexity requirements
    -- (letters, uppercase, lowercase, digits, and special characters).
    IF NOT ora_complexity_check(l_password, 
            chars       => co_cust_chars_min, 
            letter      => co_cust_letter,
            uppercase   => co_cust_uppercase,
            lowercase   => co_cust_lowercase,
            digit       => co_cust_digit,
            special     => co_cust_special) THEN
        l_ret := FALSE;
    END IF;

    -- Check if the password contains the username
    IF regexp_instr(l_password, l_canon_username, 1, 1, 0,co_regex_nocase) > 0 THEN
        raise_error_with_message(28207, co_product, co_facility, l_lang);
    END IF;

    -- Check if the password contains the username reversed
    << for_loop >> FOR l_counter IN REVERSE 1..length(l_canon_username) LOOP
        l_reverse_user := l_reverse_user|| substr(l_canon_username, l_counter, 1);
    END LOOP for_loop;

    IF regexp_instr(l_password, l_reverse_user, 1, 1, 0,co_regex_nocase) > 0 THEN
        raise_error_with_message(28208, co_product, co_facility, l_lang);
    END IF;

    -- Check if the password contains the server name
    SELECT
        name
    INTO l_db_name
    FROM
        v$database;

    IF regexp_instr(l_password, l_db_name, 1, 1, 0,co_regex_nocase) > 0 THEN
        raise_error_with_message(28209, co_product, co_facility, l_lang);
    END IF;

    -- Check if the password contains 'oracle'
    IF regexp_instr(l_password, 'oracle', 1, 1, 0,co_regex_nocase) > 0 THEN
        raise_error_with_message(28210, co_product, co_facility, l_lang);
    END IF;

    -- Check if the password differs from the previous password by at least
    -- co_cust_differ characters
    IF l_old_password IS NOT NULL THEN
        l_differ := ora_string_distance(l_old_password, l_password);
        IF l_differ < co_cust_differ THEN
            raise_error_with_message(28211, co_product, co_facility, l_lang);
        END IF;

    END IF;

    l_ret := TRUE;
    RETURN l_ret;
EXCEPTION
    WHEN no_data_found THEN
        RETURN FALSE;
    WHEN too_many_rows THEN
        RETURN FALSE;
END;
/
-- EOF oradba_verify_function --------------------------------------------------
-- EOF -------------------------------------------------------------------------