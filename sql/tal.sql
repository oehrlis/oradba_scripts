--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: tal.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: List/query alert log
--  Usage.....: @tal <STRING> or % for all
--  Notes.....: 
--  Reference.: Called as DBA or user with access to x$dbgalertext
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
col RECORD_ID for 9999999 head ID
col ORIGINATING_TIMESTAMP for a20 head Date
col MESSAGE_TEXT for a120 head Message

SET VERIFY OFF
SET TERMOUT OFF

column 1 new_value 1
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
define query = '&1'

SET TERMOUT ON

SELECT 
    record_id,
    to_char(originating_timestamp,'DD.MM.YYYY HH24:MI:SS') ORIGINATING_TIMESTAMP,
    message_text 
FROM 
    x$dbgalertext 
WHERE 
    lower(MESSAGE_TEXT) LIKE lower(DECODE('&query', '', '%', '%&query%')); 

SET HEAD OFF
SELECT 'Filter on alert log message => '||NVL('&query','%') FROM dual;    
SET HEAD ON
undefine 1
-- EOF ---------------------------------------------------------------------