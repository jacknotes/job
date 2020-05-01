#!/bin/bash
RespStr=$(/usr/bin/curl --max-time 20 --no-keepalive --silent "http://127.0.0.1/nginx_status")
[ $? != 0 ] && echo 0 && exit 1

(cat <<EOF
$RespStr
EOF
) | awk '/^Active connections/ {active = int($NF)}
 /^ *[0-9]+ *[0-9]+ *[0-9]+/ {accepts = int($1); handled = int($2); requests = int($3)}
 /^Reading:/ {reading = int($2); writing = int($4); waiting = int($NF)}
 END {
  print "- nginx.active", active;
  print "- nginx.accepts", accepts;
  print "- nginx.handled", handled;
  print "- nginx.requests", requests;
  print "- nginx.reading", reading;
  print "- nginx.writing", writing;
  print "- nginx.waiting", waiting;
}' | /usr/bin/zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --host=`hostname` --input-file - >/dev/null 2>&1
echo 1
exit 0
