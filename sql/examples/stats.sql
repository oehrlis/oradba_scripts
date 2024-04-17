select 
  nam.name,
  mys.value
from
  v$mystat   mys   join
  v$statname nam on mys.statistic# = nam.statistic#
where mys.value>0
order by
  nam.name;