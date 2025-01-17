--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: csenc_swkeystore_backup.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.12.09
--  Revision..:  
--  Purpose...: Automates the creation of a backup for the Transparent Data Encryption (TDE)
--              software keystore in Oracle databases.
--  Notes.....: Requires SYS, SYSDBA, or SYSKM privileges. The script sets up a DBMS scheduler
--              job to regularly backup the TDE keystore. Ensure the backup directory exists.
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- define default values
DEFINE def_backup_dir   = 'backup'
DEFINE def_backup_path  = 'wallet_root'

-- assign default value for parameter if argument 1 and 2 if one is empty
SET FEEDBACK OFF
SET VERIFY OFF
-- Assign default value for parameter 1 backup_dir
COLUMN 1 NEW_VALUE 1 NOPRINT
SELECT NULL "1" FROM dual WHERE ROWNUM = 0;
COLUMN def_backup_dir NEW_VALUE def_backup_dir NOPRINT
DEFINE backup_dir                 = &1 &def_backup_dir

-- Assign default value for parameter 2 backup_path
COLUMN 2 NEW_VALUE 2 NOPRINT
SELECT NULL "2" FROM dual WHERE ROWNUM = 0;
COLUMN def_backup_path NEW_VALUE def_backup_path NOPRINT
DEFINE backup_path                 = &2 &def_backup_path

SET FEEDBACK OFF
SET VERIFY OFF
-- define default values
COLUMN wallet_root NEW_VALUE wallet_root NOPRINT

-- format SQLPlus output and behavior
SET LINESIZE 160 PAGESIZE 200
SET FEEDBACK ON
SET SERVEROUTPUT ON

-- start to spool
SPOOL csenc_swkeystore_backup.log

--------------------------------------------------------------------------------
-- Anonymous PL/SQL Block: TDE Software Keystore Backup Configuration
-- This block performs the following actions:
--   1. Creates a DBMS Scheduler Program ('TDE_Backup_Keystore') to execute the
--      TDE keystore backup PL/SQL block.
--   2. Creates a DBMS Scheduler Schedule ('TDE_Backup_Schedule') to define the
--      frequency of the keystore backup.
--   3. Creates a DBMS Scheduler Job ('TDE_Backup_Job') that associates the backup
--      program with the schedule.
--   4. Outputs information about the creation of the scheduler objects and reminds
--      to create the necessary backup directory.
--------------------------------------------------------------------------------
DECLARE
    l_exists  INTEGER;

    
BEGIN

    -- Check if the program exists
    SELECT CASE WHEN EXISTS (SELECT 1 FROM user_scheduler_programs WHERE program_name = 'TDE_Backup_Keystore') THEN 1 ELSE 0 END INTO l_exists FROM dual;
    IF l_exists = 0 THEN
    -- Create program TDE_Backup_Keystore if it doesn't exist
        sys.dbms_scheduler.create_program (
            program_name   => 'TDE_Backup_Keystore',
            program_type   => 'PLSQL_BLOCK',
            program_action => q'(
                DECLARE
                    v_tag         VARCHAR2(30)  := 'BackupJob';
                    v_backup_dir  VARCHAR2(30)  := '&backup_dir';
                    v_backup_path VARCHAR2(128) := '&backup_path';
                BEGIN
                    IF upper(v_backup_path) = 'WALLET_ROOT' THEN
                    SELECT value INTO v_backup_path
                    FROM v$parameter
                    WHERE name = 'wallet_root';
                    
                    v_backup_path := v_backup_path
                                    || '/'
                                    || v_backup_dir;
                    END IF;
                    EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT 
                        BACKUP KEYSTORE USING "'
                                        || v_tag
                                        || '" FORCE KEYSTORE
                        IDENTIFIED BY EXTERNAL STORE TO '''
                                        || v_backup_path
                                        || ''' ';
                    END;
                )',
                enabled   => TRUE,
                comments  => 'Program to create a TDE Keystore backup using PL/SQL block.'); 
    END IF;

    -- Check if the schedule exists
    SELECT CASE WHEN EXISTS (SELECT 1 FROM user_scheduler_schedules WHERE schedule_name = 'TDE_Backup_Schedule') THEN 1 ELSE 0 END INTO l_exists FROM dual;
    IF l_exists = 0 THEN
    -- Create schedule TDE_Backup_Schedule if it doesn't exist
        sys.dbms_scheduler.create_schedule (
            schedule_name   => 'TDE_Backup_Schedule',
            start_date      => SYSTIMESTAMP,
            repeat_interval => 'freq=weekly; byday=fri; byhour=12; byminute=0; bysecond=0;',
            end_date        => NULL,
            comments        => 'TDE schedule, repeats weekly on Friday at 12:00 for ever.');
    END IF;

    -- Check if the job exists
    --SELECT COUNT(*) INTO l_job_exists FROM user_scheduler_jobs WHERE job_name = 'TDE_Backup_Job';
    SELECT CASE WHEN EXISTS (SELECT 1 FROM user_scheduler_jobs WHERE job_name = 'TDE_Backup_Job') THEN 1 ELSE 0 END INTO l_exists FROM dual;
    IF l_exists = 0 THEN
    --IF l_job_exists = 0 THEN
    -- Create job TDE_Backup_Job if it doesn't exist
        sys.dbms_scheduler.create_job (
            job_name      => 'TDE_Backup_Job',
            program_name  => 'TDE_Backup_Keystore',
            schedule_name => 'TDE_Backup_Schedule',
            enabled       => TRUE,
            comments      => 'TDE backup job using program TDE_BACKUP_KEYSTORE and schedule TDE_BACKUP_SCHEDULE.');
    END IF;

    sys.dbms_output.put_line('INFO : Scheduler Job for TDE software Keystore Backup created.');
    sys.dbms_output.put_line('INFO : Dont forget to create directory &backup_path/&backup_dir');
END;
/

SPOOL OFF
-- EOF -------------------------------------------------------------------------
