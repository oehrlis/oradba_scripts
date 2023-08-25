--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: rowid.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.10.24
--  Revision..:  
--  Purpose...: Audit trail size
--  Notes.....:  
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
SELECT
     decode(dbms_rowid.ROWID_TYPE (rowid),0,'restricted', 1 ,'extended')  type
    , dbms_rowid.ROWID_OBJECT (rowid) object#
    , dbms_rowid.ROWID_RELATIVE_FNO(rowid) rfile#
    , dbms_rowid.ROWID_BLOCK_NUMBER(rowid) block#
    , dbms_rowid.ROWID_ROW_NUMBER(rowid)   row#
    , rowid
FROM
    &1
WHERE
    &2
/


