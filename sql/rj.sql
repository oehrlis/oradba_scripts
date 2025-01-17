--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: rj.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: List the runing rman_jobs	
--  Usage.....: @rj <ORACLE_SID>
--  Notes.....: 
--  Reference.: Called as DBA or user with access to v$session_longops
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
COLUMN rj_sid HEAD "SID" FORMAT 999999
COLUMN rj_serial HEAD "Serial" FORMAT 999999
COLUMN rj_context HEAD "Context" FORMAT 999999
COLUMN rj_completed HEAD "Completed" FORMAT 99.99
COLUMN rj_operation HEAD "Operation" FORMAT a50
COLUMN rj_remain HEAD "Remain" FORMAT a10

SELECT SID rj_sid,
  serial# rj_serial,
  CONTEXT rj_context,
  sofar "so far",
  totalwork "total",
  ROUND (sofar / totalwork * 100, 2) rj_completed,
  opname rj_operation,
  TO_CHAR(TRUNC(time_remaining            /60/60),'09')
  ||TO_CHAR(TRUNC(mod(time_remaining,3600)/60),'09')
  ||TO_CHAR(mod(mod(time_remaining,3600),60),'09') rj_remain
  FROM v$session_longops
  WHERE opname LIKE 'RMAN%'
AND totalwork != 0
AND sofar     <> totalwork
ORDER BY 1;
-- EOF -------------------------------------------------------------------------