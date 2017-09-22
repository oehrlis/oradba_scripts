----------------------------------------------------------------------------
--     $Id: $
----------------------------------------------------------------------------
--     Trivadis AG, Infrastructure Managed Services
--     Europa-Strasse 5, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--     File-Name........:  hip.sql
--     Author...........:  Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--     Editor...........:  $LastChangedBy:   $
--     Date.............:  $LastChangedDate: $
--     Revision.........:  $LastChangedRevision: $
--     Purpose..........:  List all (hidden and regular) init parameter
--     Usage............:  @hip <PARAMETER> or % for all
--     Group/Privileges.:  SYS (or grant manually to a DBA)
--     Input parameters.:  System privilege or part of
--     Called by........:  as DBA or user with access to x$ksppi, x$ksppcv, 
--                         x$ksppsv, v$parameter
--     Restrictions.....:  unknown
--     Notes............:  --
----------------------------------------------------------------------------
--     Revision history.:  
----------------------------------------------------------------------------
col Parameter for a40
col Session for a9
col Instance for a30
col S for a1
col I for a1
col D for a1
col Description for a60 
SET VERIFY OFF
SET TERMOUT OFF

column 1 new_value 1
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
define parameter = '&1'

SET TERMOUT ON

select  
  a.ksppinm  "Parameter", 
  decode(p.isses_modifiable,'FALSE',NULL,NULL,NULL,b.ksppstvl) "Session", 
  c.ksppstvl "Instance",
  decode(p.isses_modifiable,'FALSE','F','TRUE','T') "S",
  decode(p.issys_modifiable,'FALSE','F','TRUE','T','IMMEDIATE','I','DEFERRED','D') "I",
  decode(p.isdefault,'FALSE','F','TRUE','T') "D",
  a.ksppdesc "Description"
from x$ksppi a, x$ksppcv b, x$ksppsv c, v$parameter p
where a.indx = b.indx and a.indx = c.indx
  and p.name(+) = a.ksppinm
  and upper(a.ksppinm) like upper(DECODE('&parameter', '', '%', '%&parameter%'))
order by a.ksppinm;

SET HEAD OFF
select 'Filter on parameter => '||NVL('&parameter','%') from dual;    
SET HEAD ON
undefine 1