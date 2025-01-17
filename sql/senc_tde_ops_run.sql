--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: senc_tde_ops_run.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2024.03.21
--  Revision..:  
--  Purpose...: Show TDE running operations from V$SESSION_LONGOPS
--  Notes.....:  
--  Reference.: Requires access to V$SESSION_LONGOPS
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- start to spool
SPOOL senc_tde_ops_run.log

-- format SQLPlus output and behavior
SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET LINESIZE 180
SET FEEDBACK ON SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

COLUMN sid                      FORMAT 999999 WRAP HEADING "SID"
COLUMN serial#                  FORMAT 999999 WRAP HEADING "Serial"
COLUMN file_id                  FORMAT 9999 heading "File ID"
COLUMN start_time               FORMAT A20 heading "Start Time"
COLUMN end_time                 FORMAT A20 heading "Estimated End Time"
COLUMN elapsed_seconds          FORMAT 999999999999 heading "Elapsed (Seconds)"
COLUMN formatted_elapsed_time   FORMAT A15 heading "Elapsed"
COLUMN throughput               FORMAT 999999999999 heading "Throughput (Bytes)"
COLUMN throughput_formatted     FORMAT A12 heading "Throughput"
COLUMN sofar                    FORMAT 999999999999 heading "Processed (Bytes)"
COLUMN sofar_formatted          FORMAT A12 heading "Processed"
COLUMN totalwork                FORMAT 999999999999 WRAP HEADING "Total (Bytes)"
COLUMN totalwork_formatted      FORMAT A12 WRAP HEADING "Total"
COLUMN percent                  FORMAT 999.99 WRAP HEADING "Completted (%)"
COLUMN status                   FORMAT A10 WRAP HEADING "Status"
COLUMN opname                   FORMAT A40 WRAP HEADING "Operation Name"
 
TTITLE  'Running TDE data file conversions'
SELECT
    sid,
    serial#,
    to_number(regexp_substr(message, 'data file (\d+)', 1, 1, NULL, 1)) as file_id,
    start_time,
    start_time + (time_remaining/86400) AS end_time,
    --elapsed_seconds,
    lpad(CASE
        WHEN elapsed_seconds < 60 THEN elapsed_seconds || 's'
        WHEN elapsed_seconds < 3600 THEN
            FLOOR(elapsed_seconds / 60) || 'm ' || MOD(elapsed_seconds, 60) || 's'
        WHEN elapsed_seconds < 86400 THEN
            FLOOR(elapsed_seconds / 3600) || 'h ' || FLOOR(MOD(elapsed_seconds, 3600) / 60) || 'm ' || MOD(elapsed_seconds, 60) || 's'
        ELSE
            FLOOR(elapsed_seconds / 86400) || 'd ' || FLOOR(MOD(elapsed_seconds, 86400) / 3600) || 'h ' || FLOOR(MOD(elapsed_seconds, 3600) / 60) || 'm ' || MOD(elapsed_seconds, 60) || 's'
    END,15,' ') AS formatted_elapsed_time,
    --sofar/elapsed_seconds as throughput,
    lpad(CASE
        WHEN sofar/elapsed_seconds < POWER(1024, 1) THEN ROUND(sofar/elapsed_seconds, 2) || ' B'
        WHEN sofar/elapsed_seconds < POWER(1024, 2) THEN ROUND(sofar/elapsed_seconds / POWER(1024, 1), 2) || ' KB'
        WHEN sofar/elapsed_seconds < POWER(1024, 3) THEN ROUND(sofar/elapsed_seconds / POWER(1024, 2), 2) || ' MB'
        WHEN sofar/elapsed_seconds < POWER(1024, 4) THEN ROUND(sofar/elapsed_seconds / POWER(1024, 3), 2) || ' GB'
        ELSE ROUND(sofar/elapsed_seconds / POWER(1024, 4), 2) || ' TB'
    END,12,' ')  AS throughput_formatted,
    --sofar,
    lpad(CASE
        WHEN sofar < POWER(1024, 1) THEN ROUND(sofar, 2) || ' B'
        WHEN sofar < POWER(1024, 2) THEN ROUND(sofar / POWER(1024, 1), 2) || ' KB'
        WHEN sofar < POWER(1024, 3) THEN ROUND(sofar / POWER(1024, 2), 2) || ' MB'
        WHEN sofar < POWER(1024, 4) THEN ROUND(sofar / POWER(1024, 3), 2) || ' GB'
        ELSE ROUND(sofar / POWER(1024, 4), 2) || ' TB'
    END,12,' ')  AS sofar_formatted,
    --totalwork,
    lpad(CASE
        WHEN totalwork < POWER(1024, 1) THEN ROUND(totalwork, 2) || ' B'
        WHEN totalwork < POWER(1024, 2) THEN ROUND(totalwork / POWER(1024, 1), 2) || ' KB'
        WHEN totalwork < POWER(1024, 3) THEN ROUND(totalwork / POWER(1024, 2), 2) || ' MB'
        WHEN totalwork < POWER(1024, 4) THEN ROUND(totalwork / POWER(1024, 3), 2) || ' GB'
        ELSE ROUND(totalwork / POWER(1024, 4), 2) || ' TB'
    END,12,' ') AS totalwork_formatted,
    sofar/totalwork*100 as percent,
    CASE
        WHEN time_remaining>0 THEN 'running'
        ELSE 'finished'
    END AS status
    --,opname
FROM
    v$session_longops
WHERE opname LIKE 'TDE%'
    AND time_remaining>0
ORDER BY
    file_id ASC,
    status DESC,
    start_time DESC;

UNDEFINE def_sessionid sessionid
UNDEFINE 1
TTITLE OFF

SPOOL OFF
-- EOF -------------------------------------------------------------------------