----------------------------------------------------------------------------
--     $Id: reg.sql 21 2009-09-16 09:11:28Z soe $
----------------------------------------------------------------------------
--     Trivadis AG, Infrastructure Managed Services
--     Europa-Strasse 5, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--     File-Name........:  reg.sql
--     Author...........:  Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--     Editor...........:  $LastChangedBy: soe $
--     Date.............:  $LastChangedDate: 2009-09-16 11:11:28 +0200 (Mi, 16 Sep 2009) $
--     Revision.........:  $LastChangedRevision: 21 $
--     Purpose..........:  List DBA Registry		 
--     Usage............:  @reg
--     Group/Privileges.:  select catalog
--     Input parameters.:  none
--     Called by........:  as DBA or user with access to dba_registry
--     Restrictions.....:  unknown
--     Notes............:--
----------------------------------------------------------------------------
--		 Revision history.:      see svn log
----------------------------------------------------------------------------

col reg_comp_name head "Component Name" for a50
col reg_version head "Version" for a15
col reg_status head "Status" for a11
col reg_schema head "Schema" for a15
col reg_modified head "Modified" for a20
 
select 
       COMP_NAME reg_comp_name,
       VERSION reg_version,
       STATUS reg_status, 
       SCHEMA reg_schema,
       MODIFIED reg_modified
from 
       dba_registry;
