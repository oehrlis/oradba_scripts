--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: saua_info.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.08.29
--  Revision..:  
--  Purpose...: Show information about the audit trails 
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';
COLUMN owner               format a11 wrap heading "Table Owner"
COLUMN table_name          format a20 wrap heading "Table Name"
COLUMN rec_tot             format 9,999,999,999 heading "Total records"
COLUMN max_rec             format a19 heading "Latest record"
COLUMN min_rec             format a19 heading "Oldest record"
COLUMN last_analyzed       format a19 heading "Last analysed"
COLUMN rec_day             format 9,999,999,999 heading "Avg per day"
COLUMN rec_month           format 9,999,999,999 heading "Avg per month"
COLUMN rec_year            format 9,999,999,999 heading "Avg per year"
COLUMN num_rows            format 9,999,999,999 heading "No of rows"
COLUMN avg_row_len         format 9,999,999,999 heading "Average row length"
COLUMN actual_size_of_data format a24 heading "Total data size"
COLUMN total_size          format a24 heading "Total size of segements"

SPOOL saua_info.log
WITH table_size AS (
    SELECT
        owner,
        segment_name,
        SUM(bytes) total_size
    FROM
        dba_extents
    WHERE
        segment_type IN ( 'TABLE', 'TABLE PARTITION' )
    GROUP BY
        owner,
        segment_name
)
SELECT
    a.owner,
    a.table_name,
    a.last_analyzed,
    a.num_rows,
    a.avg_row_len,
    dbms_xplan.format_size(a.num_rows * a.avg_row_len) actual_size_of_data,
    dbms_xplan.format_size(b.total_size)               total_size
FROM
    dba_tables a,
    table_size b
WHERE
    a.table_name IN ( 'AUD$', 'FGA_LOG$', 'AUD$UNIFIED' )
    AND a.table_name = b.segment_name;

SELECT 'AUD$' "table_name", min_rec,max_rec,rec_day,rec_month,rec_year,rec_tot FROM
 (SELECT min(ntimestamp#) min_rec FROM sys.aud$),
 (SELECT max(ntimestamp#) max_rec FROM sys.aud$),
 (SELECT nvl(avg(count(*)),0) rec_day FROM sys.aud$ GROUP BY to_char(ntimestamp#,'YYYY.MM.DD')),
 (SELECT nvl(avg(count(*)),0) rec_month FROM sys.aud$ GROUP BY to_char(ntimestamp#,'YYYY.MM')),
 (SELECT nvl(avg(count(*)),0) rec_year FROM sys.aud$ GROUP BY to_char(ntimestamp#,'YYYY')), 
 (SELECT nvl(count(*),0) rec_tot FROM sys.aud$)
union
SELECT 'FGA_LOG$' "table_name", min_rec,max_rec,rec_day,rec_month,rec_year,rec_tot FROM
 (SELECT max(ntimestamp#) max_rec FROM sys.fga_log$),
 (SELECT min(ntimestamp#) min_rec FROM sys.fga_log$),
 (SELECT nvl(avg(count(*)),0) rec_day FROM sys.fga_log$ GROUP BY to_char(ntimestamp#,'YYYY.MM.DD')),
 (SELECT nvl(avg(count(*)),0) rec_month FROM sys.fga_log$ GROUP BY to_char(ntimestamp#,'YYYY.MM')),
 (SELECT nvl(avg(count(*)),0) rec_year FROM sys.fga_log$ GROUP BY to_char(ntimestamp#,'YYYY')),
 (SELECT nvl(count(*),0) rec_tot FROM sys.fga_log$)  
UNION
SELECT 'UNIFIED_AUDIT_TRAIL' "table_name", min_rec,max_rec,rec_day,rec_month,rec_year,rec_tot FROM
 (SELECT max(event_timestamp) max_rec FROM unified_audit_trail),
 (SELECT min(event_timestamp) min_rec FROM unified_audit_trail),
 (SELECT nvl(avg(count(*)),0) rec_day FROM unified_audit_trail GROUP BY to_char(event_timestamp,'YYYY.MM.DD')),
 (SELECT nvl(avg(count(*)),0) rec_month FROM unified_audit_trail GROUP BY to_char(event_timestamp,'YYYY.MM')),
 (SELECT nvl(avg(count(*)),0) rec_year FROM unified_audit_trail GROUP BY to_char(event_timestamp,'YYYY')),
 (SELECT nvl(count(*),0) rec_tot FROM unified_audit_trail);

SPOOL off
-- EOF -------------------------------------------------------------------------