----------------------------------------------------------------------------
--     $Id: lgs.sql 21 2009-09-16 09:11:28Z soe $
--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: lgs.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: Report log swich per hour 30 days back		 	
--  Usage.....: @lgs 
--  Notes.....: 
--  Reference.: Called as DBA or user with access to v$log_history
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
prompt My LGS
set termout off
@@saveset
set termout on

set feedback off
COL lgs_date FOR a10 HEAD "Day"
COL lgs_blocks FOR 999999 HEAD "MB/day"
COL lgs_logs FOR 99999 HEAD "Log/day"
COL lgs_switch FOR 99999 HEAD "Switch/day" 
COL lgs_00 FOR a4 HEAD "00" JUSTIFY RIGHT
COL lgs_01 FOR a4 HEAD "01" JUSTIFY RIGHT
COL lgs_02 FOR a4 HEAD "02" JUSTIFY RIGHT
COL lgs_03 FOR a4 HEAD "03" JUSTIFY RIGHT
COL lgs_04 FOR a4 HEAD "04" JUSTIFY RIGHT
COL lgs_05 FOR a4 HEAD "05" JUSTIFY RIGHT
COL lgs_06 FOR a4 HEAD "06" JUSTIFY RIGHT
COL lgs_07 FOR a4 HEAD "07" JUSTIFY RIGHT
COL lgs_08 FOR a4 HEAD "08" JUSTIFY RIGHT
COL lgs_09 FOR a4 HEAD "09" JUSTIFY RIGHT
COL lgs_10 FOR a4 HEAD "10" JUSTIFY RIGHT
COL lgs_11 FOR a4 HEAD "11" JUSTIFY RIGHT
COL lgs_12 FOR a4 HEAD "12" JUSTIFY RIGHT
COL lgs_13 FOR a4 HEAD "13" JUSTIFY RIGHT
COL lgs_14 FOR a4 HEAD "14" JUSTIFY RIGHT
COL lgs_15 FOR a4 HEAD "15" JUSTIFY RIGHT
COL lgs_16 FOR a4 HEAD "16" JUSTIFY RIGHT
COL lgs_17 FOR a4 HEAD "17" JUSTIFY RIGHT
COL lgs_18 FOR a4 HEAD "18" JUSTIFY RIGHT
COL lgs_19 FOR a4 HEAD "19" JUSTIFY RIGHT
COL lgs_20 FOR a4 HEAD "20" JUSTIFY RIGHT
COL lgs_21 FOR a4 HEAD "21" JUSTIFY RIGHT
COL lgs_22 FOR a4 HEAD "22" JUSTIFY RIGHT
COL lgs_23 FOR a4 HEAD "23" JUSTIFY RIGHT

COL lgs_dest_id FOR 9999 HEAD "ID"
COL lgs_dest_name FOR a20 HEAD "Name"
COL lgs_target FOR a10 HEAD "Target"
COL lgs_status FOR a10 HEAD "Status"
COL lgs_destination FOR a99 HEAD "Destination"

prompt
prompt =====================================================================================================================================================
prompt Log switch's history map
prompt =====================================================================================================================================================
WITH
  archived_logs AS (
SELECT min(dest_id) DEST_ID,al.sequence#,al.BLOCKS,al.BLOCK_SIZE FROM v$archived_log al GROUP BY al.sequence#,al.blocks,al.block_size)
SELECT SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),1,10) lgs_date,
  round(sum(al.BLOCKS*al.BLOCK_SIZE)/1024/1024,0) lgs_blocks,
  COUNT(lh.first_time) lgs_switch,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'00',1,0)),'9999'))),3) lgs_00,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'01',1,0)),'9999'))),3) lgs_01,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'02',1,0)),'9999'))),3) lgs_02,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'03',1,0)),'9999'))),3) lgs_03,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'04',1,0)),'9999'))),3) lgs_04,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'05',1,0)),'9999'))),3) lgs_05,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'06',1,0)),'9999'))),3) lgs_06,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'07',1,0)),'9999'))),3) lgs_07,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'08',1,0)),'9999'))),3) lgs_08,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'09',1,0)),'9999'))),3) lgs_09,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'10',1,0)),'9999'))),3) lgs_10,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'11',1,0)),'9999'))),3) lgs_11,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'12',1,0)),'9999'))),3) lgs_12,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'13',1,0)),'9999'))),3) lgs_13,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'14',1,0)),'9999'))),3) lgs_14,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'15',1,0)),'9999'))),3) lgs_15,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'16',1,0)),'9999'))),3) lgs_16,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'17',1,0)),'9999'))),3) lgs_17,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'18',1,0)),'9999'))),3) lgs_18,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'19',1,0)),'9999'))),3) lgs_19,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'20',1,0)),'9999'))),3) lgs_20,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'21',1,0)),'9999'))),3) lgs_21,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'22',1,0)),'9999'))),3) lgs_22,
  lpad(rtrim(ltrim(TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),12,2),'23',1,0)),'9999'))),3) lgs_23
FROM 
  V$log_history lh, archived_logs al
WHERE
  lh.first_time > sysdate - 30
  AND lh.sequence#=al.sequence#
GROUP BY SUBSTR(TO_CHAR(lh.first_time, 'dd.mm.yyyy hh24mi'),1,10)
ORDER BY to_date(lgs_date, 'dd.mm.yyyy hh24mi');

prompt
prompt =====================================================================================================================================================
prompt Active archive destinations
prompt =====================================================================================================================================================
SELECT 
  a.dest_id lgs_dest_id,
  a.dest_name lgs_dest_name,
  a.target lgs_target,
  a.status lgs_status,
  a.destination lgs_destination
FROM 
  v$archive_dest a,
  v$archived_log b 
WHERE 
  a.dest_id=b.dest_id
  AND a.status='VALID' 
GROUP 
  by a.dest_id,a.dest_name,a.status,a.destination,a.target;

set feedback on

set termout off
@@loadset
set termout on
-- EOF ---------------------------------------------------------------------