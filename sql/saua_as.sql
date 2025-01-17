--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: saua_as.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.07.06
--  Revision..:  
--  Purpose...: Show audit sessions for audit any type
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
-- define default values
DEFINE _days                = '1'
DEFINE _dbuser              = '%'
DEFINE _audit_type          = '%'
DEFINE _os_user             = '%'
DEFINE _host                = '%'
DEFINE _client_program_name = '%'

-- assign default value for parameter if argument 1,2 or 3 is empty
SET FEEDBACK OFF
SET VERIFY OFF
COLUMN 1 NEW_VALUE 1 NOPRINT
COLUMN 2 NEW_VALUE 2 NOPRINT
COLUMN 3 NEW_VALUE 3 NOPRINT
COLUMN 4 NEW_VALUE 4 NOPRINT
COLUMN 5 NEW_VALUE 5 NOPRINT
COLUMN 6 NEW_VALUE 6 NOPRINT
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
SELECT '' "2" FROM dual WHERE ROWNUM = 0;
SELECT '' "3" FROM dual WHERE ROWNUM = 0;
SELECT '' "4" FROM dual WHERE ROWNUM = 0;
SELECT '' "5" FROM dual WHERE ROWNUM = 0;
SELECT '' "6" FROM dual WHERE ROWNUM = 0;
DEFINE days                 = &1 &_days
DEFINE dbuser               = &2 &_dbuser
DEFINE audit_type           = &3 &_audit_type
DEFINE os_user              = &4 &_os_user
DEFINE host                 = &5 &_host
DEFINE client_program_name  = &6 &_client_program_name

SET PAGESIZE 66  HEADING ON  VERIFY OFF
SET LINESIZE 200
SET FEEDBACK OFF  SQLCASE UPPER  NEWPAGE 1
SET SQLCASE mixed
ALTER SESSION SET nls_date_format='DD.MM.YYYY HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format='DD.MM.YYYY HH24:MI:SS';

COLUMN start_timestamp      FORMAT A20 WRAP HEADING "Session Start"
COLUMN dbusername           FORMAT A12 WRAP HEADING "DB User"
COLUMN sessionid            FORMAT 9999999999 heading "Session ID"
COLUMN proxy_sessionid      FORMAT 9999999999 heading "Proxy ID"
COLUMN audit_type           FORMAT A20 WRAP HEADING "Audit Type"
COLUMN os_username          FORMAT A14 WRAP HEADING "OS User"
COLUMN userhost             FORMAT A26 WRAP HEADING "Host"
COLUMN instance_id          FORMAT 99999999 HEADING "Instance"
COLUMN client_program_name  FORMAT A50 WRAP HEADING "Client Program"
COLUMN records              FORMAT 999,999,999 heading "Audit Records"

TTITLE  'List of audit sessions for audit type &audit_type '

SELECT
    MAX(u.event_timestamp) start_timestamp,
    u.dbusername,
    u.sessionid,
    u.proxy_sessionid,
    u.audit_type,
    u.os_username,
    u.userhost,
    u.instance_id,
    u.client_program_name,
    COUNT(u.entry_id)      records
FROM
    unified_audit_trail u
WHERE
        u.dbid = con_id_to_dbid(sys_context('USERENV', 'CON_ID'))
    AND  audit_type LIKE upper('&audit_type')
    AND ( &days IS NULL
          OR &days = ''
          OR event_timestamp >= sysdate - &days)
    AND  upper(dbusername) LIKE upper('&dbuser')
    AND  upper(os_username) LIKE upper('&os_user')
    AND  upper(userhost) LIKE upper('&host')
    AND  upper(client_program_name) LIKE upper('&client_program_name')
GROUP BY
    u.dbusername,
    u.sessionid,
    u.proxy_sessionid,
    u.audit_type,
    u.os_username,
    u.userhost,
    u.client_program_name,
    u.instance_id
ORDER BY
    start_timestamp ASC;

UNDEFINE _days,_dbuser _audit_type _os_user _host _client_program_name
UNDEFINE days dbuser audit_type os_user host client_program_name
UNDEFINE 1 2 3 4 5 6
TTITLE OFF
-- EOF -------------------------------------------------------------------------
