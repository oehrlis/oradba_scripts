----------------------------------------------------------------------------
--  Trivadis AG, Infrastructure Managed Services
--  Saegereistrasse 29, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--  Name......: net.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: List current session connection information
--  Usage.....: @net
--  Notes.....: 
--  Reference.: 
--  License...: Licensed under the Universal Permissive License v 1.0 as 
--              shown at http://oss.oracle.com/licenses/upl.
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
COL net_sid HEAD SID FOR 99999
COL net_osuser HEAD OS_USER FOR a10
COL net_authentication_type HEAD AUTH_TYPE FOR a10 
COL net_network_service_banner HEAD NET_BANNER FOR a100

SELECT 
    sid                    net_sid, 
    osuser                 net_osuser, 
    authentication_type    net_authentication_type, 
    network_service_banner net_network_service_banner
FROM v$session_connect_info
WHERE sid=(SELECT sid FROM v$mystat WHERE ROWNUM = 1);
-- EOF ---------------------------------------------------------------------