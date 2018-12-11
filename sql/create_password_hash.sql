----------------------------------------------------------------------------
--  Trivadis AG, Infrastructure Managed Services
--  Saegereistrasse 29, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--  Name......: create_password_hash.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: Callculate Oracle 10g Password Hash from Username and Password
--  Usage.....: @create_password_hash username password
--  Notes.....: 
--  Reference.: execute DBMS_CRYPTO is required
--  License...: Licensed under the Universal Permissive License v 1.0 as 
--              shown at http://oss.oracle.com/licenses/upl.
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
-- Get parameters
define  oh_user="&1"
define  oh_password="&2"

SET SERVEROUTPUT ON
DECLARE
  PasswordHashString        VARCHAR2(30);

----------------------------------------------------------------------------
-- Function and Procedures                            ----------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Function..........: PasswordHash
-- Version...........: 1.2
-- Purpose...........: Function to create an oracle password hash (pre 11g)
-- Usage.............: hash_string := PasswordHash(username,<password>);
-- User parameters...: Username as VARCHAR2
--                     Password as VARCHAR2 (DEFAULT = MANAGER)
-- Output parameters.: Unicode String as RAW
-- Notes.............: Callculate the Oracle password hash
--                     1. create an zero padded unicode string
--                     2. encrypt the unicode string with DES CBC and 
--                        0123456789ABCDEF as the initial key
--                     3. take the last 8 byte as second key
--                     4. encrypt the unicode string with DES CBC and
--                        use the last 8 byte created before
--                     5. take the last 8 byte from the second encryption
--                        as password hash
---------------------------------------------------------------------------
FUNCTION PasswordHash(u IN VARCHAR2, pPassword IN VARCHAR2 := 'MANAGER') RETURN VARCHAR2 
 IS
  vSecKey RAW(128);
  vEncRAW RAW(2048);
  vUniStr VARCHAR2(124) := '';
  -- Define CONSTANT for the crypto type DES in CBC Mode with zero padding
  cCryptoTyp CONSTANT PLS_INTEGER := DBMS_CRYPTO.ENCRYPT_DES + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_ZERO;
 BEGIN  
  -- Build the new userpwd String as multibyte with the high byte set to 0 and convert the string into raw
  FOR i IN 1..LENGTH(UPPER(u||pPassword)) LOOP vUniStr := vUniStr||CHR(0)||SUBSTR(UPPER(u||pPassword),i,1); END LOOP;
  -- First DES encryption to create the second DES key
  vEncRAW:= DBMS_CRYPTO.ENCRYPT(SRC=>UTL_RAW.CAST_TO_RAW(vUniStr), TYP => cCryptoTyp, KEY => HEXTORAW('0123456789ABCDEF'));
  -- Get the last 8 Bytes as second key
  vSecKey:= HEXTORAW(SUBSTR(vEncRAW,(LENGTH(vEncRAW)-16+1),16));
  -- Second DES encryption to create the Hash
  vEncRAW:= DBMS_CRYPTO.ENCRYPT(SRC=> UTL_RAW.CAST_TO_RAW(vUniStr), TYP => cCryptoTyp, KEY => vSecKey);
  -- Return the last 8 bytes as Oracle Hash
  RETURN(HEXTORAW(SUBSTR(vEncRAW,(LENGTH(vEncRAW)-16+1),16))); 
 END;

----------------------------------------------------------------------------
--    Main                                            ----------------------
----------------------------------------------------------------------------
BEGIN
  -- calculate oracle hash
  PasswordHashString     :=  PasswordHash('&oh_user','&oh_password');
  -- Display the whole stuff
  DBMS_OUTPUT.put_line('Username : &oh_user');
  DBMS_OUTPUT.put_line('Password : &oh_password');
  DBMS_OUTPUT.put_line('Hash     : ' ||PasswordHashString);
  DBMS_OUTPUT.put_line('SQL      : alter user &oh_user identified by values '''|| PasswordHashString ||''';');
END;
/
-- EOF ---------------------------------------------------------------------