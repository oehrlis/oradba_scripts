----------------------------------------------------------------------------
--  Trivadis AG, Infrastructure Managed Services
--  Saegereistrasse 29, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--  Name......: rj.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: List the runing rman_jobs	
--  Usage.....: @rj <ORACLE_SID>
--  Notes.....: 
--  Reference.: Called as DBA or user with access to v$session_longops
--  License...: Licensed under the Universal Permissive License v 1.0 as 
--              shown at http://oss.oracle.com/licenses/upl.
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
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
-- EOF ---------------------------------------------------------------------