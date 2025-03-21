# Cobbler




## 1. 设备和系统规范

### 1.1 物理设备层面
1. 服务器标签化（IP地址和机柜上第几台）、设备负责人、设备采购详情、设备摆放标准（负载均衡设备一个机柜放一台）
2. 网络划分、远程控制卡、网卡端口、
3. 服务器机型、硬盘、内存统一。根据业务分类。
4. 资产命名规范（FWQ-web、FWQ-db）、编号规范（00开头是网络设备、10开头是服务器，）、类型规范
5. 监控标准（日志、CPU温度）



### 1.2 操作系统层面
1. 操作系统版本统一
2. 系统初始化（DNS,NTP,内核参数调优、rsyslog、主机名规范）
3. 基础Agent配置（Zabbix Agent、Logstash Agent、Saltstack minion）
4. 系统监控标准（CPU、内存、硬盘、网络、进程）
5. history记录时间，把这个指令放到/etc/profile下
	 export HISTTIMEFORMAT="%F %T `whoami` "
6. 日志记录操作，把这个指令放到/etc/profile下
	 export PROMPT_COMMAND='{ msg=$(history 1 | { read x y; echo $y; });logger "[euid=$(whoami)]":$(who am i):[`pwd`]"$msg";}'
7. 内核参数优化
8. yum仓库
9. 主机名解析
10. 当前我公司使用操作系统为CentOS6和CentOS7,均使用x86_64位系统，需使用公司cobbler进行自动化安装，禁止自定义设置。
11. 版本选择，数据库统一使用cobbler上CentOS-7-DB这个专用的profile，其他Web应用统一使用Cobbler上CentOS-7-web。



### 1.3 主机名命名规范
**机房名称-项目-角色-集群-节点.域名**
例如：idc01-xxshop-nginx-bj-node1.shop.com



### 1.4 服务启动用户规范
1. 所有服务，统一使用www用户，uid为666
2. 除负载均衡需要监听80端口使用的root启动外，所有服务使用大于1024的端口必须使用www用户启动




## 2. 应用服务规范
1. Web服务软件选型（Apache,Nginx）
2. 进程启动用户、端口监听规范（Apache:8080,Nginx:8081）、日志收集规范（访问日志、错误日志、运行日志）
3. 配置管理（配置文件规范、脚本规范（存放目录统一））
4. 架构规范（Nginx+Keepalived、LVS+Keepalived等等）
5. 部署规范（位置、包命名等）



## 3. 运维操作规范
1. 机房巡检流（周期、内容、报修流程）
2. 业务部署流程（先测试、后生产、回滚）
3. 故障处理流程（紧急处理、故障升级、重大故障管理）
4. 工作日志标准（如何编写工作日志）
5. 业务上线流程（1.项目发起2.部署服务3.先测试后生产4.加监控5.备份）
6. 业务下线流程（谁发起，数据如何处理）
7. 运维安全规范（密码复杂度，密码更改周期、VPN使用规范、服务器登录规范）




## 4. 工具化
1. Shell脚本（功能性（流程）脚本、检查性脚本、报表性脚本）
2. 开源工具：（Zabbix(监控)、ELKStack(日志收集和分析)、SaltStack(批量管理和配置管理)、Cobbler自动化安装的）(目的自动化)
	**目标：**
	1. 促进标准化的实施
    2. 将重复的操作简单化
    3. 将多次操作流程化
    4. 减少人为操作的低效和降低故障率
	5. 工具化和标准化是好基友
	**痛点：**
	1. 你至少要ssh到服务器执行。可能犯错
	2. 多个脚本有执行顺序的时候，可能犯错。
	3. 权限不好管理，日志没法统计。
	4. 无法避免手工操作。
	
	
	
## 5. 运维平台
例子：运维管理平台、堡垒机可以录制运维的任何视频，可以回放查证
1. 做成Web界面，底层是命令或脚本
2. 权限控制
3. 日志记录
4. 弱化流程
5. 不用ssh到服务器，减少人为操作造成的故障   web ssh连接




## 6. 服务化（API化）
1. DNS Web管理	bind-DLZ	dns-api
2. 负载均衡Web管理	slb-api
3. Job管理平台	job-api
4. 监控平台 Zabbix	zabbix-api
5. 操作系统安装平台	cobbler-api
6. 部署平台		deploy-api
7. 配置管理平台	saltstack-api
8. 自动化测试平台	test-api
	1. 调用cobbler-api安装操作系统
	2. 调用saltstack-api进行系统初始化
	3. 调用dns-api解析主机名
	4. 调用zabbix-api将该新上线机器加上监控
	5. 再次调用saltstack-api部署软件（安装Nginx+PHP）
	6. 调用deploy-api将当前版本的代码部署到服务器上
	7. 调用test-api测试当前服务运行是否正常
	8. 调用slb-api将该节点加入集群


**关于自动化的要点：**
1. 运维自动化发展层级：
	1. 标准化、工具化
	2. Web化、平台化
	3. 服务化、API化
	4. 智能化
> 智能化的自动化扩容、缩容、服务降级、故障自愈

触发机制——决策系统（决策树）——自动化扩容：zabbix触发Action
触发：
1. 当某个集群的访问量超过最大支撑量，比如10000
2. 并持续5分钟
3. 不是攻击
4. 资源池有可用资源
	 4.1 当前网络带宽使用率
	 4.2 如果是公有云——钱够不够
5. 当前后端服务支撑量是否超过阈值，如果超过应该先扩容后端
6. 数据库是否可以支撑当前并发
7. 当前自动化扩展队列，是否有正在扩容的节点
8. 其它业务相关的。
	1. 先判断Buffer是否有最近X小时之前已经创建过的移除虚拟机，并查询软件版本是否和当前一致，如果一致则跳过234步骤，如果不一致则跳过23
	2. Openstack创建虚拟机
	3. Saltstack配置环境——加监控
	4. 部署系统部署当前代码
	5. 测试服务是否可用（如果不可用，实力补时5秒，实力补时30秒，还是不可用则提示扩容失败并退出）
	6. 加入集群
	7. 通知（短信、邮件）
	

自动化缩容：
1. 触发条件和决策
2. 从集群中移除节点-关闭监控-移除
3. 通知
4. 移除的节点存放于Buffer里面
5. Buffer里面超过1天的虚拟机，自动关闭，存放于XX区
6. XX区的虚拟机，每7天清理删除




## 7. 基于ITIL的IT运维体系
1. ITSM是ITIL的前身
2. ITIL（IT基础架构库）：不是硬件也不是软件，是一个可以直接使用的标准

**ITIL目的：**
1. 将IT管理工作标准化，模式化。减少人为误操作带来的隐患
2. 通过服务目录，服务报告，告诉业务部门，我们可以做什么，做了什么。
3. 通过系列流程，知识库减轻对英雄式工程师的依赖，把经验积累下来。
4. 通过对流程的管控，减少成本，降低风险，提高客户满意度。
> 个人: ITIL
> 机构: ISO20000

运维经理和运维总监：服务管理(ITIL)和项目管理(PMP)
戴明环（PDCA）: P计划(planing)——D实施(do)——C检查(check)——A处理(act)

**ITIL：成为一名运维经理**
	技术：运维知识体系
	除了技术：
	1. 服务管理  ITIL
	2. 项目管理  PMP
	做人（有时比其他还重要）
	
**ITIL v3将ITIL理论分成了五部分**
1. 服务战略
2. 服务设计
3. 服务转换
4. 服务运营
5. 持续服务改进



**服务运营(和运维技术最近)**
SLA: 服务级别协议
OLA: 运营水平协议
CSF: 关键成功因素
KPI：关键绩效指标（来考核年终奖）
服务台：客户与技术沟通的钮带
服务运营：故障管理：输入输出
所有流程都要有输入输出：
	输入：故障请求提交
	输出：故障分类汇总统计表
服务运营：问题管理





## 8. 自动化装机平台cobbler


### 8.1 Cobbler自动化部署流程
1. 网卡上的pxe芯片有512字节，存放了DHCP和TFTP的客户端。
2. 启动计算机选择网卡启动
3. PXE上的DHCP客户端会向DHCP服务器请求IP。
4. DHCP服务器分配给它IP的同时通过以下字段告诉pxe，TFTP的地址和它要下载的文件：
	 a)	name-server 192.168.1.237(TFTP服务器)
	 b)	Filename "pxelinux.0"(要下载的文件)
5. pxelinux.0告诉pxe要下载的配置文件是pxelinux.cfg目录下的default
6. pxe下载并依据配置文件的内容下载启动必须的文件，并通过ks,cfg开始系统安装



### 8.2 Cobbler自动化安装
版本为cobbler2.8
```bash
# 8.2.1 配置源和安装必备软件
yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
yum install -y httpd dhcp tftp cobbler cobbler-web pykickstart xinetd

# 安装步骤：cobbler安装centos7内存最低要求为2G
1. systemctl start httpd 
2. systemctl start cobblerd
3. 关闭selinux和iptables
4. 第一步执行cobbler check检查，可以忽略1，2不用设置，如果是虚拟机则还可以忽略3
	1 : debmirror package is not installed, it will be required to manage debian deployments and repositories
	2 : fencing tools were not found, and are required to use the (optional) power management features. install cman or fence-agents to use them
	3 : Some network boot-loaders are missing from /var/lib/cobbler/loaders.  If you only want to handle x86/x86_64 netbooting, you may ensure that you have installed a *recent* version of the syslinux package installed and can ignore this message entirely.  Files in this directory, should you want to support all architectures, should include pxelinux.0, menu.c32, elilo.efi, and yaboot.
5. vim /etc/cobbler/settings 
next_server 192.168.1.237(为TFTP主机)
server: 192.168.1.237(为cobbler主机)
manage_dhcp: 1   # 设置cobbler使用dhcp模板文件管理设置dhcp
yum_post_install_mirror: 0   # 不推送cobbler自带的yum仓库
6.	将/etc/xinetd.d/tftp中的disable设为no # 因为设置了tftp所以这里要开启tftp
systemctl restart cobblerd
7.	cobbler get-loaders  # 运行获取cobbler所需的文件
[root@autodep ~]# systemctl enable httpd cobblerd xinetd dhcpd rsyncd
[root@autodep ~]# systemctl start xinetd dhcpd rsyncd
8.	systemctl restart cobblerd  #重启cobbler的服务
# 生成加密密码，并在/etc/cobbler/settings将default_password_crypted 值设为刚才生成的加密密码，此密码为自动化部署成功后root密码,'cobbler888'为设置后的密码，'cobbler'为描述信息
9.	openssl passwd -1 -salt 'cobbler' 'cobbler888' 
10.	vim /etc/cobbler/dhcp.template ，# 修改如下内容：
subnet 192.168.1.0 netmask 255.255.255.0 {
     option routers             192.168.1.254;
     option domain-name-servers 114.114.114.114;
     option subnet-mask         255.255.255.0;
     range dynamic-bootp        192.168.1.100 192.168.1.254;
11. systemctl restart cobblerd
# 同步cobbler的配置，自动生成dhcp的配置文件并自动重启，先挂载Centos7.5镜像，然后导入Centos7.5镜像才行
12. cobbler sync
# 导入系统镜像的路径，镜像名字为CentOS-7-X86_64，系统位数为x86_64，导入后的镜像路径在/var/www/cobbler/ks_mirror/下,/mount/路径是已经挂载的系统镜像，必需要挂载才能读，删除不需要的镜像：cobbler profile remove --name=CentOS-7-X86_64 --recursive
mount -t iso9660 /dev/cdrom /mnt/
13. cobbler import --path=/mount/ --name=CentOS-7-x86_64 --arch=x86_64
14. cobbler profile  # 可查看镜像的命令
Cobbler profile report  # 查看详细的参数信息
# 导入kickstart文件，作用是指定CentOS7系统镜像的kickstart文件配置，事先要导入到这个默认位置
cobbler profile edit --name=CentOS-7-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.cfg   
cobbler profile edit --name=CentOS-7-x86_64 --kopts='net.ifnames=0 biosdevname=0'  # 使自动化安装Centos7更改linux内核参数，使网卡名称为eth0、eth1
15. cobbler sync  # 同步更改后的配置

## 镜像导入失败
-----------------------
[root@cobbler ~]# cobbler import --path=/mnt --name=Rocky-9.5-x86_64 --arch=x86_64
task started: 2024-11-21_195424_import
task started (id=Media import, time=Thu Nov 21 19:54:24 2024)
Found a candidate signature: breed=suse, version=opensuse15.0
Found a candidate signature: breed=suse, version=opensuse15.1
Found a candidate signature: breed=redhat, version=rhel8
No signature matched in /var/www/cobbler/ks_mirror/Rocky-9.5-x86_64
!!! TASK FAILED !!!
-----------------------
# 原因：Rocky Linux 9.5 存储库没有匹配的签名 cobbler signature update
# 解决： 更新 Cobbler 签名：cobbler signature update无效，最终将cobbler部署在RockyLinux9.5之上才能导入成功，cobbler版本为3.3.4
-----------------------



# CentOS-7-x86_64.cfg的kickstart配置文件参数，另centos的kickstart默认文件sample_end.ks也可以安装centos，只是不能像这样定制化安装
[root@autodep kickstarts]# cat CentOS-7.6-DVD-1810.iso-x86_64.ks 
lang en_US
keyboard us
timezone Asia/Shanghai
rootpw --iscrypted $default_password_crypted
text
install
url --url=$tree
bootloader --location=mbr
zerombr
clearpart --all --initlabel
part /boot --fstype xfs --size 1024 --ondisk sda
part / --fstype xfs --size 1 --grow --ondisk sda
auth --useshadow --enablemd5
$SNIPPET('network_config')
reboot
firewall --disabled
selinux --disabled
skipx
%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
$SNIPPET('pre_anamon')
%end

%packages
@base
@core
tree
sysstat
iptraf
ntp
lrzsz
ncurses-devel
openssl-devel
zlib-devel
OpenIPMI-tools
mysql
nmap
screen
%end
%post
systemctl disable postfix.service

rm -f /etc/yum.repos.d/*
cat >>/etc/yum.repos.d/epel.repo<<eof  # 这个cat..eof在%post中只能使用一次,变量内容需要转义，否则会报错，注释里有中文或者配置文件中有中文会导致安装系统错误，装机是应删除
[epel]
name=Extra Packages for Enterprise Linux 7 - \$basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/\$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/7/\$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/7/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
eof

$yum_config_stanza
%end
```



### 8.3 Cobbler自动化重装
```bash
1. 在tftp client端执行：
rpm –ivh https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
Yum install –y koan
Koan –-server=192.168.1.237 --list=profiles  查看可以重装的系统</pre>
2. Koan --replace-self --server=192.168.1.237 --profile=CentOS6-x86_64  # tftp客户端自动安装指定系统版本
3. Cobbler 网页管理: https://192.168.1.237/cobbler_web # 用户名和密码默认都是:cobbler 
# 如果无法访问请安装
[root@autodep certs]# yum install python2-pip
[root@autodep certs]# pip install ipaddress
[root@autodep certs]# pip install Django==1.8.9
4. 修改cobbler网页版默认密码：htdigest /etc/cobbler/users.digest  "Cobbler" cobbler 	# "Cobbler"为用户描述信息，cobbler为要改密码的用户名）
5. vim /etc/cobbler/pxe/pxedefault.template   # 更改自动部署提示信息并设置默认从哪个盘启动，都在此目录
```



### 8.4 用cobbler来创建yum源
```bash
# 1. 
[root@localhost cobbler]#cobbler repo add --name=openstack-rocky --mirror=https://mirrors.aliyun.com/centos/7.5.1804/cloud/x86_64/openstack-rocky/ --arch=x86_64 --breed=yum  
[root@autodep kickstarts]# cobbler repo add --name=epel --mirror=https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm --arch=x86_64 --breed=yum

# 2. 同步新创建的openstack-rocky --yum源到/etc/yum.repo.d/下，此步骤客户端才会自动同步，服务端不会自动同步，需要自己从/var/www/cobbler/ks_mirror/下复制一份config.repo到/etc/yum.repo.d/下
Cobbler reposync

# 3. 将新建的openstack源添加到kickstack中，使以后新装的Centos7系统自动加入新建立的源，以下二选一
Cobbler profile edit --name= CentOS-7-X86_64-x86_64 --repos=”openstack-rocky” 
# 前提要在/etc/cobbler/settings中要把yum_post_install_mirror设置成为1，使其为开启状态，并且还要在你自定义的kickstart文件中[/var/lib/cobbler/kickstarts/CentOS-7-x86_64.cfg]在最后加入这个配置$yum_config_stanza才能使用户在自动化安装系统时生效
# Cobbler profile edit --name= CentOS-7-X86_64-x86_64 --repos=”https://mirrors.aliyun.com/centos/7.5.1804/cloud/x86_64/openstack-rocky/”
# reposync要同步成功，repo源必须为repodata结尾，一个连接地址是不行的，因为需要同步rpm包到本地

# 4. 例：
	%post
	systemctl disable postfix.service
	$yum_config_stanza
	%end
然后同步：cobbler  reposync

# 5.新购买服务器得知MAC地址后接入装机vlan后自动化安装并设置网络、主机名信息：
[root@autodep yum.repos.d]# cobbler system add --name=cobbler.jack.com --mac=00:50:56:ad:36:65 --profile=CentOS-7.6-DVD-1810.iso-x86_64 --ip-address=192.168.1.237 --subnet=255.255.255.0 --gateway=192.168.1.254 --interface=eth0 --name-servers=114.114.114.114 --static=1 --hostname=cobbler.jack.com --kickstart=/var/lib/cobbler/kickstarts/CentOS-7.6-DVD-1810.iso-x86_64.ks
Cobbler system list 查看指定mac地址配置的主机设置列表
Cobbler sync	
```



### 8.5 网卡绑定
绑定也称为中继或组合。不同的供应商使用不同的名 它用于将多个物理接口连接到一个逻辑接口，以实现冗余和/或性能。
您可以设置绑定，将接口eth0和eth1连接到故障转移（主动 - 备份）接口bond0，如下所示：
```bash
$ cobbler system edit --name=foo --interface=eth0 --mac=AA:BB:CC:DD:EE:F0 --interface-type=bond_slave --interface-master=bond0
$ cobbler system edit --name=foo --interface=eth1 --mac=AA:BB:CC:DD:EE:F1 --interface-type=bond_slave --interface-master=bond0
$ cobbler system edit --name=foo --interface=bond0 --interface-type=bond --bonding-opts="miimon=100 mode=1" --ip-address=192.168.1.100 --netmask=255.255.255.0
```




### 8.6 初始化操作
* 设置DNS	192.168.56.111 192.168.56.112
* 安装Zabbix Agent:	Zabbix Server 192.168.56.112
* 安装Saltstack Minion: Saltstack Master:192.168.56.11



### 8.7 目录规范
* 脚本放置目录：/opt/shell
* 脚本日志目录：/opt/shell/log
* 脚本锁文件目录：/opt/shell/lock



### 8.8 程序服务安装规范
```bash
1. 源码安装路径：/usr/local/appname.vsesion
2. 创建软连接：ln -s /usr/local/appname.version /usr/local/appname
```



### 8.9 批量部署ubuntu
```bash
[root@prometheus os]# mount ubuntu-16.04.7-server-amd64.iso /mnt/
[root@prometheus os]# cobbler import --name=ubuntu-16.04.7-server --arch=x86_64 --path=/mnt
[root@prometheus os]# cobbler profile edit --name=ubuntu-16.04.7-server-x86_64 --kickstart=/var/lib/cobbler/kickstarts/sample.seed --kopts="net.ifnames=0 biosdevname=0"   #使用cobbler自带的默认kickstart进行安装
[root@prometheus os]# cobbler profile report --name=ubuntu-16.04.7-server-x86_64
[root@autodep kickstarts]# cobbler sync
# 注：以上完成后即可对ubuntu自动化进行安装
```



### 8.10 安装Windows7系统
自己实际操作中，可以进入PXE win7界面，需要按任意键进入安装，但是下一步时无法获取ip地址，导致无法执行setup.exe安装程序进行安装
```
# 使用Windows AIK（适用于win7的）工具来定制Win PE，需要去Microsoft官网下载ISO包
1. win7AIK下载链接：https://download.microsoft.com/download/6/3/1/631A7F90-E5CE-43AA-AB05-EA82AEAA402A/KB3AIK_CN.iso
2. 解压AIK包
3. 进入解压后的目录，双击StartCD.exe，点击Windows AIK安装程序 开始安装
4. 安装完毕后，在开启菜单以管理员权限启动'部署工具命令提示'这个工具来定制Win PE镜像
5. 通过命令行制作Win PE镜像,ip地址为Cobbler服务器地址，以后安装时需要进行连接的
--------------------- 
进入一个盘，例如这里进入E盘
C:\Program Files\Windows AIK\Tools\PETools> D:
生成Win PE预安装文件
D:\> copype amd64 D:\winpe
挂载成可读写形式
D:\> imagex /mountrw D:\winpe\winpe.wim 1 D:\winpe\mount
制作start脚本
D:\> echo ping -n 7 -l 69 192.168.1.233 >> D:\winpe\mount\Windows\System32\startnet.cmd
D:\> echo net use Z: \\192.168.1.233\share >> D:\winpe\mount\Windows\System32\startnet.cmd
D:\> echo Z: >> D:\winpe\mount\Windows\System32\startnet.cmd
D:\> echo cd win >> D:\winpe\mount\Windows\System32\startnet.cmd
D:\> echo setup.exe /unattend:Autounattend.xml >> D:\winpe\mount\Windows\System32\startnet.cmd
卸载
D:\> imagex /unmount D:\winpe\mount /commit
复制启动文件
D:\> copy D:\winpe\winpe.wim D:\winpe\ISO\sources\boot.wim
生成Win PE ISO镜像
D:\> oscdimg -n -bD:\\winpe\etfsboot.com D:\winpe\ISO D:\\winpe\winpe_cobbler_amd64.iso
--------------------- 
#注：上一步中已经定制好了Win PE ISO镜像，接下来我们需要像前面安装CentOS/Ubuntu系统那样，把它导入到Cobbler Server端中。也是下面的三个流程
上传ISO镜像到 Cobbler Server 端
导入ISO镜像到 Cobbler Server 端
配置ISO镜像相关自动值守安装文件
6. 导入ISO镜像
[root@autodep down]# cobbler distro add --name=windows7 --kernel=/var/lib/tftpboot/memdisk --initrd=/down/winpe_cobbler_amd64.iso --kopts="raw iso"
7. 配置ISO镜像的无人值守安装文件
# touch /var/lib/cobbler/kickstarts/win7pe.xml
#cobbler profile add --name=windows7 --distro=windows7 --kickstart=/var/lib/cobbler/kickstarts/win7pe.xml
注：事实上，该自动值守安装文件并没有作用，它不像CentOS的ks以及Ubuntu的Preseed文件那样，内含有操作系统的那些设置，它的作用在于每个系统distro必须有一个profile，因此尽管它并不是实际用来设定系统设置的，但也要指定。这里的win7pe.xml文件可以为空白，但必须要存在。
## 通过samba共享Windows ISO：
前面已经完成Win PE ISO镜像定制，该ISO镜像通过PXE启动后，能够根据定制中的脚本命令自动获取Windows 7镜像并安装，获取Windows 7镜像的方式是通过网络共享下载。既然是通过网络共享，那么Windows 7镜像就要通过网络共享提供出来，这里使用的方法是使用samba文件共享，通过Cobbler Server端安装部署samba文件共享，提供Windows 7镜像。这里使用的Windows 7 ISO镜像并不是ghost之类的修改版，而是微软官方发布的原生纯净ISO，如果你需要获得相关镜像，可以自行去微软MSDN或者某些网站下载。具体如下：
8. 安装Samba服务
yum install samba -y
9. 配置Samba文件
---------------------
# vi /etc/samba/smb.conf
[global]
        map to guest = bad user
        workgroup = jackligroup
        netbios name = jackliserver
        server string = Samba Server Version %v

        unix charset = utf8
        display charset = utf8
        dos charset = cp950

        log file = /var/log/samba/log.%m
        max log size = 50
        security = user
[share]
        comment = share directory
        path = /smb/
        writable = yes
        browseable = yes
        directory mask = 0755
        create mask = 0755
        guest ok = yes
--------------------- 
10. 配置win7共享文件夹
--------------------- 
# mkdir -p /smb/win
# mkdir /mnt/win7
# mount /root/cn_windows_7_ultimate_with_sp1_x64_dvd_u_677408.iso /mnt/win7
# cp -rf /mnt/win7/* /smb/win/
# chmod -R +x /smb
--------------------- 
#注：上面的命令主要功能是创建samba共享文件夹、挂载Windows 7 ISO镜像、拷贝Windows 7 ISO镜像内容到samba共享文件夹中。实际上，这里的文件不仅仅是Windows 7 ISO镜像解压后的内容，还有一个名为“Autounattend.xml”的文件，这个文件并没有通过上面的操作放入到samba共享文件夹中，它的作用和如何生成会在最后一步解释。
11. 启动Samba服务
# systemctl start smb
# systemctl enable smb
12. 验证smb能否访问
#注：客户机器PXE启动安装：
在第二步中配置ISO镜像自动值守安装文件时，说明到那里指定的profile文件可以为空，并不是实际的生效配置文件，第三步中也说到samba共享文件中不仅仅是Windows 7 ISO镜像解压后的内容，还有一个名为“Autounattend.xml”的文件。事实上，到这里已经很清楚，第二步中的空白profile文件无意义，有意义的文件跑到了第三步samba共享文件中。这个文件指定Windows 7系统安装时的参数，比如账号，硬盘分区，防火墙等。
13. 添加Autounattend.xml文件添加到/smb/win/下
[root@autodep /]# scp root@192.168.1.19:/Share/Info/3CDaemon/Autounattend.xml /smb/win
--------------------Autounattend.xml文件内容--------------------
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>zh-CN</UILanguage>
            </SetupUILanguage>
            <InputLocale>zh-CN</InputLocale>
            <SystemLocale>zh-CN</SystemLocale>
            <UILanguage>zh-CN</UILanguage>
            <UserLocale>zh-CN</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserData>
                <ProductKey>
                    <Key>87VT2-FY2XW-F7K39-W3T8R-XMFGF</Key>
                </ProductKey>
                <AcceptEula>true</AcceptEula>
            </UserData>
            <ImageInstall>
                <OSImage>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/image/index</Key>
                            <Value>4</Value>
                        </MetaData>
                    </InstallFrom>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>1</PartitionID>
                    </InstallTo>
                </OSImage>
            </ImageInstall>
            <DiskConfiguration>
                <Disk wcm:action="add">
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Active>true</Active>
                            <Extend>false</Extend>
                            <Format>NTFS</Format>
                            <Label>OS</Label>
                            <Letter>C</Letter>
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                        </ModifyPartition>
                    </ModifyPartitions>
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Size>30000</Size>
                            <Type>Primary</Type>
                        </CreatePartition>
                    </CreatePartitions>
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                </Disk>
            </DiskConfiguration>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>UABhAHMAcwB3AG8AcgBkAA==</Value>
                            <PlainText>false</PlainText>
                        </Password>
                        <DisplayName>GoSun.Inc</DisplayName>
                        <Group>Administrators</Group>
                        <Name>gosun</Name>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <OOBE>
                <ProtectYourPC>3</ProtectYourPC>
                <NetworkLocation>Work</NetworkLocation>
            </OOBE>
            <TimeZone>China Standard Time</TimeZone>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>*</ComputerName>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:c:/users/observer/desktop/cn_windows_7_ultimate_with_sp1_x64_dvd_u_677408/sources/install.wim#Windows 7 ULTIMATE" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
```



### 8.11 自动化安装系统安装salt-minion
自动化安装cobbler脚本，必需关闭selinux和firewalld
```bash
[root@localhost kickstarts]# cat /shell/autoinstall_cobbler.sh 
#!/bin/sh
#
#install cobbler
## remove: yum remove -y httpd dhcp tftp cobbler cobbler-web pykickstart xinetd

ip=192.168.15.199
echo "1.安装启动"
yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
yum install -y httpd dhcp tftp cobbler cobbler-web pykickstart xinetd 
systemctl start httpd
systemctl start cobblerd
systemctl enable httpd
systemctl enable cobblerd
echo "2.cobbler check"
cobbler check
echo "3.修改cobbler配置"
sed -i "s/next_server: 127.0.0.1/next_server: ${ip}/g" /etc/cobbler/settings   #ip地址一定要跟当前服务器一样，否则cobbler命令会用不了，会报错
sed -i "s/server: 127.0.0.1/server: ${ip}/g" /etc/cobbler/settings
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings
sed -i '/disable/{s/yes/no/;}' /etc/xinetd.d/tftp
echo "4.获取cobbler引导文件#运行获取cobbler所需的文件"
cobbler get-loaders 
echo "5.启动tftp and rsyncd"
systemctl start xinetd
systemctl enable xinetd
systemctl start rsyncd
systemctl enable rsyncd
echo "6.set root of password"
passwd=$(openssl passwd -1 -salt 'cobbler' 'cobbler888')
str1='default_password_crypted: "'
str2=\"
full_passwd=${str1}${passwd}${str2}
sed -i '/default_password_crypted/{d}' /etc/cobbler/settings  #先删除默认密码
echo ${full_passwd} >> /etc/cobbler/settings  #再添加系统密码
echo "7.更改dhcp模板"
sed -i '/subnet 192/{s/192.168.1.0/192.168.15.0/}' /etc/cobbler/dhcp.template
sed -i '/option routers/{s/192.168.1.5/192.168.15.1/}' /etc/cobbler/dhcp.template
sed -i '/option domain-name-servers/{s/192.168.1.1/8.8.8.8/}' /etc/cobbler/dhcp.template
sed -i '/option subnet-mask/{s/255.255.0.0/255.255.255.0/}' /etc/cobbler/dhcp.template
sed -i '/range dynamic-bootp/{s/192.168.1.100/192.168.15.50/;s/192.168.1.254/192.168.15.90/}' /etc/cobbler/dhcp.template
sleep 1
echo "8.重载cobbler配置并启动dhcp"
systemctl restart cobblerd   #在cobbler同步之前重新启动下cobbler服务，重载下配置，使其生效
sleep 1
cobbler sync   #这一步很重要，不同步可能导致dhcpd服务启动不起来，就是从cobbler同步dhcp配置到dhcpd服务中去
sleep 1
systemctl start dhcpd
systemctl enable dhcpd
```

**剩余步骤手工处理**
```bash
# 导入镜像
cobbler import --path=/mnt/ --name=CentOS-7-x86_64 --arch=x86_64
# 导入后的镜像路径在/var/www/cobbler/ks_mirror/下,/mnt/路径是已经挂载的系统镜像，必需要挂载才能读
# cobbler profile report name=CentOS-7-x86_64
# 指定kickstart文件，作用是指定CentOS7系统镜像的kickstart文件配置，事先要导入到这个默认位置，下面有配置
cobbler profile edit --name=CentOS-7-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.ks	
# 使自动化安装Centos7更改linux内核参数，使网卡名称为eth0、eth1
cobbler profile edit --name=CentOS-7-x86_64 --kopts='net.ifnames=0 biosdevname=0'  
# 同步更改后的配置
cobbler sync  

# 新购买服务器得知MAC地址后接入装机vlan后自动化安装并设置网络、主机名信息：
[root@node1 kickstarts]# cobbler system add --name=node2 --mac=00:50:56:3A:D3:03 --profile=CentOS-7-x86_64 --ip-address=192.168.15.201 --subnet=255.255.255.0 --gateway=192.168.15.1 --interface=eth0 --name-servers=8.8.8.8 --static=1 --hostname=node2 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.ks
[root@localhost kickstarts]# cobbler system add --name=node3 --mac=00:50:56:39:96:7D --profile=CentOS-7-x86_64 --ip-address=192.168.15.202 --subnet=255.255.255.0 --gateway=192.168.15.1 --interface=eth0 --name-servers=8.8.8.8 --static=1 --hostname=node3 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.ks
# 自动化安装加salt
[root@localhost shell]# cat /var/lib/cobbler/kickstarts/CentOS-7-x86_64.ks
lang en_US
keyboard us
timezone Asia/Shanghai
rootpw --iscrypted $default_password_crypted
text
install
url --url=$tree
bootloader --location=mbr
zerombr
clearpart --all --initlabel
part /boot --fstype xfs --size 1024 --ondisk sda
part / --fstype xfs --size 1 --grow --ondisk sda
auth --useshadow --enablemd5
$SNIPPET('network_config')
reboot
firewall --disabled
selinux --disabled
skipx
%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
$SNIPPET('pre_anamon')
%end

%packages
@base
@core
tree
sysstat
iptraf
ntp
lrzsz
ncurses-devel
openssl-devel
zlib-devel
OpenIPMI-tools
mysql
nmap
screen
tree
gcc 
glibc
gcc-c++
pcre-devel
openssl-devel
net-tools
%end
%post
systemctl disable postfix.service
rm -f /etc/yum.repos.d/*

cat >>/etc/yum.repos.d/salt-py3-2019.2.repo<<eof 
[salt-py3-2019.2]
name=SaltStack 2019.2 Release Channel for Python 3 RHEL/Centos
baseurl=https://repo.saltstack.com/py3/redhat/7/x86_64/2019.2
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/saltstack-signing-key, file:///etc/pki/rpm-gpg/centos7-signing-key
eof

cat >> /tmp/.init.sh <<eof
#!/bin/sh
yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
yum install -y salt-minion
echo 'master: 192.168.15.199' > /etc/salt/minion
systemctl start salt-minion
systemctl enable salt-minion
sed -i 's@/tmp/.init.sh@@' /etc/rc.local
sed -i 's@/tmp/.init.sh@@' /etc/rc.d/rc.local
eof

chmod 777 /tmp/.init.sh
echo /tmp/.init.sh >> /etc/rc.local
chmod a+x /etc/rc.local

$yum_config_stanza
%end
```



### 8.12 添加PXE启动菜单密码
```bash
# 生成密码
[root@prometheus rules]# openssl passwd -1 -salt 'homsom' 'jackli'
$1$homsom$oWsW1QF8cEyRzolABzsLC/

# 添加PXE菜单设置时需要的密码
[root@prometheus rules]# cat /etc/cobbler/pxe/pxedefault.template 
DEFAULT menu
PROMPT 0
MENU TITLE Cobbler | http://passport.hs.com/
MENU MASTER PASSWD $1$homsom$oWsW1QF8cEyRzolABzsLC/
TIMEOUT 200
TOTALTIMEOUT 6000
ONTIMEOUT $pxe_timeout_profile

LABEL local
        MENU LABEL (local)
        MENU DEFAULT
        LOCALBOOT -1

$pxe_menu_items

MENU end


# 添加安装系统时的密码，当启用PXE密码时则此选项不生效。
[root@prometheus kickstarts]# cat /var/lib/tftpboot/pxelinux.cfg/default 
[root@prometheus rules]# cat /etc/cobbler/pxe/pxeprofile.template 
LABEL $profile_name
	MENU PASSWD $1$homsom$oWsW1QF8cEyRzolABzsLC/
        kernel $kernel_path
        $menu_label
        $append_line
        ipappend 2
```



```bash
# cobbler_CentOS-7-x86_64_sda_lvm.ks
[root@prometheus kickstarts]# cat cobbler_CentOS-7-x86_64_sda_lvm.ks 
lang en_US
keyboard us
timezone Asia/Shanghai
rootpw --iscrypted $default_password_crypted
text
install
url --url=$tree
bootloader --location=mbr
zerombr
clearpart --all --initlabel
part /boot --fstype xfs --size 1024 --ondisk sda

part pv.31 --fstype="lvmpv" --ondisk=xvda --size=1 --grow
volgroup centos --pesize=4096 pv.31
logvol /  --fstype="xfs" --size=1 --grow --name=root --vgname=centos

auth --useshadow --enablemd5
$SNIPPET('network_config')
reboot
firewall --disabled
selinux --disabled
skipx
%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
$SNIPPET('pre_anamon')
%end

%packages
@base
@core
tree
sysstat
iptraf
ntp
lrzsz
ncurses-devel
openssl-devel
zlib-devel
OpenIPMI-tools
mysql
nmap
screen
tree
gcc 
glibc
gcc-c++
pcre-devel
openssl-devel
net-tools
%end
%post
systemctl disable postfix.service
rm -f /etc/yum.repos.d/*
curl -o /etc/yum.repos.d/centos7.repo http://mirrors.aliyun.com/repo/Centos-7.repo

$yum_config_stanza
%end
```



### 8.13 自动化安装ubuntu18.04.5

[legecy ubuntu download url](http://cdimage.ubuntu.com/ubuntu-legacy-server/releases/20.04/release/)
```bash
# 错误：
[root@prometheus os]# cobbler check
debmirror package is not installed, it will be required to manage debian deployments and repositorie
# 解决：
[root@prometheus os]# yum -y install debmirror 
[root@prometheus os]# sed -i  's|@dists=.*|#@dists=|'  /etc/debmirror.conf 
[root@prometheus os]# sed -i  's|@arches=.*|#@arches=|'  /etc/debmirror.conf 
[root@prometheus os]# cobbler check

# 错误
received on stderr: 
No signature matched in /var/www/cobbler/ks_mirror/ubuntu-20.04.2-x86_64
# 解决
[root@prometheus os]# cobbler signature update

# 导入ubuntu18.04.5
[root@prometheus kickstarts]#  cat /var/lib/cobbler/distro_signatures.json | grep bionic
      "bionic": {
        "version_file_regex": "Codename: bionic|Ubuntu 18.04",
[root@prometheus os]# mount ubuntu-18.04.5-live-server-amd64.iso /mnt/
[root@prometheus os]# cobbler import --name=ubuntu-18.04.5 --arch=x86_64 --path=/mnt/
[root@prometheus os]# cobbler profile edit --name=ubuntu-18.04.5-x86_64 --kickstart=/var/lib/cobbler/kickstarts/ubuntu18.seed --kopts='netcfg/choose_interface=auto biosdevname=0 net.ifnames=0' --kopts-post='net.ifnames=0 biosdevname=0'
[root@prometheus os]# cobbler profile report --name ubuntu-18.04.5-x86_64
[root@prometheus os]# cobbler sync

## 自动化安装
# 此参数不可以自动化安装成功，因为不支持网络配置
cobbler system add --mac=c6:c1:ac:79:c3:c6 --name=ceph02.hs.com --hostname=ceph02.hs.com --interface=eth0 --profile=ubuntu-18.04.5-x86_64 kickstart=/var/lib/cobbler/kickstarts/ubuntu18.seed --ip-address=192.168.13.32 --subnet=255.255.255.0 --gateway=192.168.13.254 --name-servers=192.168.10.250 --static=1
# 此参数可以自动化安装成功，--kopts-post选项可更改网卡名称，--hostname可配置主机名称
cobbler system add --mac=4c:d9:8f:66:19:81 --name=k8s-master01 --hostname=k8s-master01 --kopts='netcfg/choose_interface=auto biosdevname=0 net.ifnames=0' --kopts-post='net.ifnames=0 biosdevname=0' --profile=ubuntu-18.04.5-x86_64 --interface=eth0 --kickstart=/var/lib/cobbler/kickstarts/ubuntu18.seed 

# 多网卡环境网卡选择
当服务器有多块网卡时，会停在网卡选择哪里不动，需要人工进行选择。使用 seed 文件里的 netcfg/choose_interface select 选项指定网卡，并不会生效，这是一个已知的bug。要解决这个问题，需要将此选项传递给内核，则它将按预期工作，更改如下，其余不动，只添加 netcfg/choose_interface=auto 指令。
vim /var/lib/tftpboot/pxelinux.cfg/default
---
LABEL ubuntu-18.04.5-x86_64
	MENU PASSWD $1$homsom$oWsW1QF8cEyRzolABzsLC/
        kernel /images/ubuntu-18.04.5-x86_64/linux
        MENU LABEL ubuntu-18.04.5-x86_64
        append initrd=/images/ubuntu-18.04.5-x86_64/initrd.gz ksdevice=bootif lang=  text biosdevname=0 net.ifnames=0  auto-install/enable=true priority=critical url=http://192.168.13.236/cblr/svc/op/ks/profile/ubuntu-18.04.5-x86_64 hostname=ubuntu-18.04.5-x8664 domain=local.lan suite=bionic
        ipappend 2
---
# 注：安装时客户端如何报错，可按Alt+F2进行TTY切换，然后查看/var/log/syslog日志


## seed file
# ubuntu18.04.5.seed
[root@prometheus kickstarts]# grep -Ev '#|^$' ubuntu18.seed
d-i debian-installer/locale string en_US
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/xkb-keymap select us
d-i keyboard-configuration/toggle select No toggling
d-i keyboard-configuration/layoutcode string us
d-i keyboard-configuration/variantcode string
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string $myhostname
d-i time/zone string Asia/Shanghai
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean false
d-i mirror/country string manual
d-i apt-setup/use_mirror boolean false
d-i mirror/http/hostname string $http_server
d-i mirror/http/directory string $install_source_directory
d-i mirror/http/proxy string
d-i live-installer/net-image string http://$http_server/cobbler/links/$distro_name/install/filesystem.squashfs
# 客户端是硬盘是/dev/sda还是/dev/xvda，xenserver是/dev/xvda，dell主机是/dev/sda
d-i partman-auto/disk string /dev/xvda
#d-i partman-auto/method string regular
d-i partman-auto/method string lvm
#d-i partman-auto-lvm/guided_size string 50%
d-i partman-auto-lvm/guided_size string max
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-md/confirm boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto/choose_recipe select boot-root 
# min_size priority max_size filesystem
d-i partman-auto/expert_recipe string			\
		boot-root ::				\
	1024 50 1024 ext4				\
		$primary{ } $bootable{ }		\
                method{ format } format{ }		\
                use_filesystem{ } filesystem{ ext4 }	\
                mountpoint{ /boot }			\
          	.					\
	5120 100 102400000 xfs				\
		$defaultignore{ }			\
		$lvmok{ }				\
		lv_name{ root }				\
		method{ format }			\
		format{ }				\
		use_filesystem{ }			\
		filesystem{ xfs }			\
		mountpoint{ / }				\
		.					\
 
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i passwd/root-login boolean true
d-i passwd/root-password-crypted password $default_password_crypted
d-i passwd/make-user boolean false
d-i apt-setup/restricted boolean false
d-i apt-setup/universe boolean false
d-i apt-setup/backports boolean false
d-i base-installer/install-recommends boolean false 
d-i debian-installer/allow_unauthenticated boolean true
d-i apt-setup/services-select multiselect security
# cobbler主机IP地址
d-i apt-setup/security_host string 192.168.13.236
# 版本一定要一样，否则会使系统安装异常,例如安装软件依赖异常导致无法安装软件,非常重要
d-i apt-setup/security_path string /cobbler/ks_mirror/ubuntu-18.04.5-x86_64
$SNIPPET('preseed_apt_repo_config')
tasksel tasksel/first multiselect standard
d-i pkgsel/include string ssh wget
d-i grub-installer/grub2_instead_of_grub_legacy boolean true
d-i grub-installer/bootdev string default
d-i debian-installer/add-kernel-opts string $kernel_options_post
d-i finish-install/reboot_in_progress note
d-i preseed/early_command string wget -O- \
   http://$http_server/cblr/svc/op/script/$what/$name/?script=preseed_early_default | \
   /bin/sh -s
d-i preseed/late_command string wget -O- \
   http://$http_server/cblr/svc/op/script/$what/$name/?script=preseed_late_default | \
   chroot /target /bin/sh -s
d-i preseed/late_command string mkdir -p /target/root/.ssh ; \
   wget -O /target/etc/apt/sources.list http://$http_server/cobbler/ks_mirror/bash/sources.list ; \
   wget -P /target/etc/netplan/ http://$http_server/cobbler/ks_mirror/bash/50-cloud-init.yaml.bak ; \
   wget -P /target/root/ http://$http_server/cobbler/ks_mirror/bash/ubuntu18.sh ; \
   wget -P /target/root/ http://$http_server/cobbler/ks_mirror/bash/network.sh ; \
   wget -P /target/root/.ssh/ http://$http_server/cobbler/ks_mirror/bash/authorized_keys ; \
   chmod 400 /target/root/.ssh/authorized_keys ; \
   cd /target ; \
   chroot ./ bash /root/ubuntu18.sh ; \
   echo ""

[root@prometheus bash]# tree /var/www/cobbler/ks_mirror/bash
/var/www/cobbler/ks_mirror/bash
├── 50-cloud-init.yaml.bak
├── authorized_keys
├── network.sh
├── sources.list
└── ubuntu20.sh
-------------------
[root@prometheus bash]# for i in `ls`;do echo "FILENAME: $i";cat $i;done
FILENAME: 50-cloud-init.yaml.bak
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      optional: true
      addresses:
      - 192.168.13.x/24
      gateway4: 192.168.13.254
      nameservers:
        search: 
        - hs.com
        addresses:
        - 192.168.10.250
        - 192.168.10.110
---------------
FILENAME: authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC26kavBRMaXmpBxgSatSO01eelnVpOzq+cPr1qTg4AbAFEL3cFd3N1R3EUsL94AEn8fFd9Ja5SH26xQgf8T3t7oE3KooAepbMhHB8EyYNzfTJksMiJruuK7O4pLyzLqxN7lRX+vUU2IpmNjA8q3PifwtS9Wo/5VcppFg5xa+aiSYSDTvK04IPPMTTEDyNFi+n2uXc1TF+oAqDDPciKLuIsutgcsaVAxEASKNzIRHGoM8Pc0H+/8eTK+igKgYLBZ0W+sKzT20ehsdH+tvGHMLK7VqvB4rg5Hgny3FeIjqX5IwhTvGVP root@prometheus
---------------
FILENAME: network.sh
#!/bin/bash
cd /etc/netplan/
gzip *.yaml
read -p "please ip address: " IP
cat 50-cloud-init.yaml.bak | sed '/\/24$/c "        - '"$IP"'/24' | sed 's/"//' > 50-cloud-init.yaml
chmod 644 50-cloud-init.yaml
netplan apply
cd
---------------
FILENAME: sources.list
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
---------------
FILENAME: ubuntu18.sh
#!/bin/bash

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd
systemctl stop ufw.service
systemctl disable ufw.service
echo -e "NTP=ntp1.aliyun.com\nFallbackNTP=ntp.ubuntu.com" >> /etc/systemd/timesyncd.conf
systemctl restart systemd-timesyncd

apt update
apt install -y vim gcc make gparted net-tools htop screen network-manager

cat >> /etc/security/limits.conf << EOF
*       soft        nofile  655350
*       hard        nofile  655350
*       soft        nproc   655350
*       hard        nproc   655350
root        soft        nofile  655350
root        hard        nofile  655350
root        soft        nproc   655350
root        hard        nproc   655350
EOF

cp /etc/sysctl.conf /etc/sysctl.conf.bak
cat > /etc/sysctl.conf << EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024    65000
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
EOF

/sbin/sysctl -p
chmod +x /root/network.sh

echo 'ubuntu18' > /etc/hostname
hostname ubuntu18

cp /etc/default/grub{,.bak}
sed -i 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"#' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

reboot

rm -rf /root/ubuntu20.sh
```



### 8.14 pxe安装ubuntu20

#### 8.14.1 介绍
1. Ubuntu 20.04 的服务器安装程序支持新的操作模式：自动安装。自动安装可以通过自动安装配置提前回答所有这些配置问题，并使安装过程无需任何交互即可运行。
2. 在Ubuntu 18.04 中，用的应答文件是 preseeds（预配置文件），它基于 debian-installer（aka di）来实现自动安装的。需要注意的是，如果你使用的是 cobbler，那你应该使用 ubuntu-20.04-legacy-server-amd64.iso，而不是 live-server（应该是缺少netboot），Ubuntu 20.04 已没有 server。
3. Ubuntu 20.04 自动安装在以下主要方面与之前的版本有所不同：
	• 应答文件格式完全不同。现在是：cloud-init config，通常为 yaml。而之前是：debconf-set-selections 格式。
	• 当前提条件中不存在问题的答案时，di会停止并要求用户输入。而自动安装不是这样的：默认情况下，如果根本没有任何自动安装配置，则安装程序将使用任何未回答问题的默认设置（如果没有默认问题，安装程序将失败）。在自动安装中可以将配置中的特定部分指定为“交互式”，这意味着安装程序仍将停止并询问这些部分。



#### 8.14.2 环境
PXE + TFTP + HTTP + DHCP + Subiquity（ubuntu 服务器安装程序） 。镜像为：ubuntu-20.04.2-live-server-amd64.iso。注意，引导方式为UEFI。



#### 8.14.3 部署
```bash
## 1、安装相关软件
# isc-dhcp-server ：用来给客户端主机分配可用的IP地址。
# tftpd-hpa ：用来给客户端主机提供引导及驱动文件。
# apache2 ：用来给客户端主机提供镜像、应答文件以及一些自定义的文件脚本之类的。
[jack@ubuntu:/download]$ sudo apt-get -y install tftpd-hpa apache2 isc-dhcp-server whois

# 2、配置 tftp 和 apache
sudo sh -c 'cat > /etc/apache2/conf-available/tftp.conf <<EOF
<Directory /var/lib/tftpboot>
        Options +FollowSymLinks +Indexes
        Require all granted
</Directory>
Alias /tftp /var/lib/tftpboot
EOF'

# 配置tftp根目录为/var/lib/tftpboot
[jack@ubuntu:/var/lib/tftpboot]$ sudo cat /etc/default/tftpd-hpa
----------
# /etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure"
----------
[jack@ubuntu:/download]$ sudo mkdir -p /var/lib/tftpboot
[jack@ubuntu:/download]$ sudo a2enconf tftp 
[jack@ubuntu:/download]$ sudo systemctl restart apache2
# 准备镜像上传到/var/lib/tftpboot/，准备引导文件：vmlinuz（可引导的、压缩的内核），initrd（系统引导过程中挂载的一个临时根文件系统），pxelinux.0（网络引导程序）
[jack@ubuntu:/download]$ sudo mount ubuntu-20.04.2-live-server-amd64.iso /mnt/
[jack@ubuntu:/download]$ sudo cp /mnt/casper/vmlinuz /var/lib/tftpboot/
[jack@ubuntu:/download]$ sudo cp /mnt/casper/initrd /var/lib/tftpboot/
[jack@ubuntu:/download]$ sudo umount /mnt
[jack@ubuntu:/download]$ sudo wget http://archive.ubuntu.com/ubuntu/dists/focal/main/uefi/grub2-amd64/current/grubnetx64.efi.signed -O /var/lib/tftpboot/pxelinux.0
[jack@ubuntu:/download]$ ls /var/lib/tftpboot/
initrd  pxelinux.0  vmlinuz
# 准备grub
[jack@ubuntu:/download]$ sudo mkdir -p /var/lib/tftpboot/grub
sudo sh -c 'cat > /var/lib/tftpboot/grub/grub.cfg <<EOF
default=autoinstall
timeout=0
timeout_style=menu
menuentry "Focal Live Installer - automated" --id=autoinstall {
    echo "Loading Kernel..."
    linux /vmlinuz ip=dhcp url=http://172.168.2.224/tftp/ubuntu-20.04.2-live-server-amd64.iso autoinstall ds=nocloud-net\;s=http://172.168.2.224/tftp/
    echo "Loading Ram Disk..."
    initrd /initrd
}
menuentry "Focal Live Installer" --id=install {
    echo "Loading Kernel..."
    linux /vmlinuz ip=dhcp url=http://172.168.2.224/tftp/ubuntu-20.04.2-live-server-amd64.iso
    echo "Loading Ram Disk..."
    initrd /initrd
}
EOF'

# 3、配置DHCP
[jack@ubuntu:/download]$ sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
sudo sh -c 'cat > /etc/dhcp/dhcpd.conf <<EOF
ddns-update-style none;
subnet 172.168.2.0 netmask 255.255.255.0 {
     option routers             172.168.2.254;
     option domain-name-servers 192.168.10.250;
     option subnet-mask         255.255.255.0;
     range dynamic-bootp        172.168.2.31 172.168.2.32;
     default-lease-time         21600;
     max-lease-time             43200;
     next-server                172.168.2.224;
     filename "pxelinux.0";
}
EOF'
[jack@ubuntu:/download]$ sudo systemctl restart isc-dhcp-server

# 4、准备 cloud.init config，在准备 cloud.init config 前，建议先手动安装一次 ubuntu 20.04.2，在 /var/log/installer/ 目录下会生成一个 autoinstall-user-data ，这是基于当前的系统的应答文件，我们可以以它作为基础，根据实际情况进行修改。
sudo sh -c 'cat > /var/lib/tftpboot/meta-data <<EOF
instance-id: focal-autoinstall
EOF'

# 详细请查阅官方文档：https://ubuntu.com/server/docs/install/autoinstall-reference
[jack@ubuntu:/var/lib/tftpboot]$ sudo cp /var/log/installer/autoinstall-user-data .
sudo sh -c 'cat > user-data <<'EOF'
#cloud-config
autoinstall:
  version: 1
  apt:
    primary:
    - arches: [default]
      uri: http://mirrors.aliyun.com/ubuntu

  user-data:
    timezone: Asia/Shanghai
    disable_root: false
    chpasswd:
      list: |
        root:test@root
  identity: 
    hostname: ubuntu
    realname: jackli
    username: jack
    password: $6$713rnYuUHvka9DPq$Hbb6.8wt39ynfhtu5EmpKG6mOSa.VYKoqmdB/x/FgOIBZf6w8bSG/VQz9gOEqvxwTK.8ZPGxYGotr/4tBQVFv0

  keyboard: {layout: us, variant: dvorak}
  locale: en_US

#mkpasswd -m sha-512 'homsom'
  storage:
    grub:
      reorder_uefi: False
    config:
    - {ptable: gpt, path: /dev/sda, wipe: superblock-recursive, preserve: false, name: ,
      grub_device: false, type: disk, id: disk-sda}
    - {device: disk-sda, size: 209715200, wipe: superblock, flag: boot, number: 1,
      preserve: false, grub_device: true, type: partition, id: partition-0}
    - {fstype: fat32, volume: partition-0, preserve: false, type: format, id: format-0}
    - {device: disk-sda, size: -1, wipe: superblock, flag: , number: 2,
      preserve: false, type: partition, id: partition-1}
    - {fstype: ext4, volume: partition-1, preserve: false, type: format, id: format-1}
    - {device: format-1, path: /, type: mount, id: mount-1}
    - {device: format-0, path: /boot/efi, type: mount, id: mount-0}

  ssh:
    install-server: true

  packages:
  - screen
  - nginx

  late-commands:
  - curtin in-target --target=/target -- wget -P /root/ http://172.168.2.224/tftp/bash/init.sh
  - curtin in-target --target=/target -- wget -P /root/ http://172.168.2.224/tftp/bash/50-cloud-init.yaml
  - curtin in-target --target=/target -- wget -P /root/ http://172.168.2.224/tftp/bash/network.sh
  - curtin in-target --target=/target -- bash /root/init.sh
EOF'

## 5、脚本准备
# 我这里准备了两个脚本（根据实际修改）：
# • init.sh：用于在系统成功重启之前，在安装成功并安装了所有更新和软件包之后运行的初始化脚本。
# • network.sh：用于快速修改网络配置。在装好的系统上执行此脚本，输入IP，即可将动态地址换成静态地址。
[jack@ubuntu:/var/lib/tftpboot]$ sudo mkdir /var/lib/tftpboot/bash
[jack@ubuntu:/var/lib/tftpboot]$ cd /var/lib/tftpboot/bash
[jack@ubuntu:/var/lib/tftpboot/bash]$ cat init.sh 
--------------------------------
#!/bin/bash

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd
systemctl stop ufw.service
systemctl disable ufw.service
echo -e "NTP=ntp1.aliyun.com\nFallbackNTP=ntp.ubuntu.com" >> /etc/systemd/timesyncd.conf
systemctl restart systemd-timesyncd

cat >> /etc/security/limits.conf << EOF
*		soft		nofile	655350
*		hard		nofile	655350
*		soft		nproc	655350
*		hard		nproc	655350
root		soft		nofile	655350
root		hard		nofile	655350
root		soft		nproc	655350
root		hard		nproc	655350
EOF

cp /etc/sysctl.conf /etc/sysctl.conf.bak
cat > /etc/sysctl.conf << EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024    65000
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
EOF
      
/sbin/sysctl -p

rm -rf /root/init.sh
--------------------------------

[jack@ubuntu:/var/lib/tftpboot/bash]$ cat 50-cloud-init.yaml 
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    eth0:
      dhcp4: false
      optional: true
      addresses:
      - 172.168.2.x/24
      gateway4: 172.168.2.254
      nameservers:
        search: 
        - hs.com
        addresses:
        - 192.168.10.250
        - 192.168.10.110
--------------------------------

[jack@ubuntu:/var/lib/tftpboot/bash]$ cat network.sh 
#!/bin/bash
cd /etc/netplan/
gzip *.yaml
read -p "please ip address: " IP
cat 50-cloud-init.yaml.bak | sed '/\/24$/c "            - '"$IP"'/24' | sed 's/"//' > 50-cloud-init.yaml
chmod 644 50-cloud-init.yaml
netplan apply
cd
--------------------------------


---------------------autoinstall------------------------------
[root@prometheus ~]# cat ubuntu-pxe.sh 
#!/bin/sh
#PXE install ubuntu-20.04.2-live-server-amd64.iso 


root_password=`mkpasswd -m sha-512 '000000'`
user_password=`mkpasswd -m sha-512 '111111'`
ISONAME=$1
IPADDR=$2

if [ -z $1 ];then
	echo "USAGE: $0 ubuntu.iso_path ipaddr"	
	exit 1
elif [ -z $2 ];then
	echo "USAGE: $0 ubuntu.iso_path ipaddr"	
	exit 1
fi

#1. install tftpd-hpa apache2 isc-dhcp-server
sudo apt-get -y install tftpd-hpa apache2 isc-dhcp-server whois

#2. config apache2
sudo sh -c 'cat > /etc/apache2/conf-available/tftp.conf <<EOF
<Directory /var/lib/tftpboot>
        Options +FollowSymLinks +Indexes
        Require all granted
</Directory>
Alias /tftp /var/lib/tftpboot
EOF'

#3. config tftp-hpa
sudo sed -i '/^TFTP_DIRECTORY/c TFTP_DIRECTORY="/var/lib/tftpboot"' /etc/default/tftpd-hpa
sudo mkdir -p /var/lib/tftpboot
sudo a2enconf tftp
sudo systemctl restart apache2

#4. mount ubutnu iso
tmpMountDir="/tmp/ubuntu`date +'%Y%m%d%H%M%S'`"
sudo mkdir -p ${tmpMountDir} && sudo mount ${ISONAME} ${tmpMountDir} && sudo cp /${tmpMountDir}/casper/vmlinuz /var/lib/tftpboot/ && sudo cp /${tmpMountDir}/casper/initrd /var/lib/tftpboot/ && sudo umount /${tmpMountDir} && sudo wget http://archive.ubuntu.com/ubuntu/dists/focal/main/uefi/grub2-amd64/current/grubnetx64.efi.signed -O /var/lib/tftpboot/pxelinux.0 && sudo rm -rf ${tmpMountDir}

#5. prepare grub
sudo mkdir -p /var/lib/tftpboot/grub
ISO_SUBNAME=`basename ${ISONAME}`
cat | sudo tee /var/lib/tftpboot/grub/grub.cfg <<EOF
default=autoinstall
timeout=0
timeout_style=menu
menuentry "Focal Live Installer - automated" --id=autoinstall {
    echo "Loading Kernel..."
    linux /vmlinuz ip=dhcp url=http://${IPADDR}/tftp/${ISO_SUBNAME} autoinstall ds=nocloud-net\;s=http://${IPADDR}/tftp/
    echo "Loading Ram Disk..."
    initrd /initrd
}
menuentry "Focal Live Installer" --id=install {
    echo "Loading Kernel..."
    linux /vmlinuz ip=dhcp url=http://${IPADDR}/tftp/${ISO_SUBNAME}
    echo "Loading Ram Disk..."
    initrd /initrd
}
EOF

#6 config isc-dhcp-server
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
cat | sudo tee /etc/dhcp/dhcpd.conf <<EOF
ddns-update-style none;
subnet 192.168.13.0 netmask 255.255.255.0 {
     option routers             192.168.13.254;
     option domain-name-servers 192.168.10.250;
     option subnet-mask         255.255.255.0;
     range dynamic-bootp        192.168.13.75 192.168.13.79;
     default-lease-time         21600;
     max-lease-time             43200;
     next-server                ${IPADDR};
     filename "pxelinux.0";
}
EOF
sudo systemctl restart isc-dhcp-server

#7. config meta-data and user-data
sudo sh -c 'cat > /var/lib/tftpboot/meta-data <<EOF
instance-id: focal-autoinstall
EOF'

cat | sudo tee /var/lib/tftpboot/user-data <<EOF
#cloud-config
autoinstall:
  version: 1
  apt:
    primary:
    - arches: [default]
      uri: http://mirrors.aliyun.com/ubuntu

#mkpasswd -m sha-512 'homsom'
  user-data:
    timezone: Asia/Shanghai
    disable_root: false
    chpasswd:
      list: |
        root:${root_password}
  identity: 
    hostname: ubuntu
    realname: jackli
    username: jack
    password: ${user_password}

  keyboard: {layout: us, variant: dvorak}
  locale: en_US

  storage:
    grub:
      reorder_uefi: False
    config:
    - {ptable: gpt, path: /dev/sda, wipe: superblock-recursive, preserve: false, name: ,
      grub_device: false, type: disk, id: disk-sda}
    - {device: disk-sda, size: 209715200, wipe: superblock, flag: boot, number: 1,
      preserve: false, grub_device: true, type: partition, id: partition-0}
    - {fstype: fat32, volume: partition-0, preserve: false, type: format, id: format-0}
    - {device: disk-sda, size: -1, wipe: superblock, flag: , number: 2,
      preserve: false, type: partition, id: partition-1}
    - {fstype: ext4, volume: partition-1, preserve: false, type: format, id: format-1}
    - {device: format-1, path: /, type: mount, id: mount-1}
    - {device: format-0, path: /boot/efi, type: mount, id: mount-0}

  ssh:
    install-server: true

  packages:
  - screen
  - net-tools
  - network-manager

  late-commands:
  - curtin in-target --target=/target -- wget -P /root/ http://172.168.2.224/tftp/bash/init.sh
  - curtin in-target --target=/target -- wget -P /root/ http://172.168.2.224/tftp/bash/50-cloud-init.yaml
  - curtin in-target --target=/target -- wget -P /root/ http://172.168.2.224/tftp/bash/network.sh
  - curtin in-target --target=/target -- wget -P /root/ http://172.168.2.224/tftp/bash/sources.list
  - curtin in-target --target=/target -- chmod+x /root/init.sh
  - curtin in-target --target=/target -- bash /root/init.sh
EOF


#8. prepare init shell 
sudo mkdir -p /var/lib/tftpboot/bash
cat | sudo tee /var/lib/tftpboot/bash/init.sh << EOFEND
#!/bin/bash

sed -i 's/#PermitRootLogin/c PermitRootLogin yes' /etc/ssh/sshd_config && sed -i 's/LoginGraceTime/c LoginGraceTime 2m' /etc/ssh/sshd_config && sed -i 's/StrictModes/c StrictModes yes' /etc/ssh/sshd_config
systemctl restart sshd
systemctl stop ufw.service
systemctl disable ufw.service
echo -e "NTP=ntp1.aliyun.com\nFallbackNTP=ntp.ubuntu.com" >> /etc/systemd/timesyncd.conf
systemctl restart systemd-timesyncd

cat >> /etc/security/limits.conf << EOF
*		soft		nofile	655350
*		hard		nofile	655350
*		soft		nproc	655350
*		hard		nproc	655350
root		soft		nofile	655350
root		hard		nofile	655350
root		soft		nproc	655350
root		hard		nproc	655350
EOF

cp /etc/sysctl.conf /etc/sysctl.conf.bak
cat > /etc/sysctl.conf << EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024    65000
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
EOF
/sbin/sysctl -p


rm -rf /root/init.sh

EOFEND

cat | sudo tee /var/lib/tftpboot/bash/50-cloud-init.yaml << EOFEND
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    eth0:
      dhcp4: false
      optional: true
      addresses:
      - 192.168.13.x/24
      gateway4: 192.168.13.254
      nameservers:
        search: 
        - hs.com
        addresses:
        - 192.168.10.250
        - 192.168.10.110
EOFEND

cat | sudo tee /var/lib/tftpboot/bash/network.sh << EOFEND
#!/bin/bash
cd /etc/netplan/
gzip *.yaml
read -p "please ip address: " IP
cat 50-cloud-init.yaml.bak | sed '/\/24$/c "            - '"$IP"'/24' | sed 's/"//' > 50-cloud-init.yaml
chmod 644 50-cloud-init.yaml
netplan apply
cd
EOFEND

cat | sudo tee /var/lib/tftpboot/bash/sources.list << EOFEND
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOFEND
------------------------------------------------------------
```



## 问题汇总
```
1. cobbler自动化安装时，客户端无法正常安装？
答：客户端内存最小必须是2G

2. cobbler安装相关硬盘时无法找到/dev/xvda?
答：此时可在客户端安装界面按Tab键进行查看日志，可以得出kickstart文件中是/dev/sda，此时需要更改为相对应设备描述符即可。

3. cobbler客户端安装时显示 “unable to locate configuration file”？
答：此时是因为有另外的服务器开启了PXE功能，所以导致客户端获取文件找到另外的PXE服务器，从而获取文件错误。

4. 客户端获取不取IP地址：DHCPDISCOVER from 42:19:ae:b1:a7:3b via eth0: network 192.168.13.0/24: no free leases
答：rm -rf  /var/lib/dhcpd/dhcpd.leases; touch /var/lib/dhcpd/dhcpd.leases; systemctl restart dhcpd

5. NBP is too big to fit in free base memory
答：启动时不是UEFI而是Legacy，应该选择UEFI即可解决，VMwareWorkstation可在虚拟机‘选项--高级--设置UEFI’即可解决

6. PXE wget: short write: no space left on device
答：内存太小，我给的2G还不够，设成3G就可以了

7. cloud-init未成功启动
答：内存溢出导致，将内存调成最小4G即可启动，这个服务未启动会影响不能自动化安装 

8. 自动化安装未成功执行，而是跳出图形化界面
答：因为自动化程序未成功执行，一般是user-data文件格式错误

9. 安装好系统后键盘输入失灵。
答：不知
```
