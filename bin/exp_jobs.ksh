#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: exp_jobs.ksh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.05.04
# Version....: --
# Purpose....: Monitor the current runing DataPump jobs in v$session_longops
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
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
# --- EOF ----------------------------------------------------------------------