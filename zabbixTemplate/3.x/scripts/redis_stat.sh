#!/bin/bash
RespStr=$(/usr/local/redis/bin/redis-cli -h 127.0.0.1 -p 6379 info all 2>/dev/null)
[ $? != 0 ] && echo 0 && exit 1

if [ -z $1 ]; then
 (cat <<EOF
$RespStr
EOF
 ) | awk -F: '$1~/^(uptime_in_seconds|(blocked|connected)_clients|used_memory(_rss|_peak)?|total_(connections_received|commands_processed)|instantaneous_ops_per_sec|total_net_(input|output)_bytes|rejected_connections|(expired|evicted)_keys|keyspace_(hits|misses))$/ {
  print "- redis." $1, int($2)
 }
 $1~/^cmdstat_(get|setex|exists|command)$/ {
  split($2, C, ",|=")
  print "- redis." $1, int(C[2])
 }
 $1~/^db[0-9]+$/ {
  split($2, C, ",|=")
  for(i=1; i < 6; i+=2) print "- redis." C[i] "[" $1 "]", int(C[i+1])
 }' | /usr/bin/zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --host=`hostname` --input-file - >/dev/null 2>&1
 echo 1
 exit 0

elif [ "$1" = 'db' ]; then
 (cat <<EOF
$RespStr
EOF
 ) | awk -F: '$1~/^db[0-9]+$/ {
  OutStr=OutStr es "{\"{#DBNAME}\":\"" $1 "\"}"
  es=","
 }
 END { print "{\"data\":[" OutStr "]}" }'
fi

