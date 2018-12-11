----------------------------------------------------------------------------
--  Trivadis AG, Infrastructure Managed Services
--  Saegereistrasse 29, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--  Name......: df.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: Show Oracle tablespace free space in Unix df style
--  Notes.....:  
--  Reference.: Idea based on a script from tanel@tanelpoder.com
--  License...: Licensed under the Universal Permissive License v 1.0 as 
--              shown at http://oss.oracle.com/licenses/upl.
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
COL "% Used" FOR a6
COL "Used" FOR a22

SELECT t.tablespace_name, t.mb "TotalMB", t.mb - nvl(f.mb,0) "UsedMB", nvl(f.mb,0) "FreeMB", 
       lpad(ceil((1-nvl(f.mb,0)/t.mb)*100)||'%', 6) "% Used", t.ext "Ext", 
       '|'||rpad(lpad('#',ceil((1-nvl(f.mb,0)/t.mb)*20),'#'),20,' ')||'|' "Used"
FROM (
  SELECT tablespace_name, trunc(sum(bytes)/1048576) MB
  FROM dba_free_space
  GROUP BY tablespace_name
 UNION ALL
  SELECT tablespace_name, trunc(sum(bytes_free)/1048576) MB
  FROM v$temp_space_header
  GROUP BY tablespace_name
) f, (
  SELECT tablespace_name, trunc(sum(bytes)/1048576) MB, max(autoextensible) ext
  FROM dba_data_files
  GROUP BY tablespace_name
 UNION ALL
  SELECT tablespace_name, trunc(sum(bytes)/1048576) MB, max(autoextensible) ext
  FROM dba_temp_files
  GROUP BY tablespace_name
) t
WHERE t.tablespace_name = f.tablespace_name (+)
ORDER BY t.tablespace_name;
-- EOF ---------------------------------------------------------------------