#!/bin/bash
d=`date --date today +%Y%m%d_%H:%M:%S`
[ `ps -C haproxy --no-heading|wc -l` -gt 0 ] && curl -Is -uhaproxy:password http://127.0.0.1:8888/haproxy-status | grep '200 OK'
if [ $? -ne '0' ];then
        #systemctl restart haproxy
	[ `ps -C haproxy --no-heading|wc -l` -gt 0 ] && curl -Is -uhaproxy:password http://127.0.0.1:8888/haproxy-status | grep '200 OK'
        if [ $? -ne "0"  ]; then
                echo "$d haproxy down,keepalived will stop" >> /var/log/chk_nginx.log
                systemctl stop keepalived
        fi
fi
