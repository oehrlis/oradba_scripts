# sql command to be executed on all target databases
Command="set serveroutput on
set lin 1000
DECLARE
  l_version VARCHAR2(17);
  l_instance_name VARCHAR2(16);
  l_host_name VARCHAR2(64);
  l_status VARCHAR2(100);
  l_database_role VARCHAR2(16);
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  TYPE RefCurTyp IS REF CURSOR;
  c RefCurTyp;
  l_sql VARCHAR2(4000);
  l_username VARCHAR2(30);
  l_account_status VARCHAR2(32);
  l_default_tablespace VARCHAR2(30);
  l_created DATE;
  l_last_login DATE;
  l_profile VARCHAR2(128);
  l_comp_name VARCHAR2(255);
  l_cnt1 NUMBER;
  l_cnt2 NUMBER;
  l_cnt3 NUMBER;
  l_cnt4 NUMBER;
  l_cnt5 NUMBER;
  l_cnt6 NUMBER;
  l_bs VARCHAR2(30);
BEGIN
  SELECT i.version,i.instance_name,i.host_name,i.status,d.database_role,d.open_mode,d.name
    INTO l_version,l_instance_name,l_host_name,l_status,l_database_role,l_open_mode,l_db_name
  FROM v\$instance i, v\$database d;
  IF NOT (l_status='OPEN' AND l_database_role='PRIMARY' AND l_open_mode='READ WRITE') THEN
    RETURN;
  END IF;
  l_sql:='SELECT username,account_status,default_tablespace,created,profile,last_login FROM dba_users where oracle_maintained=''N'' order by 1';
  OPEN c FOR l_sql;
  LOOP
    FETCH c INTO l_username,l_account_status,l_default_tablespace,l_created,l_profile,l_last_login;
    EXIT WHEN c%NOTFOUND;
    dbms_output.put_line('RESULT:INSERT INTO migration_users (hostname,oracle_sid,db_name,db_version,username,account_status,default_tablespace,created,profile,last_login)');
    dbms_output.put_line('RESULT:VALUES ('''||l_host_name||''','''||l_instance_name||''','''||l_db_name||''','''||l_version||''','''||l_username||''','''||l_account_status||''','''||l_default_tablespace||''','||'TO_DATE('''||TO_CHAR(l_created,'YYYYMMDDHH24MISS')||''',''YYYYMMDDHH24MISS''),'''||l_profile||''','||'TO_DATE('''||TO_CHAR(l_last_login,'YYYYMMDDHH24MISS')||''',''YYYYMMDDHH24MISS''));');
  END LOOP;
  CLOSE c;
  l_sql:='SELECT comp_name,status from dba_registry order by 1';
  OPEN c FOR l_sql;
  LOOP
    FETCH c INTO l_comp_name,l_status;
    EXIT WHEN c%NOTFOUND;
    dbms_output.put_line('RESULT:INSERT INTO migration_components (hostname,oracle_sid,db_name,db_version,comp_name,status)');
    dbms_output.put_line('RESULT:VALUES ('''||l_host_name||''','''||l_instance_name||''','''||l_db_name||''','''||l_version||''','''||l_comp_name||''','''||l_status||''');');
  END LOOP;
  CLOSE c;
  l_sql:='SELECT COUNT(*) FROM dba_external_tables WHERE owner!=''SYS''';
  OPEN c FOR l_sql;
  FETCH c INTO l_cnt1;
  CLOSE c;
  l_sql:='SELECT COUNT(*) FROM dba_db_links';
  OPEN c FOR l_sql;
  FETCH c INTO l_cnt2;
  CLOSE c;
  l_sql:='SELECT COUNT(*) FROM dba_tab_columns WHERE data_type=''BFILE''';
  OPEN c FOR l_sql;
  FETCH c INTO l_cnt3;
  CLOSE c;
  l_sql:='SELECT COUNT(*) FROM dba_queues WHERE owner NOT IN (''SYS'',''GSMADMIN_INTERNAL'')';
  OPEN c FOR l_sql;
  FETCH c INTO l_cnt4;
  CLOSE c;
  l_sql:='SELECT COUNT(*) FROM dba_indexes WHERE ityp_name=''SPATIAL_INDEX''';
  OPEN c FOR l_sql;
  FETCH c INTO l_cnt5;
  CLOSE c;
  l_sql:='SELECT COUNT(*) FROM dba_network_acls';
  OPEN c FOR l_sql;
  FETCH c INTO l_cnt6;
  CLOSE c;
  l_sql:='SELECT LISTAGG(DISTINCT block_size,'' '') FROM v\$datafile';
  OPEN c FOR l_sql;
  FETCH c INTO l_bs;
  CLOSE c;
  dbms_output.put_line('RESULT:INSERT INTO migration_features (hostname,oracle_sid,db_name,db_version,external_tab,db_links,bfiles,queues,spatial_ind,acls,block_sizes)');
  dbms_output.put_line('RESULT:VALUES ('''||l_host_name||''','''||l_instance_name||''','''||l_db_name||''','''||l_version||''','||l_cnt1||','||l_cnt2||','||l_cnt3||','||l_cnt4||','||l_cnt5||','||l_cnt6||','''||l_bs||''');');
  l_sql:='SELECT COUNT(*) FROM v\$datafile';
  OPEN c FOR l_sql;
  FETCH c INTO l_cnt1;
  CLOSE c;
  l_sql:='SELECT sessions_highwater FROM v\$license';
  OPEN c FOR l_sql;
  FETCH c INTO l_cnt2;
  CLOSE c;
  dbms_output.put_line('RESULT:INSERT INTO migration_stats (hostname,oracle_sid,db_name,db_version,data_files,sessions_highwater)');
  dbms_output.put_line('RESULT:VALUES ('''||l_host_name||''','''||l_instance_name||''','''||l_db_name||''','''||l_version||''','||l_cnt1||','||l_cnt2||');');
END;
/
"