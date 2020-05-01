#!/bin/bash
if [ -z $1 ]; then
 RespStr=$(/usr/bin/iostat -dkxy 5 1 2>/dev/null)
 [ $? != 0 ] && echo 0 && exit 1

 (cat <<EOF
$RespStr
EOF
 ) | awk 'BEGIN {split("disk rrqm_s wrqm_s r_s w_s rkB_s wkB_s avgrq-sz avgqu-sz await svctm util", aParNames)}
  $1 ~ /^[hsv]d[a-z]$/ {
  gsub(",", ".", $0);
  if(NF == 14)
   for(i = 2; i <= 14; i++) print "- iostat."aParNames[i]"["$1"]", $i
 }' | /usr/bin/zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --host=`hostname` --input-file - >/dev/null 2>&1
 echo 1
 exit 0

elif [ "$1" = 'disks' ]; then
 DiskStr=`/usr/bin/iostat -d | awk '$1 ~ /^[hsv]d[a-z]$/ {print $1}'`
 es=''
 for disk in $DiskStr; do
  OutStr="$OutStr$es{\"{#DISKNAME}\":\"$disk\"}"
  es=","
 done
 echo -e "{\"data\":[$OutStr]}"
fi
