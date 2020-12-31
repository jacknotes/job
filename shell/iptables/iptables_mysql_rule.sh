#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:
PORT='3306'
IPUNTRUST='192.168.10.0/24'

for i in ${PORT};do
	iptables -vnL INPUT | grep ${i} >& /dev/null
	if [ $? != 0 ];then
		iptables -I INPUT 1 -s ${IPUNTRUST} -p tcp --dport ${PORT} -j DROP >& /dev/null
	fi
done

