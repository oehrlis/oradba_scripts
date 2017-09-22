define owner=&1
set serveroutput on
begin
  for r in (select owner,object_name from all_objects where owner=UPPER('&owner') and object_type='TYPE') loop
    dbms_output.put_line('INFO: drop type '||r.owner||'.'||r.object_name||' force');
    execute immediate 'drop type '||r.owner||'.'||r.object_name||' force';
  end loop;
end;
/

