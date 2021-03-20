#!/bin/sh
#date: 20210218
#author: jackli
#description: use linux host task planning.

LOGFILE="/tmp/linux_hosts_task.log"
HOSTS="192.168.13.160:6369 192.168.13.160:16369 192.168.13.161:6369 192.168.13.161:16369 192.168.13.162:6369 192.168.13.162:16369 pdredis1.hs.com:6379 pdredis2.hs.com:6379 192.168.13.235:15672 192.168.13.235:5672 192.168.13.65:15672 192.168.13.65:5672 192.168.13.160:15672 192.168.13.160:5672"
URL_HOSTS="http://newjenkins.hs.com/login http://jenkins.hs.com/login http://hlog.hs.com http://clog.hs.com http://blog.hs.com http://testhoteles.hs.com http://hoteles.hs.com http://rabbitmq.hs.com"
CRON_HOST="192.168.13.236"

echo "HOST: ${CRON_HOST}" > ${LOGFILE}
echo "DATETIME: `date +'%Y-%m-%d-%T'`" >> ${LOGFILE}
#IP:PORT
echo "IP:PORT" >> ${LOGFILE}
for I in ${HOSTS};do
	PROCESS_HOST=`echo ${I} | sed 's/:/ /g'`
	nc -vz ${PROCESS_HOST} >& /dev/null && echo "${PROCESS_HOST}: successful" >> ${LOGFILE}|| echo "${PROCESS_HOST}: failure" >> ${LOGFILE}
done

#URL
echo "URL" >> ${LOGFILE}
for I in ${URL_HOSTS};do
	curl -Is ${I}  | grep -E '200|201|202|203|204|300|301|302' >& /dev/null |echo "${I}: successful" >> ${LOGFILE} || echo "${I}: failure" >> ${LOGFILE}
done

