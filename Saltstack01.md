# Saltstack 自动化运维

## 简介

Saltstack 是由 python 写的，也提供 API，是 REST API。

三大功能：

1. 远程执行
2. 配置管理（状态管理）
3. 云管理

运维三板斧：

1. 监控
2. 执行
3. 配置

Saltstack 竞争对手：

- Puppet（ruby 写的）
- ansible（python 写的）

### Saltstack 四种运行方式

- Local —— 本地运行
- Minion/Master —— 类似 C/S 架构，minion 的中文是奴才
- Syndic —— 可以理解为 Zabbix 的 proxy 一样，Syndic 是 Saltstack 的代理
- Salt SSH —— 以 SSH 方式运行

Saltstack 很难回滚，docker 却可以回滚。

## 第二部分：远程执行

现在安装不用 epel 源来安装了，Saltstack 官方自己做了个源，网站是 repo.saltstack.com，可以从这个网站上找到安装 saltstack 的步骤方法：

```bash
# 安装 Saltstack 的 yum 仓库
yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm

# Saltstack 服务器安装：salt-master + salt-minion
yum install -y salt-master salt-minion

# Saltstack 客户端安装：salt-minion
yum install -y salt-minion

# 启动 Saltstack Server
systemctl start salt-master
```

### 配置 minion

```bash
[root@SaltstackServer salt]# vim /etc/salt/minion
[root@SaltstackServer salt]# grep '^[a-Z]' minion
master: 192.168.1.235
```

```bash
# 启动 salt-minion
[root@SaltstackServer salt]# systemctl start salt-minion
```

注：vim /etc/salt/minion 里面有 id 可设置，不建议随时更改 id，因为你在 minion 配置文件中改了 id 后，重启 minion 服务 /etc/salt/minion_id 还是老的 id，因为 minion 服务会先读 /etc/salt/minion_id 文件，如果它存在，那么配置里设置的 id 就永远不会生效，所以要想设置 id 必须先删除 /etc/salt/minion_id 文件，然后去 minion 配置文件设置 id，重启服务即可自动生成设置 /etc/salt/minion_id 文件。不设置默认值为主机名，例如下：

```bash
[root@SaltstackServer salt]# cat /etc/salt/minion_id
SaltstackServer.com
```

设置并启动第二台 salt-minion 服务：

```bash
root@linux-node1 salt]# vim /etc/salt/minion
[root@linux-node1 salt]# grep '^[a-Z]' /etc/salt/minion
master:192.168.1.235
[root@linux-node1 salt]# systemctl start salt-minion
```

注：minion 找到 master 后说我要当你的 minion（奴才），但是 minion 要经过 master 认证成功后才能真正成为 master 的（minion）奴才，salt 之间的传输是经过 AES 加密传输的。

#### tree minion

```bash
[root@linux-node1 salt]# tree pki
pki
├── master
└── minion
    ├── minion.pem   #私钥
    └── minion.pub   #公钥
```

pki 目录是启动 minion 时启动的，minion 公钥是先发送给 master，后期他们通过对方的公钥进行加密码传输的。

#### tree master

```bash
[root@SaltstackServer salt]# tree pki
pki
├── master
│?? ├── master.pem
│?? ├── master.pub
│?? ├── minions
│?? ├── minions_autosign
│?? ├── minions_denied
│?? ├── minions_pre
│?? │?? ├── linux-node1
│?? │?? └── SaltstackServer.com
│?? └── minions_rejected
└── minion
    ├── minion.pem
    └── minion.pub
```

没有认证之前，minion 都是把自己的公钥发给 master，在 /etc/salt/pki/master/minions_pre/ 目录下的，都是以自己的 id 来命名自己的公钥的，例如 master 端查看的 minion 公钥 md5：

```bash
[root@SaltstackServer salt]# md5sum ./pki/master/minions_pre/linux-node1
d6e378e5c25f89910f000aab3bd477f7  ./pki/master/minions_pre/linux-node1
```

本机 minion 的公钥 md5：

```bash
[root@linux-node1 salt]# md5sum ./pki/minion/minion.pub
d6e378e5c25f89910f000aab3bd477f7  ./pki/minion/minion.pub
```

### 开始认证

同意认证：

```bash
[root@SaltstackServer salt]# salt-key -a linux-node1
The following keys are going to be accepted:
Unaccepted Keys:
linux-node1
Proceed? [n/Y] y
Key for minion linux-node1 accepted.
```

或者：

```bash
[root@SaltstackServer salt]# salt-key -a Salt*
The following keys are going to be accepted:
Unaccepted Keys:
SaltstackServer.com
Proceed? [n/Y] y
Key for minion SaltstackServer.com accepted
```

或者同意所有的 minion：

```bash
[root@SaltstackServer salt]# salt-key -A
The following keys are going to be accepted:
Unaccepted Keys:
linux-node1
Proceed? [n/Y] y
Key for minion linux-node1 accepted.
```

删除认证：

```bash
salt-key -d linux-node1   #此时 linux-node1 minion 是不在 minions_pre 列表中了，所以只能重启 linux-node1 的 minion 才能重新到达 minions_pre 列表中了
```

salt-key -D 是全部删除，删除一般不建议用。

当 master 同意 minion 加入后，master 的公钥就会交换传输在各个 minion 的 /etc/salt/pki/minion/minion_master.pub 文件下，而之前 minion 请求 master 认证时已经把各自的 minion 发给 master 了，所以当 master 同意 minion 认证后就是双方成功交换了公钥，这样一来就可以进行加密传输了。

注：再次重申 id 不要随便更改，否则 master 和 minion 之前的公钥就要重头开始认证交换了，id 主要用 ip 和主机名，游戏公司用 ip 多，电商用主机名，dns 不能解析下划线的，只能解析横杠。记住。

### 远程执行

测试所有 minion 跟 master 之间的密钥通信是否正常，返回值是 True 则代表密钥成功通信，"*" 代表所有 minion 目录，test.ping 是模块加方法。注意这里的 ping 不是 ICMP 的 ping：

```bash
[root@SaltstackServer salt]# salt "*" test.ping
```

```text
linux-node1:
    True
SaltstackServer.com:
    True
```

远程执行命令（创建一个目录，linux 中没有消息就是最好的消息，说明执行成功）：

```bash
[root@SaltstackServer salt]# salt "*" cmd.run "mkdir /tmp/hello"
```

```text
SaltstackServer.com:
linux-node1:
```

列出目录下文件：

```bash
[root@SaltstackServer salt]# salt "*" cmd.run "ls /tmp"
```

```text
linux-node1:
    hello
    hsperfdata_root
    hsperfdata_zabbix
    ks-script-D9q5xY
    ks-script-UpuI3I
    netstat.tmp
    systemd-private-988e6c38a0254330909a8296af7804d5-chronyd.service-hC2Fj9
    vmware-root
    yum.log
SaltstackServer.com:
    hello
    ks-script-7x06oU
    ks-script-tc2L1X
    systemd-private-fc8b6e0ec55f4c21a4151c377b341635-chronyd.service-YsEDRL
    vmware-root
    yum.log
```

## 第二部分：配置管理

state：描述文件，YAML 格式，.sls 后缀结尾。配置文件就是 YAML 格式。

YAML 三板斧：

1. 缩进 —— 2 个空格，禁止使用 tab 键
2. 冒号 —— key: value 键值对中的冒号后面有一个空格，冒号前 2 个空格代表层级关系
3. 短横线 —— - list1 列表短横线后面也有一个空格，千万注意

```bash
[root@SaltstackServer salt]# vim /etc/salt/master
# file_roots:
#   base:
#     - /srv/salt/
#   dev:
#     - /srv/salt/dev/services
#     - /srv/salt/dev/states
#   prod:
#     - /srv/salt/prod/services
#     - /srv/salt/prod/states
#
file_roots:
  base:
    - /srv/salt
```

注：base 名称不能更改，salt 规定，dev 和 prod 可以更改。

```bash
[root@SaltstackServer ~]# systemctl restart salt-master
```

模块分为两种：

1. 执行模块（远程执行用）
2. 状态模块（配置管理用）

```bash
[root@SaltstackServer web]# vim /srv/salt/web/apache.sls
```

```yaml
apache-install:
  pkg.installed:
    - names:
      - httpd
      - httpd-devel

apache-service:
  service.running:
    - name: httpd
    - enable: True
```

执行描述文件给 minion 安装：

```bash
[root@SaltstackServer web]# salt "*" state.sls web.apache
```

minion 下收到 master 的描述文件：

```bash
[root@linux-node1 salt]# cat /var/cache/salt/minion/files/base/web/apache.sls
```

```yaml
apache-install:
  pkg.installed:
    - names:
      - httpd
      - httpd-devel

apache-service:
  service.running:
    - name: httpd
    - enable: True
```

但是生产环境有好多台不同的应用模块，总不能手动一个一个敲响，所以要用到 top.file 文件。vim /etc/salt/master 搜索 top.file 可查看 top.sls 文件放置在哪里。

```text
559 #####      State System settings     #####
560 ##########################################
561 # The state system uses a "top" file to tell the minions what environment to
562 # use and what modules to use. The state_top file is defined relative to the
563 # root of the base environment as defined in "File Server settings" below.
564 #state_top: top.sls
```

从以上描述信息可看到放置在 root(根) 的 base 环境目录下，也就是 /srv/salt 目录下。

```text
674 file_roots:
675   base:
676     - /srv/salt
```

编写 top.sls 文件：

```bash
[root@SaltstackServer /srv/salt]# cat top.sls
```

```yaml
base:
  'linux-node1':
    - web.apache
  'SaltstackServer.com':
    - web.apache
```

测试是否执行成功，重点在 test=True，没有则是执行了：

```bash
[root@SaltstackServer /srv/salt]# salt '*' state.highstate test=True
```

### 发布与订阅模式

salt 4505 端口是发布端口。

```text
tcp        0      0 0.0.0.0:4505            0.0.0.0:*               LISTEN      9262/python
tcp        0      0 0.0.0.0:4506            0.0.0.0:*               LISTEN      9268/python
```

- lsof（list open file）列出打开文件 ip 端口 4505 的状态
- man 2 kill —— 进行 kill(2) 的查询手册
- lsof -i @192.168.1.233 -n —— 查看打开这个 ip 的有哪些

```bash
[root@SaltstackServer /srv/salt]# lsof -i:4505 -n
```

```text
COMMAND     PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
salt-mini  3718 root   21u  IPv4 114430      0t0  TCP 192.168.1.235:46892->192.168.1.235:4505 (ESTABLISHED)
/usr/bin/ 17588 root   16u  IPv4 112757      0t0  TCP *:4505 (LISTEN)
/usr/bin/ 17588 root   18u  IPv4 115485      0t0  TCP 192.168.1.235:4505->192.168.1.233:49712 (ESTABLISHED)
/usr/bin/ 17588 root   19u  IPv4 113389      0t0  TCP 192.168.1.235:4505->192.168.1.235:46892 (ESTABLISHED)
```

在 master 中，4505 端口一直被 minion 连接着（tcp 长连接），所以在 master 中可以很快执行远程命令，例如：cmd.run 'w'。

### 请求与响应模式

4506 端口是 ZeroMQ REP 系统的，默认监听 4506，可通过修改 /etc/salt/master 的 ret_port 参数设置。它是 minion 与 master 通信的端口，比如说 minion 收到 master 的执行命令后，minion 去执行，把执行的返回值通过 4506 端口发送给 master。

```bash
[root@SaltstackServer /srv/salt]# ps -ef | grep salt-master
```

```text
root      9252     1  0 16:40 ?        00:00:00 /usr/bin/python /usr/bin/salt-master
root      9257  9252  0 16:40 ?        00:00:00 /usr/bin/python /usr/bin/salt-master
root      9262  9252  0 16:40 ?        00:00:00 /usr/bin/python /usr/bin/salt-master
root      9263  9252  0 16:40 ?        00:00:00 /usr/bin/python /usr/bin/salt-master
root      9266  9252  0 16:40 ?        00:00:31 /usr/bin/python /usr/bin/salt-master
root      9267  9252  0 16:40 ?        00:00:00 /usr/bin/python /usr/bin/salt-master
root      9268  9267  0 16:40 ?        00:00:00 /usr/bin/python /usr/bin/salt-master
root      9269  9267  0 16:40 ?        00:00:01 /usr/bin/python /usr/bin/salt-master
root      9276  9267  0 16:40 ?        00:00:02 /usr/bin/python /usr/bin/salt-master
root      9277  9267  0 16:40 ?        00:00:01 /usr/bin/python /usr/bin/salt-master
root      9278  9267  0 16:40 ?        00:00:01 /usr/bin/python /usr/bin/salt-master
root      9279  9267  0 16:40 ?        00:00:01 /usr/bin/python /usr/bin/salt-master
root      9280  9252  0 16:40 ?        00:00:06 /usr/bin/python /usr/bin/salt-master
root     17277 15047  0 18:27 pts/0    00:00:00 grep --color=auto salt-master
```

上面看到的都是 salt-master，不知道具体的名称，安装 python-setproctitle 可显示名称。

```bash
[root@SaltstackServer /srv/salt]# yum install -y python-setproctitle
[root@SaltstackServer /srv/salt]# systemctl restart salt-master
[root@SaltstackServer /srv/salt]# ps aux | grep salt-master
```

```text
root     17578 13.0  1.0 394884 40224 ?        Ss   18:29   0:00 /usr/bin/python /usr/bin/salt-master ProcessManager
root     17583  0.0  0.5 311044 19876 ?        S    18:29   0:00 /usr/bin/python /usr/bin/salt-master MultiprocessingLoggingQueue
root     17588  0.0  0.8 475772 34048 ?        Sl   18:29   0:00 /usr/bin/python /usr/bin/salt-master ZeroMQPubServerChannel
root     17589  0.0  0.8 393844 33580 ?        S    18:29   0:00 /usr/bin/python /usr/bin/salt-master EventPublisher
root     17592  1.0  0.9 397248 37216 ?        S    18:29   0:00 /usr/bin/python /usr/bin/salt-master Maintenance
root     17593  0.3  0.8 394748 34320 ?        S    18:29   0:00 /usr/bin/python /usr/bin/salt-master ReqServer_ProcessManager
root     17594  0.0  0.8 509460 34836 ?        Sl   18:29   0:00 /usr/bin/python /usr/bin/salt-master MWorkerQueue
root     17601 26.3  1.1 408408 43972 ?        S    18:29   0:00 /usr/bin/python /usr/bin/salt-master MWorker-0
root     17602 26.3  1.1 408424 44060 ?        S    18:29   0:00 /usr/bin/python /usr/bin/salt-master MWorker-1
root     17603 26.6  1.1 408424 44072 ?        S    18:29   0:00 /usr/bin/python /usr/bin/salt-master MWorker-2
root     17604 26.6  1.1 408408 43996 ?        S    18:29   0:00 /usr/bin/python /usr/bin/salt-master MWorker-3
root     17605  0.0  0.8 468616 34676 ?        Sl   18:29   0:00 /usr/bin/python /usr/bin/salt-master FileserverUpdate
root     17606 26.6  1.1 408408 43988 ?        R    18:29   0:00 /usr/bin/python /usr/bin/salt-master MWorker-4
root     17914  0.0  1.0 408424 42116 ?        R    18:29   0:00 /usr/bin/python /usr/bin/salt-master MWorker-1
root     17915  0.0  1.0 407432 42032 ?        R    18:29   0:00 /usr/bin/python /usr/bin/salt-master MWorker-0
root     17917  0.0  0.0 112720   976 pts/0    R+   18:29   0:00 grep --color=auto salt-master
root     17918  0.0  1.0 408424 42108 ?        R    18:29   0:00 /usr/bin/python /usr/bin/salt-master MWorker-2
root     17919  0.0  1.0 408408 42064 ?        R    18:29   0:00 /usr/bin/python /usr/bin/salt-master MWorker-3
```

## SaltStack 数据系统

1. Grains（谷粒）
2. Pillar（柱子）

### Grains：静态数据

当 Minion 启动的时候才收集 Minion 本地的相关信息。例如：操作系统版本，内核版本，CPU、内存、硬盘、设备型号、序列号。

作用：

1. 资产管理、信息查询
2. 用于目标选择
3. 配置管理中使用

#### 资产管理和信息查询

```bash
[root@SaltstackServer /srv/salt]# salt '*' grains.ls   #查看 grains 的 key
[root@SaltstackServer /srv/salt]# salt '*' grains.items   #查看所有的 key 对应的值
[root@SaltstackServer /srv/salt]# salt '*' grains.item os   #查看系统版本
```

```text
SaltstackServer.com:
    ----------
    os:
        CentOS
linux-node1:
    ----------
    os:
        CentOS
```

查看 IP 地址：

```bash
[root@SaltstackServer /srv/salt]# salt '*' grains.item ipv4
```

```text
SaltstackServer.com:
    ----------
    ipv4:
        - 127.0.0.1
        - 192.168.1.235
linux-node1:
    ----------
    ipv4:
        - 127.0.0.1
        - 192.168.1.233
```

#### 目标选择

```bash
# os 是 Centos 的测试一下
[root@SaltstackServer /srv/salt]# salt -G 'os:Centos' test.ping
```

```text
SaltstackServer.com:
    True
linux-node1:
    True
```

```bash
# ip 是 192.168.1.233 的测试一下
[root@SaltstackServer /srv/salt]# salt -G 'ipv4:192.168.1.233' test.ping
```

```text
linux-node1:
    True
```

自定义 item 值，更具灵活性，在 /etc/salt/minion 配置文件中修改。

没修改前：

```bash
[root@SaltstackServer /srv/salt]# salt '*' grains.item roles
```

```text
SaltstackServer.com:
    ----------
    roles:
linux-node1:
    ----------
    roles:
```

修改方式一：

```bash
[root@linux-node1 yum.repos.d]# vim /etc/salt/minion
# Custom static grains for this minion can be specified here and used in SLS
# files just like all other grains. This example sets 4 custom grains, with
# the 'roles' grain having two values that can be matched against.
grains:
  roles: apache
```

需要刷新 grains 参数：

```bash
[root@SaltstackServer /srv/salt]# salt '*' saltutil.sync_grains
```

修改后：

```bash
[root@SaltstackServer /srv/salt]# salt '*' grains.item roles
```

```text
linux-node1:
    ----------
    roles:
        apache
SaltstackServer.com:
    ----------
    roles:
```

修改方式二（此方法在 salt3000.1-1.el8 版本是没有用了）：

```bash
[root@linux-node1 yum.repos.d]# vim /etc/salt/grains   #这个路径下的 grains 文件 minion 自己会找
```

```yaml
cloud: openstack
```

在 master 上刷新所有 minion 的信息，使信息为最新，无论 minion 哪种方式修改都会成功：

```bash
[root@SaltstackServer /srv/salt]# salt '*' saltutil.sync_grains
# 在 master 刷新或在 minion 上重启 minion 后可查看到更改的 item
[root@SaltstackServer /srv/salt]# salt '*' grains.item cloud
```

```text
SaltstackServer.com:
    ----------
    cloud:
linux-node1:
    ----------
    cloud:
        openstack
```

#### 配置管理中使用

在 top.sls 文件中使用 grains：

```bash
[root@SaltstackServer /srv/salt]# cat /srv/salt/top.sls
```

```yaml
base:
  'linux-node1':
    - web.apache
  'roles:apache':   #:后不能有空格
    - match: grain   #:后要有空格
    - web.apache
```

#### 自定义 grains

在 /srv/salt/ 目录下新建 _grains 目录，minion 自己会到这个目录下来找自定义 grains。

```bash
cd /srv/salt/ && mkdir _grains
[root@SaltstackServer /srv/salt/_grains]# cat my_grains.py
```

```python
#!/usr/bin/env python
#-*- coding: utf-8 -*-

def my_grains():
    #初始化一个grains字典
    grains = {}
    #设置字典中的key-value
    grains['iaass'] = 'openstack'
    grains['edu'] = 'oldboyedu'
    #返回这个字典
    return  grains
```

同步自定义 grains 到 minion，让 minion 收集信息：

```bash
[root@SaltstackServer /srv/salt/_grains]# salt '*' saltutil.sync_grains
```

```text
SaltstackServer.com:
    - grains.my_grains
linux-node1:
    - grains.my_grains
```

在 minion 端查看同步的情况：

```bash
[root@linux-node1 ~]# cd /var/cache/salt/
[root@linux-node1 salt]# tree
```

```text
.
└── minion
    ├── accumulator
    ├── extmods
    │?? └── grains
    │??     ├── my_grains.py
    │??     └── my_grains.pyc
    ├── files
    │?? └── base
    │??     ├── _grains
    │??     │?? └── my_grains.py
    │??     ├── top.sls
    │??     └── web
    │??         └── apache.sls
    ├── highstate.cache.p
    ├── module_refresh
    ├── pkg_refresh
    ├── proc
    └── sls.p
```

自定义 grains 同步到 minion 的路径：/var/cache/salt/minion/extmods/grains/my_grains.py。

在 master 中查看是否同步：

```bash
[root@SaltstackServer /srv/salt]# salt '*' grains.item iaass
```

```text
SaltstackServer.com:
    ----------
    iaass:
        openstack
linux-node1:
    ----------
    iaass:
        openstack
```

#### Grains 优先级

1. 系统自带
2. grains 文件写的 /etc/salt/grains（在 salt3000.1-1.el8 版本是没有用了）
3. minion 配置文件写的 /etc/salt/minion
4. 自己写的 /srv/salt/_grains/

注：当名字一样时，优先级从 1 到 4 排序。

### Pillar

Pillar 是动态的。给特定的 Minion 指定特定的数据（top file 也是这样的）。只有指定的 minion 自己能看到自己的数据，比较安全。而 grains 却是所有的 minion 都能看到，不安全。所以在普通的信息时使用 grains，而在涉及帐号密码时使用 pillar。

Pillar 的所有 item 键值，在 /etc/salt/master 里面可以打开，例：

```text
893 # master config file that can then be used on minions.
894 pillar_opts: True
```

#### 写 pillar sls 描述文件

Pillar 描述文件文件放在哪里？

```bash
[root@SaltstackServer ~]# vim /etc/salt/master
#####         Pillar settings        #####
```

```text
838 ##########################################
839 # Salt Pillars allow for the building of global data that can be made selectively
840 # available to different minions based on minion grain filtering. The Salt
841 # Pillar is laid out in the same fashion as the file server, with environments,
842 # a top file and sls files. However, pillar data does not need to be in the
843 # highstate format, and is generally just key/value pairs.
844 pillar_roots:
845   base:
846     - /srv/pillar
```

打开 pillar 设置，并设置存放 pillar 描述文件 URL：

```bash
cd /srv; mkdir pillar; cd pillar; mkdir web ;cd web ;vim apache.sls
```

注：pillar 里面可以嵌套 grains。

```bash
[root@SaltstackServer /srv/pillar/web]# cat apache.sls
```

```jinja
{% if grains['os'] == 'CentOS' %}
apache: httpd
{% elif grains['os'] == 'Debian' %}
apache: apache2
{% endif %}
```

注：pillar 不写 top file 文件是不能执行的，而 grains 不写 top file 也可以执行。

#### 编写 top file

```bash
[root@SaltstackServer /srv]# cat ./pillar/top.sls
base:
  'linux-node1':
    - web.apache
[root@SaltstackServer /srv]# salt '*' saltutil.refresh_pillar   #刷新pillar
```

查找 pillar 里面 item 是 apache 的 key：

```bash
[root@SaltstackServer /srv]# salt '*' pillar.items apache
```

```text
SaltstackServer.com:
    ----------
    apache:
linux-node1:
    ----------
    apache:
        httpd
```

pillar 使用场景，还是用于目标选择上，pillar 用 -I 来选择，grains 用 -G 来选择，注意：

```bash
[root@SaltstackServer /srv]# salt -I 'apache:httpd' test.ping
```

```text
linux-node1:
    True
```

#### Grains 和 Pillar 对比

| 对比项 | Grains | Pillar |
| --- | --- | --- |
| 类型 | 静态（需要重启 minion 服务或在 master 端使用 saltutil.snyc_grains 同步 grains） | 动态（不需要重启，需要使用 saltutil.refresh_pillar 同步 pillar） |
| 数据采集方式 | minion 启动时采集或 master 自定义 | master 自定义 |
| 应用场景 | 数据查询，目标选择，配置管理 | 目标选择，配置管理，机密数据 |
| 定义位置 | minion 端和 master 端 | master 端 |

假如有 100 台机器：如果定义 grains，那么需要在每台 minion 去设置或在 master 上的 /srv/salt/_grains 目录下设置即可，如果定义 pillar，只需要在 master 一台机器上设置就可以了。

## 深入学习 Saltstack 远程执行

例如：salt '*' cmd.run 'w'

| 部分 | 说明 |
| --- | --- |
| 命令 | salt |
| 目标 | '*' |
| 模块 | cmd.run（自带 150+ 模块，也可自己写模块） |
| 命令 | 'w' |
| 返回 | 执行后的结果返回，Returnners |

### 目标选择 Targeting

两种：

1. 和 Minion ID 有关
2. 和 Minion ID 无关

#### 和 Minion ID 有关

通配符：

```bash
[root@SaltstackServer ~]# salt 'linux?node1' test.ping
```

```text
linux-node1:
    True
```

```bash
[root@SaltstackServer ~]# salt '*' test.ping
```

```text
SaltstackServer.com:
    True
linux-node1:
    True
```

```bash
[root@SaltstackServer ~]# salt 'linux-node[1-2]' test.ping
```

列表：

```bash
[root@SaltstackServer ~]# salt -L 'linux-node1,SaltstackServer.com' test.ping
```

```text
SaltstackServer.com:
    True
linux-node1:
    True
```

正则表达式：

```bash
[root@SaltstackServer ~]# salt -E 'linux-node[1-2]*' test.ping
```

注：所有匹配目标的方式，都可以在 Top file 里面用。

#### 主机名设置方案

1. IP 地址
2. 根据业务来进行设置

例：redis-node1-redis04-idc04-soa.example.com

- redis-node1：redis 第一个节点
- redis04：redis 第 4 个集群
- idc04：idc 机房
- soa：业务线
- examplo.com：域名

#### 和 Minion ID 无关

IP、子网：

```bash
[root@SaltstackServer ~]# salt -S 192.168.1.233 test.ping
```

```text
linux-node1:
    True
```

```bash
[root@SaltstackServer ~]# salt -S 192.168.1.235 test.ping
```

```text
SaltstackServer.com:
    True
```

```bash
[root@SaltstackServer ~]# salt -S 192.168.1.0/24 test.ping
```

```text
SaltstackServer.com:
    True
linux-node1:
    True
```

以百分比来执行远程命令，-b 10 代表百分之 10：

```bash
[root@SaltstackServer ~]# salt '*' -b 10 test.ping
```

### 常用模块

官网模块 URL：https://docs.saltstack.com/en/latest/ref/modules/all/index.html

#### network

```bash
[root@SaltstackServer ~]# salt '*' network.arp
```

```text
SaltstackServer.com:
    ----------
    00:50:56:ad:60:3c:
        192.168.1.233
    08:62:66:c8:28:d0:
        192.168.1.223
    74:a2:e6:ab:42:c0:
        192.168.1.254
    f4:4e:05:65:4e:42:
        192.168.1.1
    fc:aa:14:b5:3b:a0:
        192.168.1.19
linux-node1:
    ----------
    00:50:56:ad:20:00:
        192.168.1.201
    00:50:56:ad:32:8c:
        192.168.1.235
    08:62:66:c8:28:d0:
        192.168.1.223
    74:a2:e6:ab:42:c0:
        192.168.1.254
    f4:4e:05:65:4e:42:
        192.168.1.1
    fc:aa:14:b5:3b:a0:
        192.168.1.19
```

#### service

```bash
[root@SaltstackServer ~]# salt '*' service.status sshd
```

```text
linux-node1:
    True
SaltstackServer.com:
    True
```

#### salt-cp —— 从 master 分发文件到指定 minion（默认开启）

```bash
[root@SaltstackServer ~]# salt-cp '*' /etc/hosts /tmp/hi
```

```text
SaltstackServer.com:
    ----------
    /tmp/hi:
        True
linux-node1:
    ----------
    /tmp/hi:
        True
    -rw-------. 1 root root   0 Oct 20 13:54 yum.log
```

```bash
[root@salt ~]# salt-cp -C 'master01.k8s.hs.com' /root/tmpelk.tar.gz /tmp/tmpelk.tar.gz
```

```text
master01.k8s.hs.com:
    ----------
    /tmp/tmpelk.tar.gz:
        True
```

```bash
[root@SaltstackServer ~]# salt '*' cmd.run 'ls -l /tmp/hi'
```

```text
SaltstackServer.com:
    -rw-r--r-- 1 root root 158 Oct 21 14:11 /tmp/hi
linux-node1:
    -rw-r--r-- 1 root root 158 Oct 21 14:11 /tmp/hi
```

#### cp 模块

可从 master 分发文件到指定 minion（默认开启），也可从指定 minion 上传文件到 master（默认不开启）。

- cp.get_fle —— 复制文件到 minion，只能是文件
- cp.get_fle makedirs=True —— 同上，加了 makedirs=True 后，如果目录不存在则会建立目录
- cp.get_dir —— 复制目录
- cp.push —— 默认不开启

复制文件：

```bash
cp nacos-server-1.3.0.tar.gz /srv/salt/dev/
sudo salt 'ceph*' cp.get_file salt://nacos-server-1.3.0.tar.gz /usr/local/src/ saltenv=dev
```

上传文件：

```bash
[root@node1 files]# salt 'node2' cp.push /etc/yum.repos.d/zabbix.repo
```

```text
node2:
    False
```

```bash
[root@node1 files]# grep file_recv /etc/salt/master
#file_recv: False
#file_recv_max_size: 100
[root@node1 files]# grep file_recv /etc/salt/master
file_recv: True
file_recv_max_size: 100
[root@node1 files]# systemctl restart salt-master
[root@node1 files]# salt 'node2' cp.push /etc/yum.repos.d/zabbix.repo
```

```text
node2:
    True
```

```bash
# 这是上传文件的路径
[root@node1 files]# ls /var/cache/salt/master/minions/node2/files/etc/yum.repos.d/zabbix.repo
/var/cache/salt/master/minions/node2/files/etc/yum.repos.d/zabbix.repo
```

#### state

```bash
# 查看目标 minion 在 top file 文件中需要做什么事
[root@SaltstackServer ~]# salt '*' state.show_top
```

```text
SaltstackServer.com:
    ----------
linux-node1:
    ----------
    base:
        - web.apache
```

手动执行安装模块：

```bash
[root@SaltstackServer ~]# salt '*' state.single pkg.installed name=lsof
```

把 minion 的返回结果直接写到 mysql，写到 mysql 的不是 master 写的，而是 minion 直接写的。因为 Saltstack 是 python 写的，minion 又要写到 mysql，所以 minion 要安装 MYSQL-python 软件。

需要用到的模块：return

```bash
[root@SaltstackServer ~]# salt '*' state.single pkg.installed name=MySQL-python
```

```text
linux-node1:
----------
          ID: MySQL-python
    Function: pkg.installed
      Result: True
     Comment: The following packages were installed/updated: MySQL-python
     Started: 14:35:25.672391
    Duration: 5163.711 ms
     Changes:   
              ----------
              MySQL-python:
                  ----------
                  new:
                      1.2.5-1.el7
                  old:

Summary for linux-node1
------------
Succeeded: 1 (changed=1)
Failed:    0
------------
Total states run:     1
Total run time:   5.164 s
SaltstackServer.com:
----------
          ID: MySQL-python
    Function: pkg.installed
      Result: True
     Comment: The following packages were installed/updated: MySQL-python
     Started: 14:35:25.687389
    Duration: 5585.818 ms
     Changes:   
              ----------
              MySQL-python:
                  ----------
                  new:
                      1.2.5-1.el7
                  old:

Summary for SaltstackServer.com
------------
Succeeded: 1 (changed=1)
Failed:    0
------------
Total states run:     1
Total run time:   5.586 s
```

安装 mariadb：

```bash
[root@SaltstackServer ~]# salt '*' state.single pkg.installed name=mariadb-sever
```

返回结果到 mysql 参考 URL：https://docs.saltstack.com/en/latest/ref/returners/all/salt.returners.mysql.html

在数据库上创建 mysql 表：

```sql
CREATE DATABASE  `salt`
  DEFAULT CHARACTER SET utf8
  DEFAULT COLLATE utf8_general_ci;

USE `salt`;

--
-- Table structure for table `jids`
--

DROP TABLE IF EXISTS `jids`;
CREATE TABLE `jids` (
  `jid` varchar(255) NOT NULL,
  `load` mediumtext NOT NULL,
  UNIQUE KEY `jid` (`jid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE INDEX jid ON jids(jid) USING BTREE;

--
-- Table structure for table `salt_returns`
--

DROP TABLE IF EXISTS `salt_returns`;
CREATE TABLE `salt_returns` (
  `fun` varchar(50) NOT NULL,
  `jid` varchar(255) NOT NULL,
  `return` mediumtext NOT NULL,
  `id` varchar(255) NOT NULL,
  `success` varchar(10) NOT NULL,
  `full_ret` mediumtext NOT NULL,
  `alter_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY `id` (`id`),
  KEY `jid` (`jid`),
  KEY `fun` (`fun`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `salt_events`
--

DROP TABLE IF EXISTS `salt_events`;
CREATE TABLE `salt_events` (
`id` BIGINT NOT NULL AUTO_INCREMENT,
`tag` varchar(255) NOT NULL,
`data` mediumtext NOT NULL,
`alter_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
`master_id` varchar(255) NOT NULL,
PRIMARY KEY (`id`),
KEY `tag` (`tag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

授权：

```sql
grant all on salt.* to salt@'%' identified by 'salt@pw';
```

在所有 minion 上设置连接数据库参数：

```bash
[root@SaltstackServer ~]# vim /etc/salt/minion
```

```yaml
mysql.host: '192.168.1.235'
mysql.user: 'salt'
mysql.pass: 'salt@pw'
mysql.db: 'salt'
mysql.port: 3306
```

```bash
[root@SaltstackServer ~]# systemctl restart salt-minion
[root@SaltstackServer ~]# salt '*' test.ping --return mysql
```

查询到 minion 的返回结果：

```sql
MariaDB [salt]> select * from salt_returns \G;
```

```text
*************************** 1. row ***************************
       fun: test.ping
       jid: 20181021152047898888
    return: true
        id: SaltstackServer.com
   success: 1
  full_ret: {"fun_args": [], "jid": "20181021152047898888", "return": true, "retcode": 0, "success": true, "fun": "test.ping", "id": "SaltstackServer.com"}
alter_time: 2018-10-21 15:20:47
*************************** 2. row ***************************
       fun: test.ping
       jid: 20181021152047898888
    return: true
        id: linux-node1
   success: 1
  full_ret: {"fun_args": [], "jid": "20181021152047898888", "return": true, "retcode": 0, "success": true, "fun": "test.ping", "id": "linux-node1"}
alter_time: 2018-10-21 15:20:48
```

### 如何编写一个状态模块

1. 模块放置位置：cd /srv/salt; mkdir _modules; vim my_disk.py
2. 命名：文件名就是模块名：

```bash
[root@SaltstackServer /srv/salt/_modules]# cat my_disk.py
def list():
  cmd = 'df -h'
  ret = __salt__['cmd.run'](cmd)
  return ret
[root@SaltstackServer /srv]# salt '*' saltutil.sync_modules
```

```text
linux-node1:
SaltstackServer.com:
```

4. 执行：

```bash
[root@SaltstackServer /srv]# salt '*' my_disk.list
```

```text
SaltstackServer.com:
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/sda2        99G  1.6G   98G   2% /
    devtmpfs        1.9G     0  1.9G   0% /dev
    tmpfs           1.9G   28K  1.9G   1% /dev/shm
    tmpfs           1.9G  8.9M  1.9G   1% /run
    tmpfs           1.9G     0  1.9G   0% /sys/fs/cgroup
    /dev/sda1      1014M  140M  875M  14% /boot
    tmpfs           380M     0  380M   0% /run/user/0
linux-node1:
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/sda2        99G  3.0G   96G   3% /
    devtmpfs        909M     0  909M   0% /dev
    tmpfs           920M   12K  920M   1% /dev/shm
    tmpfs           920M   17M  903M   2% /run
    tmpfs           920M     0  920M   0% /sys/fs/cgroup
    /dev/sda1      1014M  140M  875M  14% /boot
    tmpfs           184M     0  184M   0% /run/user/0
```

## 小结

1. minion 启动时收集本地信息成为 grains 的键值对。
2. 使用 grains 可用于目标选择、配置管理、信息查询。
3. grains 不用 top 文件亦可执行，例如：(salt -G 'os:Centos' state.sls web.apache)，但 pillar 却不行，pillar 只有 top 文件才能执行。
4. grains 目标选择也可以写入 /srv/salt/top.sls 文件中使用。
5. grains 自定义优先组：1. 系统自带，2. minion 端 /etc/salt/grains 自定义，需要重启 minion 服务，3. minion 端 /etc/salt/minion 自定义，需要重启 minion 服务，4. master 端 /srv/salt/_grains/*.py 自定义，需要使用（salt '*' saltutil.sync_grains）命令来同步。
6. pillar 常用于机密信息处理，grains 常用于普通信息处理。
7. pillar 的描述文件在 /srv/pillar/*.sls，pillor 的 top 文件在 /srv/pillar/top.sls，pillar 的描述文件编写完成后必需刷新才能生效，命令：(salt '*' saltutil.refresh_pillar)。
8. 自定义模块可满足自己的需要，在 /srv/salt/_modules/ 目录下编写 *.py 文件。

## 文件路径

1. master 配置文件：/etc/salt/master
2. minion 配置文件：/etc/salt/minion
3. master 下发任务到 minion 后 minion 同步的路径：/var/cache/salt/minion
4. minion 和 master 的公钥和私钥路径：/etc/salt/pki/minion/ 和 /etc/salt/pki/master/
5. minion 的 id 文件路径：/etc/salt/minion_id
6. minion 的自定义 item 目录：1. /etc/slat/grains  2. /etc/salt/minion
7. master 上的 top file 文件路径：/srv/salt/top.sls
8. master 上的 pillar 的 top file 文件路径：/srv/pillar/top.sls
9. master 上的 pillar 的描述文件路径：/srv/pillar/*.sls
10. master 上的描述文件路径：/srv/salt/*.sls
11. master 自定义 grains 路径：/srv/salt/_grains/*.py
12. master 自定义模块路径：/srv/salt/_modules/*.py