#Saltstack自动化运维
<pre>
Saltstack是由python写的，也提供API，是REST API
三大功能：
		1. 远程执行
		2. 配置管理（状态管理）
		3. 云管理
运维三板斧：
		1. 监控
		2. 执行
		3. 配置
Saltstack竞争对手：
Puppet (ruby写的)
ansible(python写的)

Saltstack四种运行方式：
	Local    #本地运行
	Minion/Master	#类似C/S架构，minion的中文是奴才，
	Syndic	#可以理解为Zabbix的proxy一样，Syndic是Saltstack的代理
	Salt SSH #以SSH方式运行

Saltstack很难回滚，docker却可以回滚

Saltstack典型案例：
第二部分：远程执行
现在安装不用epel源来安装了，Saltstack官方自己做了个源，网站是：repo.saltstack.com,可以从这个网站上找到安装saltstack的步骤方法：
1. yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm  #安装Saltstack的yum仓库
2. Saltstack服务器安装：yum install -y salt-master salt-minion
3. Saltstack客户端安装：yum install -y salt-minion
4. 启动Saltstack Server:systemctl start salt-master
############
[root@SaltstackServer salt]# vim /etc/salt/minion
[root@SaltstackServer salt]# grep '^[a-Z]' minion
master: 192.168.1.235
############
6. [root@SaltstackServer salt]# systemctl start salt-minion  #启动salt-minion
注：vim /etc/salt/minion里面有id可设置，不建议随时更改id,因为你在minion配置文件中改了id后，重启minion服务/etc/salt/minion_id还是老的id,因为minion服务会先读/etc/salt/minion_id文件，如果它存在，那么配置里设置的id就永远不会生效，所以要想设置id必须先删除/etc/salt/minion_id文件，然后去minion配置文件设置id，重启服务即可自动生成设置/etc/salt/minion_id文件。不设置默认值为主机名，例如下：
[root@SaltstackServer salt]# cat /etc/salt/minion_id 
SaltstackServer.com
7. 设置并启动第二台salt-minion服务：
############
root@linux-node1 salt]# vim /etc/salt/minion
[root@linux-node1 salt]# grep '^[a-Z]' /etc/salt/minion
master:192.168.1.235 
[root@linux-node1 salt]# systemctl start salt-minion
############
注：minion找到master后说我要当你的minion(奴才)，但是minion要经过master认证成功后才能真正成为master的(minion)奴才，salt之间的传输是经过AES加密传输的
###tree minion
[root@linux-node1 salt]# tree pki
pki
├── master
└── minion
    ├── minion.pem	  #私钥
    └── minion.pub    #公钥
pki目录是启动minion时启动的，minion公钥是先发送给master,后期他们通过对方的公钥进行加密码传输的
###tree master
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
没有认证之前，minion都是把自己的公钥发给master,在/etc/salt/pki/master/minions_pre/目录下的，都是以自己的id来命名自己的公钥的,例：
#master端查看的minion公钥md5
[root@SaltstackServer salt]# md5sum ./pki/master/minions_pre/linux-node1 
d6e378e5c25f89910f000aab3bd477f7  ./pki/master/minions_pre/linux-node1
#本机minion的公钥md5
[root@linux-node1 salt]# md5sum ./pki/minion/minion.pub 
d6e378e5c25f89910f000aab3bd477f7  ./pki/minion/minion.pub

8. 开始认证：
##############
同意认证：
[root@SaltstackServer salt]# salt-key -a linux-node1
The following keys are going to be accepted:
Unaccepted Keys:
linux-node1
Proceed? [n/Y] y
Key for minion linux-node1 accepted.
或者
[root@SaltstackServer salt]# salt-key -a Salt*
The following keys are going to be accepted:
Unaccepted Keys:
SaltstackServer.com
Proceed? [n/Y] y
Key for minion SaltstackServer.com accepted
或者
#同意所有的minion
[root@SaltstackServer salt]# salt-key -A
The following keys are going to be accepted:
Unaccepted Keys:
linux-node1
Proceed? [n/Y] y
Key for minion linux-node1 accepted.
删除认证：
salt-key -d linux-node1  #此时linux-node1 minion是不在minions_pre列表中了，所以只能重启linux-node1的minion才能重新到达minions_pre列表中了
salt-key -D是全部删除，删除一般不建议用
############
当master同意minion加入后，master的公钥就会交换传输在各个minion的/etc/salt/pki/minion/minion_master.pub文件下，而之前minion请求master认证时已经把各自的minion发给master了，所以当master同意minion认证后就是双方成功交换了公钥，这样一来就可以进行加密传输了
注：再次重申id不要随便更改，否则master和minion之前的公钥就要重头开始认证交换了，id主要用ip和主机名，游戏公司用ip多，电商用主机名，dns不能解析下划线的，只能解析横杠。记住

###远程执行：
#测试所有minion跟master之间的密钥通信是否正常，返回值是True则代表密钥成功通信，"*" 代表所有minion目录，test.ping是模块加方法。注意这里的ping不是ICMP的ping
[root@SaltstackServer salt]# salt "*" test.ping
linux-node1:
    True
SaltstackServer.com:
    True

远程执行命令：
#创建一个目录，#linux中没有消息就是最好的消息，说明执行成功
[root@SaltstackServer salt]# salt "*" cmd.run "mkdir /tmp/hello"
SaltstackServer.com:		
linux-node1:
#列出目录下文件
[root@SaltstackServer salt]# salt "*" cmd.run "ls /tmp"
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

第二部分：配置管理
state：描述文件，YAML格式，.sls后缀结尾。配置文件就是YAML格式
YAML三板斧：
	1. 缩进		#2个空格，禁止使用tab键，
	2. 冒号		#key: value 键值对中的冒号后面有一个空格，冒号前2个空格代表层级关系
	3. 短横线	#- list1 列表短横线后面也有一个空格，千万注意

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
注：base名称不能更改，salt规定，dev和prod可以更改
[root@SaltstackServer ~]# systemctl restart salt-master
模块分为两种：1. 执行模块（远程执行用） 2. 状态模块（配置管理用）
[root@SaltstackServer web]# vim /srv/salt/web/apache.sls 
apache-install:
  pkg.installed:
    - names:
      - httpd
      - httpd-devel

apache-service:
  service.running:
    - name: httpd
    - enable: True
#执行描述文件给minion安装
[root@SaltstackServer web]# salt "*" state.sls web.apache
#minion下收到master的描述文件
[root@linux-node1 salt]# cat /var/cache/salt/minion/files/base/web/apache.sls 
apache-install:
  pkg.installed:
    - names:
      - httpd
      - httpd-devel

apache-service:
  service.running:
    - name: httpd
    - enable: True
但是生产环境有好多台不同的应用模块，总不能手动一个一个敲响，所以要用到top.file文件，vim /etc/salt/master  搜索top.file可查看top.sls文件放置在哪里
 559 #####      State System settings     #####
 560 ##########################################
 561 # The state system uses a "top" file to tell the minions what environment to
 562 # use and what modules to use. The state_top file is defined relative to the
 563 # root of the base environment as defined in "File Server settings" below.
 564 #state_top: top.sls
从以上描述信息可看到放置在root(根)的base环境目录下，也就是/srv/salt目录下
 674 file_roots:
 675   base:
 676     - /srv/salt

#编写top.sls文件
[root@SaltstackServer /srv/salt]# cat top.sls 
base:
  'linux-node1':
    - web.apache
  'SaltstackServer.com':
    - web.apache
[root@SaltstackServer /srv/salt]# salt '*' state.highstate test=True  #测试是否执行成功，重点在test=True,没有则是执行了

###发布与订阅模式
salt4505端口是发布端口
tcp        0      0 0.0.0.0:4505            0.0.0.0:*               LISTEN      9262/python         
tcp        0      0 0.0.0.0:4506            0.0.0.0:*               LISTEN      9268/python
####lsof(list open file)列出打开文件ip端口4505的壮态
###man 2 kill  //进行kill(2)的查询手册 
###lsof -i @192.168.1.233 -n//查看打开这个ip的有哪里
[root@SaltstackServer /srv/salt]# lsof -i:4505 -n
COMMAND     PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
salt-mini  3718 root   21u  IPv4 114430      0t0  TCP 192.168.1.235:46892->192.168.1.235:4505 (ESTABLISHED)
/usr/bin/ 17588 root   16u  IPv4 112757      0t0  TCP *:4505 (LISTEN)
/usr/bin/ 17588 root   18u  IPv4 115485      0t0  TCP 192.168.1.235:4505->192.168.1.233:49712 (ESTABLISHED)
/usr/bin/ 17588 root   19u  IPv4 113389      0t0  TCP 192.168.1.235:4505->192.168.1.235:46892 (ESTABLISHED)

在master中，4505端口一直被minion连接着(tcp长连接)，所以在master中可以很快执行远程命令，例： cmd.run 'w' 
###请求与响应模式
4506端口是ZeroMQ REP系统的，默认监听4506，可通过修改/etc/salt/master的ret_port参数设置。它是minion与master通信的端口，比如说minion收到master的执行命令后，minion去执行，把执行的返回值通过4506端口发送给master


[root@SaltstackServer /srv/salt]# ps -ef | grep salt-master
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
#上面看到的都是/salt-master，不知道具体的名称，安装python-setproctitle可显示名称
[root@SaltstackServer /srv/salt]# yum install -y python-setproctitle
[root@SaltstackServer /srv/salt]# systemctl restart salt-master
[root@SaltstackServer /srv/salt]# ps aux | grep salt-master
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

###SaltStack数据系统
1. Grains(谷粒)
2. Pillar(柱子)

#Grains:静态数据
当Minion启动的时候才收集Minion本地的相关信息。例如：操作系统版本，内核版本，CPU,内存，硬盘。设备型号。序列号。
作用：
1. 资产管理。信息查询。
2. 用于目标选择
3. 配置管理中使用

###1. 资产管理。信息查询。
[root@SaltstackServer /srv/salt]# salt '*' grains.ls  #查看grains的key
[root@SaltstackServer /srv/salt]# salt '*' grains.items  #查看所有的key对应的值
[root@SaltstackServer /srv/salt]# salt '*' grains.item os   #查看系统版本
SaltstackServer.com:
    ----------
    os:
        CentOS
linux-node1:
    ----------
    os:
        CentOS
[root@SaltstackServer /srv/salt]# salt '*' grains.item ipv4  #查看IP地址
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
        
#目标选择
[root@SaltstackServer /srv/salt]# salt -G 'os:Centos' test.ping   #os是Centos的测试一下
SaltstackServer.com:
    True
linux-node1:
    True
[root@SaltstackServer /srv/salt]# salt -G 'ipv4:192.168.1.233' test.ping  #ip是192.168.1.233的测试一下
linux-node1:
    True

自定义item值，更具灵活性，在/etc/salt/minion配置文件中修改：
#没修改前：
[root@SaltstackServer /srv/salt]# salt '*' grains.item roles
SaltstackServer.com:
    ----------
    roles:
linux-node1:
    ----------
    roles:
#修改方式一：
[root@linux-node1 yum.repos.d]# vim /etc/salt/minion
# Custom static grains for this minion can be specified here and used in SLS
# files just like all other grains. This example sets 4 custom grains, with
# the 'roles' grain having two values that can be matched against.
grains:
  roles: apache

##需要刷新grains参数：[root@SaltstackServer /srv/salt]# salt '*' saltutil.sync_grains 
#修改后：
[root@SaltstackServer /srv/salt]# salt '*' grains.item roles
linux-node1:
    ----------
    roles:
        apache
SaltstackServer.com:
    ----------
    roles:

#修改方式二：此方法在salt3000.1-1.el8版本是没有用了
[root@linux-node1 yum.repos.d]# vim /etc/salt/grains  #这个路径下的grains文件minion自己会找
	cloud: openstack
[root@SaltstackServer /srv/salt]# salt '*' saltutil.sync_grains  #在master上刷新所有minion的信息，使信息为最新无论minion哪种方式修改都会成功
[root@SaltstackServer /srv/salt]# salt '*' grains.item cloud  #在master刷新或在minion上重启minion后可查看到更改的item
SaltstackServer.com:
    ----------
    cloud:
linux-node1:
    ----------
    cloud:
        openstack

###配置管理中使用
#在top.sls文件中使用grains：
[root@SaltstackServer /srv/salt]# cat /srv/salt/top.sls 
base:
  'linux-node1':
    - web.apache
  'roles:apache':   #:后不能有空格
    - match: grain   #:后要有空格
    - web.apache

###自定义grains
在/srv/salt/目录下新建_grains目录，minion自己会到这个目录下来找自定义grains
cd /srv/salt/ && mkdir _grains
[root@SaltstackServer /srv/salt/_grains]# cat my_grains.py 
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
#同步自定义grains到minion，让minion收集信息
[root@SaltstackServer /srv/salt/_grains]# salt '*' saltutil.sync_grains
SaltstackServer.com:
    - grains.my_grains
linux-node1:
    - grains.my_grains
#在minion端查看同步的情况
[root@linux-node1 ~]# cd /var/cache/salt/
[root@linux-node1 salt]# tree
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
自定义grains同步到minion的路径：/var/cache/salt/minion/extmods/grains/my_grains.py
#在master中查看是否同步
[root@SaltstackServer /srv/salt]# salt '*' grains.item iaass
SaltstackServer.com:
    ----------
    iaass:
        openstack
linux-node1:
    ----------
    iaass:
        openstack

#Grains优先级：
	1. 系统自带
	2. grains文件写的  /etc/salt/grains  #在salt3000.1-1.el8版本是没有用了
	3. minion配置文件写的  /etc/salt/minion
	4. 自己写的   /srv/salt/_grains/
注：当名字一样时，优先级从1到4排序

#Pillar:
Pillar是动态的。给特定的Minion指定特定的数据（top file也是这样的）。只有指定的minion自己能看到自己的数据，比较安全。而grains却是所有的minion都能看到，不安全。所以在普通的信息时使用grains,而在涉及帐号密码时使用pillar。
Pillar的所有item键值，在/etc/salt/master里面可以打开，例：
893 # master config file that can then be used on minions.
894 pillar_opts: True

#####1. 写pillar sls描述文件：
Pillar描述文件文件放在哪里？
[root@SaltstackServer ~]# vim /etc/salt/master
#####         Pillar settings        #####
 838 ##########################################
 839 # Salt Pillars allow for the building of global data that can be made selectively
 840 # available to different minions based on minion grain filtering. The Salt
 841 # Pillar is laid out in the same fashion as the file server, with environments,
 842 # a top file and sls files. However, pillar data does not need to be in the
 843 # highstate format, and is generally just key/value pairs.
 844 pillar_roots:
 845   base:
 846     - /srv/pillar
打开pillar设置，并设置存放pillar描述文件URL
cd /srv; mkdir pillar; cd pillar; mkdir web ;cd web ;vim apache.sls
注：pillar里面可以嵌套grains
[root@SaltstackServer /srv/pillar/web]# cat apache.sls 
{% if grains['os'] == 'CentOS' %}
apache: httpd
{% elif grains['os'] == 'Debian' %}
apache: apache2
{% endif %}
注：pillar不写top file文件是不能执行的，而grains不写top file也可以执行
####2. 编写top file
[root@SaltstackServer /srv]# cat ./pillar/top.sls 
base:
  'linux-node1':
    - web.apache

[root@SaltstackServer /srv]# salt '*' saltutil.refresh_pillar   #刷新pillar

##查找pillar里面item是apache的key
[root@SaltstackServer /srv]# salt '*' pillar.items apache
SaltstackServer.com:
    ----------
    apache:
linux-node1:
    ----------
    apache:
        httpd

###pillar使用场景，还是用于目标选择上，pillar用-I 来选择，grains用-G来选择，注意
[root@SaltstackServer /srv]# salt -I 'apache:httpd' test.ping
linux-node1:
    True

######Grains和Pillar对比：
Grains:
类型：静态（需要重启minion服务或在master端使用saltutil.snyc_grains同步grains）
数据采集方式：minion启动时采集或master自定义
应用场景：数据查询，目标选择，配置管理
定义位置：minion端和master端

Pillar:
类型：动态（不需要重启,需要使用saltutil.refresh_pillar同步pillar）
数据采集方式：master自定义
应用场景：目标选择，配置管理，机密数据
定义位置：master端

假如有100台机器：如果定义grains，那么需要在每台minion去设置或在master上的/srv/salt/_grains目录下设置即可，如果定义pillar,只需要在master一台机器上设置就可以了

#########深入学习Saltstack远程执行：
例如:salt '*' cmd.run 'w'
命令：salt
目标：'*'
模块：cmd.run   #自带150+模块，也可自己写模块
命令：'w'
返回：执行后的结果返回，Returnners
解析：
目标：Targeting
	两种：
		1.和Minion ID 有关
		2.和Minion ID 无关
1.和Minion ID 有关
#通配符：
#[root@SaltstackServer ~]# salt 'linux?node1' test.ping
linux-node1:
    True
#[root@SaltstackServer ~]# salt '*' test.ping
SaltstackServer.com:
    True
linux-node1:
    True
#[root@SaltstackServer ~]# salt 'linux-node[1-2]' test.ping
#列表：[root@SaltstackServer ~]# salt -L 'linux-node1,SaltstackServer.com' test.ping
SaltstackServer.com:
    True
linux-node1:
    True
#正则表达式：
[root@SaltstackServer ~]# salt -E 'linux-node[1-2]*' test.ping
注：所有匹配目标的方式，都可以在Top file里面用

主机名设置方案：
1. IP地址
2. 根据业务来进行设置
例：redis-node1-redis04-idc04-soa.example.com
redis-node1:redis第一个节点
redis04:redis第4个集群
idc04:idc机房
soa:业务线
examplo.com:域名

#和Minion ID 无关：
IP，子网：
[root@SaltstackServer ~]# salt -S 192.168.1.233 test.ping
linux-node1:
    True
[root@SaltstackServer ~]# salt -S 192.168.1.235 test.ping
SaltstackServer.com:
    True
^[[A[root@SaltstackServer ~]# salt -S 192.168.1.0/24 test.ping
SaltstackServer.com:
    True
linux-node1:
    True
#以百分比来执行远程命令，-b 10代表百分之10
[root@SaltstackServer ~]# salt '*' -b 10 test.ping

###官网模块URL：https://docs.saltstack.com/en/latest/ref/modules/all/index.html
###常用模块：
#network
[root@SaltstackServer ~]# salt '*' network.arp
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
#service
[root@SaltstackServer ~]# salt '*' service.status sshd
linux-node1:
    True
SaltstackServer.com:
    True
#salt-cp --从master分发文件到指定minion(默认开启)  
[root@SaltstackServer ~]# salt-cp '*' /etc/hosts /tmp/hi
SaltstackServer.com:
    ----------
    /tmp/hi:
        True
linux-node1:
    ----------
    /tmp/hi:
        True
    -rw-------. 1 root root   0 Oct 20 13:54 yum.log
[root@salt ~]# salt-cp -C 'master01.k8s.hs.com' /root/tmpelk.tar.gz /tmp/tmpelk.tar.gz 
master01.k8s.hs.com:
    ----------
    /tmp/tmpelk.tar.gz:
        True
[root@SaltstackServer ~]# salt '*' cmd.run 'ls -l /tmp/hi'
SaltstackServer.com:
    -rw-r--r-- 1 root root 158 Oct 21 14:11 /tmp/hi
linux-node1:
    -rw-r--r-- 1 root root 158 Oct 21 14:11 /tmp/hi
#cp模块 --可从master分发文件到指定minion(默认开启),也可从指定minion上传文件到master(默认不开启)，
cp.get_fle  --复制文件到minion,只能是文件
cp.get_fle makedirs=True   --同上，加了makedirs=True后，如果目录不存在则会主同建立目录
cp.get_dir  --复制目录
cp.push  --默认不开启
--复制文件
cp nacos-server-1.3.0.tar.gz /srv/salt/dev/
sudo salt 'ceph*' cp.get_file salt://nacos-server-1.3.0.tar.gz /usr/local/src/ saltenv=dev


[root@node1 files]# salt 'node2' cp.push /etc/yum.repos.d/zabbix.repo
node2:
    False
[root@node1 files]# grep file_recv /etc/salt/master
#file_recv: False
#file_recv_max_size: 100
[root@node1 files]# grep file_recv /etc/salt/master
file_recv: True
file_recv_max_size: 100
[root@node1 files]# systemctl restart salt-master
[root@node1 files]# salt 'node2' cp.push /etc/yum.repos.d/zabbix.repo
node2:
    True
[root@node1 files]# ls /var/cache/salt/master/minions/node2/files/etc/yum.repos.d/zabbix.repo  --这是上传文件的路径
/var/cache/salt/master/minions/node2/files/etc/yum.repos.d/zabbix.repo

#state
salt '*' state.show_top   #查看目标minion在top file文件中需要做什么事
[root@SaltstackServer ~]# salt '*' state.show_top
SaltstackServer.com:
    ----------
linux-node1:
    ----------
    base:
        - web.apache
#手动执行安装模块：[root@SaltstackServer ~]# salt '*' state.single pkg.installed name=lsof

把minion的返回结果直接写到mysql,写到mysql的不是master写的，而是minion直接写的。因为Saltstack是python写的，minion又要写到mysql，所以minion要安装MYSQL-python软件
需要用到的模块：return
[root@SaltstackServer ~]# salt '*' state.single pkg.installed name=MySQL-python
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

#安装mariadb [root@SaltstackServer ~]# salt '*' state.single pkg.installed name=mariadb-sever
返回结果到mysql参考URL：
https://docs.saltstack.com/en/latest/ref/returners/all/salt.returners.mysql.html
#############################在数据库上创建mysql表
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
授权：
grant all on salt.* to salt@'%' identified by 'salt@pw';
##########################
[root@SaltstackServer ~]# vim /etc/salt/minion
#在所有minion上设置连接数据库参数
mysql.host: '192.168.1.235'
mysql.user: 'salt'
mysql.pass: 'salt@pw'
mysql.db: 'salt'
mysql.port: 3306                                          
[root@SaltstackServer ~]# systemctl restart salt-minion
[root@SaltstackServer ~]# salt '*' test.ping --return mysql
#查询到minion的返回结果：MariaDB [salt]> select * from salt_returns \G;
MariaDB [salt]> select * from salt_returns \G;
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

#如何编写一个状态模块：
1. 模块放置位置：cd /srv/salt;mkdir _modules;vim my_disk.py
2. 命名：文件名就是模块名：
[root@SaltstackServer /srv/salt/_modules]# cat my_disk.py 
def list():
  cmd = 'df -h'
  ret = __salt__['cmd.run'](cmd)
  return ret
3. 刷新
[root@SaltstackServer /srv]# salt '*' saltutil.sync_modules
linux-node1:
SaltstackServer.com:
4. 执行：
[root@SaltstackServer /srv]# salt '*' my_disk.list
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

小结：
1.minion启动时收集本地信息成为grains的键值对
2.使用grains可用于目标选择，配置管理，信息查询。
3.grains不用top文件亦可执行，例：( salt -G 'os:Centos' state.sls web.apache ),但pillar却不行，pillar只有top文件才能执行
4.grains目标选择也可以写入/srv/salt/top.sls文件中使用。
5.grains自定义优先组：1.系统自带，2.minion端/etc/salt/grains自定义，需要重启minion服务，3.minion端/etc/salt/minion自定义，需要重启minion服务，4.master端/srv/salt/_grains/*.py自定义,需要使用（salt '*' saltutil.sync_grains）命令来同步。
6.pillar常用于机密信息处理，grains常用于普通信息处理。
7.pillar的描述文件在/srv/pillar/*.sls，pillor的top文件在/srv/pillar/top.sls，pillar的描述文件编写完成后必需刷新才能生效，命令：(salt '*' saltutil.refresh_pillar)
8.自定义模块可满足自己的需要，在/srv/salt/_modules/目录下编写*.py文件

文件路径：
1. master配置文件：/etc/salt/master
2. minion配置文件：/etc/salt/minion
3. master下发任务到minion后minion同步的路径：/var/cache/salt/minion
4. minion和master的公钥和私钥路径：/etc/salt/pki/minion/和/etc/salt/pki/master/
5. minion的id文件路径：/etc/salt/minion_id
6. minion的自定义item目录1./etc/slat/grains 2./etc/salt/minion
7. master上的top file文件路径：/srv/salt/top.sls
8. master上的pillar的top file文件路径：/srv/pillar/top.sls
9. master上的pillar的描述文件路径：/srv/pillar/*.sls
10. master上的描述文件路径：/srv/salt/*.sls
11. master自定义grains路径：/srv/salt/_grains/*.py
12. master自定义模块路径：/srv/salt/_modules/*.py
</pre>
