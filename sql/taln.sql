----------------------------------------------------------------------------
--     $Id: $
----------------------------------------------------------------------------
--     Trivadis AG, Infrastructure Managed Services
--     Europa-Strasse 5, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--     File-Name........:  taln.sql
--     Author...........:  Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--     Editor...........:  $LastChangedBy:   $
--     Date.............:  $LastChangedDate: $
--     Revision.........:  $LastChangedRevision: $
--     Purpose..........:  List/query alert log
--     Usage............:  @taln <NUMBER>
--     Group/Privileges.:  SYS (or grant manually to a DBA)
--     Input parameters.:  System privilege or part of
--     Called by........:  as DBA or user with access to x$dbgalertext
--     Restrictions.....:  unknown
--     Notes............:  --
----------------------------------------------------------------------------
--     Revision history.:  
----------------------------------------------------------------------------
col RECORD_ID for 9999999 head ID
col ORIGINATING_TIMESTAMP for a20 head Date
col MESSAGE_TEXT for a120 head Message

SET VERIFY OFF
SET TERMOUT OFF

column 1 new_value 1
column 2 new_value 2
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
define number = '&1'
SELECT '' "2" FROM dual WHERE ROWNUM = 0;
define query = '&2'
SET TERMOUT ON

select 
    * 
from (select 
        record_id,
        to_char(originating_timestamp,'DD.MM.YYYY HH24:MI:SS') ORIGINATING_TIMESTAMP,
        message_text 
    from 
        x$dbgalertext
    order by RECORD_ID desc) 
where 
    rownum <= DECODE('&number', '', '10', '&number')
    and lower(MESSAGE_TEXT) like lower(DECODE('&query', '', '%', '%&query%'))
order by RECORD_ID asc;

undefine 1
undefine 2