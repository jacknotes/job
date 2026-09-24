# OpenStack

## 什么是 OpenStack？

OpenStack 是一个云操作系统，可控制整个数据中心中的大型计算、存储和网络资源池。所有这些资源都通过仪表板（Dashboard）进行管理，该仪表板使管理员能够进行控制，同时允许用户通过 Web 界面配置资源。OpenStack 主要以 Python 语言开发。

**三大资源**：计算、网络、存储。

## 组件介绍

| 服务名称 | 项目名称 | 描述 |
| --- | --- | --- |
| **Dashboard** | Horizon | 基于 OpenStack API 接口使用 Django 开发的 Web 管理 |
| **Compute** | Nova | 通过虚拟化技术提供计算资源池 |
| **Networking** | Neutron | 实现了虚拟机的网络资源管理 |
| **Storage（存储）** | | |
| Object Storage | Swift | 对象存储，适用于“一次写入、多次读取” |
| Block Storage | Cinder | 块存储，提供存储资源池 |
| **Shared Service（共享服务）** | | |
| Identity Service | Keystone | 认证管理 |
| Image Service | Glance | 提供虚拟镜像的注册和存储管理 |
| Telemetry | Ceilometer | 提供监视和数据采集、计量服务 |
| **Higher-level service（高层服务）** | | |
| Orchestration | Heat | 自动化部署的组件 |
| Database Service | Trove | 提供数据库应用服务 |

## 基础服务安装（mysql, rabbitmq）

> 生产需要集群高可用。

- 除了 Horizon，OpenStack 其它组件都需要连接数据库。
- 除了 Horizon 和 KeyStone，其它组件都需要连接 RabbitMQ。

---

# 快速部署两个节点的 OpenStack 集群

## openstack 环境准备

- node01：`172.168.2.17`
- node02：`172.168.2.18`

## 1. 安装基础环境包

### 1.1 安装 epel 仓库

```bash
[root@openstack-node01 ~]# sed -i '/mirrors.cloud.aliyuncs.com/d' /etc/yum.repos.d/centos7.repo
[root@openstack-node01 ~]# rpm -ivh http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
```

### 1.2 安装 OpenStack 仓库

```bash
[root@openstack-node01 ~]# yum install -y centos-release-openstack-queens
```

### 1.3 安装 OpenStack 客户端

```bash
[root@openstack-node01 ~]# yum install -y python-openstackclient
```

### 1.4 安装 openstack SELinux 管理包

```bash
[root@openstack-node01 ~]# yum install -y openstack-selinux
```

## 2. 安装 mysql —— OpenStack 的数据存储

```bash
[root@openstack-node01 ~]# yum install -y mariadb mariadb-server python2-PyMySQL
```

修改配置文件 `/etc/my.cnf.d/openstack.cnf`：

```ini
[mysqld]
bind-address = 172.168.2.17        # 设置监听的 IP 地址
default-storage-engine = innodb    # 设置默认的存储引擎
innodb_file_per_table = on         # 使用独享表空间
collation-server = utf8_general_ci # 服务器的默认校对规则
character-set-server = utf8        # 服务器安装时指定的默认字符集设定
max_connections = 4096             # 设置 MySQL 的最大连接数，生产请根据实际情况设置。
```

启动 MySQL 并进行安全配置：

```bash
[root@openstack-node01 yum.repos.d]# systemctl enable mariadb.service
[root@openstack-node01 yum.repos.d]# systemctl start mariadb.service
[root@openstack-node01 yum.repos.d]# mysql_secure_installation
```

安全配置交互过程（root 密码设为 `123456`）：

```text
Enter current password for root (enter for none):
Set root password? [Y/n] y
New password:            #123456
Re-enter new password:
Remove anonymous users? [Y/n] y
Disallow root login remotely? [Y/n] y
Remove test database and access to it? [Y/n] y
Reload privilege tables now? [Y/n] y
```

### 创建数据库

```bash
[root@openstack-node01 my.cnf.d]# mysql -uroot -p
```

Keystone 数据库：

```sql
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'keystone';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'keystone';
```

Glance 数据库：

```sql
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'glance';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'glance';
```

Nova 数据库：

```sql
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'nova';

CREATE DATABASE nova_api;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'nova';

CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'nova';
```

Neutron 数据库：

```sql
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'neutron';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'neutron';
```

Cinder 数据库：

```sql
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'cinder';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'cinder';
```

查看当前数据库：

```text
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
```

## 3. 安装 rabbitMQ —— OpenStack 通过消息队列通信

```bash
[root@openstack-node01 my.cnf.d]# yum install -y rabbitmq-server
[root@openstack-node01 my.cnf.d]# systemctl enable rabbitmq-server.service && systemctl start rabbitmq-server.service
[root@openstack-node01 my.cnf.d]# rabbitmqctl add_user openstack openstack
[root@openstack-node01 my.cnf.d]# rabbitmqctl set_permissions openstack ".*" ".*" ".*"
[root@openstack-node01 my.cnf.d]# rabbitmq-plugins list
[root@openstack-node01 my.cnf.d]# rabbitmq-plugins enable rabbitmq_management
```

## 4. 安装 keystone

- **用户与认证**：用户权限与用户行为跟踪
- **服务目录**：提供一个服务目录，包括所有服务项与相关 API 的端点
- SOA 相关知识

### KeyStone 对象

用户认证：

- **User**：用户
- **Project**：项目
- **Token**：令牌
- **Role**：角色

服务目录：

- **Service**：服务
- **Endpoint**：端点

## 5. 安装 Glance 镜像服务

- **Glance-api**：接受云系统镜像的创建、删除、读取请求
- **Glance-Registry**：云系统的镜像注册服务

## 6. 安装 Nova（分控制节点和数据节点）

- **API**：负责接收和响应外部请求，支持 OpenStack API、EC2 API
- **Cert**：负责身份认证 EC2
- **Scheduler**：用于云主机调度
- **Conductor**：计算节点访问数据的中间件
- **Consoleauth**：用于控制台的授权验证
- **Novncproxy**：VNC 代理

### 6.1 安装控制节点 nova

控制节点通过 libvirt 控制数据节点的 KVM。

### 6.2 安装数据节点 nova

## 7. 部署 Neutron

- **网络**：在实际的物理环境下，我们使用交换机或者集线器把多个计算机连接起来形成网络。在 Neutron 的世界里，网络也是将多个不同的云主机连接起来。
- **子网**：在实际的物理环境下，在一个网络中可以划分成多个逻辑子网。在 Neutron 的世界里，子网也是隶属于网络下的。
- **端口**：在实际的物理环境下，每个子网或者每个网络都有很多的端口，比如交换机端口来供计算机连接。在 Neutron 的世界里端口也是隶属于子网下，云主机的网卡会对应到一个端口上。
- **路由器**：在实际的网络环境下，不同网络或者不同逻辑子网之间如果需要进行通信，需要通过路由器进行路由。在 Neutron 的世界里路由也是这个作用，用来连接不同的网络或者子网。