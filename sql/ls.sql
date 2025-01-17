--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: ls.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: List datafiles belonging to tablespaces matching parameter
--  Usage.....: @ls <TABLESPACE_NAME>
--  Notes.....: Called  DBA or user with access to x$ksppi, x$ksppcv, 
--              x$ksppsv, v$parameter
--  Reference.: Idea based on a script from tanel@tanelpoder.com
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
COL ls_file_name HEAD FILE_NAME FOR a80
COL ls_mb HEAD MB
COL ls_maxsize HEAD MAXSZ

SELECT 
    tablespace_name,
    file_id,
    file_name ls_file_name,
    autoextensible ext,
    round(bytes/1048576,2) ls_mb,
    decode(autoextensible, 'YES', round(maxbytes/1048576,2), NULL) ls_maxsize
FROM
    (SELECT tablespace_name, file_id, file_name, autoextensible, bytes, maxbytes FROM dba_data_files WHERE upper(tablespace_name) LIKE upper('%&1%')
     UNION ALL
     SELECT tablespace_name, file_id, file_name, autoextensible, bytes, maxbytes FROM dba_temp_files WHERE upper(tablespace_name) LIKE upper('%&1%')
    )
ORDER BY
    tablespace_name,
    file_name;
-- EOF ---------------------------------------------------------------------