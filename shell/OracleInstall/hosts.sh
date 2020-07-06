#!/bin/sh
#
CURRENT_DIR=$(/bin/pwd)
LOGFILE=${CURRENT_DIR}/log.txt
CURRENT_TIME='/usr/bin/date +"%Y-%m-%d-%T"'
NETCARD=$(ip link show  | grep -E 'eth.*<|ens.*<' | awk -F':' '{sub(/\ /,""); print $2}')
HOSTIP=$(ip add show ${NETCARD} | grep 'inet ' | awk '{print $2}' | awk -F '/' '{print $1}')

echo '--------------' >> ${LOGFILE}
/usr/bin/echo $(${CURRENT_TIME}) >> ${LOGFILE};
/usr/bin/echo ${HOSTIP} $(/usr/bin/hostname) >> /etc/hosts
/usr/bin/ping -A -q -s 500 -W 1000 -c 1 $(/usr/bin/hostname) && echo "hostname resolve config succeesful" >> ${LOGFILE} || echo "hostname resolve config failure" >> ${LOGFILE}
echo '--------------' >> ${LOGFILE}
/bin/grep 'hostname resolve config succeesful' ${LOGFILE} &> /dev/null || exit 1 

