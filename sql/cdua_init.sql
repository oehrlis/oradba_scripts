--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: cdua_init.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.26.29
--  Usage.....: cdua_init.sql <TABLESPACE NAME> <DATAFILE SIZE> <AUDIT RETENTION>
--
--              TABLESPACE NAME   Name of the audit tablespace. Default is AUDIT_DATA
--              DATAFILE SIZE     Initial size of datafile. Default 20480K
--              AUDIT RETENTION   Day for which a audit timestamp will be created e.g.
--                                sysdate - <AUDIT RETENTION> This does help to create
--                                somekind of time window where audit records will be
--                                awailable on the system. This amount of DAY
--                                is also the fallback when the AVAGENT does not CREATE
--                                timestamps. Default 30 days
--  Purpose...: Initialize Audit environment. Create Tablespace, reorganize Audit
--              tables and create jobs
--  Notes.....: 
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------

-- define default values
DEFINE _tablespace_name = 'AUDIT_DATA'
DEFINE _tablespace_size = '20480K'
DEFINE _audit_retention = 30

-- assign default value for parameter if argument 1,2 or 3 is empty
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
COLUMN 2 NEW_VALUE 2 NOPRINT
COLUMN 3 NEW_VALUE 3 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0; 
SELECT '' "2" FROM dual WHERE ROWNUM = 0; 
SELECT '' "3" FROM dual WHERE ROWNUM = 0; 
DEFINE tablespace_name    = &1 &_tablespace_name
DEFINE tablespace_size    = &2 &_tablespace_size
DEFINE audit_retention    = &3 &_audit_retention
COLUMN tablespace_name NEW_VALUE tablespace_name NOPRINT
SELECT upper('&tablespace_name') tablespace_name FROM dual;

SPOOL cdua_init.log
-- Anonymous PL/SQL Block to configure audit environment
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200

DECLARE

  -- Types
  SUBTYPE text_type IS VARCHAR2(512 CHAR); -- NOSONAR G-2120 keep function independent

  -- Local variables
  l_version           PLS_INTEGER;
  l_datafile_path     dba_data_files.file_name%TYPE;
  l_db_unique_name    v$database.db_unique_name%TYPE;
  l_audit_tablespace  v$tablespace.name%TYPE := '&tablespace_name';
  l_audit_data_file   dba_data_files.file_name%TYPE;
  l_file_dest         v$parameter.value%TYPE;
  l_sql               text_type;              -- sql used in EXECUTE IMMEDIATE
  l_status            text_type;              -- sql used in EXECUTE IMMEDIATE
  e_tablespace_exists EXCEPTION;
  e_job_exists        EXCEPTION;
  e_audit_job_exists  EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_tablespace_exists,-1543);
  PRAGMA EXCEPTION_INIT(e_job_exists, -27477 );
  PRAGMA EXCEPTION_INIT(e_audit_job_exists, -46254);

BEGIN

  sys.dbms_output.put_line('Setup and initialize audit configuration');
  -- Get required DB info
  <<get_data_dict_infos>>
  BEGIN
    SELECT 
      (SELECT value FROM v$parameter WHERE name = 'db_create_file_dest'),
      (SELECT db_unique_name FROM v$database),
      (SELECT regexp_substr(version, '^\d+') FROM v$instance),
      (SELECT file_name FROM dba_data_files WHERE file_name LIKE '%system%' AND ROWNUM = 1)
    INTO
      l_file_dest, l_db_unique_name, l_version, l_datafile_path
    FROM dual;
  EXCEPTION
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
      sys.dbms_output.put_line('Error: Unable to retrieve data dictionary information.');
  END get_data_dict_infos;
  
-- Create Tablespace but rise an exception if it already exists
  sys.dbms_output.put('- Create ' || l_audit_tablespace || ' Tablespace... ');
  <<create_tablespace>>
  BEGIN
    IF l_file_dest IS NOT NULL THEN
      -- OMF is enabled
      l_sql := 'CREATE BIGFILE TABLESPACE ' || l_audit_tablespace ||
               ' DATAFILE SIZE &tablespace_size AUTOEXTEND ON NEXT 10240K MAXSIZE UNLIMITED';
      l_status:='created (OMF)';
    ELSE
      -- Derive path or diskgroup from SYSTEM datafile
      IF l_datafile_path LIKE '+%' THEN
        -- ASM path
        l_datafile_path := regexp_substr(l_datafile_path, '[^/]*');
        l_sql := 'CREATE BIGFILE TABLESPACE ' || l_audit_tablespace ||
                 ' DATAFILE ''' || l_datafile_path || ''' SIZE &tablespace_size AUTOEXTEND ON NEXT 10240K MAXSIZE UNLIMITED';
        l_status:='created (ASM)';
      ELSE
        -- Filesystem path
        l_datafile_path := regexp_substr(l_datafile_path, '^/.*/');
        l_audit_data_file := l_datafile_path || LOWER(l_audit_tablespace) || '01' || l_db_unique_name || '.dbf';
        l_sql := 'CREATE BIGFILE TABLESPACE ' || l_audit_tablespace ||
                 ' DATAFILE ''' || l_audit_data_file || ''' SIZE &tablespace_size AUTOEXTEND ON NEXT 10240K MAXSIZE UNLIMITED';
        l_status:='created (regular)';
      END IF;
    END IF;
    EXECUTE IMMEDIATE l_sql;
    sys.dbms_output.put_line(l_status);
  EXCEPTION
    WHEN e_tablespace_exists THEN
      sys.dbms_output.put_line('already exists');
  END create_tablespace;

  -- set location for Unified Audit Trail
  sys.dbms_output.put_line('Set location to '||l_audit_tablespace||' for Unified Audit');
  sys.dbms_audit_mgmt.set_audit_trail_location(
    audit_trail_type           => sys.dbms_audit_mgmt.audit_trail_unified,
    audit_trail_location_value => l_audit_tablespace
  );

  -- set location for Standard and FGA Audit Trail
  sys.dbms_output.put_line('Set location to '||l_audit_tablespace||' for Standard and FGA Audit Trail');
  sys.dbms_audit_mgmt.set_audit_trail_location(
    audit_trail_type           => sys.dbms_audit_mgmt.audit_trail_db_std,
    audit_trail_location_value => l_audit_tablespace
  );

  sys.dbms_output.put_line('Set partition interval to 1 day');
  sys.dbms_audit_mgmt.alter_partition_interval(
    interval_number       => 1,
    interval_frequency    => 'DAY');

  sys.dbms_output.put_line('Create archive timestamp jobs');
  sys.dbms_output.put('- Unified Audit Trail........... ');
  <<create_ts_job>>
  BEGIN
    sys.dbms_scheduler.create_job (
      job_name   => 'DAILY_UNIFIED_AUDIT_TIMESTAMP',
      job_type   => 'PLSQL_BLOCK',
      job_action => 'BEGIN sys.dbms_audit_mgmt.set_last_archive_timestamp(audit_trail_type => 
                      sys.dbms_audit_mgmt.audit_trail_unified,last_archive_time => sysdate-&audit_retention); END;',
      start_date => sysdate,
      repeat_interval => 'FREQ=HOURLY;INTERVAL=24',
      enabled    =>  TRUE,
      comments   => 'Archive timestamp for unified audit to sysdate-&audit_retention'
    );
    sys.dbms_output.put_line('created');
  EXCEPTION
    WHEN e_job_exists THEN
      sys.dbms_output.PUT_LINE('already exists');
  END create_ts_job;

-- Create daily purge job
  sys.dbms_output.put_line('Create archive purge jobs');
  -- Purge Job Unified Audit Trail
  sys.dbms_output.put('- Unified Audit Trail............ ');
  <<create_purge_job>>
  BEGIN
    sys.dbms_audit_mgmt.create_purge_job(
      audit_trail_type           => sys.dbms_audit_mgmt.audit_trail_unified,
      audit_trail_purge_interval => 24 /* hours */,
      audit_trail_purge_name     => 'Daily_Unified_Audit_Purge_Job',
      use_last_arch_timestamp    => TRUE
    );
    sys.dbms_output.put_line('created');
  EXCEPTION
    WHEN e_audit_job_exists THEN
      sys.dbms_output.PUT_LINE('already exists');
  END create_purge_job;

END;
/

COL parameter_name FOR a30
COL parameter_value FOR a20
COL audit_trail FOR a20
SELECT audit_trail,parameter_name, parameter_value 
FROM dba_audit_mgmt_config_params ORDER BY audit_trail;

COL job_name FOR a30
COL job_frequency FOR a40
SELECT job_name,job_status,audit_trail,job_frequency FROM dba_audit_mgmt_cleanup_jobs;

COL job_name FOR a30
COL repeat_interval FOR a80
SELECT job_name,repeat_interval,comments FROM dba_scheduler_jobs WHERE job_name LIKE '%AUDIT%' ;

COL policy_name for a40
COL entity_name for a30
SELECT policy_name, enabled_option, entity_name, entity_type, success, failure FROM audit_unified_enabled_policies;

SPOOL off
-- EOF -------------------------------------------------------------------------