#云计算与虚拟化
<pre>
#传统的数据中心面临的问题：
电子商务网站：工信部备案，公安部备案，ICP备案，ICP证
游戏网站：文网文备案
公有云服务器接入备案
IDC租用
VPS：虚拟专用主机
虚拟主机（类似apache虚拟主机）
资源利用率低，资源分配不合理，自动化能力差，初始成本高。

#云计算来了：
云计算是什么：
资源交付的一种模式
1.一种模式
2.云计算必须通过网络使用
3.弹性计算，按需付费，快速扩展。你不用关心太多，都有云计算提供商提供。

#云计算分类：
公有云：阿里云，青云，金山云，腾讯云
私有云：自己搭建私有云。用openstack来搭建。
混合云：私有云和公有云的混合称为混合云，核心数据在私有云，不那么重要的放在公有云上。

云计算的分层：
套装软件层（从硬件到系统到数据应用）=>基础设施服务(ias，从系统到数据应用)=>平台服务(pas，从数据到应用)=>软件服务(sas，全部由提供商来做)

云计算不等于虚拟化。

LXC听说是docker有用到。
LXD性能比KVM更好。
LXCFS来隔离docker,因为docker使用uptime命令获取的是物理机的时间，而不是容器的时间。

硬件虚拟化和软件虚拟化
全虚拟化（硬件虚拟化，kvm）和半虚拟化（xen）
半虚拟化性能比全虚拟化好

kvm:一个8G的内存可以配两个8G的内存，能超配。
xen:一个8G的内存只能能一个8G的内存，不能超配。
虚拟化使用场景：服务器虚拟化、桌面虚拟化、应用虚拟化（xenapp，用浏览器来访问客户端程序）。
KVM（kernel-based Virtual Machine）：以色列创办的，被REDHAT收购了。
RHEV:红帽企业虚拟化。
VMware workstation支持嵌套虚拟机，其他的不行.
QEMU:软件虚拟化软件
KVM:硬件虚拟化

#kvm:
1.vmware workstation在虚拟机中开启VT-x和AMD-V的cpu虚拟化
2.ESXI开户嵌套虚拟化:
1.登录至ESXi Shell 2.find / -name *.vmx 3.找到对应的虚拟机更改配置文件,在最后一行添加vhv.enable = "TRUE"
sed -i '$ avhv.enable = "TRUE"' /vmfs/volumes/570794cb-7a2de328-398b-000c294ee9b7/centos7/centos7.vmx
查看cpu是否支持虚拟化,linux中使用grep -E 'vmx|svm' /proc/cpuinfo 看是否有,有的话现在安装KVM
#安装KVM:
yum install -y qemu-kvm qemu-kvm-tools libvirt  #安装kvm
systemctl start libvirtd    #启动libvirtu
systemctl enable libvirtd
[root@Linux-node1-salt ~]# ifconfig 
virbr0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 192.168.122.1  netmask 255.255.255.0  broadcast 192.168.122.255
        ether 52:54:00:8d:87:d3  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
注:kvm默认帮你安装了个桥接的网上,名字叫virbr0,ip地址永远是192.168.122.1

[root@Linux-node1-salt ~]# ps aux | grep dns
nobody    2772  0.0  0.0  55936  1120 ?        S    23:02   0:00 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
root      2773  0.0  0.0  55908   388 ?        S    23:02   0:00 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
root      2890  0.0  0.0 112708   972 pts/0    S+   23:05   0:00 grep --color=auto dns
注:kvm默认帮你安装启动了dnsmasq(开源工具),这个服务有dns和dhcp的功能,会给你的虚拟机分配ip和dns。[root@Linux-node1-salt ~]# systemctl restart dnsmasq.service为开启dnsmasq,依托NAT模式。网格模式不开启

现在要在kvm上安装一个虚拟机,需要安装一个vnc的客户端,自己先安装好
[root@Linux-node1-salt ~]# qemu-img create -f raw /opt/CentOS-7-x86_64.raw 10G   #raw虚拟机镜像的格式,是一种裸磁盘,镜像给10G大小，就是整个虚拟机的硬盘大小 
Formatting '/opt/CentOS-7-x86_64.raw', fmt=raw size=10737418240
[root@kvm img]# qemu-img create -f qcow2 test.qcow2 10G
Formatting 'test.qcow2', fmt=qcow2 size=10737418240 encryption=off cluster_size=65536 lazy_refcounts=off  #qcow2磁盘的格式，可用于快照
[root@kvm img]# qemu-img info test.qcow2
image: test.qcow2
file format: qcow2
virtual size: 10G (10737418240 bytes)
disk size: 196K
cluster_size: 65536
Format specific information:
    compat: 1.1
    lazy refcounts: false

在kvm上安装虚拟机:
[root@Linux-node1-salt ~]# yum install -y virt-install #先安装装虚拟机的工具
[root@Linux-node1-salt ~]# scp 192.168.1.19:/Share/Info/Linux/Centos7.5.iso /opt #复制iso到/opt下
#安装虚拟机（不支持热部署）:
 virt-install --virt-type kvm --name CentOS-7-x86_64 --ram 2048 --cdrom=/opt/Centos7.5.iso  --disk path=/opt/CentOS-7-x86_64.raw --network network=default --graphics vnc,listen=0.0.0.0 --noautoconsole
#安装虚拟机（支持热部署）：
[root@Linux-node1-salt opt]# virt-install --virt-type kvm --name CentOS7-x86_64 --memory=2048,maxmemory=2048 --vcpus=1,maxvcpus=2 --cdrom=/opt/Centos7.5.iso --disk path=/opt/CentOS7-x86_64.qcow2 --network bridge=br0 --graphics vnc,listen=0.0.0.0 --noautoconsole
注：在创建虚拟机的时候尽量不要把cpu，内存,硬盘这些限定死，否则以后热部署会很麻烦。--vcpus 5,maxcpus=10,cpuset=1-4,6,8参数可以设置cpu为动态可扩展，方便以后支持热部署。--memory 512,maxmemory=1024参数可以动态设置内存，方便以后热部署。

[root@kvm data]# virt-install --virt-type kvm --graphics vnc,password=foobar,port=5910,listen=0.0.0.0 --network bridge=b
r0 --network bridge=br1 --disk /data/img/test.qcow2 --vcpus 1,maxvcpus=2 --memory 1024,maxmemory=2048 --name testlinux -
-cdrom /data/CentOS7-x86_64.iso  --noautoconsole#可以安装时指定两张网卡，设置vnc会话密码，指定vnc端口
[root@kvm data]# netstat -tunlp | grep 5910
tcp        0      0 0.0.0.0:5910            0.0.0.0:*               LISTEN      28389/qemu-kvm


netstat -tnlp | grep kvm  #查看开启vnc的服务端口
再然后赶紧用vnc客户端连上去安装Centos7系统,vnc的ip地址不是192.168.122.1,而是这个虚拟机的ip192.168.1.233,光标停留在Install CentOS7上,按tab键进入设置,在quiet后面添加net.ifnames=0 biosdevname=0 使网上名称为eth0
注：如果没有来得急vnc连接上，连上后你先可以选退出，然后服务器重新创建虚拟机，再重新连接即可。
[root@Linux-node1-salt opt]# virt-install --virt-type kvm --name CentOS-7.5-x86_64 --ram 2048 --cdrom=/opt/Centos7.5.iso  --disk path=/opt/CentOS-7-x86_64.raw --network network=default --graphics vnc,listen=0.0.0.0 --noautoconsole
ERROR    Disk /opt/CentOS-7-x86_64.raw is already in use by other guests ['CentOS-7-x86_64']. (Use --check path_in_use=off or --check all=off to override) #由于刚才退出过，有重名，所以这里会报错，提示使用--check path_in_use=off覆盖原先的参数
[root@Linux-node1-salt opt]# virt-install --virt-type kvm --name CentOS-7.5-x86_64 --ram 2048 --cdrom=/opt/Centos7.5.iso  --disk path=/opt/CentOS-7-x86_64.raw --network network=default --graphics vnc,listen=0.0.0.0 --noautoconsole --check path_in_use=off
WARNING  Disk /opt/CentOS-7-x86_64.raw is already in use by other guests ['CentOS-7-x86_64'].

[root@Linux-node1-salt ~]# virsh list --all   #安装系统完成后vnc会断开，这时候需要进入到192.168.1.233中查看虚拟机
 Id    Name                           State
----------------------------------------------------
 -     CentOS-7-x86_64                shut off
 -     CentOS-7.5-x86_64              shut off
[root@Linux-node1-salt opt]# virsh start  CentOS-7-x86_64 #启动虚拟机
[root@Linux-node1-salt opt]# virsh dominfo CentOS-7-x86_64  #查看虚拟机信息
Id:             5
Name:           CentOS-7-x86_64
UUID:           e05cc42a-9619-49c6-bad5-c01495bc8cf0
OS Type:        hvm
State:          running
CPU(s):         1
CPU time:       17.9s
Max memory:     2097152 KiB
Used memory:    2097152 KiB
Persistent:     yes
Autostart:      disable
Managed save:   no
Security model: none
Security DOI:   0
[root@Linux-node1-salt opt]# virsh dominfo  CentOS-7.5-x86_64 
Id:             -
Name:           CentOS-7.5-x86_64
UUID:           79d2437f-f372-44eb-8a7e-dc8700056b0c
OS Type:        hvm
State:          shut off
CPU(s):         1
Max memory:     2097152 KiB
Used memory:    2097152 KiB
Persistent:     yes
Autostart:      disable
Managed save:   no
Security model: none
Security DOI:   0

[root@Linux-node1-salt opt]# virsh undefine 79d2437f-f372-44eb-8a7e-dc8700056b0c #删除CentOS-7.5-x86_64虚拟机
Domain 79d2437f-f372-44eb-8a7e-dc8700056b0c has been undefined

[root@Linux-node1-salt opt]# virsh list --all
 Id    Name                           State
----------------------------------------------------
 5     CentOS-7-x86_64                running

镜像制件：去掉/dev下的网络规则，网卡的mac地址和UUID去掉

#libvirt
libvirt：kvm管理工具，xen,vmware,virtualbox等都可以管理。有libvirt API，openstack来基于这个API来调用kvm的。libvirt挂了不影响虚拟机的使用，只是不能管理虚拟机了。
[root@Linux-node1-salt ~]# ls /etc/libvirt/qemu/ #查看虚拟机的xml
CentOS-7-x86_64.xml  networks  Windows-10-x86.xml
[root@Linux-node1-salt ~]# cat /etc/libvirt/qemu/CentOS-7-x86_64.xml   #libvirt虚拟机的配置参数。
virsh dumpxml CentOS-7-x86_64 > backup.xml  #备份虚拟机xml
virsh list --all #此时还在。关机后真的没了
virsh shutdown kvm-1 #关机虚拟机
virsh destroy kvm-1  #断电虚拟机
virsh undefine kvm-1  #删除虚拟机
virsh list --all #此时没有CentOS-7-x86_64这个虚拟机了
virsh define backup.xml #恢复CentOS-7-x86_64虚拟机，如果当时在删除这个虚拟机的时候删除了硬盘，则这个操作不能恢复虚拟机
virsh suspend CentOS-7-x86_64 #暂停
virsh resumed CentOS-7-x86_64 #恢复
virsh snapshot-create CentOS-7-x86_64 #创建快照，不支持raw格式硬盘快照
virsh autostart study01  # 设置宿主机开机时该虚拟机也开机
virsh autostart --disable study01  # 解除开机启动

#编辑虚拟机的cpu：
[root@Linux-node1-salt ~]# head /etc/libvirt/qemu/CentOS-7-x86_64.xml
<!--
WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
OVERWRITTEN AND LOST. Changes to this xml configuration should be made using:
  virsh edit CentOS-7-x86_64  #提示使用这个命令来更改虚拟机参数
or other application using the libvirt API.
-->

<domain type='kvm'>
  <name>CentOS-7-x86_64</name>
  <uuid>e05cc42a-9619-49c6-bad5-c01495bc8cf0</uuid>

 virsh edit CentOS-7-x86_64  #编辑虚拟机参数
<vcpu placement='auto' current='1'>4</vcpu> #把static改成auto动态的，现在的cpu为1核，最大为4核
virsh setvcpus CentOS-7-x86_64 2 --live  #不用重启虚拟机就可以改cpu个数（虚拟机cpu模式必须是auto,而不是static,否则此命令失效。如果为static模式只能先关机，再开启虚拟机。最后就可以使用这个命令了，cpu只能添加不能缩小）
#编辑虚拟机的内存
[root@Linux-node1-salt ~]# virsh --help | grep monitor
    qemu-monitor-command           QEMU Monitor Command
    qemu-monitor-event             QEMU Monitor Events
 Domain Monitoring (help keyword 'monitor')
[root@Linux-node1-salt ~]# virsh qemu-monitor-command CentOS-7-x86_64 --hmp --cmd balloon 1024  #更改内存到1024M，最大内存为之前设置的静态内存大小，不能超过2G
[root@Linux-node1-salt ~]# virsh qemu-monitor-command CentOS-7-x86_64 --hmp --cmd info balloon #查看虚拟机现在的内存大小
balloon: actual=1024
#编辑虚拟机的硬盘
硬盘支持resize扩容，但是不建议resize扩容。系统盘一定不能扩，数据备不建议扩，数据盘扩之前一定要备份数据，如果要扩容建议添加硬盘。
kvm硬盘的两种格式：qcow2和raw，openstack推荐qcow2。
qcow2：可以和动态扩展。使用多大就多大。最新是qcow3版本了。
raw：硬盘初始多大就多大
qemu-img：硬盘管理工具
[root@Linux-node1-salt opt]# qemu-img convert -f raw -O  qcow2 CentOS-7-x86_64.raw CentOS-7-x86_64.qcow2  #将raw格式硬盘转换为qcow2格式
[root@Linux-node1-salt opt]# qemu-img info CentOS-7-x86_64.qcow2
image: CentOS-7-x86_64.qcow2
file format: qcow2
virtual size: 10G (10737418240 bytes)
disk size: 1.3G    #转换为qcow2后实际的硬盘大小
cluster_size: 65536
Format specific information:
    compat: 1.1
    lazy refcounts: false
注：kvm虚拟机硬盘格式是以cluster为单位的，而linux是以block为单位的。 

#编辑虚拟机的网卡
#设置NAT
[root@Linux-node1-salt ~]# virsh net-define /usr/share/libvirt/networks/default.xml #定义NAT
[root@Linux-node1-salt ~]# virsh net-autostart default #开启自动启动NAT
[root@Linux-node1-salt ~]# virsh net-start default #启动NAT
[root@Linux-node1-salt ~]# cat /proc/sys/net/ipv4/ip_forward #设置路由转发
1

#设置桥接
#方法1:
[root@Linux-node1-salt opt]# brctl show  #bridge control show查看kvm的网桥。
bridge name     bridge id               STP enabled     interfaces
virbr0          8000.5254008d87d3       yes             virbr0-nic
                                                        vnet0  #网桥virbr0-nic接口下的网络接口
注：kvm默认是NAT模式，生产要用桥接模式。把NAT模式变成桥接，生产是要用脚本来跑的
脚本：
--------------
#!/bin/bash
brctl addbr br0 
brctl addif br0 eth0
ip addr del dev eth0 192.168.1.233/24
ifconfig br0 192.168.1.233/24 up
route add default gw 192.168.1.254
echo "nameserver 114.114.114.114" >> /etc/resolv.conf
if [ #? == 0 ] {
echo "seccessful"
} else {echo "faild"} fi
--------------

[root@Linux-node1-salt opt]# brctl addbr br0  #增加网桥br0
[root@Linux-node1-salt opt]# brctl show #查看新添加的网桥
bridge name     bridge id               STP enabled     interfaces
br0             8000.000000000000       no
virbr0          8000.5254008d87d3       yes             virbr0-nic
                                                        vnet0
[root@Linux-node1-salt opt]# brctl addif br0 eth0 #增加eth0接口到网桥（此时ssh连接会断卡。只能从原系统登录）
ip addr del dev eth0 192.168.1.233/24  #删除eth0接口的ip地址
ifconfig br0 192.168.1.233/24 up   #添加ip地址到br0网桥并启动，此时刚才断开的ssh连接现在可以连上了
[root@Linux-node1-salt opt]# route add default gw 192.168.1.254 #连上但上不了网。因为没有网关，此时要添加网关就可以上网。
echo "nameserver 114.114.114.114" >> /etc/resolv.conf #添加dns服务器
注：上面的一连串改网卡操作在生产环境下是写成一个脚本执行的。
现在网络通了，但是kvm创建的虚拟机还是以nat模式工作的，现在也上不了网，所以得用virsh edit kvm-host来编辑虚拟机配置。
[root@Linux-node1-salt opt]# virsh edit CentOS-7-x86_64 
编辑前：
	 69     <interface type='network'>
     70       <mac address='52:54:00:34:22:53'/>
     71       <source network='default'/>
     72       <model type='virtio'/>
编辑后：
			<interface type='bridge'>  #网桥模式由NAT设成网桥模式
     70       <mac address='52:54:00:34:22:53'/>
     71       <source bridge='br0'/>  #设成网桥模式的br0网卡
     72       <model type='virtio'/>
然后重启kvm虚拟机配置网络即可

#方法2：
[root@kvm ~]# cat /etc/sysconfig/network-scripts/ifcfg-br0
# Generated by parse-kickstart
DEVICE="br0"
BOOTPROTO="none"
ONBOOT="yes"
IPADDR=192.168.1.233
NETMASK=255.255.255.0
GATEWAY=192.168.1.254
NM_CONTROLLED=no
TYPE=Bridge
[root@kvm ~]# cat /etc/sysconfig/network-scripts/ifcfg-eth0
# Generated by parse-kickstart
DEVICE="eth0"
TYPE=Ethernet
BRIDGE=br0
ONBOOT="yes"
NM_CONTROLLED=no
#设置两个桥接网卡，可以使用外网IP
[root@kvm network-scripts]# cat ifcfg-br1
# Generated by parse-kickstart
DEVICE="br1"
BOOTPROTO="none"
ONBOOT="yes"
NM_CONTROLLED=no
TYPE=Bridge
[root@kvm network-scripts]# cat ifcfg-eth1
# Generated by parse-kickstart
DEVICE="eth1"
TYPE=Ethernet
BRIDGE=br1
ONBOOT="yes"
NM_CONTROLLED=no
[root@kvm network-scripts]# brctl show
bridge name     bridge id               STP enabled     interfaces
br0             8000.005056ad0d3c       no              eth0
                                                        vnet0
br1             8000.005056ad5f6e       no              eth1
                                                        vnet1
virbr0          8000.525400f5460e       yes             virbr0-nic
[root@kvm network-scripts]# virsh attach-interface win7 --type bridge --source br1 #使用此命令给已运行的虚拟机添加网卡
Interface attached successfully


#删除virbr0 NAT接口
网桥方式的配置与虚拟机支持模块安装时预置的虚拟网络桥接接口virbr0没有任何关系，配置网桥方式时，可以把virbr0接口（即NAT方式里面的default虚拟网络）删除。
# virsh net-destroy default  
# virsh net-undefine default
# service libvirtd restart

##kvm的相关优化：
CPU,内存,IO
#CPU优化：
windowsX86系统有4个xekl,Ring0（内核态）、Ring1、Ring2、Ring3（用户态），用户态到内核态的切换就是上下文切换的一种。
BIOS开启虚拟化，是开启VMX，为了加速上下文切换
kvm进程会受到多个cpu的调度，因为cpu有缓存，A的cpu缓存不能放到B的cpu上运行，会报缓存错误，所以为了提高kvm的性能，我们把kvm绑定到某一个cpu上来提高性能。
[root@Linux-node1-salt opt]# taskset -pc 0  1257 #设定kvm的进程1257专门在0号cpu上运行缓存（能提高性能不到10%）
pid 1257's current affinity list: 0-3
pid 1257's new affinity list: 0
#内存优化：
1. linux物理机有物理内存和虚拟内存，kvm里面也有物理内存和虚拟内存，在kvm中虚拟机使用内存时最终会体现在linux物理机上，kvm与linux物理机的内存映射很复杂，会导致速度低下。所以开启Inter的EPT技术可以加快映射速度，在BIOS打开就可以了。
2. 内存寻址：就是分给虚拟机的大页内存（Hugepagesize）多点,几M几M的分，可以提高虚拟机10%左右的性能。可通过cat /proc/meminfo查看大页内存。默认是开启的
进行内存碎片的合并，提高内存的性能：[root@Linux-node1-salt postinst.d]# cat /sys/kernel/mm/transparent_hugepage/enabled #默认是永远开启的
[always] madvise never

#IO优化：
virtio：是半虚拟化技术，kvm物理机默认是virtio,告诉硬盘虚拟机是运行在虚拟化环境中的。默认是开启的。
[root@Linux-node1-salt postinst.d]# cat /sys/block/sda/queue/scheduler #查看io调试算法
noop [deadline] cfq  #centos7默认是deadline
noop:专门为ssd设备，不使用io调度。 #echo noop >/sys/block/sda/queue/scheduler更改io调度模式
cfq:完全公平的io调度，平均调度
deadline:使用了四个队列，有两组读请求和写请求。Centos7默认是这个io调度
写入方式：Guest OS和Host OS，虚拟机读写到硬盘要经过Guest OS Pagecache和Host OS Pagecache。有3种方式写到物理硬盘：1.Writeback(速度更快，但在断电的情况下丢失数据也多)2.None(使用传统方式写)3.WriteThrough(速度稍慢，但断电的情况下不易选择数据，kvm默认是这种方式)




centos7下mode1端口聚合：
#!/bin/bash
#创建一个名为bond0的链路接口
IP=192.168.101.1
GATE=192.168.101.254
ETH1=eno1
ETH2=eno2
modprobe bonding   #必须加载此模块才支持链路聚合
cat <<EOF> /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0
TYPE=Bond
NAME=bond0
BONDING_MASTER=yes
BOOTPROTO=static
USERCTL=no
ONBOOT=yes
IPADDR=$IP
PREFIX=24
GATEWAY=$GATE
BONDING_OPTS="mode=1 miimon=100"
EOF
cat <<EOF> /etc/sysconfig/network-scripts/ifcfg-$ETH1
TYPE=Ethernet
BOOTPROTO=none
DEVICE=$ETH1
ONBOOT=yes
MASTER=bond0
SLAVE=yes
EOF
cat <<EOF> /etc/sysconfig/network-scripts/ifcfg-$ETH2
TYPE=Ethernet
BOOTPROTO=none
DEVICE=$ETH2
ONBOOT=yes
MASTER=bond0
SLAVE=yes
EOF
systemctl restart network
ping $GATE -c 1
reboot

验证：
查看bond0状态：
[root@localhost ~]# cat /proc/net/bonding/bond0

[root@kvm ~]# virsh domiflist win7  #查看kvm接口信息，dom命令查看虚拟机域的信息
Interface  Type       Source     Model       MAC
-------------------------------------------------------
vnet0      bridge     br0        e1000       52:54:00:36:37:54







</pre>
