--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: ssenc_swkeystore_backup.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.12.09
--  Revision..:  
--  Purpose...: Displays the configuration and status of the TDE software keystore backup 
--              components created in the Oracle database.
--  Notes.....: This script queries the DBMS Scheduler objects related to TDE keystore backup, 
--              including programs, schedules, and jobs. Requires SYS, SYSDBA, or SYSKM privileges.
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- format SQLPlus output and behavior
SET LINESIZE 200 PAGESIZE 200
SET FEEDBACK ON
SET SERVEROUTPUT ON

COLUMN program_name     FORMAT A20
COLUMN program_action   FORMAT A100
COLUMN schedule_name    FORMAT A20
COLUMN job_name         FORMAT A20
COLUMN start_date       FORMAT A35
COLUMN repeat_interval  FORMAT A60
COLUMN comments         FORMAT A60
COLUMN last_start_date  FORMAT A20
COLUMN next_run_date    FORMAT A20
ALTER SESSION SET nls_timestamp_tz_format='DD.MM.YYYY HH24:MI:SS';

-- Start spooling to log file
SPOOL ssenc_swkeystore_backup.log

--------------------------------------------------------------------------------
-- SQL Queries: TDE Software Keystore Backup Scheduler Objects Information
-- This section queries the following DBMS Scheduler objects:
--   1. Scheduler Programs: Lists all TDE-related programs including their attributes.
--   2. Scheduler Schedules: Displays the schedules configured for TDE backups.
--   3. Scheduler Jobs: Shows the details of the jobs set up for performing the backups.
--   4. Outputs include program actions, schedule timings, job execution history, etc.
--------------------------------------------------------------------------------

-- Query Scheduler Programs related to TDE
SELECT program_name, program_type, enabled, comments 
FROM user_scheduler_programs WHERE program_name LIKE 'TDE%';

-- Query Program Actions for TDE Programs
SELECT program_action FROM user_scheduler_programs WHERE program_name LIKE 'TDE%';

-- Query Scheduler Schedules related to TDE
SELECT schedule_name, start_date, repeat_interval, comments 
FROM user_scheduler_schedules WHERE schedule_name LIKE 'TDE%';

-- Query Scheduler Jobs related to TDE
SELECT job_name, program_name, schedule_name, enabled, state,
       run_count, last_start_date, next_run_date
FROM user_scheduler_jobs WHERE job_name LIKE 'TDE%';

-- Stop spooling and close the log file
SPOOL OFF
-- EOF -------------------------------------------------------------------------