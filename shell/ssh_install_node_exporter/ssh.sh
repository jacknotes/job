#!/bin/sh
#description: remote execute shell
#author: jack
#date: 2020-08-28

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:~/bin
IP_NETWORK='192.168.13.'
#IP_NETWORK='172.168.2.'
IP_ADDR='213 206 212 31 214 33 230 32 221 116 236'
#IP_ADDR='42'
URL='/root/node_exporter.sh'
for i in ${IP_ADDR};do
    echo "--------------------------------------------------------------"
    echo "scp shell to ${IP_NETWORK}${i} and in ${IP_NETWORK}${i} execute shell"
    echo "--------------------------------------------------------------"
    read -p "input y/Y to execute scp and ssh:" VALUE
    if [ ${VALUE} == 'y' -o ${VALUE} == 'Y' ];then
	echo "--------------------------------"
	echo "scp shell to ${IP_NETWORK}${i}"
	echo "--------------------------------"
	scp -o StrictHostKeyChecking=no ${URL} root@${IP_NETWORK}${i}:~
	echo "--------------------------------"
	echo "start in ${IP_NETWORK}${i} execute shell"
	echo "--------------------------------"
	ssh root@${IP_NETWORK}${i} '~/node_exporter.sh'
	echo "--------------------------------"
	echo "in ${IP_NETWORK}${i} exec shell end."
	echo "--------------------------------"
    else 
	echo "--------------------------------"
	echo "no input y/Y,programs will exit." 
	echo "--------------------------------"
	exit
    fi
done
