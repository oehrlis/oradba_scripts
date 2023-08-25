--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: saua_asstd.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2023.07.06
--  Revision..:  
--  Purpose...: Show audit sessions for audit type Standard
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
-- define default values
DEFINE _days                = '1'
DEFINE _dbuser              = '%'
DEFINE _audit_type          = 'Standard'
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

@aue_sessions.sql &days &dbuser &audit_type &os_user &host &client_program_name

UNDEFINE _days,_dbuser _audit_type _os_user _host _client_program_name
UNDEFINE days dbuser audit_type os_user host client_program_name
UNDEFINE 1 2 3 4 5 6
TTITLE OFF
-- EOF -------------------------------------------------------------------------
