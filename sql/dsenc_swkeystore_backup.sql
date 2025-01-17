--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: dsenc_swkeystore_backup.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.12.09
--  Revision..:  
--  Purpose...: Deletes the DBMS Scheduler objects created for backing up the
--              Transparent Data Encryption (TDE) software keystore.
--  Notes.....: This script removes the DBMS Scheduler job, schedule, and program
--              that are used for periodic TDE keystore backups. Requires SYS, SYSDBA,
--              or SYSKM privileges to execute. Ensure no backups are running before
--              execution.
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
-- format SQLPlus output and behavior
SET LINESIZE 160 PAGESIZE 200
SET FEEDBACK ON
SET SERVEROUTPUT ON

--------------------------------------------------------------------------------
-- Script Actions: Deletion of TDE Software Keystore Backup Scheduler Objects
-- This section of the script performs the following actions:
--   1. Deletes the DBMS Scheduler Job ('TDE_Backup_Job') created for TDE keystore backup.
--   2. Deletes the DBMS Scheduler Schedule ('TDE_Backup_Schedule') associated with the backup job.
--   3. Deletes the DBMS Scheduler Program ('TDE_Backup_Keystore') that defines the backup logic.
--   4. Outputs a confirmation message indicating the successful deletion of scheduler objects.
--------------------------------------------------------------------------------

-- Delete the Scheduler Job for TDE Keystore Backup
EXECUTE dbms_scheduler.drop_job(job_name => 'TDE_Backup_Job');

-- Delete the Scheduler Schedule for TDE Keystore Backup
EXECUTE dbms_scheduler.drop_schedule(schedule_name => 'TDE_Backup_Schedule');

-- Delete the Scheduler Program for TDE Keystore Backup
EXECUTE dbms_scheduler.drop_program(program_name => 'TDE_Backup_Keystore');

-- Output confirmation message
EXECUTE dbms_output.put_line('INFO : Scheduler Job for TDE software Keystore Backup deleted.');

-- Stop spooling and close the log file
SPOOL OFF
-- EOF -------------------------------------------------------------------------