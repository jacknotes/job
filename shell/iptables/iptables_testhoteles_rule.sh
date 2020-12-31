#!/bin/sh
#iptables for docker custom rules.

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:
PORT='8080'
IPTRUST='192.168.13.0/24'

for i in ${PORT};do
	IPPORT=`iptables -t nat -vnL DOCKER | grep ${PORT} | awk -F 'to:' '{print $2}'`
	IP=`echo $IPPORT | awk -F ':' '{print $1}'`
	PORT=`echo $IPPORT | awk -F ':' '{print $2}'`
        if [ -n ${PORT} ];then
		iptables -vnL FORWARD | grep ${IP} | grep ${PORT} >& /dev/null
		if [ $? != 0 ];then
			iptables -I FORWARD -p tcp -d ${IP} --dport ${PORT} -j DROP
			iptables -I FORWARD -s ${IPTRUST} -p tcp -d ${IP} --dport ${PORT} -j ACCEPT
        	fi
	fi
done

