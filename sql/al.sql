--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: al.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.10.24
--  Revision..:  
--  Purpose...: List/query alert log
--  Usage.....: @al <STRING> or % for all
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
COL record_id FOR 9999999 HEAD id
COL originating_timestamp FOR a20 HEAD Date
COL message_text FOR a120 HEAD message

SET VERIFY OFF
SET TERMOUT OFF

column 1 new_value 1
SELECT
    '' "1"
FROM
    dual
WHERE
    ROWNUM = 0;

DEFINE query = '&1'

SET TERMOUT ON

SELECT
    record_id,
    TO_CHAR(originating_timestamp,'DD.MM.YYYY HH24:MI:SS'),
    message_text
FROM
    x$dbgalertext
WHERE
    lower(message_text) LIKE lower(DECODE('&query','','%','%&query%') );
    
SET HEAD OFF
SELECT
    'Filter on alert log message => ' || nvl('&query','%')
FROM
    dual;
SET HEAD ON
undefine 1
-- EOF ---------------------------------------------------------------------