--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: net.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: List current session connection information
--  Usage.....: @net
--  Notes.....: 
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
COLUMN net_sid HEAD "SID" FOR 99999
COLUMN net_osuser HEAD OS_USER FOR a10
COLUMN net_authentication_type HEAD AUTH_TYPE FOR a10 
COLUMN net_network_service_banner HEAD NET_BANNER FOR a100

SELECT 
    sid                    net_sid, 
    osuser                 net_osuser, 
    authentication_type    net_authentication_type, 
    network_service_banner net_network_service_banner
FROM v$session_connect_info
WHERE sid=(SELECT sid FROM v$mystat WHERE ROWNUM = 1);
-- EOF ---------------------------------------------------------------------
