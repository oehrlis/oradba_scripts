----------------------------------------------------------------------------
--     $Id: iux.sql 21 2009-09-16 09:11:28Z soe $
----------------------------------------------------------------------------
--     Trivadis AG, Infrastructure Managed Services
--     Europa-Strasse 5, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--     File-Name........:  i.sql
--     Author...........:  tanel@tanelpoder.com
--     Editor...........:  Stefan Oehrli stefan.oehrli@trivadis.com
--     Date.............:  $LastChangedDate: 2009-09-16 11:11:28 +0200 (Mi, 16 Sep 2009) $
--     Revision.........:  $LastChangedRevision: 21 $
--     Purpose..........:  initialize environment
--     Usage............:  @i
--     Group/Privileges.:  n/a
--     Input parameters.:  n/a
--     Called by........:  --
--     Restrictions.....:  --
--     Notes............:  --
----------------------------------------------------------------------------
--     Revision history.:      see svn log
----------------------------------------------------------------------------
 
def   mysid="NA"
def _i_spid="NA"
def _i_cpid="NA"
def _i_inst="NA"
def _i_host="NA"
def _i_user="&_user"
def _i_conn="&_connect_identifier"

col i_username head USERNAME for a18
col i_sid head SID for a5 new_value mysid
col i_serial# head SERIAL# for 999999
col i_cpid head CPID for a15 new_value _i_cpid
col i_spid head SPID for a15 new_value _i_spid
col i_authentication_type head AUTH_TYPE for a10 
col i_network_service_banner head ENC_TYPE for a10 
--col i_opid head OPID for 99999 new_value _i_opid noprint
col i_opid head OPID for 99999 new_value _i_opid
col i_host_name head HOST_NAME for a18 new_value _i_host
col i_instance_name head INST_NAME for a12 new_value _i_inst
col i_ver head VERSION for a10
col i_startup_day head STARTED for a8
col _i_user noprint new_value _i_user
col _i_conn noprint new_value _i_conn
col i_myoraver noprint new_value myoraver

select 
	s.username			i_username, 
	i.instance_name	i_instance_name, 
	i.host_name			i_host_name, 
	(select authentication_type from v$session_connect_info si where si.sid=s.sid and rownum = 1) i_authentication_type,
	(select nvl(max(regexp_substr(network_service_banner,'([[:alnum:]]+)',1)),'n/a') from v$session_connect_info si where si.sid=s.sid and lower(network_service_banner) like '%encryption%adapter%' and rownum = 1) i_network_service_banner,
	(select substr(banner, instr(banner, 'Release ')+8,10) from v$version where rownum = 1) i_ver,
	(select  substr(substr(banner, instr(banner, 'Release ')+8),
	 		1,
			instr(substr(banner, instr(banner, 'Release ')+8),'.')-1)
	 from v$version 
	 where rownum = 1) i_myoraver,
	to_char(startup_time, 'YYYYMMDD') i_startup_day, 
	to_char(s.sid) 	i_sid, 
	s.serial#			i_serial#, 
	p.pid				i_opid, 
	p.spid				i_spid, 
	s.process			i_cpid, 
	s.saddr				saddr, 
	p.addr				paddr,
	lower(s.username) "_i_user",
	upper('&_connect_identifier') "_i_conn"
from 
	v$session s, 
	v$instance i, 
	v$process p
where 
	s.paddr = p.addr
and 
	s.sid = (select sid from v$mystat where rownum = 1);

-- host set_putty_title.ksh &_i_user@&_i_conn [sid=&mysid spid=&_i_spid inst=&_i_inst host=&_i_host cpid=&_i_cpid]
--host title &_i_user@&_i_conn [sid=&mysid spid=&_i_spid inst=&_i_inst host=&_i_host cpid=&_i_cpid]

def myopid=&_i_opid
def myspid=&_i_spid
def mycpid=&_i_cpid

undef _i_spid _i_inst _i_host _i_user _i_conn _i_cpid
