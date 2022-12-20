#!/bin/ksh -p
# ---------------------------------------------------------------------------
#               $Id: rman_jobs.ksh 2927 2006-12-07 15:24:04Z oracle $
# ---------------------------------------------------------------------------
#               sunrise, IT Technology, Database Operation Group
#               Thurgauerstrasse 60, 8050 Zuerich, Switzerland
# ---------------------------------------------------------------------------
#		File-Name........:	rman_jobs.ksh
#               Author...........:      Stefan Oehrli (oes) stefan.oehrli@sunrise.net
#               Editor...........:      $LastChangedBy: oracle $
#               Date.............:      $LastChangedDate: 2006-12-07 16:24:04 +0100 (Thu, 07 Dec 2006) $
#               Revision.........:      $LastChangedRevision: 2927 $
#		Purpose..........:	Monitor the current runing RMAN jobs in v$session_longops
#		Usage............:	rman_jobs.ksh  [ORACLE_SID]
#		Reference........:	Oracle9i Recovery Manager User's Guide
#		Group/Privileges.:	--
#		Input parameters.:	[ORACLE_SID] 	list of SID eg. DCRM01
#							this is optional, if opmitted it takes the current SID
#		Output.......... :	stout
#		Restrictions.....:	unknown
#		Notes............:	--
# -------------------------------------------------------------------------
#               Revision history.:      see svn log
# -------------------------------------------------------------------------
# Define initial values for sid_list
if [ $# -ne 0 ]; then
 DB_SID=$*
else
 DB_SID=$ORACLE_SID
fi

# loop over the sid list
for i in $DB_SID
  do
    echo "RMAN LongOps for $i"
# change the oracle environment
    . oraenv.ksh $i
# run the sql query
    sqlplus -S /nolog << EOI
      set echo off
      connect / as sysdba
      set linesize 200
      column "SID" format 999999
      column "Serial" format 999999
      column "Context" format 999999
      column "Completed" format 99.99
      column "Operation" format a50
      column "Remain" format a12
     SELECT SID "SID", serial# "Serial", CONTEXT "Context", sofar "so far", totalwork "total", 
        ROUND (sofar / totalwork * 100, 2) "Completed", opname "Operation", 
        to_char(trunc(time_remaining/60/60),'009')||to_char(trunc(mod(time_remaining,3600)/60),'09')||to_char(mod(mod(time_remaining,3600),60),'09')  "Remain"
FROM 
        v\$session_longops 
     WHERE 
        opname LIKE '%EXP%' 
        AND totalwork != 0 AND sofar <> totalwork
   ORDER BY 1;
EOI
done
