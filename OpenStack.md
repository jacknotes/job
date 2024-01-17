#OpenStack
<pre>
什么是OpenStack？ 
OpenStack 是一个云操作系统，可控制整个数据中心中的大型计算、存储和网络资源池，所有这些资源都通过仪表板进行管理，该仪表板使管理员能够进行控制，同时允许用户通过 Web 界面配置资源。Openstack主要以Python语言开发。

三大资源：计算、网络、存储

#组件介绍
服务名称				项目名称						描述
Dashboard			Horizon						基于Openstack API接口使用django开发的Web管理
Compute				Nova						通过虚拟化技术提供计算资源池
Networking			Neutron						实现了虚拟机的网络资源管理
							Storage（存储）
Object Storage		Swift						对象存储，适用于“一次写入、多次读取”
Block Storage		Cinder						块存储，提供存储资源池
							Shared Service（共享服务）
Identity Service	Keystone					认证管理
Image Service		Glance						提供虚拟镜像的注册和存储管理
Telemetry			Ceilometer					提供监视和数据采集、计量服务
							Higher-level service（高层服务）
Orchestration		Heat						自动化部署的组件
Database Service	Trove						提供数据库应用服务



####基础服务安装(mysql,rabbitmq)---生产需要集群高可用
除了Horizon，OpenStack其它组件都需要连接数据库
除了Horizon和KeyStone，其它组件都需要连接RabbitMQ

#快速的部署两个节点的OpenStack集群
####openstack环境准备
node01-172.168.2.17
node02-172.168.2.18

#1. 安装基础环境包
1.1 安装epel仓库
[root@openstack-node01 ~]# sed -i '/mirrors.cloud.aliyuncs.com/d' /etc/yum.repos.d/centos7.repo
[root@openstack-node01 ~]# rpm -ivh http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
1.2 安装OpenStack仓库
[root@openstack-node01 ~]# yum install -y centos-release-openstack-queens
1.3 安装OpenStack客户端
[root@openstack-node01 ~]# yum install -y python-openstackclient
1.4 安装openstack SELinux管理包
[root@openstack-node01 ~]# yum install -y openstack-selinux

#2. 安装mysql----openstack的数据存储
[root@openstack-node01 ~]# yum install -y mariadb mariadb-server python2-PyMySQL
[root@openstack-node01 yum.repos.d]#  vim /etc/my.cnf.d/openstack.cnf
[mysqld]
bind-address = 172.168.2.17 #设置监听的IP地址
default-storage-engine = innodb  #设置默认的存储引擎
innodb_file_per_table = on#使用独享表空间
collation-server = utf8_general_ci #服务器的默认校对规则
character-set-server = utf8 #服务器安装时指定的默认字符集设定
max_connections = 4096 #设置MySQL的最大连接数，生产请根据实际情况设置。
---
[root@openstack-node01 yum.repos.d]# systemctl enable mariadb.service
[root@openstack-node01 yum.repos.d]# systemctl start mariadb.service
[root@openstack-node01 yum.repos.d]# mysql_secure_installation
Enter current password for root (enter for none):
Set root password? [Y/n] y
New password:			#123456
Re-enter new password:
Remove anonymous users? [Y/n] y
Disallow root login remotely? [Y/n] y
Remove test database and access to it? [Y/n] y
Reload privilege tables now? [Y/n] y
----创建数据库
[root@openstack-node01 my.cnf.d]# mysql -uroot -p
--Keystone数据库
MariaDB [(none)]> CREATE DATABASE keystone;
MariaDB [(none)]>  GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'keystone';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'keystone';
--Glance数据库
MariaDB [(none)]> CREATE DATABASE glance;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'glance';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'glance';
--Nova数据库
MariaDB [(none)]> CREATE DATABASE nova;
MariaDB [(none)]>  GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'nova';
MariaDB [(none)]>  CREATE DATABASE nova_api;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'nova';
MariaDB [(none)]> CREATE DATABASE nova_cell0;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'nova';
--Neutron数据库
MariaDB [(none)]> CREATE DATABASE neutron;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'neutron';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'neutron';
--Cinder数据库
MariaDB [(none)]> CREATE DATABASE cinder;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'cinder';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'cinder';
MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| cinder             |
| glance             |
| information_schema |
| keystone           |
| mysql              |
| neutron            |
| nova               |
| nova_api           |
| nova_cell0         |
| performance_schema |
+--------------------+


#3. 安装rabbitMQ----openstack通过消息队列通信
[root@openstack-node01 my.cnf.d]# yum install -y rabbitmq-server
[root@openstack-node01 my.cnf.d]# systemctl enable rabbitmq-server.service && systemctl start rabbitmq-server.service
[root@openstack-node01 my.cnf.d]# rabbitmqctl add_user openstack openstack
[root@openstack-node01 my.cnf.d]# rabbitmqctl set_permissions openstack ".*" ".*" ".*"
[root@openstack-node01 my.cnf.d]# rabbitmq-plugins list
[root@openstack-node01 my.cnf.d]# rabbitmq-plugins enable rabbitmq_management

4. 安装keystone
- 用户与认证：用户权限与用户行为跟踪
- 服务目录：提供一个服务目录，包括所有服务项与相关API的端点
- SOA相关知识

#KeyStone对象
--用户认证
User：用户
project：项目
Token：令牌
Role：角色
--服务目录
Service：服务
Endpoint：端点

5. 安装Glance镜像服务
Galnce-api：接受云系统镜像的创建、删除、读取请求
Glance-Registry：云系统的镜像注册服务

6. 安装Nova（分控制节点和数据节点）
API：负责接收和响应外部请求，支持OpenStack API，EC2 API
Cert：负责身份认证EC2
Scheduler：用于云主机调度
Conductor：计算节点访问数据的中间件
Consoleauth：用于控制台的授权验证
Novncproxy：VNC代理
6.1 安装控制节点nova
  - 控制节点通过libvirt控制数据节点的KVM
6.2 安装数据节点nova

7. 部署Neutron
- 网络：在实际的物理环境下，我们使用交换机或者集线器把多个计算机连接起来形成了网络。在Neutron的世界里，网络也是将多个不同的云主机连接起来。
- 子网：在实际的物理环境下，在一个网络中。我们可以将网络划分成多个逻辑子网。在Neutron的世界里，子网也是隶属于网络下的。
- 端口：是实际的物理环境下，每个子网或者每个网络，都有很多的商品，比如交换机端口来供计算机连接。在Neutron的世界里端口也是隶属于子网下，云主机的网上会对应到一个端口上。
- 路由器：在实际的网络环境下，不同网络或者不同逻辑子网之间如果需要进行通信，需要通过路由器进行路由。在Neutron的世界里路由也是这个作用。用来连接不同的网络或者子网。







</pre>
