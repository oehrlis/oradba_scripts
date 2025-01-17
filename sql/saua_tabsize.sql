--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: saua_tabsize.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.07.06
--  Revision..:  
--  Purpose...: Show Unified Audit trail table and partition size
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';
COLUMN owner            FORMAT A10 WRAP HEADING "Owner"
COLUMN segment_name     FORMAT A25 WRAP HEADING "Segment Name"
COLUMN segment_type     FORMAT A20 WRAP HEADING "Segment Type"
COLUMN tablespace_name  FORMAT A20 WRAP HEADING "Tablespace Name"
COLUMN segment_size     FORMAT A10 WRAP HEADING "Size"
COLUMN bytes            FORMAT 9,999,999,999 heading "Bytes"
COLUMN blocks           FORMAT 9,999,999,999 heading "Blocks"
COLUMN extents          FORMAT 9,999,999,999 heading "extents"

SPOOL saua_tabsize.log
SELECT
    owner,
    segment_name,
    segment_type,
    tablespace_name,
    dbms_xplan.format_size(bytes) segment_size,
    bytes,
    blocks,
    extents
FROM
    dba_segments ds
WHERE
    owner = 'AUDSYS'
ORDER BY
    segment_name;
SPOOL OFF
-- EOF -------------------------------------------------------------------------
