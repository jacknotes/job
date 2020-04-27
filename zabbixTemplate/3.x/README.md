#use version: Zabbix3.4
#rabbitmq 
#refrence https://github.com/jasonmcintosh/rabbitmq-zabbix
您应该.rab.auth在scripts/rabbitmq目录中创建一个文件。该文件允许您更改默认参数。格式为VARIABLE=value，每行一种：默认值如下：
USERNAME=zabbix
PASSWORD=pass
CONF=/etc/zabbix/zabbix_agent.conf
LOGLEVEL=INFO
LOGFILE=/var/log/zabbix/rabbitmq_zabbix.log
PORT=15672
设置rabbitmq_zabbix.log文件权限:
touch /var/log/zabbix/rabbitmq_zabbix.log
chown root:zabbix /var/log/zabbix/rabbitmq_zabbix.log
chmod 770 /var/log/zabbix/rabbitmq_zabbix.log
#add rabbitmq monitor user
[root@node2 zabbix_agentd.d]# rabbitmqctl add_user zabbix pass
[root@node2 zabbix_agentd.d]# rabbitmqctl set_user_tags zabbix monitoring
[root@node2 zabbix_agentd.d]# rabbitmqctl set_permissions -p / zabbix '^aliveness-test$' '^amq\.default$' '^aliveness-test$'
#最后不要忘记重启zabbix-agent service

#mysql
#refrence https://github.com/RuslanMahotkin/zabbix
install zabbix-sender plugin: zabbix-sender
create user and grant,Example:
  GRANT PROCESS,SHOW DATABASES,REPLICATION CLIENT,SHOW VIEW ON *.* TO 'zbx_monitor'@'localhost' IDENTIFIED BY PASSWORD 'zbx_monitor';
grant mysql_stat.sh permission:
  chmod 750 mysql_stat.sh
  chgrp zabbix mysql_stat.sh
service restart: systemctl restart zabbix-agent 

#redis
#refrence https://github.com/RuslanMahotkin/zabbix
install zabbix-sender plugin: zabbix-sender
grant redis_stat.sh permission:
  chmod 750 redis_stat.sh
  chgrp zabbix redis_stat.sh
service restart: systemctl restart redis-agent

