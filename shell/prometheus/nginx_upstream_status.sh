#!/bin/bash
# description: output nginx upstream status
# author: jackli
# date: 2023-05-04
# email: jack.li@homsom.com

#instance_name=$(hostname -f | cut -d '.' -f 1)
#if [ ${instance_name} == "localhost" ];then
#	echo "hostanem Must FQDN"
#	exit 1
#fi

user='user'
password='password'
instance_name=$(hostname) 
PushgatewayServer="127.0.0.1:9091"
metrics_file='/usr/local/pushgateway/metrics.txt'
local_pro_nginx_status_address='http://nginx-status.hs.com/checkstatus?format=json'
local_ops_nginx_status_address='http://192.168.13.50:8088/checkstatus?format=json'
aliyun_nginx_status_address='http://10.10.10.240:8088/checkstatus?format=json'
nginx_upstream_status_label="nginx_upstream_status" 



## TYPE ${nginx_upstream_status_label} gauge
echo "#HELP ${nginx_upstream_status_label} 0(down) 1(up)" > ${metrics_file}
echo "#TYPE ${nginx_upstream_status_label} gauge" >> ${metrics_file}


# local pro nginx
local_pro_nginx_upstream_status_down_value=`curl -s -u${user}:${password} ${local_pro_nginx_status_address} | jq '.servers.server[] | select(.status == "down")' | jq '{"index":.index|tostring,upstream,name,status,type,"port":.port|tostring,"nginx":"192.168.13.207","env":"local"}' | jq -c`
local_pro_nginx_upstream_status_up_value=`curl -s -u${user}:${password} ${local_pro_nginx_status_address} | jq '.servers.server[] | select(.status == "up")' | jq '{"index":.index|tostring,upstream,name,status,type,"port":.port|tostring,"nginx":"192.168.13.207","env":"local"}' | jq -c`

# local ops nginx
local_ops_nginx_upstream_status_down_value=`curl -s -u${user}:${password} ${local_ops_nginx_status_address} | jq '.servers.server[] | select(.status == "down")' | jq '{"index":.index|tostring,upstream,name,status,type,"port":.port|tostring,"nginx":"192.168.13.50","env":"local"}' | jq -c`
local_ops_nginx_upstream_status_up_value=`curl -s -u${user}:${password} ${local_ops_nginx_status_address} | jq '.servers.server[] | select(.status == "up")' | jq '{"index":.index|tostring,upstream,name,status,type,"port":.port|tostring,"nginx":"192.168.13.50","env":"local"}' | jq -c`

# aliyun nginx
aliyun_nginx_upstream_status_down_value=`curl -s -u${user}:${password} ${aliyun_nginx_status_address} | jq '.servers.server[] | select(.status == "down")' | jq '{"index":.index|tostring,upstream,name,status,type,"port":.port|tostring,"nginx":"10.10.10.240","env":"aliyun"}' | jq -c`
aliyun_nginx_upstream_status_up_value=`curl -s -u${user}:${password} ${aliyun_nginx_status_address} | jq '.servers.server[] | select(.status == "up")' | jq '{"index":.index|tostring,upstream,name,status,type,"port":.port|tostring,"nginx":"10.10.10.240","env":"aliyun"}' | jq -c`


## output down metrics
for i in $local_pro_nginx_upstream_status_down_value $local_ops_nginx_upstream_status_down_value $aliyun_nginx_upstream_status_down_value
do
	echo "${nginx_upstream_status_label}$i 0" | sed 's/":/=/g' | sed 's/\,"/,/g' | sed 's/{"/{/g' >> ${metrics_file}
done

## output up metrics
for i in $local_pro_nginx_upstream_status_up_value $local_ops_nginx_upstream_status_up_value $aliyun_nginx_upstream_status_up_value
do
	echo "${nginx_upstream_status_label}$i 1" | sed 's/":/=/g' | sed 's/\,"/,/g' | sed 's/{"/{/g' >> ${metrics_file}
done

## push to pushgateway
cat ${metrics_file} | curl --data-binary @- http://${PushgatewayServer}/metrics/job/pushgateway/instance/${instance_name}
