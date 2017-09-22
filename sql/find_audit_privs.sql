-- -----------------------------------------------------------------------------
--                 WWW.PETEFINNIGAN.COM LIMITED
-- -----------------------------------------------------------------------------
-- Script Name : find_audit_privs.sql
-- Author      : Pete Finnigan
-- Date        : June 2003
-- -----------------------------------------------------------------------------
-- Description : Use this script to find which users have been granted 
--               privileges to audit the database.
-- -----------------------------------------------------------------------------
-- Maintainer  : Pete Finnigan (http://www.petefinnigan.com)
-- Copyright   : Copyright (C) 2003 PeteFinnigan.com Limited. All rights
--               reserved. All registered trademarks are the property of their
--               respective owners and are hereby acknowledged.
-- -----------------------------------------------------------------------------
--  Usage      : The script provided here is available free. You can do anything 
--               you want with it commercial or non commercial as long as the 
--               copyrights and this notice are not removed or edited in any way. 
--               The scripts cannot be posted / published / hosted or whatever 
--               anywhere else except at www.petefinnigan.com/tools.htm
-- -----------------------------------------------------------------------------
-- Version History
-- ===============
--
-- Who         version     Date      Description
-- ===         =======     ======    ======================
-- P.Finnigan  1.0         Jun 2003  First Issue.
-- P.Finnigan  1.1         Oct 2004  Added usage notes.
-- -----------------------------------------------------------------------------

whenever sqlerror exist rollback
set feed on
set head on
set arraysize 1
set space 1
set verify on
set pages 25
set lines 80
set termout on
clear screen

spool find_audit_privs.lis

col grantee for a20
col privilege for a15
col admin_option for a4
select grantee,privilege,admin_option
from dba_sys_privs
where privilege like '%AUDIT%'
/

spool off
