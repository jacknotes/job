# Zabbix

---

## 第一章 监控基础知识

### 1.1 SecureCRT

```bash
yum install -y lrzsz   	# 安装 secretCRT 中的 rz 上传和 sz 下载
```

CentOS7 用 TAB 键补全命令软件：

```bash
yum install -y bash-completion
```

然后退出 bash 并重登 bash。

监控宝参考链接：https://wiki.jiankongbao.com/doku.php

### 1.2 监控概述

#### 1.2.1 监控对象

1. 监控对象的理解：CPU 是怎么工作的，原理。
2. 监控对象的指标：CPU 使用率、CPU 负载、CPU 个数、上下文切换。
3. 确定性能基准线：怎么样才算故障？CPU 负载多少算高。

#### 1.2.2 监控范围

1. 硬件监控：服务器的硬件故障。
2. 操作系统监控：CPU、内存、IO（硬盘和网络）、进程等。
3. 应用服务监控：Apache 是否正常，是否宕机等。
4. 业务监控：例如今天下了多少单，今天客户客单价多少等。

#### 1.2.3 硬件监控

远程控制卡：和服务器没有太大的关系，服务器有没有操作系统也跟它无关系（DELL 服务器：iDRAC，HP 服务器：ILO，IBM 服务器：IMM）。

远程控制卡的标准是 IPMI 标准，有了 IPMI 标准，Linux 就可以对 IPMI 标准进行监控，IPMI 依赖于 BMC 控制器（BMC 控制器放在远程控制卡上面），它们之间来沟通监控 CPU 温度、风扇转速、硬盘有没有报警。

在 Linux 下用 ipmitool 工具来监控硬件：

1. 硬件要支持（硬件要支持 ipmi 协议，并且不是虚拟机）。
2. 操作系统要支持（Linux 是支持 IPMI 的）。
3. 管理工具：ipmitool。

使用 IPMI 有两种方式：

1. 本地调用。
2. 远程调用（需要 IP 地址、用户名和密码）。

IPMI 配置网络有两种方式：

1. ipmi over lan：ipmi 数据包通过服务器网卡来走。
2. 独立网卡。

硬件监控两种方式：

1. 使用 IPMI。
2. 机房巡检。

##### 安装及使用 ipmi

1. 安装 ipmitool 软件：

   ```bash
   yum install OpenIPMI ipmitool -y
   ```

2. 启动服务：

   ```bash
   systemctl start ipmi
   ```

3. `ipmitool help` 获取 ipmi 的命令。

Linux 监控：路由器和交换机监控使用 SNMP（简单网络管理协议）监控，要开启 SNMP 协议。

client 端（安装 net-snmp，需要启动代理服务）`<----------->` server 端（安装 net-snmp-utils，不需要启动服务）。

* 安装 SNMP 协议软件：

  ```bash
  yum install -y net-snmp net-snmp-utils
  ```

* 更改 snmp 配置文件 `/etc/snmp/snmpd.conf`，只添加如下一行即可：

  ```
  rocommunity oldboy 192.168.1.201
  ```

  `rocommunity` 是只读社区名（在 zabbix 中用 `$(SNMP_COMMUNITY)` 表示社区名）；`oldboy` 是社区名值，IP 地址是要监控的主机，这里写的是本地主机。snmp 需要 snmp 代理端起服务，不需要服务端起服务，然后使用工具来连接代理就可以获取数据（相当于 ssh，通过 ssh 命令就可以连接过去）。

* 开启 snmp 服务：

  ```bash
  systemctl start snmpd
  ```

* snmp 默认监听的是 TCP 的 199 端口和 UDP 的 161 端口。
* MIB 对象的唯一标识符是 OID（有两种表达方式，数字和字符串方式，数字例子：`1.3.6.1.2.1.1.3.0`）。
* 获取系统启动时间：

  ```bash
  snmpget -v2c -c oldboy 192.168.1.201 1.3.6.1.2.1.1.3.0
  ```

  其中 `-v2c` 为 snmp 的 v2 版本协议，`-c oldboy` 为团体名，`192.168.1.201 1.3.6.1.2.1.1.3.0` 获取本机 IP 的开机时间，`1.3.6.1.2.1.1.3.0` 这个为 OID。

* 获取系统负载：

  ```bash
  snmpget -v2c -c oldboy 192.168.1.201 1.3.6.1.4.1.2021.10.1.3.1
  ```

  只能获取单独的 1 分钟负载。

* 以树结点来获取 1 分钟、5 分钟、15 分钟的负载：

  ```bash
  snmpwalk -v2c -c oldboy 192.168.1.201 1.3.6.1.4.1.2021.10.1.3
  ```

监控的流程：

1. 收集。
2. 存储。
3. 展示。
4. 报警。

snmp 有 5 种报文跟 snmp 代表来沟通，例如两种：

1. GetRequest PDU（例如：`snmpget -v2c -c oldboy 192.168.1.201 1.3.6.1.4.1.2021.10.1.3.1`）。
2. GetNextRequest PDU（例如：`snmpwalk -v2c -c oldboy 192.168.1.201 1.3.6.1.4.1.2021.10.1.3`）。

### 1.3 系统监控

系统监控包含：

1. CPU。
2. 内存。
3. IO（input/output，网络、磁盘）。

#### 1.3.1 CPU 监控

CPU 三个重要的概念：一个标准的 Linux 可以运行 50 到 5 万个进程；时间片；上下文切换。

1. 上下文切换：CPU 调度器实施对进程的切换过程，称为上下文切换。
2. 运行队列（负载）：运行队列的多少来判别负载的大小。
3. 使用率：user time（用户态）、system time（系统态）。

确定服务类型：

- IO 密集型：数据库。
- CPU 密集型：web、mail。

确定性能基准线：

- 运行队列：1 - 3 个线程为正常，1CPU 4 核来计算，线程应不超过 12 为正常。
- CPU 使用：65% - 70% 用户态利用率为正常；30% - 35% 内核态利用率为正常；0% - 5% 空闲为正常。
- 上下文切换：越少越好。

##### TOP 命令详解

CPU 栏：

- `us`：用户态百分比使用率。
- `sy`：内核态或系统态百分比使用率。
- `ni`：nice 值之间切换的百分比使用率。
- `id`：CPU 空闲百分比使用率。
- `wa`：IO 队列等待百分比使用率。
- `hi`：CPU 硬中断百分比使用率。
- `si`：CPU 软中断百分比使用率。
- `st`：虚拟 CPU 等待实际 CPU 的百分比使用率。

内存栏：

- Mem total：全部物理内存。
  - free：空闲内存。
  - used：使用内存。
  - buff/cache：缓冲缓存内存，Linux 尽量把不用的内存分存给 buff/cache。
- Swap 内存和物理内存一样。

top 动态窗口菜单：

- `PID`：进程 ID。
- `user`：进程所有者。
- `PR`：优先级。
- `NI`：nice 值。
- `VIRT`：进程占用的虚拟内存。
- `RES`：进程占用的物理内存。
- `SHR`：共享内存。
- `S`：进程状态。
- `%CPU`：cpu 使用率。
- `%MEM`：内存使用率。
- `TIME+`：进程启动后的运行时间。
- `COMMAND`：命令。

快捷键：

- 以内存排序：按大写的 M 进行排序。
- 以 CPU 排序：按大写的 P 进行排序。

##### sysstat 工具包

mpstat 工具：监控。vmstat 工具：监控 cpu 状态。

- `r`：表示运行队列（就是说多少个进程真的分配到 CPU）。我测试的服务器目前 CPU 比较空闲，没什么程序在跑，当这个值超过了 CPU 数目，就会出现 CPU 瓶颈了。这个也和 top 的负载有关系，一般负载超过了 3 就比较高，超过了 5 就高，超过了 10 就不正常了，服务器的状态很危险。top 的负载类似每秒的运行队列。如果运行队列过大，表示你的 CPU 很繁忙，一般会造成 CPU 使用率很高。
- `b`：表示阻塞的进程。
- `swpd`：虚拟内存已使用的大小，如果大于 0，表示你的机器物理内存不足了，如果不是程序内存泄露的原因，那么你该升级内存了或者把耗内存的任务迁移到其他机器。
- `free`：空闲的物理内存的大小。
- `buff`：Linux/Unix 系统是用来存储目录里面有什么内容、权限等的缓存。
- `cache`：直接用来记忆我们打开的文件，给文件做缓冲（这里是 Linux/Unix 的聪明之处，把空闲的物理内存的一部分拿来做文件和目录的缓存，是为了提高程序执行的性能，当程序使用内存时，buffer/cached 会很快地被使用）。
- `si`：每秒从磁盘读入虚拟内存的大小，如果这个值大于 0，表示物理内存不够用或者内存泄露了，要查找耗内存进程解决掉。
- `so`：每秒虚拟内存写入磁盘的大小，如果这个值大于 0，同上。
- `bi`：块设备每秒接收的块数量，这里的块设备是指系统上所有的磁盘和其他块设备，默认块大小是 1024byte。
- `bo`：块设备每秒发送的块数量，例如我们读取文件，bo 就要大于 0。bi 和 bo 一般都要接近 0，不然就是 IO 过于频繁，需要调整。
- `in`：每秒 CPU 的中断次数，包括时间中断。
- `cs`：每秒上下文切换次数。例如我们调用系统函数，就要进行上下文切换，线程的切换，也要进程上下文切换，这个值要越小越好，太大了要考虑调低线程或者进程的数目。例如在 apache 和 nginx 这种 web 服务器中，我们一般做性能测试时会进行几千并发甚至几万并发的测试，选择 web 服务器的进程可以由进程或者线程的峰值一直下调，压测，直到 cs 到一个比较小的值，这个进程和线程数就是比较合适的值了。系统调用也是，每次调用系统函数，我们的代码就会进入内核空间，导致上下文切换，这个是很耗资源，也要尽量避免频繁调用系统函数。上下文切换次数过多表示你的 CPU 大部分浪费在上下文切换，导致 CPU 干正经事的时间少了，CPU 没有充分利用，是不可取的。
- `us`：用户 CPU 时间，我曾经在一个做加密解密很频繁的服务器上，可以看到 us 接近 100，r 运行队列达到 80（机器在做压力测试，性能表现不佳）。
- `sy`：系统 CPU 时间，如果太高，表示系统调用时间长，例如是 IO 操作频繁。
- `id`：空闲 CPU 时间，一般来说，id + us + sy = 100，一般我认为 id 是空闲 CPU 使用率，us 是用户 CPU 使用率，sy 是系统 CPU 使用率。
- `wa`：等待 IO CPU 时间。
- `st`：虚拟 CPU 等待实际 CPU 的时间。

CPU 详细的内容：

- `%nice`：nice 值改变时对 CPU 占用的百分比。

#### 1.3.2 内存监控

1. linux 是不知道物理内存和交换分区内存的。
2. 内存是分成页的，硬盘是分成块的。
3. 寻址；空间（连续的内存空间合并）。
4. 共享内存是给进程与进程之间使用的，各使一点共享内存。
5. vmstat 下：`si` 每秒从磁盘读入虚拟内存的大小，`so` 每秒虚拟内存写入磁盘的大小，`bi` 块设备每秒接收的块数量，`bo` 块设备每秒发送的块数量。
6. 交换分区使用得越多是不行的。内存使用率在 80% 会报警。

#### 1.3.3 硬盘监控（块）

1. IOPS：IO Per Second，每秒 IO 请求次数。
2. IO 分为顺序 IO 和随机 IO，顺序 IO 最快，最快有时候会接近内存的速度。
3. `yum install iotop -y` 安装 iotop 工具。
4. 监控硬盘用得最多的是 iotop 和 iostat。

#### 1.3.4 网络监控

```bash
yum install -y iftop   # iftop 工具
iftop -n               # 查看网络流向
```

阿里测、奇云测、站长工具可测网站访问速度和 dns 解析情况等。

TCP 监控。

IBM 的 nmon 工具可生成性能报表：在 linux 下执行 nmon 二进制文件生成 nmon 报告文件，命令例如：

```bash
./nmon16e_x86_rhel72 -s 10 -c 10 -f -m /tmp/
```

则会在 /tmp 下生成 nmon 报告文件，然后利用 `nmon analyser v55.xlsm` 这个文件来读取 nmon 文件生成 excel 形式的报告文件。

#### 1.3.5 应用监控

##### 例如：nginx（源码安装，尽量下载 nginx 的最新稳定版本）

1. 安装 nginx 的依赖包：

   ```bash
   yum install -y gcc glibc gcc-c++ pcre-devel openssl-devel
   ```

2. 建立普通用户用于运行 nginx：

   ```bash
   useradd -s /sbin/nologin -M www
   ```

3. 生成 makefile 文件（收集系统环境信息，用于编译用），设置程序安装路径、程序启动的用户和组、开启两个相关模块：

   ```bash
   ./configure --prefix=/usr/local/nginx-1.14.0 --user=www --group=www \
     --with-http_ssl_module --with-http_stub_status_module
   ```

4. `make && make install`：make 是编译工作，make install 把生成的文件复制到指定的目录下（生成的文件可以直接复制到同系统环境下运行）。
5. 生成软链接安装目录：

   ```bash
   ln -s /usr/local/nginx-1.14.0/ /usr/local/nginx
   ```

6. 启动测试：

   ```bash
   /usr/local/nginx/sbin/nginx -t
   ```

7. 启动服务：

   ```bash
   /usr/local/nginx/sbin/nginx
   ```

8. 修改 nginx 配置文件，只对 192.168.1.0/24 网段开启监控：

   ```bash
   cd /usr/local/nginx/conf && vim nginx.conf
   ```

   添加如下：

   ```nginx
   location /nginx-status {
       stub_status on;
       access_log off;
       allow 192.168.1.0/24;
       deny all;
   }
   ```

9. 启动 nginx 服务：

   ```bash
   /usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
   ```

10. 重启 nginx 服务：

    ```bash
    /usr/local/nginx/sbin/nginx -s reload
    ```

11. 停止 nginx 服务：

    ```bash
    ps -ef | grep nginx
    kill -9 pid
    ```

---

## 第二章 安装 Zabbix（CentOS 7.5）

1. 安装 zabbix yum 源：

   ```bash
   # 安装 centos7 源
   rpm -ivh https://mirrors.aliyun.com/zabbix/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm

   # 安装 centos8 源
   yum install -y https://mirrors.aliyun.com/zabbix/zabbix/4.4/rhel/8/x86_64/zabbix-release-4.4-1.el8.noarch.rpm
   ```

2. 安装相关软件：

   ```bash
   yum install zabbix-web zabbix-web-mysql zabbix-server-mysql mariadb-server mariadb zabbix-agent -y
   ```

3. 修改 PHP 时区配置：

   ```bash
   sed -i 's@# php_value date.timezone Europe/Riga@php_value date.timezone Asia/Shanghai@g' /etc/httpd/conf.d/zabbix.conf
   ```

4. 启动 mariadb 数据库：

   ```bash
   systemctl start mariadb
   ```

5. 创建 Zabbix 所用的数据库及用户：

   ```sql
   create database zabbix character set utf8 collate utf8_bin;
   grant all on zabbix.* to zabbix@'localhost' identified by '123456';
   exit
   ```

   ```bash
   cd /usr/share/doc/zabbix-server-mysql-3.0.22/
   zcat create.sql.gz | mysql -uzabbix -p123456 zabbix
   ```

6. 修改 zabbix 配置：

   ```bash
   vim /etc/zabbix/zabbix_server.conf
   ```

   ```ini
   DBHost=localhost	# 数据库所在主机
   DBName=zabbix		# 数据库名
   DBUser=zabbix		# 数据库用户
   DBPassword=123456	# 数据库密码
   ```

7. 启动 Zabbix 及 http：

   ```bash
   systemctl start zabbix-server  # 如果启动失败，使用 yum update 更新系统内核
   systemctl start httpd
   ```

8. WEB 上配置 zabbix：

   1. 输入 web 上配置 zabbix-server 的地址 `http://zabbix-IP/zabbix/setup.php`，进入配置。
   2. 填写数据库地址、端口、用户、密码，及 zabbix-server 在 web 上右上角展示的名称，直至配置完成。

9. 输入 zabbix-server 管理地址进行管理配置：`http://zabbix-IP/zabbix`。

10. zabbix 默认用户名为 `Admin`，密码为 `zabbix`，登进去后第一步更改密码。

11. 配置 agent 端：

    ```bash
    vim /etc/zabbix/zabbix_agentd.conf
    ```

    ```ini
    Server=127.0.0.1	        # 设置被动端的 zabbix-server 地址，等待客户端汇报
    ServerActive=127.0.0.1	# 设置主动端的 zabbix-server 地址，服务端主动抓取
    ```

    ```bash
    systemctl start zabbix-agent.service  # 启动 zabbix-agent
    ```

12. `netstat -tunlp` 查看 zabbix-server、zabbix-agent、httpd 服务是否正常启动。

### 2.1 添加 Zabbix 自定义监控项

#### 拿 nginx 来监控

1. `vim /etc/zabbix/zabbix_agentd.conf` 可查看到 `include=/etc/zabbix/zabbix_agentd.d`，此目录下所有配置将备引用，所以在 `/etc/zabbix/zabbix_agentd.d` 目录下新建一个 nginx 应用监控的配置文件，用来当作 nginx 的监控项。

2. 编辑 `/etc/zabbix/zabbix_agentd.d/nginx.conf` 文件：

   ```bash
   vim /etc/zabbix/zabbix_agentd.d/nginx.conf
   UserParameter=nginx.active,/usr/bin/curl -s http://192.168.1.233/nginx_status |grep 'Active' | awk '{print $NF}'
   ```

3. 重启 zabbix-agent：

   ```bash
   systemctl restart zabbix-agent
   ```

4. 安装 zabbix-get（必须在 server 端执行）：

   ```bash
   yum install zabbix-get -y
   ```

5. `vim /etc/zabbix/zabbix-agentd.conf`，把 `Server=127.0.0.1` 设置成 `192.168.1.201`，这样下一步才不会报错，server 地址为 zabbix-server 地址。

6. 在 zabbix-server 上测试获取值是否设置成功（`-s` 指的是 zabbix-agent 的地址）：

   ```bash
   zabbix_get -s 192.168.1.201 -p 10050 -k "nginx.active"
   ```

> 注：自定义监控项如果是通用的话，需要复制到所有 agent 才能使所有 agent 生效。如果不通用，则自行放置到需要的 agent 上即可。

7. 在 zabbix-web 界面上创建 item 监控项。

   1. 数据更新间隔（秒） 60
   2. 自定义时间间隔 50 1-7,00:00-24:00
   3. 历史数据保留时长（单位天） 90
   4. 趋势数据存储周期（单位天） 365
   5. 新的应用集 nginx（对 item 做分组）
   6. 描述 Nginx 活动连接数
   7. 键值 nginx.active
   8. 类型 zabbix agent
   9. 信息类型和数据类型

8. 创建图形：选择主机，进入图形菜单，新建图形，图形类别，选中刚刚创建的 item 监控项。

- 网络监控：Smokeping。
- 流量分析系统：Piwik。
- 注：解决 zabbix 字体无法显示中文问题，找到一个中文字体替换 zabbix 默认字体，路径 `/usr/share/zabbix/fonts`，或 `/usr/share/zabbix/assets/fonts`：

  ```bash
  mv graphfont.ttf graphfont.ttf.bak
  mv simhei.ttf graphfont.ttf
  ```

### 2.2 Zabbix 通知设置

通知（配置 - 动作下设置）：

1. 通知什么（action）。
2. 什么时候通知（conditions）。
3. 怎么通知（operation）。
4. 通过什么途径发送。
5. 发送给谁。
6. 通知升级（多步骤通知给不同人）。
7. 通知给谁。

### 2.3 实战第一步

1. 新建用户群组并分配权限，权限只能分配给群组。
2. 创建用户并选择用户角色（有普通用户、管理员、超级管理员）。
3. 报警媒介。
4. action（动作）。

### 2.4 Zabbix 生产案例实战

1. 项目规划：主机分组：交换机、Nginx、Tomcat、Mysql。

监控对象识别：

1. 使用 SNMP 监控交换机。
2. 使用 IPMI 监控服务器硬件。
3. 使用 Agent 监控服务器。
4. 使用 JMX 监控 java。
5. 监控 mysql 状态。
6. 监控 Web 状态。
7. 监控 Nginx 状态。

#### SNMP 监控交换机等 snmp 设备

linux snmp oid（百度搜索）。

- MIB：管理信息库，所有可被查询和修改的参数（`1.3.6.1.1.2.5.3` 这个是 MIB）。
- OID：对象标识符（`SNMPv2-MIB::sysDescr.0` 这个是对象标识符）。
- snmp-get、snmp-set。
- snmptranslate：可以将 MIB 和 OID 两种表现形式进行转换。

1. 交换机上开启 snmp：

   ```
   config terminal 
   snmp-server community route ro
   snmp-server enable traps entity  # 开启 snmp 实体陷阱
   end
   ```

2. 在 zabbix-web 上添加监控，设置 snmp Interfaces：

   ```bash
   yum -y install net-snmp-utils net-snmp  # 安装 snmp
   snmpwalk -v 2c -c route 192.168.1.1 SNMPv2-MIB::sysDescr.0  # 测试跟开启 snmp 设备的连通性
   ```

3. 关联监控模板 `Templete SNMP DEVICE`，监控 SNMP 思科设备。

#### IPMI

建议使用自定义 item 将值传给 zabbix，来实现 ipmi 监控。

#### JMX（使用 zabbix-java-gateway 代理）监控 java 程序

1. 安装 JMX 和 java JDK（装哪都可以）：

   ```bash
   yum install -y zabbix-java-gateway java-1.8.0
   ```

2. 默认配置即可：

   ```bash
   vim /etc/zabbix/zabbix_java_gateway.conf
   ```

   ```ini
   LISTEN_IP="0.0.0.0"
   LISTEN_PORT=10052
   PID_FILE="/var/run/zabbix/zabbix_java.pid"
   START_POLLERS=5
   TIMEOUT=3
   ```

3. 开启 java 代理：

   ```bash
   systemctl start zabbix-java-gateway.service
   ```

4. 检查 10052 端口和进程是否起来：

   ```bash
   netstat -tunlp
   ```

5. 用于配置 zabbix-java-gateway 代理跟 zabbix server 联系：

   ```bash
   vim /etc/zabbix/zabbix_server.conf
   ```

   ```ini
   JavaGateway=192.168.1.233   # 指定 Java 网关地址
   JavaGatewayPort=10052	    # 指定 java 网关端口
   StartJavaPollers=5	        # 设置启动多少个服务来轮循 java 代理，必须设置
   ```

6. 重启 zabbix server。

7. 安装 java 应用测试，例如安装 Tomcat（tomcat 默认端口为 8080）：

   ```bash
   wget http://mirrors.shu.edu.cn/apache/tomcat/tomcat-8/v8.5.34/bin/apache-tomcat-8.5.34.tar.gz
   wget http://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-8/v8.5.42/bin/apache-tomcat-8.5.42.tar.gz
   tar -zxvf apache-tomcat-8.5.34.tar.gz 
   mv apache-tomcat-8.5.34 /usr/local/
   ln -s apache-tomcat-8.5.34/ /usr/local/tomcat
   /usr/local/tomcat/bin/start.sh
   ```

   JMX 有三种类型：1. 无密码认证；2. 用户名密码认证；3. ssl 加密认证。

   开启 JMX 远程监控（查看 tomcat 官方文档），在 `/usr/local/tomcat/bin/catalina.sh` 最前面添加如下行（从 tomcat 官网文档中搜索 JMX 找到的）：

   ```bash
   vim /usr/local/tomcat/bin/catalina.sh
   ```

   ```ini
   CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote
   -Dcom.sun.management.jmxremote.port=8888  # 本机打开 jmx 协议的端口
   -Dcom.sun.management.jmxremote.ssl=false
   -Dcom.sun.management.jmxremote.authenticate=false
   -Djava.rmi.server.hostname=192.168.1.233"  # 本机的 ip
   ```

   重启 tomcat 并检查 8888 和 8080 端口是否开启：`netstat -tunlp`。然后使用 windows 下装的 java JDK 安装目录中 `/bin/jconsole` 进行连接测试看有没有问题，选择远程进程，输入开启 jmx 的 IP 加端口（例 `192.168.1.233:8888`），能连接看到信息则表示开启成功。最后在 zabbix-web 上加入 tomcat 的 jmx 类型监控即可，只需要输入 JMX 主机和端口，并链接模板应用。

#### 监控 Nginx

1. 开启 Nginx 监控。
2. 编写脚本来采集数据。
3. 设置用户自定义参数。
4. 重启 zabbix-agent。
5. 添加 item。
6. 创建图形。
7. 创建触发器。
8. 创建模板（包含 item、图形、触发器、screen）。

##### 监控 Nginx 操作

制作脚本放到 nginx 服务器中：

```bash
#### zabbix_linux_plugin.sh ####
#!/bin/bash
###########################################
# $Name:	Zabbix_linux_plugins.sh
# $Version: v1.0
# $Function: zabbix plugins
# $Author: jack Li
# $organization: www.mi.com
# $Create Date: 2018-10-13
# $Description: Monitor  Linux Service Status
###########################################
tcp_status_fun(){
	TCP_STAT=$1
	# 当 TCP 多的时候 ss 比 netstat 快
	# netstat -n |  awk '/^tcp/ {++state[$NF]} END {for(key in state) print key,state[key]}' > /tmp/netstat.tmp
	ss -ant | awk 'NR>1 {++s[$1]} END {for(k in s) print k,s[k]}' > /tmp/netstat.tmp
	TCP_STAT_VALUE=$(grep "$TCP_STAT" /tmp/netstat.tmp | cut -d ' ' -f2)
	if [ -z $TCP_STAT_VALUE ];then
		TCP_STAT_VALUE=0
	fi
	echo $TCP_STAT_VALUE
}
nginx_status_fun(){
	NGINX_PORT=$1
	NGINX_COMMAND=$2
	nginx_active(){
		/usr/bin/curl "http://127.0.0.1:"$NGINX_PORT"/nginx_status/" 2> /dev/null | grep 'Active' | awk '{print $NF}'
	}
	nginx_reading(){
		/usr/bin/curl "http://127.0.0.1:"$NGINX_PORT"/nginx_status/" 2> /dev/null | grep 'Reading' | awk '{print $2}'
	}
	nginx_writing(){
		/usr/bin/curl "http://127.0.0.1:"$NGINX_PORT"/nginx_status/" 2> /dev/null | grep 'Writing' | awk '{print $4}'
	}
	nginx_waiting(){
		/usr/bin/curl "http://127.0.0.1:"$NGINX_PORT"/nginx_status/" 2> /dev/null | grep 'Waiting' | awk '{print $6}'
	}
	nginx_accepts(){
		/usr/bin/curl "http://127.0.0.1:"$NGINX_PORT"/nginx_status/" 2> /dev/null | awk NR==3  | awk '{print $1}'
	}
	nginx_handled(){
		/usr/bin/curl "http://127.0.0.1:"$NGINX_PORT"/nginx_status/" 2> /dev/null | awk NR==3  | awk '{print $2}'
	}
	nginx_requests(){
		/usr/bin/curl "http://127.0.0.1:"$NGINX_PORT"/nginx_status/" 2> /dev/null | awk NR==3  | awk '{print $3}'
	}
	case $NGINX_COMMAND in
		active)
			nginx_active;
			;;
		reading)
			nginx_reading;
			;;
		writing)
			nginx_writing;
			;;
		waiting)
			nginx_waiting;
			;;
		accepts)
			nginx_accepts;
			;;
		handled)
			nginx_handled;
			;;
		requests)
			nginx_requests;
			;;
	esac
}
memcached_status_fun(){
	M_PORT=$1
	M_COMMAND=$2
	echo -e "stats\nquit" | nc 127.0.0.1 "$M_PORT" | grep "STAT $M_COMMAND" | awk '{print $3}'
}
redis_status_fun(){
	R_PORT=$1
	R_COMMAND=2
	(echo -en "INFO \r\n";sleep 1;) | nc 127.0.0.1 "$R_PORT" > /tmp/redis_"$R_PORT" .tmp
	REDIS_STAT_VALUE=$(grep "" $R_COMMAND":" /tmp/redis_"$R_PORT".tmp | cut -d ':' -f2)
	echo $REDIS_STAT_VALUE
}
main(){
        case $1 in
                tcp_status)
                        tcp_status_fun $2;
                        ;;
                nginx_status)
                        nginx_status_fun $2 $3;
                        ;;
                memcached_status)
                        memecached_status_fun $2 $3;
                        ;;
                redis_status)
                        redis_status_fun $2 $3
                        ;;
	*)
		echo $"Usage:$0 {tcp_status key | memcached_status key | redis_status key | nginx_status key}"
	esac
}
main $1 $2 $3
```

操作步骤：

1. 修改 `/etc/zabbix/zabbix_agentd.conf`，包含 `Include=/etc/zabbix/zabbix_agentd.d/*.conf`。
2. 把脚本移动到 `/etc/zabbix/zabbix_agentd.d`。
3. 把 nginx 中的 `nginx-status` 改成 `nginx_status`，并设置 IP 地址为只允许本机使用，以使脚本兼容：

   ```nginx
   location /nginx_status {
       stub_status on;
       access_log off;
       allow 127.0.0.1;
       deny all;
   }
   ```

4. 测试脚本。

5. 配置自定义监控项：

   ```bash
   vim /etc/zabbix/zabbix_agentd.d/linux.conf
   UserParameter=linux_status[*],/etc/zabbix/zabbix_agentd.d/zabbix_linux_plugin.sh "$1" "$2" "$3"
   ```

6. 重启 zabbix-agent：

   ```bash
   systemctl restart zabbix-agent
   ```

7. 用 get 测试一下：

   ```bash
   zabbix_get -s 192.168.1.201 -k linux_status[nginx_status,8080,active]
   ```

8. 创建模板（机器太多无法创建很多个 item，所以创建模板，最佳也是创建模板，后期可以导出直接使用）。
9. 链接模板到主机。

创建触发器：选中主机，并选中触发器，新建触发器，选择一个处理函数（例如 `last()`、`max()` 等），就会触发触发器做动作。动作就是我们定义的信息、条件、和操作（发送给谁，哪种方式，必须先添加媒体介质）。

- 名称：Nginx Active > 1
- 表达式：`{lnmp.jack.com:nginx.active.last()}>1`（可以选择添加）
- 严重性分类：警告（可自行分类选择）
- 已启用：勾选

#### 媒体介质添加（用脚本添加短信通知）

1. `vim /etc/zabbix/zabbix_server.conf` 可查看到警告脚本路径 `AlertScriptsPath=/usr/lib/zabbix/alertscripts`。
2. 编写短信脚本在警告脚本路径下：

   ```bash
   cat sms.sh 
   #!/bin/bash
   ALERT_TO=$1
   ALERT_TITLE=$2
   ALERT_BODY=$3
   echo $ALERT_TO >> /tmp/sms.log
   echo $ALERT_TITLE >> /tmp/sms.log
   echo $ALERT_BODY >> /tmp/sms.log
   ```

   添加媒介为脚本类型，指定名称脚本 `sms.sh`（自己会去 `AlertScriptsPath=/usr/lib/zabbix/alertscripts` 查找），如有需要添加脚本参数：`{ALERT.SENDTO}`（此 zabbix 函数表示发送给哪个用户，在用户属性的报警媒介中设置手机号）、`{ALERT.SUBJECT}`（此 zabbix 函数表示动作里面的主题）、`{ALERT.MESSAGE}`（此 zabbix 函数表示动作的信息）。

3. 在要监控的主机上添加 item 项和图形 - 然后设置触发器 - 设置动作（actions），并设置动作上的发信内容和发信方式及对象 - 最后在对象用户上设置接收媒体的类型。

用脚本添加微信通知：

1. 企业注册企业号，拥有唯一的 key。
2. 在 linux 中设置脚本，使用 curl 连接微信 API 发送微信报警。

移值监控项：如果要把自定义 item 监控项移值到其他 agent 服务器上，只需要复制 `/etc/zabbix/zabbix_agentd.d/` 下的 `zabbix_linux_plugin.sh` 和 `linux.conf`，还有 `/etc/zabbix/zabbix_agentd.conf` 即可，然后可以在 zabbix-server 上用命令 `zabbix_get` 测试是否成功连接。

#### 使用 Percona 监控插件监控 mysql（自己实操失败，查看官方文档）

1. 安装 percona 监控插件源：

   ```bash
   yum install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm
   ```

2. 安装 percona 监控插件及所有的组件：

   ```bash
   yum install -y percona-zabbix-templates php php-mysql
   ```

3. 导入模板 `/var/lib/zabbix/percona/templates/zabbix_agent_template_percona_mysql_server_ht_2.0.9-sver1.1.8.xml` 到 zabbix server web 上的模板库上（此模板导入会错误，需从网上自己找 zabbix3.0 的模板）。
4. 复制配置文件 `/var/lib/zabbix/percona/templates/userparameter_percona_mysql.conf` 到 `/etc/zabbix/zabbix_agentd.d/` 下。
5. 在 `/var/lib/zabbix/percona/scripts/` 目录下新建 `ss_get_mysql_stats.php.cnf` 文件，并输入值：

   ```php
   <?php
   $mysql_user = 'root';
   $mysql_pass = 's3cret';
   ```

6. 测试脚本：

   ```bash
   /var/lib/zabbix/percona/scripts/get_mysql_stats_wrapper.sh gg
   ```

   结果 `405647` 表示有值为成功；若是没有值，表示连接不上 mysql.sock，报错：`ERROR: Can't connect to local MySQL server through socket '/var/lib/mysql/mysql.sock' (2)`。

7. 关联模板到主机中。

注意事项：当 zabbix 中监控没有图数据时，大部分是 /tmp 下的文件 zabbix 没有写入的文件，可以在 zabbix server 上使用 `zabbix_get` 工具测试一下。

再次补充：使用 Percona 监控插件监控 mysql，需要查看官方文档：

```bash
yum install https://www.percona.com/downloads/percona-monitoring-plugins/1.1.6/percona-zabbix-templates-1.1.6-1.noarch.rpm
yum install -y php php-mysql
sz zabbix_agent_template_percona_mysql_server_ht_2.0.9-sver1.1.6.xml   # 导出模板到 windows
```

导入模板 `/var/lib/zabbix/percona/templates/zabbix_agent_template_percona_mysql_server_ht_2.0.9-sver1.1.6.xml` 到 zabbix server web 上的模板库上（此模板导入会错误，格式错误，需要从 2.4 导出来使用，需从网上自己找 zabbix3.0 的模板）。链接：https://pan.baidu.com/s/1j4-zgBgTTaqh-gGNAaeIlw 提取码：w4az ；链接：https://pan.baidu.com/s/17nEADrpEyPVXWRi_mikCLA 提取码：dfio

```bash
cp /var/lib/zabbix/percona/templates/userparameter_percona_mysql.conf /etc/zabbix/zabbix_agentd.d/
```

在 `/var/lib/zabbix/percona/scripts/` 目录下新建 `ss_get_mysql_stats.php.cnf` 文件，并输入值：

```bash
cat ss_get_mysql_stats.php.cnf 
<?php
$mysql_user = 'root';
$mysql_pass = 'root123';
ll /tmp/
```

```text
total 4
-rw-rw-r-- 1 zabbix zabbix 1245 Jul  1 16:45 localhost-mysql_cacti_stats.txt  # 确定此文件为 zabbix 权限
```

#### WEB 监控（不依赖 zabbix agent，zabbix server 自带的）

1. 在 zabbix web 中，点击目标主机旁边的 web 进行设置监控。
2. 点击右上角新建方案。
3. 设置方案名称、更新间隔时间、要监听的网址、最大超时时间、需要返回的状态码 200 等。
4. 设置触发器，设置表达式为 web 监控自动添加的 web 类型的 item 项：

   ```
   {smb:web.test.fail[smb-web].last()}<>0
   ```

   设置失败的步骤是否不等于 0，不等于 0 表示有失败的步骤，会触发报警（Failed step of scenario "smb-web"）。

   ```
   {smb:web.test.rspcode[smb-web,smb-web].last()}<>200
   ```

   设置响应的代码是否不等于 200，不等于 200 表示服务异常，会触发报警（Response code for step "smb-web" of scenario "smb-web"）。

5. 如果需要设置认证，在步骤选项上添加 post 的用户名及密码。

#### Action 信息模板

- 默认标题：

  ```
  Problem: {EVENT.NAME}
  ```

- 消息内容：

  ```
  状态：{TRIGGER.STATUS}
  ```

- 恢复消息和消息内容：

  ```
  主机名：{HOST.NAME1}
  监控项：{ITEM.KEY1}
  监控项值：{ITEM.VALUE1}
  FROM:{TRIGGER.NAME}
  ```

### 2.5 主动模式与被动模式

针对 zabbix agent 来说，有两种模式：

1. 被动模式（默认模式 zabbix-agent）。
2. 主动模式（zabbix-agent(active)）。

什么时候切换为主动模式？

1. 当队列（Queue）的 item 1 分钟、5 分钟、10 分钟有延迟时。
2. 当 zabbix server 监控 300+ 服务器时（针对普通服务器配置）。
3. 主动模式可以不受防火墙的影响。

怎么设置为主动模式？（实操失败）

1. 在 zabbix agent 机器中，设置配置文件：

   ```bash
   vim /etc/zabbix/zabbix_agentd.conf 
   ```

   ```ini
   # Server=192.168.1.201    # 注释被动模式
   StartAgents=0            # 关闭 agent 监听端口
   ServerActive=192.168.1.201  # 设置主动模式 zabbix server 地址
   Hostname=linux-node1	    # 设置本地 agent 主机名，唯一标识
   ```

2. 重启 zabbix-agent：

   ```bash
   systemctl restart zabbix-agent
   ```

3. 在 zabbix server 上添加 agent 主机，并关联主动模式（zabbix agent (active)）的模板即可。因为默认无主动模式的模板（从模板中的 item 中可以看出 item 的类型为 zabbix-agent），所以只能用全部克隆功能来克隆一个模板，并（mass update）批量更新来更改（type）类型为 zabbix agent (active) 模式。

4. 由于是主动模式，所以在主机添加完成后，主机界面 ZBX 图标是不亮的（跟 item 的 key `agent.ping` 有关），而如果是被动模式则是开的。

### 2.6 zabbix proxy

zabbix proxy 没有触发器，不发报警，不能执行远程命令，只做收集，需要单独数据库。zabbix proxy 不仅能解决主机多的问题还能解决跨机房的问题。zabbix proxy 不能跟 zabbix server 装在一台机器上，而且 zabbix proxy 必须是单独的数据库。

安装 zabbix proxy：

```bash
# 先要切换成阿里云的源
yum install -y zabbix-proxy zabbix-proxy-mysql mariadb-server
systemctl start mariadb
```

创建数据库：

```sql
create database zabbix_proxy character set utf8;
grant all on zabbix_proxy.* to zabbix_proxy@localhost identified by 'zabbix_proxy';
```

```bash
cd /usr/share/doc/zabbix-proxy-mysql-3.0.3/
zcat schema.sql.gz | mysql -uzabbix_proxy -p zabbix_proxy
```

修改代理配置：

```bash
vim /etx/zabbix/zabbix-proxy.conf
```

```ini
Server=192.168.1.201	# agent server 的地址
Hostname=192.168.1.234  # agent proxy 的地址
DBHost=localhost        
DBName-zabbix_proxy
DBUser=zabbix_proxy
DBPassword=zabbix_proxy
```

```bash
systemctl start zabbix-proxy  # zabbix-proxy 端口是 10051，和 zabbix server 端口一样，是简化版的 zabbix server
```

zabbix-proxy 和 zabbix-agent 一样也可以设置主动和被动模式。

附 Server(1)、Proxy(2)、Agent(3) 的配置信息：

**1. Server 配置**

```bash
grep '^[a-Z]' /etc/zabbix/zabbix_server.conf 
```

```ini
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=0
PidFile=/var/run/zabbix/zabbix_server.pid
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=123456
JavaGateway=192.168.1.233
StartJavaPollers=5
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
AlertScriptsPath=/usr/lib/zabbix/alertscripts
ExternalScripts=/usr/lib/zabbix/externalscripts
LogSlowQueries=3000
```

**2. Proxy 配置**

```bash
grep '^[a-Z]' /etc/zabbix/zabbix_proxy.conf 
```

```ini
Server=192.168.1.201
ServerPort=10051
Hostname=192.168.1.234
LogFile=/var/log/zabbix/zabbix_proxy.log
LogFileSize=0
PidFile=/var/run/zabbix/zabbix_proxy.pid
DBHost=localhost
DBName=zabbix_proxy
DBUser=zabbix_proxy
DBPassword=zabbix_proxy
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
ExternalScripts=/usr/lib/zabbix/externalscripts
LogSlowQueries=3000
```

**3. Agent 配置**

```bash
grep '^[a-Z]' /etc/zabbix/zabbix_agentd.conf 
```

```ini
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=192.168.1.234
ListenPort=10050
ServerActive=192.168.1.234
Hostname=192.168.1.233   # 要么写 localhost，要么写 IP，其他名称因为没有 DNS，所以解析不出来，Hostname 都一样
Include=/etc/zabbix/zabbix_agentd.d/*.conf
```

### 2.7 自动化监控

1. 自动注册（zabbix server 基于 zabbix agent 的主动模式）。
   - 1.1 Zabbix Agent 自动添加。
2. 主动发现（zabbix server 基于 zabbix agent 的被动模式）。
   - 2.1 自动发现 Discovery。
   - 2.2 Zabbix API。

> 注：无论是主动模式还是被动模式下，触发条件应都先包含不能先等于，因为可能值中还包含其它的字符。

#### 自动注册操作

1. 在 Agent 中更改配置，关闭 Agent 被动模式，并设置 `StartAgents=0`，设置主动模式的 `ServerActive` 地址。设置 `HostMetadataItem` 或者 `HostMetadata`。`HostMetadata` 是手动设置值，例：`HostMetadata=Linux`。`HostMetadataItem` 是使用 Zabbix Agent 的 key 来自动获取值，例如 `HostMetadataItem=system.uname`。

   ```bash
   vim /etc/zabbix/zabbix_agentd.conf
   grep '^[a-Z]'  /etc/zabbix/zabbix_agentd.conf             
   ```

   ```ini
   PidFile=/var/run/zabbix/zabbix_agentd.pid
   LogFile=/var/log/zabbix/zabbix_agentd.log
   LogFileSize=0
   StartAgents=0
   ServerActive=192.168.1.201  
   Hostname=192.168.1.233
   HostMetadataItem=system.uname  # 告诉 server 我的特征，和 HostMetadata 二选一，system.uname 相当于在 shell 上执行 uname 功能
   Include=/etc/zabbix/zabbix_agentd.d/*.conf
   ```

2. 然后去 Zabbix Server Web 界面里面 Action 选项添加自动注册功能（另外有子菜单 trigger、自动发现）。设置名称，触发条件（主机元数据包含 linux-node），并设置添加操作（添加主机，添加到某个主机组，添加相匹配的模板）。
3. 查看自动成功添加的模板图形。

#### 自动发现（Discovery）操作

先在 zabbix server web 上的自动发现选项上添加一个自动发现规则，设置名称、IP 范围、更新间隔、检查选项（使用 zabbix 客户端的 key 等于 `system.uname`），`system.uname` 可以获取系统是 Linux 还是 Windows，在后面用到。

在动作（Action）上添加一个自动发现（Discovery）类型的 action，设置名称，设置触发条件为`接收到的值包含 Linux`（如果有多个条件，则需要使用或模式），设置操作（添加主机、添加主机群组、链接模板[跟据获取到的值是 linux 还是 windows 来判断加什么模板]）。

1. 在 Agent 中更改配置，关闭 Agent 主动模式，并设置 `StartAgent=3`（表示开启 Agent 监听端口，等于 0 则表示禁用端口），然后设置被动模式的 Server 地址。

   ```bash
   vim /etc/zabbix/zabbix_agentd.conf
   grep '^[a-Z]'  /etc/zabbix/zabbix_agentd.conf             
   ```

   ```ini
   PidFile=/var/run/zabbix/zabbix_agentd.pid
   LogFile=/var/log/zabbix/zabbix_agentd.log
   LogFileSize=0
   StartAgents=3
   Server=192.168.1.201
   Hostname=192.168.1.233
   Include=/etc/zabbix/zabbix_agentd.d/*.conf
   ```

> 注：`HostMetadata` 这个选项在被动模式下的 Agent 没什么用，在主动模式下的作用很大。

#### 主动发现操作——Zabbix API

去官网查找 API 使用方法：设置前端后，可以使用远程 HTTP 请求来调用 API。为此，您需要将 HTTP POST 请求发送到 `api_jsonrpc.php` 位于前端目录中的文件。

例如，如果您的 Zabbix 前端安装在 `http://company.com/zabbix` 下，则调用该 `apiinfo.version` 方法的 HTTP 请求可能如下所示：

```http
POST http://company.com/zabbix/api_jsonrpc.php
Content-Type: application/json-rpc
```

```json
{"jsonrpc": "2.0", "method": "apiinfo.version", "id": 1, "auth": null, "params": {}}
```

该请求必须具有 `Content-Type` 标头集合至这些值中的一个：`application/json-rpc`、`application/json` 或 `application/jsonrequest`。

HTTP 请求方法示例工作流程：

| 序号 | 方法    | 描述                                                                                         |
| ---- | ------- | -------------------------------------------------------------------------------------------- |
| 1    | GET     | 请求指定的页面信息，并返回实体主体。                                                          |
| 2    | HEAD    | 类似于 GET 请求，只不过返回的响应中没有具体的内容，用于获取报头。                             |
| 3    | POST    | 向指定资源提交数据进行处理请求（例如提交表单或者上传文件）。数据被包含在请求体中。POST 请求可能会导致新的资源的建立和/或已有资源的修改。 |
| 4    | PUT     | 从客户端向服务器传送的数据取代指定的文档的内容。                                              |
| 5    | DELETE  | 请求服务器删除指定的页面。                                                                    |
| 6    | CONNECT | HTTP/1.1 协议中预留给能够将连接改为管道方式的代理服务器。                                      |
| 7    | OPTIONS | 允许客户端查看服务器的性能。                                                                  |
| 8    | TRACE   | 回显服务器收到的请求，主要用于测试或诊断。                                                    |
| 9    | PATCH   | 是对 PUT 方法的补充，用来对已知资源进行局部更新。                                              |

在您可以访问 Zabbix 内部的任何数据之前，您需要登录并获取身份验证令牌。这可以使用 `user.login` 方法完成。我们假设您要以标准 Zabbix Admin 用户身份登录，则您的 JSON 请求将如下所示：

```json
{
    "jsonrpc": "2.0",
    "method": "user.login",
    "params": {
        "user": "Admin",
        "password": "zabbix"
    },
    "id": 1,
    "auth": null
}
```

请求对象具有以下属性：

- `jsonrpc`：API 使用的是 JSON-RPC 协议版本；Zabbix API 实现了 JSON-RPC 2.0 版；
- `method`：被调用的 API 方法；
- `params`：将传递给 API 方法的参数；
- `id`：请求的任意标识符；
- `auth`：用户认证令牌；因为我们还没有，所以它设置为 null。

如果您正确提供了凭据，则 API 返回的响应将包含用户身份验证令牌（token）：

```json
{
    "jsonrpc": "2.0",
    "result": "0424bd59b807674191e7d77572075f33",
    "id": 1
}
```

响应对象又包含以下属性：

- `jsonrpc`：再次，JSON-RPC 协议的版本；
- `result`：方法返回的数据；
- `id`：相应请求的标识符。

### 2.8 老男孩 Zabbix API 实操

linux curl 使用 API 方法，下面这两个可以成功获取 token：

```bash
curl -s -X POST -H 'Content-Type:application/json' -d'{"jsonrpc":"2.0","method":"user.login","params":{"user":"jackli","password":"Mu123"},"auth":null,"id":1}' http://192.168.1.201/zabbix/api_jsonrpc.php | python -m json.tool
```

```bash
curl -s -X POST -H 'Content-Type:application/json' -d'{"jsonrpc": "2.0","method":"user.login","params":{"user":"jackli","password":"Mu123"},"auth": null,"id":0}' http://192.168.1.201/zabbix/api_jsonrpc.php
```

curl 参数说明：`-s` 参数静默；`-X` 参数请求命令；`-H` 参数标头集合值（application/json）；`-d` 参数请求的数据；最后是请求地址 `http://192.168.1.201/zabbix/api_jsonrpc.php` 调用 API，并用 python 的 json.tool 工具来输出结果。

安装 python-pip 工具：

```bash
yum install -y python-setuptools
rpm -ivh https://mirrors.aliyun.com/centos/7.5.1804/cloud/x86_64/openstack-pike/common/python-pip-8.1.2-1.el7.noarch.rpm
pip install requests
```

例子：获取 token

```bash
curl -s -X POST -H 'Content-Type:application/json' -d'{"jsonrpc":"2.0","method":"user.login","params":{"user":"jackli","password":"Mu123"},"auth":null,"id":1}' http://192.168.1.201/zabbix/api_jsonrpc.php | python -m json.tool
```

```json
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": "82cee37adf4cc37374f9558dcb5310d8"
}
```

下面可获取主机名：

```bash
curl -s -X POST -H 'Content-Type:application/json' -d'{"jsonrpc":"2.0","method":"host.get","params":{"output":["hostid","host"],"selectInterfaces":["interfaceid","ip"]},"auth":"82cee37adf4cc37374f9558dcb5310d8","id":3}' http://192.168.1.201/zabbix/api_jsonrpc.php | python -m json.tool
```

例子：获取主机名

```bash
curl -s -X POST -H 'Content-Type:application/json' -d'{"jsonrpc":"2.0","method":"host.get","params":{"output":["hostid","host"],"selectInterfaces":["interfaceid","ip"]},"auth":"82cee37adf4cc37374f9558dcb5310d8","id":3}' http://192.168.1.201/zabbix/api_jsonrpc.php | python -m json.tool
```

```json
{
    "id": 3,
    "jsonrpc": "2.0",
    "result": [
        {
            "host": "Zabbix -server",
            "hostid": "10084",
            "interfaces": [
                {
                    "interfaceid": "1",
                    "ip": "192.168.1.201"
                }
            ]
        },
        {
            "host": "cisco-switch3",
            "hostid": "10109",
            "interfaces": [
                {
                    "interfaceid": "6",
                    "ip": "192.168.1.254"
                }
            ]
        }
    ]
}
```

下面可获取模板：

```bash
curl -s -X POST -H 'Content-Type:application/json' -d'{"jsonrpc":"2.0","method":"template.get","params":{"output":"extend","filter":{"host":["Template OS Linux","Template OS Windows"]}},"auth":"82cee37adf4cc37374f9558dcb5310d8","id":3}' http://192.168.1.201/zabbix/api_jsonrpc.php | python -m json.tool
```

例子：获取模板

```bash
curl -s -X POST -H 'Content-Type:application/json' -d'{"jsonrpc":"2.0","method":"template.get","params":{"output":"extend","filter":{"host":["Template OS Linux","Template OS Windows"]}},"auth":"82cee37adf4cc37374f9558dcb5310d8","id":3}' http://192.168.1.201/zabbix/api_jsonrpc.php | python -m json.tool
```

```json
{
    "id": 3,
    "jsonrpc": "2.0",
    "result": [
        {
            "available": "0",
            "description": "",
            "disable_until": "0",
            "error": "",
            "errors_from": "0",
            "flags": "0",
            "host": "Template OS Linux",
            "ipmi_authtype": "0",
            "ipmi_available": "0",
            "ipmi_disable_until": "0",
            "ipmi_error": "",
            "ipmi_errors_from": "0",
            "ipmi_password": "",
            "ipmi_privilege": "2",
            "ipmi_username": "",
            "jmx_available": "0",
            "jmx_disable_until": "0",
            "jmx_error": "",
            "jmx_errors_from": "0",
            "lastaccess": "0",
            "maintenance_from": "0",
            "maintenance_status": "0",
            "maintenance_type": "0",
            "maintenanceid": "0",
            "name": "Template OS Linux",
            "proxy_hostid": "0",
            "snmp_available": "0",
            "snmp_disable_until": "0",
            "snmp_error": "",
            "snmp_errors_from": "0",
            "status": "3",
            "templateid": "10001",
            "tls_accept": "1",
            "tls_connect": "1",
            "tls_issuer": "",
            "tls_psk": "",
            "tls_psk_identity": "",
            "tls_subject": ""
        },
        {
            "available": "0",
            "description": "",
            "disable_until": "0",
            "error": "",
            "errors_from": "0",
            "flags": "0",
            "host": "Template OS Windows",
            "ipmi_authtype": "0",
            "ipmi_available": "0",
            "ipmi_disable_until": "0",
            "ipmi_error": "",
            "ipmi_errors_from": "0",
            "ipmi_password": "",
            "ipmi_privilege": "2",
            "ipmi_username": "",
            "jmx_available": "0",
            "jmx_disable_until": "0",
            "jmx_error": "",
            "jmx_errors_from": "0",
            "lastaccess": "0",
            "maintenance_from": "0",
            "maintenance_status": "0",
            "maintenance_type": "0",
            "maintenanceid": "0",
            "name": "Template OS Windows",
            "proxy_hostid": "0",
            "snmp_available": "0",
            "snmp_disable_until": "0",
            "snmp_error": "",
            "snmp_errors_from": "0",
            "status": "3",
            "templateid": "10081",
            "tls_accept": "1",
            "tls_connect": "1",
            "tls_issuer": "",
            "tls_psk": "",
            "tls_psk_identity": "",
            "tls_subject": ""
        }
    ]
}
```

#### 获取 token 的 python 脚本

```bash
vim zabbix_auth.py
```

```python
#!/usr/bin/env python
# _*_ coding:utf-8 _*_

import requests
import json

url = 'http://192.168.1.201/zabbix/api_jsonrpc.php'
post_data = {
        "jsonrpc": "2.0",
        "method": "user.login",
        "params": {
                "user":"jackli",
                "password":"Mu123"
        },
        "id": 1
}
post_header = {'Content-Type': 'application/json'}
ret = requests.post(url, data=json.dumps(post_data),headers=post_header)

zabbix_ret = json.loads(ret.text)
if not zabbix_ret.has_key('result'):
        print 'login error'
else:
        print zabbix_ret.get('result')
```

#### 用 python 添加 zabbix agent 主机

```bash
vim zabbix_host_create.py
```

```python
#!/usr/bin/env python
# _*_ coding:utf-8 _*_

import requests
import json

url = 'http://192.168.1.201/zabbix/api_jsonrpc.php'
post_data = {
    "jsonrpc": "2.0",
    "method": "host.create",
    "params": {
        "host": "Linux server",
        "interfaces": [
            {
                "type": 1,
                "main": 1,
                "useip": 1,
                "ip": "192.168.1.233",
                "dns": "",
                "port": "10050"
            }
        ],
        "groups": [
            {
                "groupid": "2"
            }
        ],
        "templates": [
            {
                "templateid": "10001"
            }
        ]
    },
    "auth": "bbacb5612a00a60a6da1d1d782f8c080",
    "id": 1
}
post_header = {'Content-Type': 'application/json'}
ret = requests.post(url, data=json.dumps(post_data),headers=post_header)

zabbix_ret = json.loads(ret.text)
print zabbix_ret
```

执行的结果：

```bash
python zabbix_host_create.py
```

```text
{u'jsonrpc': u'2.0', u'result': {u'hostids': [u'10132']}, u'id': 1}
```

#### 自定义监控其他

设置 ping 网关看是否存活：

```bash
cat /etc/zabbix/zabbix_agentd.d/ping-gw.conf 
```

```ini
UserParameter=route-idc.ping,/usr/bin/ping -c 3 -W 1 211.152.62.226 | grep -c 'icmp_seq'
UserParameter=route-qp.ping,/usr/bin/ping -c 3 -W 1 101.231.195.138 | grep -c 'icmp_seq'
UserParameter=route-yw.ping,/usr/bin/ping -c 3 -W 1 122.226.124.58 | grep -c 'icmp_seq'
```

然后在对应的主机上增加 item，并设置图表和触发器即可实现。

对 web 服务器进行探测，看是否存活：

```bash
cat web.conf 
```

```ini
UserParameter=smbweb.ping,curl -u jack:jackli -m 10 -o /dev/null -s -w %{http_code} http://192.168.1.19/server-status/
```

然后在对应的主机上增加 item，并设置图表和触发器即可实现。

```bash
cat nginx.conf 
```

```ini
UserParameter=nginx.active,/usr/bin/curl -s http://192.168.1.233/nginx_status |grep 'Active' | awk '{print $NF}'
UserParameter=nginx.server,/usr/bin/curl -s http://192.168.1.233/nginx_status | awk '{print $1}' | awk 'NR==3{print}'
UserParameter=nginx.accepts,/usr/bin/curl -s http://192.168.1.233/nginx_status | awk '{print $2}' | awk 'NR==3{print}'
UserParameter=nginx.handled,/usr/bin/curl -s http://192.168.1.233/nginx_status | awk '{print $3}' | awk 'NR==3{print}'
UserParameter=nginx.reading,/usr/bin/curl -s http://192.168.1.233/nginx_status | awk '{print $2}' | awk 'NR==4{print}'
UserParameter=nginx.writing,/usr/bin/curl -s http://192.168.1.233/nginx_status | awk '{print $4}' | awk 'NR==4{print}'
```

---

## 第三章 源码安装 zabbix

参考链接：https://www.cnblogs.com/me80/p/7232975.html

安装 zabbix 之前先准备好 LAMP 环境。

#### 3.1 yum 安装 lamp

```bash
yum install -y httpd php php-mbstring mariadb mariadb-server
```

注：如果是源码安装 lamp 时，php 需要注意编译参数。zabbix 对 PHP 参数、PHP 模块有特殊要求。

PHP 安装参数（php 具体安装方法参考上面的链接，不过如下模块要特别留意加上）：

```ini
bcmath        --enable-bcmath
mbstring    --enable-mbstring
sockets        --enable-sockets
gd            --with-gd
libxml        --with-libxml-dir=/usr/local
xmlwriter     同上
xmlreader     同上
ctype         默认支持
session       默认支持
gettext       默认支持
```

#### 3.2 下载源码包

```bash
wget https://nchc.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.0.28/zabbix-3.0.28.tar.gz
tar xf zabbix-3.0.28.tar.gz 
cd zabbix-3.0.28/
```

创建数据库：

```sql
create database zabbix character set utf8 collate utf8_bin;
grant all on zabbix.* to zabbix@'localhost' identified by 'zabbix';
flush privileges;
```

创建用户并导入数据库：

```bash
groupadd -r zabbix
useradd -r -g zabbix zabbix

mysql -uroot -p zabbix < schema.sql
Enter password: 
mysql -uroot -p zabbix < images.sql 
Enter password: 
mysql -uroot -p zabbix < data.sql 
Enter password: 
```

#### 3.3 编译安装

```bash
# 安装开发包
yum groupinstall "Development and Creative Workstation" "Development Tools" -y
# 安装依赖包
yum install mariadb-devel curl-devel net-snmp-devel libxml2-devel -y

# 编译安装 zabbix server 和 agent
./configure --prefix=/usr/local/zabbix --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2

# 安装 zabbix
make install

/usr/local/zabbix/sbin/zabbix_server -V
```

```text
zabbix_server (Zabbix) 3.0.28   # 显示已经安装
```

> 注：自 Zabbix 3.0.0 版本起，SMTP 认证需要 `--with-libcurl` 配置选项，同时要求 cURL 7.20.0 或者更新版本。自 Zabbix 2.2.0 版本起，虚拟机监控需 `--with-libcurl` 和 `--with-libxml2` 配置选项。

编辑配置：

```bash
egrep -v '#|^$' /usr/local/zabbix/etc/zabbix_server.conf
```

```ini
ListenPort=10051
LogFile=/tmp/zabbix_server.log
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
DBPort=3306
Timeout=4
LogSlowQueries=3000
```

```bash
egrep -v '#|^$' /usr/local/zabbix/etc/zabbix_agentd.conf
```

```ini
LogFile=/tmp/zabbix_agentd.log
Server=192.168.1.239
ListenPort=10050
ServerActive=192.168.1.239
Hostname=zabbix-server
```

复制开机启动脚本：

```bash
cp misc/init.d/fedora/core/zabbix_* /etc/init.d/ -v
```

```text
'misc/init.d/fedora/core/zabbix_agentd' -> '/etc/init.d/zabbix_agentd'
'misc/init.d/fedora/core/zabbix_server' -> '/etc/init.d/zabbix_server'
```

```bash
vim /etc/init.d/zabbix_server
```

```ini
BASEDIR=/usr/local/zabbix  # 修改 zabbix 路径
```

```bash
vim /etc/init.d/zabbix_agentd 
```

```ini
BASEDIR=/usr/local/zabbix  # 修改 zabbix 路径
```

添加开机自启并启动服务：

```bash
chkconfig --add zabbix_server
chkconfig --add zabbix_agentd

service zabbix_server start    # 启动
```

```text
Starting zabbix_server (via systemctl):  [  OK  ]
```

```bash
service zabbix_agentd start
```

```text
Starting zabbix_agentd (via systemctl):  [  OK  ]
```

```bash
ss -tnl
```

```text
State       Recv-Q Send-Q Local Address:Port               Peer Address:Port              
LISTEN      0      50          *:3306                    *:*                  
LISTEN      0      128         *:111                     *:*                  
LISTEN      0      128         *:22                      *:*                  
LISTEN      0      128         *:10050                   *:*                  
LISTEN      0      128         *:10051                   *:*                  
LISTEN      0      128        :::111                    :::*                  
LISTEN      0      128        :::80                     :::*                  
LISTEN      0      128        :::22                     :::*                  
LISTEN      0      128        :::10050                  :::*                  
LISTEN      0      128        :::10051                  :::*             
```

```bash
chkconfig --level 35 zabbix_server on 
chkconfig --level 35 zabbix_agentd on 
```

#### 3.4 前端 web 配置

```bash
vim /etc/httpd/conf/httpd.conf 
```

```ini
DocumentRoot "/var/www/html"   # 确保文档根目录位置
```

拷贝源码包中的前端 PHP 代码到 apache 根目录：

```bash
mkdir -pv /var/www/html/zabbix
```

```text
mkdir: created directory ‘/var/www/html/zabbix’
```

```bash
cp -a ./frontends/php/* /var/www/html/zabbix/
chown -R zabbix.zabbix  /var/www/html/zabbix/
systemctl restart httpd
```

访问：`http://192.168.1.239/zabbix`。

解决访问报错（Check of pre-requisites）：

```text
Minimum required size of PHP post is 16M (configuration option "post_max_size").
Minimum required limit on execution time of PHP scripts is 300 (configuration option "max_execution_time").
Minimum required limit on input parse time for PHP scripts is 300 (configuration option "max_input_time").
Time zone for PHP is not set (configuration parameter "date.timezone").
PHP bcmath extension missing (PHP configuration parameter --enable-bcmath).
PHP gd extension missing (PHP configuration parameter --with-gd).
PHP gd PNG image support missing.
PHP gd JPEG image support missing.
PHP gd FreeType support missing.
PHP xmlwriter extension missing.
PHP xmlreader extension missing.
```

解决 php 依赖报错问题：

```bash
vim /etc/php.ini:
```

```ini
post_max_size = 16M
max_execution_time = 300
max_input_time = 300
date.timezone = Asia/Shanghai
```

```bash
yum install -y php-bcmath php-gd.x86_64 php-xml php-devel php-ldap
systemctl restart httpd
```

访问又报错：

```text
Unable to create the configuration file.
```

```bash
cd /var/www/html/zabbix/conf/ 
ls
```

```text
maintenance.inc.php  zabbix.conf.php.example
```

```bash
cp zabbix.conf.php.example zabbix.conf.php
vim zabbix.conf.php
```

```php
<?php
// Zabbix GUI configuration file.
global $DB;

$DB['TYPE']                             = 'MYSQL';
$DB['SERVER']                   = 'localhost';
$DB['PORT']                             = '3306';
$DB['DATABASE']                 = 'zabbix';
$DB['USER']                             = 'zabbix';
$DB['PASSWORD']                 = 'zabbix';
// Schema name. Used for IBM DB2 and PostgreSQL.
$DB['SCHEMA']                   = '';

$ZBX_SERVER                             = 'localhost';
$ZBX_SERVER_PORT                = '10051';
$ZBX_SERVER_NAME                = 'zabbix-server';

$IMAGE_FORMAT_DEFAULT   = IMAGE_FORMAT_PNG;
```

```bash
chown zabbix.zabbix zabbix.conf.php
```

---

## 第四章 钉钉报警

### 4.1 钉钉机器人创建

登录钉钉客户端，创建一个群，把需要收到报警信息的人员都拉到这个群内。然后点击群右上角的"群机器人"->"添加机器人"->"自定义"，记录该机器人的 webhook 值。

### 4.2 脚本 1：dingding.py

```bash
cat dingding.py 
```

```python
#!/usr/bin/env python
# coding:utf-8
# zabbix钉钉报警
import requests,json,sys,os,datetime
webhook="https://oapi.dingtalk.com/robot/send?access_token=dcdb94119d8f6d349bb1311c60fa749ab701b55a5d5a6b9f41ae9548bf1ea0"
user=sys.argv[1]
text=sys.argv[3]
data={
    "msgtype": "text",
    "text": {
        "content": text
    },
    "at": {
        "atMobiles": [
            user
        ],
        "isAtAll": False
    }
}
headers = {'Content-Type': 'application/json'}
x=requests.post(url=webhook,data=json.dumps(data),headers=headers)
if os.path.exists("/usr/local/zabbix/logs/dingding.log"):
    f=open("/usr/local/zabbix/logs/dingding.log","a+")
else:
    f=open("/usr/local/zabbix/logs/dingding.log","w+")
f.write("\n"+"-"*30)
if x.json()["errcode"] == 0:
    f.write("\n"+str(datetime.datetime.now())+"    "+str(user)+"    "+"发送成功"+"\n"+str(text))
    f.close()
else:
    f.write("\n"+str(datetime.datetime.now()) + "    " + str(user) + "    " + "发送失败" + "\n" + str(text))
    f.close()
```

### 4.3 脚本 2：post.sh

```bash
cat post.sh 
```

```bash
#!/bin/bash
header="Content-Type: application/json;charset=utf-8"
url="https://oapi.dingtalk.com/robot/send?access_token=dcdb94119d8f6d349bb1311c60fa749ab701b55a5d5a6b9f41ae9548bf1ea0"
txt='{
      "msgtype":"text",
          "text":{
                 "content":"'$1'"
                 },
          "at":{
                 "atMobiles":["'$2'"],
                 "isAtAll":false
                 }
     }'
curl  -X POST "${url}" -H "${header}"  -d "${txt}"
```

### 4.4 测试

1. `./post.sh waninthisisaest 13661196xxx`，第一个值为消息内容，第二个值为你要@的特定手机号。
2. `./dingding.py 13661196xxx test "这个条测试信息,忽略"`，第一个值为要@的特定手机号，第二个值为主题，第三个值为消息内容。
3. 编辑 zabbix_server.conf 配置文件：

   ```bash
   AlertScriptsPath=/usr/local/zabbix/share/zabbix/alertscripts
   ```

   设成报警脚本的目录，后面在 zabbix GUI 上新建媒介才有用。

   测试通过后去 zabbix WEB GUI 进行添加媒介：

   - 名称：dingding_alert
   - 类型：script
   - 脚本名称：dingding.py
   - 脚本参数：
     - `{ALERT.SENDTO}`   # 接收的用户地址
     - `{ALERT.SUBJECT}`  # 消息主题
     - `{ALERT.MESSAGE}`  # 消息内容

   去用户添加媒介：收件人就是你的接收者地址，这里是发到钉钉群里，所以填写 @ 的人手机号即可。

   在对应主机上添加 web 监测：新建 web 场景，并添加设置步骤，步骤内容为对应的 WEB URL 地址、设定超时时间、和你需要的代码 200。

   新建触发器：

   - `{smb:web.test.fail[smb-web].last()}<>0`，设置失败的步骤是否不等于 0，不等于 0 表示有失败的步骤，会触发报警。
   - `{smb:web.test.rspcode[smb-web,smb-web].last()}<>200`，设置响应的代码是否不等于 200，不等于 200 表示服务异常，会触发报警。

   发送消息内容模板：

   ```
   Trigger: {TRIGGER.NAME}
   Trigger status: {TRIGGER.STATUS}
   Trigger severity: {TRIGGER.SEVERITY}
   Original event ID: {EVENT.ID}

   {ITEM.NAME} ({HOST.NAME}:{ITEM.KEY}): {ITEM.VALUE}
   ```

---

## 第五章 zabbix auto add host to zabbix web（pass zabbixAPI）

```bash
tree .
```

```text
.
├── zabbix-add-host.py
├── zabbix-agent-ip.txt
├── zabbixBaseAPI.py
└── zabbix-process.txt  # 脚本执行过程生成的日志文件
```

### 5.1 自定义的 zabbix 基本 API 库

```bash
cat zabbixBaseAPI.py 
```

```python
#!/usr/bin/env python3
# filename: zabbixBaseAPI.py
# author: jack
# datetime:20200419

import json
import urllib.request 

class zabbixBaseAPI(object):
    def __init__(self,url = "http://127.0.0.1:8081/zabbix/api_jsonrpc.php" ,header = {"Content-Type": "application/json"}):
        self.url = url
        self.header = header

    # post request
    def post_request(self,url, data, header):
        request = urllib.request.Request(url, data, header) 
        result = urllib.request.urlopen(request)
        response = json.loads(result.read())
        result.close()
        return response
    
    # json data process
    def json_data(self,method,params,authid):
        data = json.dumps(
        {
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "auth": authid,
            "id": 1
        })
        request_info = self.post_request(self.url, data.encode('utf-8'), self.header)
        return request_info
    
    # login authentication 
    def authid(self,user,password): 
        data = json.dumps(
        {
            "jsonrpc": "2.0",
            "method": "user.login",
            "params": {
                "user": user,
                "password": password
            },
            "id": 1
        })
        authid = self.post_request(self.url, data.encode('utf-8'), self.header)
        try:
            return authid['result']
            print('认证成功')
        except KeyError:
            print ('认证失败,用户名或密码错误')
            exit()
    
    # ip file process
    def text_process(self,file):
        import re
        find = re.compile(r"^#")
        text_info = []
        f = open(file, "r")
        text = f.readlines()
        f.close()
        for i in text:
           t = i.strip()
           if len(t) >= 6:
              if find.search(t.rstrip("\n")) == None:
                text_info.append(t.rstrip("\n"))
        return text_info
    
    # logout authentication
    def login_out(self,authid):
        data = json.dumps(
        {
            "jsonrpc": "2.0",
            "method": "user.logout",
            "params": [],
            "id": 1,
            "auth": authid
        })
        a = self.post_request(self.url, data.encode('utf-8'), self.header)
        return '认证信息已注销'
```

### 5.2 zabbix 添加主机的 python 脚本

```bash
cat zabbix-add-host.py   
```

```python
#!/usr/bin/env python3
# import zabbix_base_api  # import custom class for zabbix_base_api.py
import zabbixBaseAPI
import time 
import re

# write zabbix API address replace old address
z_api_con = zabbixBaseAPI.zabbixBaseAPI(url='http://192.168.43.201/zabbix/api_jsonrpc.php')

# get host id function
def hostGet(method,ip,authid):
    data = {
        "output": ["hostid", "host"],
        "filter": {
            "ip": ip
        },
        "selectInterfaces": ["ip"],
        "selectParentTemplates": ["name"]

    }
    responses = z_api_con.json_data(method, data, authid)
    return responses

# will mouse move zabbix web front hostGroup,template can get id
def hostCreate(method,ip,hostname,serverType,authid):
    data = {
        "host": hostname,
        # "proxy_hostid": 13323,                    # proxy id
        "interfaces": [
            {
                "type": 1,
                "main": 1,
                "useip": 1,
                "ip": ip,			    # zabbix agent ip
                "dns": "",
                "port": "10050"                     # zabbix agent port 
            }
        ],
        "groups": [
            {
                "groupid": 2                        # host group id
            }
        ],
        "tags": [
            {
                "tag": hostname,
                "value": serverType
            }
        ],
        "templates": [
            {
                "templateid": 10001                 # require join of template id
            }
        ]
    }

    responses = z_api_con.json_data(method, data, authid)
    return responses

def hostDelete(method,authid,*hostids):
    data = hostids 
    responses = z_api_con.json_data(method, data, authid)
    return responses

# get all proxyAgent info(proxyAgent id,name.....)
def proxyGet(method,authid):
    data = {
        "output": "extend",
        "selectInterface": "extend"
    }
    responses = z_api_con.json_data(method, data, authid)
    return responses

# update proxyAgent manager of host
def proxyUpdate(method,hostid,authid):
    data = {
        "proxyid": 10255,              # proxyAgent id 
        "hosts": [
            hostid
        ]
    }
    responses = z_api_con.json_data(method, data, authid)
    return responses

def main_all(authid):
    # call text_process function
    lists = z_api_con.text_process('zabbix-agent-ip.txt')
    add_file = open("zabbix-process.txt","a+")
    for list in lists:
        rlist = re.split(r'\s+',list)
        ip = rlist[0]
        hostname = rlist[1]
        serverType = rlist[2]
        hostget = hostGet("host.get",ip,authid)["result"]
    # judge host whether exist,if exist will 'hostid' and 'host name' write file 'zabbix_process.txt'
        if hostget:
            print("info: " + ip + '  This host already exist!')
            hostid = hostget[0]["hostid"]
            host = hostget[0]["host"]
            add_file.writelines(hostid+"\t"+host+"\n")
    # else will ip write file 'zabbix_process.txt'
        else:
            print('info: Create host  ' + ip)
            hostcreate = hostCreate("host.create",ip,hostname,serverType,authid)
            add_file.writelines(ip+"\n")
    add_file.close()
    # file.close()


if __name__ == "__main__":
    starttime = time.time()
    print ("Process is running...")
    authid = z_api_con.authid('Admin', 'zabbix')
    main_all(authid)
    z_api_con.login_out(authid)
    endtime = time.time()
    print (endtime-starttime)
```

```bash
cat zabbix-agent-ip.txt   # zabbix agent ip file
```

```text
# ip		serverName		serverType   
192.168.43.202   node2 			 docker-server      
192.168.43.203   node3       		 windows_server   
```

---

## 第六章 zabbix 3.4

下面的使用均基于 zabbix-sender 插件。

```bash
chown root:zabbix -R /etc/zabbix/
```

### 6.1 monitor for mysql

```bash
rpm -qa | grep zabbix-sender
```

```text
zabbix-sender-3.4.15-1.el7.x86_64   # install zabbix-sender plugin
```

```bash
cat mysql_stat.sh
```

```bash
#!/bin/bash
RespStr=$(/usr/bin/mysqladmin --silent --user=zbx_monitor --password=zbx_monitor extended-status 2>/dev/null)
[ $? != 0 ] && echo 0 && exit 1

(cat <<EOF
$RespStr
EOF
) | awk -F'|' '$2~/^ (Com_(delete|insert|replace|select|update)|Connections|Created_tmp_(files|disk_tables|tables)|Key_(reads|read_requests|write_requests|writes)|Max_used_connections|Qcache_(free_memory|hits|inserts|lowmem_prunes|queries_in_cache)|Questions|Slow_queries|Threads_(cached|connected|created|running)|Bytes_(received|sent)|Uptime) +/ {
 gsub(" ", "", $2);
 print "- mysql." $2, int($3)
}' | /usr/bin/zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --host=`hostname` --input-file - >/dev/null 2>&1
echo 1
exit 0
```

```bash
cat mysql_status.conf 
```

```ini
UserParameter		= mysql_status,/etc/zabbix/scripts/mysql_stat.sh
```

mysql database operation：

```sql
GRANT PROCESS,SHOW DATABASES,REPLICATION CLIENT,SHOW VIEW ON *.* TO 'zbx_monitor'@'localhost' IDENTIFIED BY PASSWORD 'zbx_monitor';
```

```bash
chmod 750 mysql_stat.sh
chgrp zabbix mysql_stat.sh
systemctl restart zabbix-agent
```

### 6.2 monitor for redis

```bash
cat redis_stat.sh 
```

```bash
#!/bin/bash
RespStr=$(/usr/local/redis/bin/redis-cli -h 127.0.0.1 -p 6379 info all 2>/dev/null)
[ $? != 0 ] && echo 0 && exit 1

if [ -z $1 ]; then
 (cat <<EOF
$RespStr
EOF
 ) | awk -F: '$1~/^(uptime_in_seconds|(blocked|connected)_clients|used_memory(_rss|_peak)?|total_(connections_received|commands_processed)|instantaneous_ops_per_sec|total_net_(input|output)_bytes|rejected_connections|(expired|evicted)_keys|keyspace_(hits|misses))$/ {
  print "- redis." $1, int($2)
 }
 $1~/^cmdstat_(get|setex|exists|command)$/ {
  split($2, C, ",|=")
  print "- redis." $1, int(C[2])
 }
 $1~/^db[0-9]+$/ {
  split($2, C, ",|=")
  for(i=1; i < 6; i+=2) print "- redis." C[i] "[" $1 "]", int(C[i+1])
 }' | /usr/bin/zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --host=`hostname` --input-file - >/dev/null 2>&1
 echo 1
 exit 0

elif [ "$1" = 'db' ]; then
 (cat <<EOF
$RespStr
EOF
 ) | awk -F: '$1~/^db[0-9]+$/ {
  OutStr=OutStr es "{\"{#DBNAME}\":\"" $1 "\"}"
  es=","
 }
 END { print "{\"data\":[" OutStr "]}" }'
fi
```

```bash
cat redis_stat.conf 
UserParameter		= redis_status,/etc/zabbix/scripts/redis_stat.sh
UserParameter		= redis.discovery_db,/etc/zabbix/scripts/redis_stat.sh db
chgrp zabbix redis_stat.sh
chmod 750 redis_stat.sh
systemctl restart redis-agent
```

> 注：redis 模板中图形的 get、setex 等指标只有在 redis 中使用相应命令操作后才显示，否则为未捕捉到数据。

### 6.3 monitor for rabbitmq

此部分不使用 zabbix-sender 插件，基于 python2.x。

```bash
cat ../rabbitmq/api.py 
```

```python
#!/usr/bin/env /usr/bin/python
'''Python module to query the RabbitMQ Management Plugin REST API and get
results that can then be used by Zabbix.
https://github.com/jasonmcintosh/rabbitmq-zabbix
'''
from __future__ import unicode_literals

import io
import json
import optparse
import socket
import urllib2
import subprocess
import os
import logging


class RabbitMQAPI(object):
    '''Class for RabbitMQ Management API'''

    def __init__(self, user_name='guest', password='guest', host_name='',
                 port=15672, conf='/etc/zabbix/zabbix_agentd.conf', senderhostname=None, protocol='http'):
        self.user_name = user_name
        self.password = password
        self.host_name = host_name or socket.gethostname()
        self.port = port
        self.conf = conf or '/etc/zabbix/zabbix_agentd.conf'
        self.senderhostname = senderhostname or socket.gethostname()
        self.protocol = protocol or 'http'
    
    def call_api(self, path):
        '''Call the REST API and convert the results into JSON.'''
        url = '{0}://{1}:{2}/api/{3}'.format(self.protocol, self.host_name, self.port, path)
        password_mgr = urllib2.HTTPPasswordMgrWithDefaultRealm()
        password_mgr.add_password(None, url, self.user_name, self.password)
        handler = urllib2.HTTPBasicAuthHandler(password_mgr)
        logging.debug('Issue a rabbit API call to get data on ' + path + " against " + self.host_name)
        logging.debug('Full URL:' + url)
        return json.loads(urllib2.build_opener(handler).open(url).read())
    
    def list_queues(self, filters=None):
        '''
        List all of the RabbitMQ queues, filtered against the filters provided
        in .rab.auth. See README.md for more information.
        '''
        queues = []
        if not filters:
            filters = [{}]
        for queue in self.call_api('queues'):
            logging.debug("Discovered queue " + queue['name'] + ", checking to see if it's filtered...")
            for _filter in filters:
                check = [(x, y) for x, y in queue.items() if x in _filter]
                shared_items = set(_filter.items()).intersection(check)
                if len(shared_items) == len(_filter):
                    element = {'{#NODENAME}': queue['node'],
                               '{#VHOSTNAME}': queue['vhost'],
                               '{#QUEUENAME}': queue['name']}
                    queues.append(element)
                    logging.debug('Discovered queue '+queue['vhost']+'/'+queue['name'])
                    break
        return queues
    
    def list_shovels(self, filters=None):
        '''
        List all of the RabbitMQ shovels, filtered against the filters provided
        in .rab.auth. See README.md for more information.
        '''
        shovels = []
        if not filters:
            filters = [{}]
        try:
            for shovel in self.call_api('shovels'):
                logging.debug("Discovered shovel " + shovel['name'] + ", checking to see if it's filtered...")
                for _filter in filters:
                    check = [(x, y) for x, y in shovel.items() if x in _filter]
                    shared_items = set(_filter.items()).intersection(check)
                    if len(shared_items) == len(_filter):
                        element = {'{#VHOSTNAME}': shovel['vhost'],
                                   '{#SHOVELNAME}': shovel['name']}
                        shovels.append(element)
                        logging.debug('Discovered shovel '+shovel['vhost']+'/'+shovel['name'])
                        break
            return shovels
        except urllib2.HTTPError as err:
            if err.code == 404:
                return shovels
            else:
                raise err
    
    def list_nodes(self):
        '''Lists all rabbitMQ nodes in the cluster'''
        nodes = []
        for node in self.call_api('nodes'):
            # We need to return the node name, because Zabbix
            # does not support @ as an item parameter
            name = node['name'].split('@')[1]
            element = {'{#NODENAME}': name,
                       '{#NODETYPE}': node['type']}
            nodes.append(element)
            logging.debug('Discovered nodes '+name+'/'+node['type'])
        return nodes
    
    def check_queue(self, filters=None):
        '''Return the value for a specific item in a queue's details.'''
        return_code = 0
        if not filters:
            filters = [{}]
    
        buffer = io.StringIO()
    
        try:
            for queue in self.call_api('queues'):
                success = False
                logging.debug("Filtering out by " + str(filters))
                for _filter in filters:
                    check = [(x, y) for x, y in queue.items() if x in _filter]
                    shared_items = set(_filter.items()).intersection(check)
                    if len(shared_items) == len(_filter):
                        success = True
                        break
                if success:
                    self._prepare_data(queue, buffer)
        except urllib2.HTTPError as err:
            if err.code == 404:
                buffer.close()
                return return_code
            else:
                raise err
    
        return_code = self._send_data(buffer)
        buffer.close()
        return return_code
    
    def check_shovel(self, filters=None):
        '''Return the value for a specific item in a shovel's details.'''
        return_code = 0
        if not filters:
            filters = [{}]
    
        buffer = io.StringIO()
    
        try:
            for shovel in self.call_api('shovels'):
                success = False
                logging.debug("Filtering out by " + str(filters))
                for _filter in filters:
                    check = [(x, y) for x, y in shovel.items() if x in _filter]
                    shared_items = set(_filter.items()).intersection(check)
                    if len(shared_items) == len(_filter):
                        success = True
                        break
                if success:
                    key = '"rabbitmq.shovels[{0},shovel_{1},{2}]"'
                    key = key.format(shovel['vhost'], 'state', shovel['name'])
                    value = shovel.get('state', 0)
                    logging.debug("SENDER_DATA: - %s %s" % (key,value))
                    buffer.write("- %s %s\n" % (key, value))
        except urllib2.HTTPError as err:
            if err.code == 404:
                buffer.close()
                return return_code
            else:
                raise err
    
        return_code = self._send_data(buffer)
        buffer.close()
        return return_code
    
    def _prepare_data(self, queue, file):
        '''Prepare the queue data for sending'''
        for item in ['memory', 'messages', 'messages_unacknowledged',
                     'consumers']:
            key = '"rabbitmq.queues[{0},queue_{1},{2}]"'
            key = key.format(queue['vhost'], item, queue['name'])
            value = queue.get(item, 0)
            logging.debug("SENDER_DATA: - %s %s" % (key,value))
            file.write("- %s %s\n" % (key, value))
        ##  This is a non standard bit of information added after the standard items
        for item in ['deliver_get', 'publish', 'ack']:
            key = '"rabbitmq.queues[{0},queue_message_stats_{1},{2}]"'
            key = key.format(queue['vhost'], item, queue['name'])
            value = queue.get('message_stats', {}).get(item, 0)
            logging.debug("SENDER_DATA: - %s %s" % (key,value))
            file.write("- %s %s\n" % (key, value))
    
    def _send_data(self, file):
        '''Send the queue data to Zabbix.'''
        args = 'zabbix_sender -vv -c {0} -i -'
        if self.senderhostname:
            args = args + " -s '%s' " % self.senderhostname
        return_code = 0
        process = subprocess.Popen(args.format(self.conf),
                                           shell=True,
                                           stdin=subprocess.PIPE,
                                           stdout=subprocess.PIPE,
                                           stderr=subprocess.PIPE)
        out, err = process.communicate(input=file.getvalue())
        logging.debug("Finished sending data")
        return_code = process.wait()
        logging.info("Found return code of " + str(return_code))
        if return_code == 1:
            logging.error(out)
            logging.error(err)
        else:
            logging.debug(err)
            logging.debug(out)
        return return_code
    
    def check_aliveness(self):
        '''Check the aliveness status of a given vhost.'''
        return self.call_api('aliveness-test/%2f')['status']
    
    def check_server(self, item, node_name):
        '''First, check the overview specific items'''
        if item == 'message_stats_deliver_get':
          return self.call_api('overview').get('message_stats', {}).get('deliver_get_details', {}).get('rate',0)
        elif item == 'message_stats_publish':
          return self.call_api('overview').get('message_stats', {}).get('publish_details', {}).get('rate',0)
        elif item == 'message_stats_ack':
          return self.call_api('overview').get('message_stats', {}).get('ack_details', {}).get('rate',0)
        elif item == 'message_count_total':
          return self.call_api('overview').get('queue_totals', {}).get('messages',0)
        elif item == 'message_count_ready':
          return self.call_api('overview').get('queue_totals', {}).get('messages_ready',0)
        elif item == 'message_count_unacknowledged':
          return self.call_api('overview').get('queue_totals', {}).get('messages_unacknowledged',0)
        elif item == 'rabbitmq_version':
          return self.call_api('overview').get('rabbitmq_version', 'None')
        '''Return the value for a specific item in a node's details.'''
        node_name = node_name.split('.')[0]
        nodeInfo = self.call_api('nodes')
        for nodeData in nodeInfo:
            logging.debug("Checking to see if node name {0} is in {1} for item {2} found {3} nodes".format(node_name, nodeData['name'], item, len(nodeInfo)))
            if node_name in nodeData['name'] or len(nodeInfo) == 1:
                logging.debug("Got data from node {0} of {1} ".format(node_name, nodeData.get(item)))
                return nodeData.get(item)
        return 'Not Found'


def main():
    '''Command-line parameters and decoding for Zabbix use/consumption.'''
    choices = ['list_queues', 'list_shovels', 'list_nodes', 'queues', 'shovels', 'check_aliveness',
               'server']
    parser = optparse.OptionParser()
    parser.add_option('--username', help='RabbitMQ API username', default='guest')
    parser.add_option('--password', help='RabbitMQ API password', default='guest')
    parser.add_option('--hostname', help='RabbitMQ API host', default=socket.gethostname())
    parser.add_option('--protocol', help='Use http or https', default='http')
    parser.add_option('--port', help='RabbitMQ API port', type='int', default=15672)
    parser.add_option('--check', type='choice', choices=choices, help='Type of check')
    parser.add_option('--metric', help='Which metric to evaluate', default='')
    parser.add_option('--filters', help='Filter used queues (see README)')
    parser.add_option('--node', help='Which node to check (valid for --check=server)')
    parser.add_option('--conf', default='/etc/zabbix/zabbix_agentd.conf')
    parser.add_option('--senderhostname', default='', help='Allows including a sender parameter on calls to zabbix_sender')
    parser.add_option('--logfile', help='File to log errors (defaults to /var/log/zabbix/rabbitmq_zabbix.log)', default='/var/log/zabbix/rabbitmq_zabbix.log')
    parser.add_option('--loglevel', help='Defaults to INFO', default='INFO')
    (options, args) = parser.parse_args()
    if not options.check:
        parser.error('At least one check should be specified')
    logging.basicConfig(filename=options.logfile or "/var/log/zabbix/rabbitmq_zabbix.log", level=logging.getLevelName(options.loglevel or "INFO"), format='%(asctime)s %(levelname)s: %(message)s')

    logging.debug("Started trying to process data")
    api = RabbitMQAPI(user_name=options.username, password=options.password,
                      host_name=options.hostname, port=options.port,
                      conf=options.conf, senderhostname=options.senderhostname,
    	     protocol=options.protocol)
    if options.filters:
        try:
            filters = json.loads(options.filters)
        except KeyError:
            parser.error('Invalid filters object.')
    else:
        filters = [{}]
    if not isinstance(filters, (list, tuple)):
        filters = [filters]
    if options.check == 'list_queues':
        print json.dumps({'data': api.list_queues(filters)})
    elif options.check == 'list_nodes':
        print json.dumps({'data': api.list_nodes()})
    elif options.check == 'list_shovels':
        print json.dumps({'data': api.list_shovels()})
    elif options.check == 'queues':
        print api.check_queue(filters)
    elif options.check == 'shovels':
        print api.check_shovel(filters)
    elif options.check == 'check_aliveness':
        print api.check_aliveness()
    elif options.check == 'server':
        if not options.metric:
            parser.error('Missing required parameter: "metric"')
        else:
            if options.node:
                print api.check_server(options.metric, options.node)
            else:
                print api.check_server(options.metric, api.host_name)

if __name__ == '__main__':
    main()
```

```bash
cat list_rabbit_nodes.sh 
```

```bash
#!/bin/bash
#
# https://github.com/jasonmcintosh/rabbitmq-zabbix
#
cd "$(dirname "$0")"
. .rab.auth

if [[ -z "$HOSTNAME" ]]; then
    HOSTNAME=`hostname`
fi
if [[ -z "$NODE" ]]; then
    NODE=`hostname`
fi

./api.py --username=$USERNAME --password=$PASSWORD --check=list_nodes --filter="$FILTER" --conf=$CONF --hostname=$HOSTNAME --node="$NODE" --loglevel=${LOGLEVEL} --logfile=${LOGFILE} --port=$PORT --protocol=$PROTOCOL
```

```bash
cat list_rabbit_queues.sh 
```

```bash
#!/bin/bash
#
# https://github.com/jasonmcintosh/rabbitmq-zabbix
#
cd "$(dirname "$0")"
. .rab.auth

if [[ -z "$HOSTNAME" ]]; then
    HOSTNAME=`hostname`
fi
if [[ -z "$NODE" ]]; then
    NODE=`hostname`
fi

./api.py --username=$USERNAME --password=$PASSWORD --check=list_queues --filter="$FILTER" --conf=$CONF --hostname=$HOSTNAME --node="$NODE"  --loglevel=${LOGLEVEL} --logfile=${LOGFILE} --port=$PORT --protocol=$PROTOCOL
```

```bash
cat list_rabbit_shovels.sh 
```

```bash
#!/bin/bash
#
# https://github.com/jasonmcintosh/rabbitmq-zabbix
#
cd "$(dirname "$0")"
. .rab.auth

if [[ -z "$HOSTNAME" ]]; then
    HOSTNAME=`hostname`
fi
if [[ -z "$NODE" ]]; then
    NODE=`hostname`
fi


./api.py --username=$USERNAME --password=$PASSWORD --check=list_shovels --filter="$FILTER"  --hostname=$HOSTNAME --node="$NODE"  --conf=$CONF  --loglevel=${LOGLEVEL} --logfile=${LOGFILE} --port=$PORT --protocol=$PROTOCOL
```

```bash
cat rabbitmq-status.sh 
```

```bash
#!/bin/bash
#
# https://github.com/jasonmcintosh/rabbitmq-zabbix
#
# UserParameter=rabbitmq[*],<%= zabbix_script_dir %>/rabbitmq-status.sh
cd "$(dirname "$0")"

. .rab.auth

TYPE_OF_CHECK=$1
METRIC=$2
NODE=$3

if [[ -z "$HOSTNAME" ]]; then
    HOSTNAME=`hostname`
fi
if [[ -z "$NODE" ]]; then
    NODE=`hostname`
fi
# rabbitmq[queues]
# rabbitmq[server,disk_free]
# rabbitmq[check_aliveness]

# This assumes that the server is going to then use zabbix_sender to feed the data BACK to the server.  Right now, I'm doing that
# in the python script

./api.py --hostname=$HOSTNAME --username=$USERNAME --password=$PASSWORD --check=$TYPE_OF_CHECK --metric=$METRIC --node="$NODE" --filters="$FILTER" --conf=$CONF  --loglevel=${LOGLEVEL} --logfile=${LOGFILE} --port=$PORT --protocol=$PROTOCOL
```

```bash
cat ../rabbitmq/.rab.auth   # this require create
```

```ini
USERNAME=zabbix
PASSWORD=pass
CONF=/etc/zabbix/zabbix_agent.conf
LOGLEVEL=INFO
LOGFILE=/var/log/zabbix/rabbitmq_zabbix.log
PORT=15672
```

```bash
cat zabbix_agentd.d/zabbix-rabbitmq.conf 
```

```ini
UserParameter=rabbitmq.discovery_queues,/etc/zabbix/scripts/rabbitmq/list_rabbit_queues.sh
UserParameter=rabbitmq.discovery_shovels,/etc/zabbix/scripts/rabbitmq/list_rabbit_shovels.sh
UserParameter=rabbitmq.discovery_nodes,/etc/zabbix/scripts/rabbitmq/list_rabbit_nodes.sh
UserParameter=rabbitmq[*],/etc/zabbix/scripts/rabbitmq/rabbitmq-status.sh $1 $2 $3
```

SET rabbitmq monitor user：

```bash
rabbitmqctl add_user zabbix pass
rabbitmqctl set_user_tags zabbix monitoring
rabbitmqctl set_permissions -p / zabbix '.*' '.*' '.*'
```

set rabbitmq-zabbix.log permissions：

```bash
chown root:zabbix /var/log/zabbix/rabbitmq_zabbix.log
chmod 770 /var/log/zabbix/rabbitmq_zabbix.log
```

### 6.4 monitor for elasticsearch

参考：
- https://github.com/RuslanMahotkin/zabbix
- https://github.com/dominictarr/JSON.sh

安装 zabbix-sender 插件。

> 这个脚本我更改过才有值，原作者的脚本在 elasticsearch 7.1.1 中没有获取值，原作者脚本放在下面。

```bash
cat elasticsearch_stat.sh
```

```bash
#!/bin/bash
CurlAPI(){
 RespStr=$(/usr/bin/curl --max-time 20 --no-keepalive --silent "http://127.0.0.1:9200/$1" | /etc/zabbix/JSON.sh -l 2>/dev/null | sed -e 's/\[//g' -e 's/\]//g' -e 's/\"//g')
 [ $? != 0 ] && echo 0 && exit 1
}

CurlAPI '_cluster/health'
OutStr=$((cat <<EOF
$RespStr
EOF
) | awk -F\\t '$1~/^((active_primary|active|initializing|relocating|unassigned)_shards|(number_of_data|number_of)_nodes|status)$/ {
 if( $2 == "green"  ) $2 = 0
 if( $2 == "yellow" ) $2 = 1
 if( $2 == "red"    ) $2 = 2
 print "- elasticsearch.cluster." $1, int($2)
}')

CurlAPI '_nodes/_local/stats/indices,jvm'
OutStr1=$((cat <<EOF
$RespStr
EOF
) |awk -F, -v OFS='.' ' {print $3,$4,$5,$6,$7,$8,$9,$10}' | sed 's/\.\.\+//g' | awk -F\\t '$1~/(indices.(docs.(count|deleted)|store.size_in_bytes|indexing.(index_total|index_current|delete_total|delete_current)|get.(total|exists_total|missing_total|current)|search.(open_contexts|query_total|query_current|fetch_total|fetch_current)|merges.(current|current_docs|current_size_in_bytes|total|total_docs|total_size_in_bytes)|(refresh|flush).total|warmer.(current|total)|(filter_cache|id_cache|fielddata).memory_size_in_bytes|percolate.(total|current|memory_size_in_bytes|queries)|completion.size_in_bytes|segments.(count|memory_in_bytes)|translog.(operations|size_in_bytes)|suggest.(total|current))|jvm.(mem.(heap_(used|committed)_in_bytes|non_heap_(used|committed)_in_bytes)|threads.count))$/ {
 print "- elasticsearch.nodes." $1, int($2)
}')

(cat <<EOF
$OutStr
$OutStr1
EOF
) | /usr/bin/zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --host=`hostname` --input-file - >/dev/null 2>&1
echo 1
exit 0
```

```bash
cat elasticsearch_stat.sh.source  # is source author
```

```bash
#!/bin/bash
CurlAPI(){
 RespStr=$(/usr/bin/curl --max-time 20 --no-keepalive --silent "http://127.0.0.1:9200/$1" | /etc/zabbix/JSON.sh -l 2>/dev/null)
 [ $? != 0 ] && echo 0 && exit 1
}

CurlAPI '_cluster/health'
OutStr=$((cat <<EOF
$RespStr
EOF
) | awk -F\\t '$1~/^((active_primary|active|initializing|relocating|unassigned)_shards|(number_of_data|number_of)_nodes|status)$/ {
 if( $2 == "green"  ) $2 = 0
 if( $2 == "yellow" ) $2 = 1
 if( $2 == "red"    ) $2 = 2
 print "- elasticsearch.cluster." $1, int($2)
}')

CurlAPI '_nodes/_local/stats/indices,jvm'
OutStr1=$((cat <<EOF
$RespStr
EOF
) | awk -F\\t '$1~/(indices.(docs.(count|deleted)|store.size_in_bytes|indexing.(index_total|index_current|delete_total|delete_current)|get.(total|exists_total|missing_total|current)|search.(open_contexts|query_total|query_current|fetch_total|fetch_current)|merges.(current|current_docs|current_size_in_bytes|total|total_docs|total_size_in_bytes)|(refresh|flush).total|warmer.(current|total)|(filter_cache|id_cache|fielddata).memory_size_in_bytes|percolate.(total|current|memory_size_in_bytes|queries)|completion.size_in_bytes|segments.(count|memory_in_bytes)|translog.(operations|size_in_bytes)|suggest.(total|current))|jvm.(mem.(heap_(used|committed)_in_bytes|non_heap_(used|committed)_in_bytes)|threads.count))$/ {
 sub("^nodes.[^.]+.", "", $1)
 print "- elasticsearch.nodes." $1, int($2)
}')

(cat <<EOF
$OutStr
$OutStr1
EOF
) | /usr/bin/zabbix_sender --config /etc/zabbix/zabbix_agentd.conf --host=`hostname` --input-file - >/dev/null 2>&1
echo 1
exit 0
```

```bash
cat JSON.sh 
```

```sh
#!/bin/sh

throw() {
  echo "$*" >&2
  exit 1
}

BRIEF=0
LEAFONLY=0
PRUNE=0
NO_HEAD=0
NORMALIZE_SOLIDUS=0

usage() {
  echo
  echo "Usage: JSON.sh [-b] [-l] [-p] [-s] [-h]"
  echo
  echo "-p - Prune empty. Exclude fields with empty values."
  echo "-l - Leaf only. Only show leaf nodes, which stops data duplication."
  echo "-b - Brief. Combines 'Leaf only' and 'Prune empty' options."
  echo "-n - No-head. Do not show nodes that have no path (lines that start with [])."
  echo "-s - Remove escaping of the solidus symbol (straight slash)."
  echo "-h - This help text."
  echo
}

parse_options() {
  set -- "$@"
  local ARGN=$#
  while [ "$ARGN" -ne 0 ]
  do
    case $1 in
      -h) usage
          exit 0
      ;;
      -b) BRIEF=1
          LEAFONLY=1
          PRUNE=1
      ;;
      -l) LEAFONLY=1
      ;;
      -p) PRUNE=1
      ;;
      -n) NO_HEAD=1
      ;;
      -s) NORMALIZE_SOLIDUS=1
      ;;
      ?*) echo "ERROR: Unknown option."
          usage
          exit 0
      ;;
    esac
    shift 1
    ARGN=$((ARGN-1))
  done
}

awk_egrep () {
  local pattern_string=$1

  gawk '{
    while ($0) {
      start=match($0, pattern);
      token=substr($0, start, RLENGTH);
      print token;
      $0=substr($0, start+RLENGTH);
    }
  }' pattern="$pattern_string"
}

tokenize () {
  local GREP
  local ESCAPE
  local CHAR

  if echo "test string" | egrep -ao --color=never "test" >/dev/null 2>&1
  then
    GREP='egrep -ao --color=never'
  else
    GREP='egrep -ao'
  fi

  if echo "test string" | egrep -o "test" >/dev/null 2>&1
  then
    ESCAPE='(\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
    CHAR='[^[:cntrl:]"\\]'
  else
    GREP=awk_egrep
    ESCAPE='(\\\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
    CHAR='[^[:cntrl:]"\\\\]'
  fi

  local STRING="\"$CHAR*($ESCAPE$CHAR*)*\""
  local NUMBER='-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?'
  local KEYWORD='null|false|true'
  local SPACE='[[:space:]]+'

  # Force zsh to expand $A into multiple words
  local is_wordsplit_disabled=$(unsetopt 2>/dev/null | grep -c '^shwordsplit$')
  if [ $is_wordsplit_disabled != 0 ]; then setopt shwordsplit; fi
  $GREP "$STRING|$NUMBER|$KEYWORD|$SPACE|." | egrep -v "^$SPACE$"
  if [ $is_wordsplit_disabled != 0 ]; then unsetopt shwordsplit; fi
}

parse_array () {
  local index=0
  local ary=''
  read -r token
  case "$token" in
    ']') ;;
    *)
      while :
      do
        parse_value "$1" "$index"
        index=$((index+1))
        ary="$ary""$value" 
        read -r token
        case "$token" in
          ']') break ;;
          ',') ary="$ary," ;;
          *) throw "EXPECTED , or ] GOT ${token:-EOF}" ;;
        esac
        read -r token
      done
      ;;
  esac
  [ "$BRIEF" -eq 0 ] && value=$(printf '[%s]' "$ary") || value=
  :
}

parse_object () {
  local key
  local obj=''
  read -r token
  case "$token" in
    '}') ;;
    *)
      while :
      do
        case "$token" in
          '"'*'"') key=$token ;;
          *) throw "EXPECTED string GOT ${token:-EOF}" ;;
        esac
        read -r token
        case "$token" in
          ':') ;;
          *) throw "EXPECTED : GOT ${token:-EOF}" ;;
        esac
        read -r token
        parse_value "$1" "$key"
        obj="$obj$key:$value"        
        read -r token
        case "$token" in
          '}') break ;;
          ',') obj="$obj," ;;
          *) throw "EXPECTED , or } GOT ${token:-EOF}" ;;
        esac
        read -r token
      done
    ;;
  esac
  [ "$BRIEF" -eq 0 ] && value=$(printf '{%s}' "$obj") || value=
  :
}

parse_value () {
  local jpath="${1:+$1,}$2" isleaf=0 isempty=0 print=0
  case "$token" in
    '{') parse_object "$jpath" ;;
    '[') parse_array  "$jpath" ;;
    # At this point, the only valid single-character tokens are digits.
    ''|[!0-9]) throw "EXPECTED value GOT ${token:-EOF}" ;;
    *) value=$token
       # if asked, replace solidus ("\/") in json strings with normalized value: "/"
       [ "$NORMALIZE_SOLIDUS" -eq 1 ] && value=$(echo "$value" | sed 's#\\/#/#g')
       isleaf=1
       [ "$value" = '""' ] && isempty=1
       ;;
  esac
  [ "$value" = '' ] && return
  [ "$NO_HEAD" -eq 1 ] && [ -z "$jpath" ] && return

  [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 0 ] && print=1
  [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && [ $PRUNE -eq 0 ] && print=1
  [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 1 ] && [ "$isempty" -eq 0 ] && print=1
  [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && \
    [ $PRUNE -eq 1 ] && [ $isempty -eq 0 ] && print=1
  [ "$print" -eq 1 ] && printf "[%s]\t%s\n" "$jpath" "$value"
  :
}

parse () {
  read -r token
  parse_value
  read -r token
  case "$token" in
    '') ;;
    *) throw "EXPECTED EOF GOT $token" ;;
  esac
}

if ([ "$0" = "$BASH_SOURCE" ] || ! [ -n "$BASH_SOURCE" ]);
then
  parse_options "$@"
  tokenize | parse
fi

# vi: expandtab sw=2 ts=2
```

```bash
cat elasticsearch_stat.conf 
UserParameter		= elasticsearch_status,/etc/zabbix/elasticsearch_stat.sh
chmod 750 elasticsearch_stat.sh
chgrp zabbix elasticsearch_stat.sh
chmod 750 JSON.sh   # JSON.sh AND elasticsearch_stat.sh will together
chgrp zabbix JSON.sh
systemctl restart redis-agent
```

---

## 第七章 docker 安装 zabbix 3.4

### 7.1 安装 mysql

```bash
docker run --name zabbix-mysql-server --hostname zabbix-mysql-server \
-e MYSQL_ROOT_PASSWORD="123456" \
-e MYSQL_USER="zabbix" \
-e MYSQL_PASSWORD="123456" \
-e MYSQL_DATABASE="zabbix" \
-v /data/docker/zabbix/mysql/data:/var/lib/mysql \
-p 33061:3306 \
-d mysql:5.7 \
--character-set-server=utf8 --collation-server=utf8_bin
```

### 7.2 创建 zabbix server

```bash
docker run  --name zabbix-server-mysql --hostname zabbix-server-mysql \
--link zabbix-mysql-server:mysql \
-e DB_SERVER_HOST="mysql" \
-e MYSQL_USER="zabbix" \
-e MYSQL_DATABASE="zabbix" \
-e MYSQL_PASSWORD="123456" \
-v /etc/localtime:/etc/localtime:ro \
-v /data/docker/zabbix/zabbix-server/alertscripts:/usr/lib/zabbix/alertscripts \
-v /data/docker/zabbix/zabbix-server/externalscripts:/usr/lib/zabbix/externalscripts \
-p 10051:10051 \
-d \
zabbix/zabbix-server-mysql:centos-3.4.15
```

### 7.3 安装 nginx web front

```bash
docker run --name zabbix-web-nginx-mysql --hostname zabbix-web-nginx-mysql \
--link zabbix-mysql-server:mysql \
--link zabbix-server-mysql:zabbix-server \
-e DB_SERVER_HOST="mysql" \
-e MYSQL_USER="zabbix" \
-e MYSQL_PASSWORD="123456" \
-e MYSQL_DATABASE="zabbix" \
-e ZBX_SERVER_HOST="zabbix-server" \
-e PHP_TZ="Asia/Shanghai" \
-p 80:80 \
-d \
zabbix/zabbix-web-nginx-mysql:centos-3.4.15
```

### 7.4 docker-compose 安装 zabbix3.4

```bash
cat /data/docker/zabbix/docker-compose.yml 
```

```yaml
version: '3.4'
services:
  zabbix-mysql-server:                    # 服务名称
    image: mysql:5.7      # 使用的镜像
    container_name: zabbix-mysql-server   # 容器名称
    hostname: zabbix-mysql-server
    restart: always                 # 失败自动重启策略
    environment:                                    
      - MYSQL_ROOT_PASSWORD=123456
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=123456
      - MYSQL_DATABASE=zabbix
    volumes:
      - /data/docker/zabbix/mysql/data:/var/lib/mysql
    ports:
      - 33061:3306
    command: 
      - --character-set-server=utf8
      - --collation-server=utf8_bin
  zabbix-server-mysql:                    # 服务名称
    image: zabbix/zabbix-server-mysql:centos-3.4.15      # 使用的镜像
    container_name: zabbix-server-mysql   # 容器名称
    hostname: zabbix-server-mysql
    links:
      - zabbix-mysql-server:mysql
    restart: always                 # 失败自动重启策略
    environment:                                    
      - DB_SERVER_HOST=mysql
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=123456
      - MYSQL_DATABASE=zabbix
    depends_on:
      - zabbix-mysql-server
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /data/docker/zabbix/zabbix-server/alertscripts:/usr/lib/zabbix/alertscripts
      - /data/docker/zabbix/zabbix-server/externalscripts:/usr/lib/zabbix/externalscripts
    ports:
      - 10051:10051
  zabbix-web-nginx-mysql:                    # 服务名称
    image: zabbix/zabbix-web-nginx-mysql:centos-3.4.15     # 使用的镜像
    container_name: zabbix-web-nginx-mysql   # 容器名称
    hostname: zabbix-web-nginx-mysql
    links:
      - zabbix-mysql-server:mysql
      - zabbix-server-mysql:zabbix-server
    restart: always                 # 失败自动重启策略
    environment:    
      - DB_SERVER_HOST=mysql
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=123456
      - MYSQL_DATABASE=zabbix
      - ZBX_SERVER_HOST=zabbix-server
      - PHP_TZ=Asia/Shanghai
    depends_on:
      - zabbix-mysql-server
      - zabbix-server-mysql
    ports:
      - 80:80
networks:
  default:
    driver: bridge
```

### 7.5 zabbix for docker（部署 zabbix）

mysql、zabbix-server-mysql、zabbix-web-nginx-mysql DEPLOY。

```bash
cat /data/docker/zabbix/docker-compose.yml 
```

```yaml
version: '3.4'
services:
  zabbix-mysql-server:                    # 服务名称
    image: jackidocker/mysql:5.7      # 使用的镜像
    container_name: zabbix-mysql-server   # 容器名称
    hostname: zabbix-mysql-server
    restart: always                 # 失败自动重启策略
    environment:                                    
      - MYSQL_ROOT_PASSWORD=123456		# `=` 号以后都是密码
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=123456
      - MYSQL_DATABASE=zabbix
    volumes:
      - /data/docker/zabbix/mysql/data:/var/lib/mysql
    ports:
      - 33061:3306
    command: 
      - --character-set-server=utf8
      - --collation-server=utf8_bin
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          memory: 200M
  zabbix-server-mysql:                    # 服务名称
    image: jackidocker/zabbix-server-mysql:centos-3.4.15      # 使用的镜像
    container_name: zabbix-server-mysql   # 容器名称
    hostname: zabbix-server-mysql
    links:
      - zabbix-mysql-server:mysql
    restart: always                 # 失败自动重启策略
    environment:                                    
      - DB_SERVER_HOST=mysql
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=123456
      - MYSQL_DATABASE=zabbix
    depends_on:
      - zabbix-mysql-server
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /data/docker/zabbix/zabbix-server/alertscripts:/usr/lib/zabbix/alertscripts
      - /data/docker/zabbix/zabbix-server/externalscripts:/usr/lib/zabbix/externalscripts
    ports:
      - 10051:10051
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 200M
        reservations:
          memory: 50M
  zabbix-web-nginx-mysql:                    # 服务名称
    image: jackidocker/zabbix-web-nginx-mysql:centos-3.4.15     # 使用的镜像
    container_name: zabbix-web-nginx-mysql   # 容器名称
    hostname: zabbix-web-nginx-mysql
    links:
      - zabbix-mysql-server:mysql
      - zabbix-server-mysql:zabbix-server
    restart: always                 # 失败自动重启策略
    environment:    
      - DB_SERVER_HOST=mysql
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=123456
      - MYSQL_DATABASE=zabbix
      - ZBX_SERVER_HOST=zabbix-server
      - PHP_TZ=Asia/Shanghai
    volumes:
      - /data/docker/zabbix/graphfont.ttf:/usr/share/zabbix/fonts/graphfont.ttf   
    depends_on:
      - zabbix-mysql-server
      - zabbix-server-mysql
    ports:
      - 80:80
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 500M
        reservations:
          memory: 100M
networks:
  default:
    driver: bridge
```

zabbix-server-mysql、zabbix-web-nginx-mysql DEPLOY：

```bash
cat /shell/docker-compose.yml 
```

```yaml
version: '3.4'
services:
  zabbix-server-mysql:                   
    image: zabbix/zabbix-server-mysql:centos-3.4.15
    container_name: zabbix-server-mysql   
    hostname: zabbix-server-mysql
    restart: always
    environment:                                    
      - DB_SERVER_HOST=mysql.test.com
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=aaa123456
      - MYSQL_DATABASE=zabbix
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /data/docker/zabbix/zabbix-server/alertscripts:/usr/lib/zabbix/alertscripts
      - /data/docker/zabbix/zabbix-server/externalscripts:/usr/lib/zabbix/externalscripts
    ports:
      - 10051:10051
    dns:
      - 192.168.10.250
      - 192.168.10.110
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 500M
        reservations:
          memory: 100M
  zabbix-web-nginx-mysql:            
    image: zabbix/zabbix-web-nginx-mysql:centos-3.4.15
    container_name: zabbix-web-nginx-mysql 
    hostname: zabbix-web-nginx-mysql
    links:
      - zabbix-server-mysql:zabbix-server
    restart: always        
    environment:    
      - DB_SERVER_HOST=mysql.test.com
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=aaa123456
      - MYSQL_DATABASE=zabbix
      - ZBX_SERVER_HOST=zabbix-server
      - PHP_TZ=Asia/Shanghai
    volumes:
      - /data/docker/zabbix/zabbix-web-nginx/graphfont.ttf:/usr/share/zabbix/fonts/graphfont.ttf
    depends_on:
      - zabbix-server-mysql
    ports:
      - 80:80
    dns:
      - 192.168.10.250
      - 192.168.10.110
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 500M
        reservations:
          memory: 100M
networks:
  default:
    driver: bridge
```

> 注：默认用户 Admin，默认密码 zabbix。

### 7.6 zabbix-server-mysql 启动不了的问题

如果 zabbix-server-mysql 启动不了，是因为配置缓存（CacheSize）过小或者系统整体内存不足所致。

**问题报错：**

```text
** Starting Zabbix server
Starting Zabbix Server. Zabbix 3.4.15 (revision 86739).
Press Ctrl+C to exit.

   128:20241205:192107.848 Starting Zabbix Server. Zabbix 3.4.15 (revision 86739).
   128:20241205:192107.849 ****** Enabled features ******
   128:20241205:192107.849 SNMP monitoring:           YES
   128:20241205:192107.849 IPMI monitoring:           YES
   128:20241205:192107.849 Web monitoring:            YES
   128:20241205:192107.849 VMware monitoring:         YES
   128:20241205:192107.849 SMTP authentication:       YES
   128:20241205:192107.849 Jabber notifications:      YES
   128:20241205:192107.849 Ez Texting notifications:  YES
   128:20241205:192107.849 ODBC:                      YES
   128:20241205:192107.849 SSH2 support:              YES
   128:20241205:192107.849 IPv6 support:              YES
   128:20241205:192107.849 TLS support:               YES
   128:20241205:192107.849 ******************************
   128:20241205:192107.849 using configuration file: /etc/zabbix/zabbix_server.conf
   128:20241205:192115.876 current database version (mandatory/optional): 03040000/03040007
   128:20241205:192115.876 required mandatory version: 03040000
   128:20241205:192120.911 __mem_malloc: skipped 0 asked 80 skip_min 4294967295 skip_max 0
   128:20241205:192120.911 [file:dbconfig.c,line:90] zbx_mem_malloc(): out of memory (requested 80 bytes)
   128:20241205:192120.911 [file:dbconfig.c,line:90] zbx_mem_malloc(): please increase CacheSize configuration parameter
   128:20241205:192120.911 === memory statistics for configuration cache ===
   128:20241205:192120.911 free chunks of size     24 bytes:       36
   128:20241205:192120.911 free chunks of size     32 bytes:        3
   128:20241205:192120.911 free chunks of size     40 bytes:        4
   128:20241205:192120.911 free chunks of size     48 bytes:        1
   128:20241205:192120.911 free chunks of size     56 bytes:        8
   128:20241205:192120.911 free chunks of size     64 bytes:        1
   128:20241205:192120.911 free chunks of size     72 bytes:        4
   128:20241205:192120.911 min chunk size:         24 bytes
   128:20241205:192120.911 max chunk size:         72 bytes
   128:20241205:192120.911 memory of total size 7129936 bytes fragmented into 59465 chunks
   128:20241205:192120.911 of those,       1968 bytes are in       57 free chunks
   128:20241205:192120.911 of those,    6176544 bytes are in    59408 used chunks
   128:20241205:192120.911 ================================
   128:20241205:192120.911 === Backtrace: ===
   128:20241205:192120.913 12: /usr/sbin/zabbix_server(zbx_backtrace+0x35) [0x56060ae30a0d]
   128:20241205:192120.913 11: /usr/sbin/zabbix_server(__zbx_mem_malloc+0x163) [0x56060ae2c929]
   128:20241205:192120.913 10: /usr/sbin/zabbix_server(+0xb9fd1) [0x56060ae00fd1]
   128:20241205:192120.913 9: /usr/sbin/zabbix_server(zbx_hashset_insert_ext+0x2d4) [0x56060ae35bdf]
   128:20241205:192120.913 8: /usr/sbin/zabbix_server(zbx_hashset_insert+0x2d) [0x56060ae35909]
   128:20241205:192120.913 7: /usr/sbin/zabbix_server(+0xba9f1) [0x56060ae019f1]
   128:20241205:192120.913 6: /usr/sbin/zabbix_server(+0xc0f06) [0x56060ae07f06]
   128:20241205:192120.913 5: /usr/sbin/zabbix_server(DCsync_configuration+0xc48) [0x56060ae0b61f]
   128:20241205:192120.913 4: /usr/sbin/zabbix_server(MAIN_ZABBIX_ENTRY+0x5fa) [0x56060ad874e4]
   128:20241205:192120.913 3: /usr/sbin/zabbix_server(daemon_start+0x32b) [0x56060ae30258]
   128:20241205:192120.913 2: /usr/sbin/zabbix_server(main+0x31e) [0x56060ad86ee8]
   128:20241205:192120.914 1: /lib64/libc.so.6(__libc_start_main+0xf5) [0x7eff3bc39445]
   128:20241205:192120.914 0: /usr/sbin/zabbix_server(+0x344d9) [0x56060ad7b4d9]
```

**解决办法：增加缓存大小**

```bash
vim /etc/zabbix/zabbix_server.conf
CacheSize=256M
```

### 7.7 测试 snmp

zabbix-server 安装 snmpget 工具：

```bash
yum -y install net-snmp-utils
```

测试是否可获取值：

```bash
snmpget -v 2c -c public 192.168.0.201 .1.3.6.1.4.1.674.10892.2.1.1.2.0
```

```text
SNMPv2-SMI::enterprises.674.10892.2.1.1.2.0 = STRING: "iDRAC6"
```

注：值为 iDRAC6，类型是 string。

使用 snmpwalk 命令获取父 OID 下所有子 OID 的 key 和值：

```bash
snmpwalk -v 2c -c public 192.168.0.202 1.3.6.1.4.1.674.10892.5.4.1100.90.1.2.1
```

```text
SNMPv2-SMI::enterprises.674.10892.5.4.1100.90.1.2.1.1 = INTEGER: 1
SNMPv2-SMI::enterprises.674.10892.5.4.1100.90.1.2.1.2 = INTEGER: 2
SNMPv2-SMI::enterprises.674.10892.5.4.1100.90.1.2.1.3 = INTEGER: 3
SNMPv2-SMI::enterprises.674.10892.5.4.1100.90.1.2.1.4 = INTEGER: 4
```

注：值为 1、2、3、4，类型是 INTEGER。

```bash
snmpwalk -v 2c -c public 192.168.0.202 1.3.6.1.4.1.674.10892.5.4.1100.90.1.3.1.1
```

```text
SNMPv2-SMI::enterprises.674.10892.5.4.1100.90.1.3.1.1 = INTEGER: 3
```

```bash
snmpwalk -v 2c -c public 192.168.0.202 1.3.6.1.4.1.674.10892.5.4.1100.90.1.3.1.2
```

```text
SNMPv2-SMI::enterprises.674.10892.5.4.1100.90.1.3.1.2 = INTEGER: 3
```

```bash
snmpwalk -v 2c -c public 192.168.0.202 1.3.6.1.4.1.674.10892.5.4.1100.90.1.3.1.3
```

```text
SNMPv2-SMI::enterprises.674.10892.5.4.1100.90.1.3.1.3 = INTEGER: 3
```

```bash
snmpwalk -v 2c -c public 192.168.0.202 1.3.6.1.4.1.674.10892.5.4.1100.90.1.3.1.4
```

```text
SNMPv2-SMI::enterprises.674.10892.5.4.1100.90.1.3.1.4 = INTEGER: 3
```

在 Discovery rules 中建立发现规则：

- Name: Network Enumeration
- Type: SNMPv2 agent
- Key: NetworkEnum
- SNMP OID: `discovery[{#NETIF},1.3.6.1.4.1.674.10892.5.4.1100.90.1.2.1]`，此 `discovery[]` 函数为 zabbix 内置函数，作用是使用 snmpwalk 命令获取父 OID `1.3.6.1.4.1.674.10892.5.4.1100.90.1.2.1` 下所有子 OID 的 key 和值，并且赋值给变量数组 `{#NETIF}`。
- SNMP community: `{$SNMP_COMMUNITY}`
- Update interval: 7200

在 Discovery rules 中新建的 Network Enumeration 中建立 item prototypes：

- Name: 网卡 {#NETIF} : 连接状态。此变量数组就是在 Network Enumeration 中建立的，这里会引用此变量数组的所有值并且遍历，就是会有网卡 1 : 连接状态、网卡 2 : 连接状态、网卡 3 : 连接状态、网卡 4 : 连接状态这些 item 产生。
- Type: SNMPv2 agent
- Key: `NetConnStatus.[{#SNMPINDEX}]`。此 `{#SNMPINDEX}` 变量数组是 zabbix 内置的变量，此变量的值是此变量数组 `{#NETIF}` 中所有子 OID 标签符最后一位，就是 `1.3.6.1.4.1.674.10892.5.4.1100.90.1.2.1` 中的最后一位，结果是 1、2、3、4。
- SNMP OID: `1.3.6.1.4.1.674.10892.5.4.1100.90.1.4.1.{#SNMPINDEX}`。此 OID 就是要具体查找的 oid，这个 oid 结合 `1.3.6.1.4.1.674.10892.5.4.1100.90.1.2.1` 中的最后一位，结果是 `1.3.6.1.4.1.674.10892.5.4.1100.90.1.4.1.1`、`1.3.6.1.4.1.674.10892.5.4.1100.90.1.4.1.2` 等。
- SNMP community: `{$SNMP_COMMUNITY}`
- Type of information: Numeric(unsigned)
- Update interval: 120
- Show value: Dell iDRAC Network Device Connections Status（引用值映射模板）
- Applications: Network Cards

### 7.8 配置 zabbix-web 端

1. 下载模板：Dell idrac(chinese)。

   模板共享网址：https://share.zabbix.com/
   下载 URL：https://share.zabbix.com/index.php?option=com_mtree&task=att_download&link_id=659&cf_id=40

2. 把下载的模板导入到 zabbix_server 中。配置 - 模板 - 选择文件 - 导入。

   - 将 item 为型号的配置进行更改：Populates host inventory field 为 None。

3. 添加监控服务器。配置 - 主机 - 创建主机。

   1. 填写 snmp 相关信息。端口为 161。
   2. 在"模板"栏中链接模板 Template Server Dell iDRAC SNMPv2。
   3. 在"宏菜单"栏中设置团体名称：`{$SNMP_COMMUNITY}` ==> public。
   4. 修改最新的数据是否正常。

4. 监控告警。

   安装 mailx 软件，提供发送邮件功能：

   ```bash
   yum install -y mailx
   ```

   修改 `/etc/mail.rc`，最后面增加：

   ```bash
   vi /etc/mail.rc
   ```

   ```ini
   set from=prometheus@homsom.com
   set smtp=smtp.qiye.163.com
   set smtp-auth=login
   set smtp-auth-user=username
   set smtp-auth-password=password
   set ssl-verify=ignore
   set nss-config-dir=/etc/aildbs/
   ```

   邮件发送脚本：

   ```bash
   cat email.sh 
   ```

   ```bash
   #!/bin/bash
   # send mail
   messages=`echo $3 | tr '\r\n' '\n'`
   subject=`echo $2 | tr '\r\n' '\n'`
   echo "${messages}" | mail -s "${subject}" $1 >>/tmp/mailx.log 2>&1
   ```

   钉钉发送脚本：

   ```bash
   cat dingding.sh 
   ```

   ```bash
   #!/bin/bash
   header="Content-Type: application/json;charset=utf-8"
   url="https://oapi.dingtalk.com/robot/send?access_token=546b346e9ddc0bbcf180f203f2cd446565893ec50100c467f808e50ba7f3c5d2"
   txt='{
         "msgtype":"text",
             "text":{
                    "content":"'$1'"
                    },
             "at":{
                    "atMobiles":["'$2'"],
                    "isAtAll":false
                    }
        }'
   curl  -X POST "${url}" -H "${header}"  -d "${txt}"
   ```

   添加告警类型：

   - Name: email-homsom
   - Type: Script
   - Script name: email.sh
   - Script parameters:
     - `{ALERT.SENDTO}`
     - `{ALERT.SUBJECT}`
     - `{ALERT.MESSAGE}`

   - Name: dingding-homsom
   - Type: Script
   - Script name: dingding.sh
   - Script parameters:
     - `{ALERT.MESSAGE}`
     - `{ALERT.SENDTO}`

> 注：邮件收到信息显示中文乱码，建议使用英文。

---

## 第八章 zabbix 3.4.15 部署

### 8.1 docker 部署

环境：

| 名称            | 角色          | 描述                                     |
| --------------- | ------------- | ---------------------------------------- |
| zabbix-server01 | zabbix-server | zabbix 节点 1                            |
| zabbix-server02 | zabbix-server | zabbix 节点 2                            |
| zabbix-proxy    | zabbix 代理   | 代理 zabbix-server 收集数据给 zabbix-server |
| mysql.test.com  | mysql 集群    | 确保 zabbix-server 集群高可用            |

#### 8.1.1 zabbix-server01

依赖文件：

```bash
cat /data/docker/zabbix/zabbix-server/zabbix_server.conf 
```

```ini
LogType=console
DBHost=mysql.test.com
DBName=zabbix
DBUser=zabbix
DBPassword=aaa123456
DBPort=3306
AlertScriptsPath=/usr/lib/zabbix/alertscripts
ExternalScripts=/usr/lib/zabbix/externalscripts
FpingLocation=/usr/sbin/fping
Fping6Location=/usr/sbin/fping6
SSHKeyLocation=/var/lib/zabbix/ssh_keys
SSLCertLocation=/var/lib/zabbix/ssl/certs/
SSLKeyLocation=/var/lib/zabbix/ssl/keys/
SSLCALocation=/var/lib/zabbix/ssl/ssl_ca/
LoadModulePath=/var/lib/zabbix/modules/
StartJavaPollers=4
JavaGateway=127.0.0.1
CacheSize=256M
Timeout=30
```

```bash
ls /data/docker/zabbix/zabbix-server/alertscripts
```

```text
dingding.sh  email.sh
```

```bash
cat /data/docker/zabbix/zabbix-server/alertscripts/dingding.sh 
```

```bash
#!/bin/bash
header="Content-Type: application/json;charset=utf-8"
url="https://oapi.dingtalk.com/robot/send?access_token=XXXXXX"
txt='{
      "msgtype":"text",
          "text":{
                 "content":"'$1'"
                 },
          "at":{
                 "atMobiles":["'$2'"],
                 "isAtAll":false
                 }
     }'
curl  -X POST "${url}" -H "${header}"  -d "${txt}"
```

```bash
cat /data/docker/zabbix/zabbix-server/alertscripts/email.sh 
```

```bash
#!/bin/bash
# send mail
messages=`echo $3 | tr '\r\n' '\n'`
subject=`echo $2 | tr '\r\n' '\n'`
echo "${messages}" | mail -s "${subject}" $1 >>/tmp/mailx.log 2>&1
```

```bash
cat /data/docker/zabbix/zabbix-server/mail.rc
```

```text
....
set from=prometheus@test.com
set smtp=smtp.qiye.163.com
set smtp-auth=login
set smtp-auth-user=prometheus@test.com
set smtp-auth-password=PASSWORD
set ssl-verify=ignore
set nss-config-dir=/etc/aildbs/
```

部署清单（使用新 mysql 数据库部署）：

```bash
cat docker-compose.yml 
```

```yaml
# docker exec -it zabbix-server-mysql bash
# rm -rf /etc/yum.repos.d/* && curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && yum --disablerepo=* --enablerepo=base install -y mailx

version: '3.4'
services:
  zabbix-mysql-server:                   
    image: harborrepo.test.com/ops/zabbix-mysql:5.7
    container_name: zabbix-mysql-server
    hostname: zabbix-mysql-server
    restart: always
    environment:                                    
      - MYSQL_ROOT_PASSWORD=aaa123456
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=aaa123456
      - MYSQL_DATABASE=zabbix
    volumes:
      - /data/docker/zabbix/mysql/data:/var/lib/mysql
    networks:
      zabbix:
        ipv4_address: 172.30.238.10
    ports:
      - 23306:3306
    command: 
      - --character-set-server=utf8
      - --collation-server=utf8_bin
  zabbix-server-mysql:                   
    image: harborrepo.test.com/ops/zabbix/zabbix-server-mysql:centos-3.4.15
    container_name: zabbix-server-mysql   
    hostname: zabbix-server-mysql
    restart: always
    links:
      - zabbix-mysql-server:mysql
    environment:                                    
      - DB_SERVER_HOST=mysql
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=aaa123456
      - MYSQL_DATABASE=zabbix
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /data/docker/zabbix/zabbix-server/alertscripts:/usr/lib/zabbix/alertscripts
      - /data/docker/zabbix/zabbix-server/externalscripts:/usr/lib/zabbix/externalscripts
      - /data/docker/zabbix/zabbix-server/mail.rc:/etc/mail.rc
        # - /data/docker/zabbix/zabbix-server/zabbix_server.conf:/etc/zabbix/zabbix_server.conf
    depends_on:
      - zabbix-mysql-server
    networks:
      zabbix:
        ipv4_address: 172.30.238.11
    ports:
      - 10051:10051
    dns:
      - 192.168.13.186
      - 192.168.13.251
      - 192.168.10.110
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4096M
        reservations:
          memory: 100M
  zabbix-web-nginx-mysql:            
    image: harborrepo.test.com/ops/zabbix/zabbix-web-nginx-mysql:centos-3.4.15
    container_name: zabbix-web-nginx-mysql 
    hostname: zabbix-web-nginx-mysql
    links:
      - zabbix-mysql-server:mysql
      - zabbix-server-mysql:zabbix-server
    restart: always        
    environment:    
      - DB_SERVER_HOST=mysql
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=aaa123456
      - MYSQL_DATABASE=zabbix
      - ZBX_SERVER_HOST=zabbix-server
      - PHP_TZ=Asia/Shanghai
    volumes:
      - /data/docker/zabbix/zabbix-web-nginx/graphfont.ttf:/usr/share/zabbix/fonts/graphfont.ttf
    depends_on:
      - zabbix-mysql-server
      - zabbix-server-mysql
    networks:
      zabbix:
        ipv4_address: 172.30.238.12
    ports:
      - 80:80
    dns:
      - 192.168.13.186
      - 192.168.13.251
      - 192.168.10.110
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4096M
        reservations:
          memory: 100M
networks:
  zabbix:
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.238.0/16
```

使用已有外部数据库部署：

```bash
cat docker-compose-no-mysql.yml 
```

```yaml
# docker exec -it zabbix-server-mysql bash
# rm -rf /etc/yum.repos.d/* && curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && yum --disablerepo=* --enablerepo=base install -y mailx

version: '3.4'
services:
  zabbix-server-mysql:                   
    image: harborrepo.test.com/ops/zabbix/zabbix-server-mysql:centos-3.4.15
    container_name: zabbix-server-mysql   
    hostname: zabbix-server-mysql
    restart: always
    environment:                                    
      - DB_SERVER_HOST=mysql.test.com
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=aaa123456
      - MYSQL_DATABASE=zabbix
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /data/docker/zabbix/zabbix-server/alertscripts:/usr/lib/zabbix/alertscripts
      - /data/docker/zabbix/zabbix-server/externalscripts:/usr/lib/zabbix/externalscripts
      - /data/docker/zabbix/zabbix-server/mail.rc:/etc/mail.rc
      - /data/docker/zabbix/zabbix-server/zabbix_server.conf:/etc/zabbix/zabbix_server.conf
    networks:
      zabbix:
        ipv4_address: 172.30.238.11
    ports:
      - 10051:10051
    dns:
      - 192.168.13.186
      - 192.168.13.251
      - 192.168.10.110
networks:
  zabbix:
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.238.0/16
```

#### 8.1.2 zabbix-server02

依赖配置文件：

```bash
cat /data/docker/zabbix/zabbix-server/zabbix_server.conf 
```

```ini
LogType=console
DBHost=mysql.test.com
DBName=zabbix
DBUser=zabbix
DBPassword=aaa123456
DBPort=3306
AlertScriptsPath=/usr/lib/zabbix/alertscripts
ExternalScripts=/usr/lib/zabbix/externalscripts
FpingLocation=/usr/sbin/fping
Fping6Location=/usr/sbin/fping6
SSHKeyLocation=/var/lib/zabbix/ssh_keys
SSLCertLocation=/var/lib/zabbix/ssl/certs/
SSLKeyLocation=/var/lib/zabbix/ssl/keys/
SSLCALocation=/var/lib/zabbix/ssl/ssl_ca/
LoadModulePath=/var/lib/zabbix/modules/
StartJavaPollers=4
JavaGateway=127.0.0.1
CacheSize=256M
Timeout=30
```

```bash
ls /data/docker/zabbix/zabbix-server/alertscripts
```

```text
dingding.sh  email.sh
```

```bash
cat /data/docker/zabbix/zabbix-server/alertscripts/dingding.sh 
```

```bash
#!/bin/bash
header="Content-Type: application/json;charset=utf-8"
url="https://oapi.dingtalk.com/robot/send?access_token=XXXXXX"
txt='{
      "msgtype":"text",
          "text":{
                 "content":"'$1'"
                 },
          "at":{
                 "atMobiles":["'$2'"],
                 "isAtAll":false
                 }
     }'
curl  -X POST "${url}" -H "${header}"  -d "${txt}"
```

```bash
cat /data/docker/zabbix/zabbix-server/alertscripts/email.sh 
```

```bash
#!/bin/bash
# send mail
messages=`echo $3 | tr '\r\n' '\n'`
subject=`echo $2 | tr '\r\n' '\n'`
echo "${messages}" | mail -s "${subject}" $1 >>/tmp/mailx.log 2>&1
```

```bash
cat /data/docker/zabbix/zabbix-server/mail.rc
```

```text
....
set from=prometheus@test.com
set smtp=smtp.qiye.163.com
set smtp-auth=login
set smtp-auth-user=prometheus@test.com
set smtp-auth-password=PASSWORD
set ssl-verify=ignore
set nss-config-dir=/etc/aildbs/
```

docker 部署清单：

```bash
cat zabbix/docker-compose-no-mysql.yml 
```

```yaml
# docker exec -it zabbix-server-mysql bash
# rm -rf /etc/yum.repos.d/* && curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && yum --disablerepo=* --enablerepo=base install -y mailx

version: '3.4'
services:
  zabbix-server-mysql:                   
    image: zabbix/zabbix-server-mysql:centos-3.4.15
    container_name: zabbix-server-mysql   
    hostname: zabbix-server-mysql
    restart: always
    environment:                                    
      - DB_SERVER_HOST=mysql.test.com
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=aaa123456
      - MYSQL_DATABASE=zabbix
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /data/docker/zabbix/zabbix-server/alertscripts:/usr/lib/zabbix/alertscripts
      - /data/docker/zabbix/zabbix-server/externalscripts:/usr/lib/zabbix/externalscripts
      - /data/docker/zabbix/zabbix-server/mail.rc:/etc/mail.rc
      - /data/docker/zabbix/zabbix-server/zabbix_server.conf:/etc/zabbix/zabbix_server.conf
    networks:
      zabbix:
        ipv4_address: 172.30.238.11
    ports:
      - 10051:10051
    dns:
      - 192.168.13.186
      - 192.168.13.251
      - 192.168.10.110
  zabbix-web-nginx-mysql:            
    image: zabbix/zabbix-web-nginx-mysql:centos-3.4.15
    container_name: zabbix-web-nginx-mysql 
    hostname: zabbix-web-nginx-mysql
    links:
      - zabbix-server-mysql:zabbix-server
    restart: always        
    environment:    
      - DB_SERVER_HOST=mysql.test.com
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=aaa123456
      - MYSQL_DATABASE=zabbix
      - ZBX_SERVER_HOST=zabbix-server
      - PHP_TZ=Asia/Shanghai
    volumes:
      - /data/docker/zabbix/zabbix-web-nginx/graphfont.ttf:/usr/share/zabbix/fonts/graphfont.ttf
    depends_on:
      - zabbix-server-mysql
    networks:
      zabbix:
        ipv4_address: 172.30.238.12
    ports:
      - 80:80
    dns:
      - 192.168.13.186
      - 192.168.13.251
      - 192.168.10.110
networks:
  zabbix:
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.238.0/16
```

#### 8.1.3 zabbix-proxy

依赖配置文件：

```bash
cat /data/docker/zabbix/zabbix-proxy/zabbix_proxy.conf 
```

```ini
# ProxyMode: 0主动，1被动，默认是主动模式
ProxyMode=0
Server=192.168.13.235
ServerPort=10051
Hostname=172.168.2.199
LogType=console
DBHost=mysql
DBName=zabbix_proxy
DBUser=zabbix
DBPassword=aaa123456
DBPort=3306
ExternalScripts=/usr/lib/zabbix/externalscripts
FpingLocation=/usr/sbin/fping
Fping6Location=/usr/sbin/fping6
SSHKeyLocation=/var/lib/zabbix/ssh_keys
SSLCertLocation=/var/lib/zabbix/ssl/certs/
SSLKeyLocation=/var/lib/zabbix/ssl/keys/
SSLCALocation=/var/lib/zabbix/ssl/ssl_ca/
LoadModulePath=/var/lib/zabbix/modules/
CacheSize=256M
Timeout=30
```

部署清单：

```bash
cat zabbix/docker-compose.yml
```

```yaml
version: '3.7'
services:
  zabbix-mysql-server:                   
    image: harborrepo.test.com/ops/zabbix-mysql:5.7
    container_name: zabbix-mysql-server
    hostname: zabbix-mysql-server
    restart: always
    environment:                                    
      - MYSQL_ROOT_PASSWORD=aaa123456
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=aaa123456
      - MYSQL_DATABASE=zabbix_proxy
    volumes:
      - /data/docker/zabbix/mysql/data:/var/lib/mysql
    networks:
      zabbix:
        ipv4_address: 172.30.238.10
    ports:
      - 23306:3306
    command: 
      - --character-set-server=utf8
      - --collation-server=utf8_bin
  zabbix-proxy-mysql:                   
    image: harborrepo.test.com/ops/zabbix/zabbix-proxy-mysql:centos-3.4.15
    container_name: zabbix-proxy-mysql   
    hostname: zabbix-proxy-mysql
    restart: always
    links:
      - zabbix-mysql-server:mysql
    environment:                                    
      - DB_SERVER_HOST=mysql
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=aaa123456
      - MYSQL_DATABASE=zabbix_proxy
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /data/docker/zabbix/zabbix-proxy/zabbix_proxy.conf:/etc/zabbix/zabbix_proxy.conf
    networks:
      zabbix:
        ipv4_address: 172.30.238.11
    ports:
      - 10051:10051
    dns:
      - 192.168.13.186
      - 192.168.13.251
      - 192.168.10.110
networks:
  zabbix:
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.238.0/16
```

> **问题**：如果监控设备添加了 zabbix_proxy 去监控，但是主机界面仍然无法看到有数据，原因如下：
>
> 1. zabbix-proxy 无法获取目标对象数据，例如无法获取 snmp 对象数据，可用命令进行测试：
>
>    ```bash
>    snmpwalk -v2c -c public 192.168.102.15 1.3.6.1.2.1.1.3.0
>    ```
>
> 2. 另外一个原因是 zabbix-proxy 数据缓冲区填满了。如果 Proxy 和 Server 的连接出现问题，且无法及时同步数据，Proxy 的本地缓存可能会填满，导致数据丢失或无法进一步采集。解决办法在 zabbix-server.conf 和 zabbix-proxy.conf 中配置如下参数：
>
>    ```bash
>    CacheSize=256M
>    Timeout=30
>    ```