----------------------------------------------------------------------------
--  Trivadis AG, Infrastructure Managed Services
--  Saegereistrasse 29, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--  Name......: aud_size.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--  Editor....: Stefan Oehrli
--  Date......: 2018.10.24
--  Revision..:  
--  Purpose...: Audit trail size
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Licensed under the Universal Permissive License v 1.0 as 
--              shown at http://oss.oracle.com/licenses/upl.
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
COLUMN table_name          format a30 wrap heading "Table Name"
COLUMN rec_tot             format 9,999,999,999 heading "Total records"
COLUMN max_rec             format a14 heading "Latest record"
COLUMN min_rec             format a14 heading "Oldest record"
COLUMN rec_day             format 9,999,999,999 heading "Avg per day"
COLUMN rec_month           format 9,999,999,999 heading "Avg per month"
COLUMN rec_year            format 9,999,999,999 heading "Avg per year"
COLUMN avg_row_len         format 9,999,999,999 heading "Average row length"
COLUMN actual_size_of_data format 9,999,999,999 heading "Total data size"
COLUMN total_size          format 9,999,999,999 heading "Total size of table"

WITH table_size AS
     (SELECT   owner, segment_name, SUM (BYTES) total_size
          FROM dba_extents
         WHERE segment_type = 'TABLE'
      GROUP BY owner, segment_name)
SELECT table_name, avg_row_len, num_rows * avg_row_len actual_size_of_data,
       b.total_size
  FROM dba_tables a, table_size b
 WHERE a.owner = UPPER ('SYS')
   AND a.table_name in  ('AUD$','FGA_LOG$')
   AND a.owner = b.owner
   AND a.table_name = b.segment_name;

SELECT 'AUD$' "table_name", min_rec,max_rec,rec_day,rec_month,rec_year,rec_tot FROM
 (SELECT nvl(to_char(min(ntimestamp#),'YYYY.MM.DD'),'n/a') min_rec FROM sys.aud$),
 (SELECT nvl(to_char(max(ntimestamp#),'YYYY.MM.DD'),'n/a') max_rec FROM sys.aud$),
 (SELECT nvl(avg(count(*)),0) rec_day FROM sys.aud$ GROUP BY to_char(ntimestamp#,'YYYY.MM.DD')),
 (SELECT nvl(avg(count(*)),0) rec_month FROM sys.aud$ GROUP BY to_char(ntimestamp#,'YYYY.MM')),
 (SELECT nvl(avg(count(*)),0) rec_year FROM sys.aud$ GROUP BY to_char(ntimestamp#,'YYYY')), 
 (SELECT nvl(count(*),0) rec_tot FROM sys.aud$) 
union
SELECT 'FGA_LOG$' "table_name", min_rec,max_rec,rec_day,rec_month,rec_year,rec_tot FROM
 (SELECT nvl(to_char(max(ntimestamp#),'YYYY.MM.DD'),'n/a') max_rec FROM sys.fga_log$),
 (SELECT nvl(to_char(min(ntimestamp#),'YYYY.MM.DD'),'n/a') min_rec FROM sys.fga_log$),
 (SELECT nvl(avg(count(*)),0) rec_day FROM sys.fga_log$ GROUP BY to_char(ntimestamp#,'YYYY.MM.DD')),
 (SELECT nvl(avg(count(*)),0) rec_month FROM sys.fga_log$ GROUP BY to_char(ntimestamp#,'YYYY.MM')),
 (SELECT nvl(avg(count(*)),0) rec_year FROM sys.fga_log$ GROUP BY to_char(ntimestamp#,'YYYY')),
 (SELECT nvl(count(*),0) rec_tot FROM sys.fga_log$) ;
-- EOF ---------------------------------------------------------------------