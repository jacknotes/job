#use version: Zabbix3.4
#default: shell under /etc/zabbix/scripts,zabbix custom monitor configure file under /etc/zabbix/zabbix_agentd.d/
chmod -R 774 /etc/zabbix/scripts
chown -R root:zabbit /etc/zabbix/
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
service restart: systemctl restart zabbix-agent

#elasticsearch
#refrence https://github.com/RuslanMahotkin/zabbix
#refrence https://github.com/dominictarr/JSON.sh
install zabbix-sender plugin: zabbix-sender
  chmod 750 elasticsearch_stat.sh
  chgrp zabbix elasticsearch_stat.sh
  chmod 750 JSON.sh   #JSON.sh AND elasticsearch_stat.sh will together
  chgrp zabbix JSON_stat.sh
service restart: systemctl restart zabbix-agent

#nginx
#refrence https://github.com/RuslanMahotkin/zabbix
cat nginx.conf #add nginx monitor configuration
server {
                listen         80;
                server_name 127.0.0.1;
        	location /nginx_status {
                stub_status on;
                access_log off;
                allow 127.0.0.1;
                deny all;
                }
        }
}
install zabbix-sender plugin: zabbix-sender
grant nginx_stat.sh permission:
  chmod 750 nginx_stat.sh
  chgrp zabbix nginx_stat.sh
service restart: systemctl restart zabbix-agent

#apache
#refrence https://github.com/RuslanMahotkin/zabbix
[root@node1 conf.d]# cat /etc/httpd/conf.d/apache_status.conf 
ExtendedStatus		On
LoadModule status_module modules/mod_status.so
<VirtualHost 127.0.0.1:80>
ServerName	localhost
CustomLog	/dev/null combined
<Location /apache_status>
SetHandler		server-status
Order			allow,deny
Allow			from 127.0.0.1
</Location>
</VirtualHost>
service restart: systemctl restart httpd 
install zabbix-sender plugin: zabbix-sender
grant apache_stat.sh permission:
  chmod 750 apache_stat.sh
  chgrp zabbix apache_stat.sh
service restart: systemctl restart zabbix-agent
