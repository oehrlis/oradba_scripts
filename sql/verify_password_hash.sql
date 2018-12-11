----------------------------------------------------------------------------
--  Trivadis AG, Infrastructure Managed Services
--  Saegereistrasse 29, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--  Name......: verify_password_hash.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: Check if user has a weak password
--  Usage.....: @verify_password_hash USER PASSWORDHASH SHOW TIMOUT
--              USER         User name to check
--              PASSWORDHASH Corresponding password hash
--              SHOW         TRUE or FALSE depending if passwords should be displayed
--              TIMEOUT      A timeout for the proceedure
--  Notes.....: 
--  Reference.: requires execute on dbms_crypto
--  License...: Licensed under the Universal Permissive License v 1.0 as 
--              shown at http://oss.oracle.com/licenses/upl.
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------

-- Get parameters
define  vph_user="&1"
define  vph_hash="&2"
define  vp_show="&3"
define  vp_timeout="&4"

SET SERVEROUTPUT ON FORMAT WRAPPED SIZE 1000000 
-- Get parameters
DECLARE
 Show BOOLEAN       := &vp_show;    -- set show to TRUE if passwords have to be displayed
 t1 NUMBER          := &vp_timeout; -- Timeout password check after t1 seconds
 cUser  VARCHAR2(30):= '&vph_user';  -- limit user
 t0 NUMBER;
 vPass VARCHAR2(30);
 vUser VARCHAR2(30);
 eMatch EXCEPTION;
 eTimeout EXCEPTION;
 TYPE pwdDt IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
 Dict pwdDt;             -- Dictionary arry
 DictEmpty pwdDt;        -- empty Dictionary array to clean up
 CURSOR Accounts IS SELECT name, password AS pass, astatus AS status FROM sys.user$ WHERE type#=1 AND LOWER(name) LIKE LOWER('%'||cUser||'%') ORDER BY user#;

----------------------------------------------------------------------------
-- Function and Procedures                            ----------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Function..........: timeout
-- Version...........: 1.0
-- Purpose...........: create number / timestamp from sysdate used to create
--                     a timeout exception
-- Usage.............: timeout
-- User parameters...: none
-- Output parameters.: number
---------------------------------------------------------------------------
FUNCTION timeout RETURN NUMBER IS BEGIN RETURN TO_NUMBER(TO_CHAR(SYSDATE,'SSSSS')); END;

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
-- Procedure.........: initDict
-- Version...........: 1.1
-- Purpose...........: Initialize a password dictionary based on a username. 
--                     A limit can be specified for creating passwords with 
--                     numbers eg. user1,user2,user3....userLIMIT DEFAULT=10
-- Usage.............: initDict(username,<limit>);
-- User parameters...: Username as VARCHAR2
--                     limit as NUMBER (DEFAULT = 10)
-- Output parameters.: none
---------------------------------------------------------------------------
PROCEDURE initDict(u IN VARCHAR2 := 'USER', m IN NUMBER := 10)
 IS
  vDBName VARCHAR2(30);
  vOSUser VARCHAR2(30);
  vHost VARCHAR2(30);
  vServerHost VARCHAR2(30);
  vDomainName VARCHAR2(30);
  n NUMBER :=0;
 BEGIN
  -- get some values from the sys_context. sub blocks are used to handle expeption eg. 9i / 10g
  BEGIN vDBName:= sys_context('USERENV','DB_NAME'); EXCEPTION WHEN OTHERS THEN vDBName:='ORCL'; END;
  BEGIN vOSUser:= sys_context('USERENV','OS_USER'); EXCEPTION WHEN OTHERS THEN vOSUser:='ORACLE'; END;
  BEGIN vHost:= sys_context('USERENV','HOST'); EXCEPTION WHEN OTHERS THEN vHost:='LOCALHOST'; END;
  BEGIN vServerHost:= sys_context('USERENV','SERVER_HOST'); EXCEPTION WHEN OTHERS THEN vServerHost:='LOCALHOST'; END;
  BEGIN vDomainName:= sys_context('USERENV','DB_DOMAIN'); EXCEPTION WHEN OTHERS THEN vDomainName:='WORLD'; END;
  Dict:=DictEmpty;
  -- password equals user and reverse user name as first values
  Dict(1) :=u;
  Dict(Dict.COUNT+1):=utl_raw.cast_to_varchar2(UTL_RAW.REVERSE(utl_raw.cast_to_raw(u)));
  -- some really well known passwords
  Dict(Dict.COUNT+1):='MANAGER';
  Dict(Dict.COUNT+1):='PASSWORD';
  Dict(Dict.COUNT+1):='ADMIN';	
  Dict(Dict.COUNT+1):='WELCOME1';	
  Dict(Dict.COUNT+1):='WELCOME';
  Dict(Dict.COUNT+1):='CHANGE_ON_INSTALL';
  Dict(Dict.COUNT+1):='ORACLE';
  -- passords with user and database name
  Dict(Dict.COUNT+1):=vDBName;
  Dict(Dict.COUNT+1):=u||vDBName;
  Dict(Dict.COUNT+1):=vDBName||u;
  -- password with user name / database name and year (last, current and next two years)
  Dict(Dict.COUNT+1):=u||TO_CHAR(SYSDATE+365,'YYYY');
  Dict(Dict.COUNT+1):=u||TO_CHAR(SYSDATE,'YYYY');
  Dict(Dict.COUNT+1):=u||TO_CHAR(SYSDATE-365,'YYYY');
  Dict(Dict.COUNT+1):=u||TO_CHAR(SYSDATE-750,'YYYY');
  Dict(Dict.COUNT+1):=u||TO_CHAR(SYSDATE+365,'YY');
  Dict(Dict.COUNT+1):=u||TO_CHAR(SYSDATE,'YY');
  Dict(Dict.COUNT+1):=u||TO_CHAR(SYSDATE-365,'YY');
  Dict(Dict.COUNT+1):=u||TO_CHAR(SYSDATE-750,'YY');
  Dict(Dict.COUNT+1):=vDBName||TO_CHAR(SYSDATE,'YYYY');
  Dict(Dict.COUNT+1):=vDBName||TO_CHAR(SYSDATE-365,'YYYY');
  Dict(Dict.COUNT+1):=vDBName||TO_CHAR(SYSDATE-750,'YYYY');
  -- passwords with user name / oracle and some numbers eg 1, 12, 123, 1234 etc
  FOR i IN 1..9 LOOP n := 10*n+i; Dict(Dict.COUNT+1):=u||n; END LOOP; n := 0;
  FOR i IN 1..5 LOOP n := 10*n+i; Dict(Dict.COUNT+1):='ORACLE'||n; END LOOP;  n := 0;
  -- bunch of known passwords
  Dict(Dict.COUNT+1):='MANAG3R';
  Dict(Dict.COUNT+1):='TIGER';
  Dict(Dict.COUNT+1):='SYSPASS';
  Dict(Dict.COUNT+1):='ADMIN1';	
  Dict(Dict.COUNT+1):='ADMIN12';
  Dict(Dict.COUNT+1):='ADMIN123';			
  Dict(Dict.COUNT+1):='ADMIN1234';	
  Dict(Dict.COUNT+1):='SYSPASS';
  Dict(Dict.COUNT+1):='ORACL3';
  Dict(Dict.COUNT+1):='0RACL3';
  Dict(Dict.COUNT+1):='ORACLE8';
  Dict(Dict.COUNT+1):='ORACLE9';
  Dict(Dict.COUNT+1):='ORACLE8I';
  Dict(Dict.COUNT+1):='ORACLE9I';
  Dict(Dict.COUNT+1):='0RACLE9I';
  Dict(Dict.COUNT+1):='0RACL39I';
  Dict(Dict.COUNT+1):='0RACLE10G';
  Dict(Dict.COUNT+1):='0RACLE11g';
  Dict(Dict.COUNT+1):='DATABASE1';
  Dict(Dict.COUNT+1):='ACCOUNT1';
  Dict(Dict.COUNT+1):='USER1234';
  Dict(Dict.COUNT+1):='COMPUTER1';
  Dict(Dict.COUNT+1):='ABCDEFG1';
  Dict(Dict.COUNT+1):='NCC1701';
  Dict(Dict.COUNT+1):='QWERTY';
  Dict(Dict.COUNT+1):='QWERTZ';
  Dict(Dict.COUNT+1):='GEHEIM';
  -- passwords based on system / host information
  Dict(Dict.COUNT+1):=vServerHost;
  Dict(Dict.COUNT+1):=u||vServerHost;
  Dict(Dict.COUNT+1):=vServerHost||u;
  Dict(Dict.COUNT+1):=vOSUser;
  Dict(Dict.COUNT+1):=vHost;
  Dict(Dict.COUNT+1):=vDomainName;
  -- passwords with user name, oracle, database name and numbers from 0-LIMIT
  FOR i IN 0..m LOOP Dict(Dict.COUNT+1):=u||i; END LOOP;
  FOR i IN 0..m LOOP Dict(Dict.COUNT+1):='ORACLE'||i; END LOOP;
  FOR i IN 0..m LOOP Dict(Dict.COUNT+1):=vDBName||i; END LOOP;
 EXCEPTION WHEN OTHERS THEN Dict(Dict.COUNT) := 'EXCEPTION';
END;

----------------------------------------------------------------------------
--    Main                                            ----------------------
----------------------------------------------------------------------------
BEGIN
-- get the input parameters
  SELECT UPPER('&vph_user') INTO vUser FROM DUAL;
  SELECT UPPER('&vph_hash') INTO vPass FROM DUAL;
 
 -- set time t0 to track start time
 t0 := timeout;
 initDict(vUser);
 -- print username and account status
 DBMS_OUTPUT.PUT ('Check user ' ||vUser||' ... => ');
 BEGIN
  -- start to loop over the password dictionary
  FOR i IN 1..Dict.COUNT LOOP
   -- raise timeout exception if timeout reached
   IF (timeout - t0) >= t1 THEN RAISE eTimeout; END IF;
   -- raise a match exception if password is equal a password from the dictionary
   IF vPass=PasswordHash(vUser,UPPER(Dict(i))) THEN vPass:=Dict(i); RAISE eMatch; END IF;
  END LOOP;
   -- just print OK if loop end's normal
  DBMS_OUTPUT.put_line(RPAD('OK',20));
 EXCEPTION
  -- match exception and display Not OK if Show=FALSE or the Password if Show= TRUE
  WHEN eMatch THEN IF Show THEN DBMS_OUTPUT.put_line(RPAD(vPass,20)); ELSE DBMS_OUTPUT.put_line(RPAD('Not OK',20)); END IF;
  WHEN eTimeout THEN DBMS_OUTPUT.put_line('Timeout');
 END;
END;
/
-- EOF ---------------------------------------------------------------------