--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: uapex.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: Show APEX user sessions in database (no background procs)
--  Usage.....: @Show APEX user sessions in database (no background procs)
--  Notes.....: 
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
col u_username head USERNAME for a20
col u_sid head SID for a14 
col u_spid head SPID for a12 wrap
col u_audsid head AUDSID for 9999999999
col u_osuser head OSUSER for a16 truncate
col u_machine head MACHINE for a18 truncate
col u_program head PROGRAM for a20 truncate
col u_module head MODULE for a35 truncate
col u_action head ACTION for a20 truncate
col u_service_name head SERVICE_NAME for a15 truncate

select s.username u_username, ' ''' || s.sid || ',' || s.serial# || '''' u_sid, 
       s.audsid u_audsid,
--       s.osuser u_osuser, 
--       substr(s.machine,instr(s.machine,'\')) u_machine, 
--       s.machine u_machine, 
--       s.program u_program,
--       substr(s.program,instr(s.program,'(')) u_program, 
--       p.pid,
       s.service_name u_service_name,
			 s.module u_module,
			 s.action u_action,
       p.spid u_spid, 
       -- s.sql_address, 
       s.sql_hash_value, 
--       s.last_call_et lastcall, 
       s.status 
       --, s.logon_time
from 
    v$session s,
    v$process p
where
    s.paddr=p.addr
and s.type!='BACKGROUND'
--and s.status='ACTIVE'
order  by STATUS desc
/
-- EOF ---------------------------------------------------------------------