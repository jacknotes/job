#use version: Zabbix3.4
chmod 2770 /etc/zabbix/
chown root:zabbit -R /etc/zabbix/
#rabbitmq 
#refrence https://github.com/jasonmcintosh/rabbitmq-zabbix
您应该.rab.auth在scripts/rabbitmq目录中创建一个文件。该文件允许您更改默认参数。格式为VARIABLE=value，每行一种：默认值如下：
USERNAME=zabbix
PASSWORD=pass
CONF=/etc/zabbix/zabbix_agent.conf
LOGLEVEL=INFO
LOGFILE=/var/log/zabbix/zabbix_agentd.log
PORT=15672
#add rabbitmq monitor user
rabbitmqctl add_user zabbix pass
rabbitmqctl set_user_tags zabbix monitoring
rabbitmqctl set_permissions -p / zabbix '.*' '.*' '.*'
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

