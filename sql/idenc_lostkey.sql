--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: idenc_lostkey.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.08.30
--  Revision..:  
--  Purpose...: Set hidden parameter *_db_discard_lost_masterkey* to force
--              discard of lost master keys 
--  Notes.....:  
--  Reference.: Requires SYS, SYSDBA or DBA privilege
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
-- format SQLPlus output and behavior
SET LINESIZE 160 PAGESIZE 200
SET HEADING ON
SET FEEDBACK ON

-- set hidden parameter
ALTER SYSTEM SET "_db_discard_lost_masterkey"=TRUE SCOPE=MEMORY;

-- EOF -------------------------------------------------------------------------