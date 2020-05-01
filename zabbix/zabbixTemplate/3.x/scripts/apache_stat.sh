#!/bin/bash
RespStr=$(/usr/bin/curl --max-time 20 --no-keepalive --silent "http://127.0.0.1/apache_status?auto")
[ $? != 0 ] && echo 0 && exit 1

(cat <<EOF
$RespStr
EOF
) | awk -F: '!/^Scoreboard/ {
  gsub(" ", "", $1)
  print "- apache." $1 $2
  } /^Scoreboard/ {
   par["WaitingForConnection"] = "_"
   par["StartingUp"] = "S"
   par["ReadingRequest"] = "R"
   par["SendingReply"] = "W"
   par["KeepAlive"] = "K"
   par["DNSLookup"] = "D"
   par["ClosingConnection"] = "C"
   par["Logging"] = "L"
   par["GracefullyFinishing"] = "G"
   par["IdleCleanupOfWorker"] = "I"
   par["OpenSlotWithNoCurrentProcess"] = "\\."
   for(p in par) print "- apache." p, gsub(par[p], "", $2)
}' | /usr/bin/zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --host=`hostname` --input-file - >/dev/null 2>&1
echo 1
exit 0
