#!/bin/bash
d=`date --date today +%Y%m%d_%H:%M:%S`
[ `ps aux | grep beam | grep -v grep |wc -l` -gt 0 ] && ncat -vz 127.0.0.1 5672 &> /dev/null
if [ $? -ne '0' ];then
        #systemctl restart rabbitmq-server
	[ `ps aux | grep beam | grep -v grep |wc -l` -gt 0 ] && ncat -vz 127.0.0.1 5672 &> /dev/null
        if [ $? -ne "0"  ]; then
                echo "$d rabbitmq-server down,keepalived will stop" >> /var/log/chk_shell.log
                systemctl stop keepalived
        fi
fi
