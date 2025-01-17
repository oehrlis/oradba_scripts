--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: tab_size.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.10.24
--  Revision..:  
--  Purpose...: Table Average Row Length and Total Size Report
--  Usage.....: @tab_size 
--  Notes.....: 
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
UNDEF ENTER_OWNER_NAME
UNDEF ENTER_TABLE_NAME

SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 3
UNDEF ENTER_OWNER_NAME
UNDEF ENTER_TABLE_NAME
COLUMN table_name          format a30 wrap
COLUMN avg_row_len         format 9,999,999,999 heading "Average|Row|Length"
COLUMN actual_size_of_data format 9,999,999,999 heading "Total|Data|Size"
COLUMN total_size          format 9,999,999,999 heading "Total|Size|Of|Table"

TTITLE left _date center "Table Average Row Length and Total Size Report"
WITH table_size AS
     (SELECT   owner, segment_name, SUM (BYTES) total_size
          FROM dba_extents
         WHERE segment_type = 'TABLE'
      GROUP BY owner, segment_name)
SELECT table_name, avg_row_len, num_rows * avg_row_len actual_size_of_data,
       b.total_size
  FROM dba_tables a, table_size b
 WHERE a.owner = UPPER ('&&ENTER_OWNER_NAME')
   AND a.table_name = UPPER ('&&ENTER_TABLE_NAME')
   AND a.owner = b.owner
   AND a.table_name = b.segment_name;
-- EOF ---------------------------------------------------------------------