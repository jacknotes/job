#分布式文件系统glusterFS
<pre>
###windows远程桌面无法复制粘添：在目标主机上杀死rdpclip进程并重新运行rdpclip.exe即可

事前准备：
1. 准备4台虚拟机，并设定主机名和ip,主机名要想即时生效，可先设临时主机名以后再重启即可
2. 关闭selinux和防火墙
3. 给每台虚拟机再加一块10G硬盘，并使用  echo "- - -" > /sys/class/scsi_host/host${i}/scan 进行添加的硬盘即时生效
------- 添加新硬盘即时生效脚本
[root@salt-server ~]# cat disk.tmp
#!/usr/bin/bash

scsisum=`ls -l /sys/class/scsi_host/host*|wc -l`

for ((i=0;i<${scsisum};i++))
do
    echo "- - -" > /sys/class/scsi_host/host${i}/scan
done
------

开始安装：
1. 安装epel源：
[root@salt-server ~]# salt 'clus*' cmd.run "yum install -y epel-release"
2. 安装gluster源：
[root@salt-server ~]# salt 'clusterFS-node*' cmd.run "yum install -y centos-release-gluster41.noarch"
3. 安装glusterfs:
[root@salt-server ~]# salt 'clusterFS-node*' cmd.run "yum --enablerepo=centos-gluster*-test install glusterfs-server glusterfs-cli glusterfs-geo-replication -y"
4. 查看安装的gluster包：
clusterFS-node1-salt:
    centos-release-gluster41-1.0-3.el7.centos.noarch
    glusterfs-client-xlators-4.1.6-1.el7.x86_64
    glusterfs-4.1.6-1.el7.x86_64
    glusterfs-api-4.1.6-1.el7.x86_64
    glusterfs-fuse-4.1.6-1.el7.x86_64
    python2-gluster-4.1.6-1.el7.x86_64
    glusterfs-geo-replication-4.1.6-1.el7.x86_64
    glusterfs-libs-4.1.6-1.el7.x86_64
    glusterfs-cli-4.1.6-1.el7.x86_64
    glusterfs-server-4.1.6-1.el7.x86_64
5. 配置glusterfs:
  1. 查看glusterfs版本
  [root@salt-server ~]# salt clusterFS-node* cmd.run 'glusterfs -V'
  clusterFS-node2-salt:
    glusterfs 4.1.6
    Repository revision: git://git.gluster.org/glusterfs.git
    Copyright (c) 2006-2016 Red Hat, Inc. <https://www.gluster.org/>
    GlusterFS comes with ABSOLUTELY NO WARRANTY.
    It is licensed to you under your choice of the GNU Lesser
    General Public License, version 3 or any later version (LGPLv3
    or later), or the GNU General Public License, version 2 (GPLv2),
    in all cases as published by the Free Software Foundation.
  2. 启动glusterd服务
    2.1 [root@salt-server ~]# salt clusterFS-node* cmd.run 'systemctl start glusterd'
clusterFS-node3-salt:
clusterFS-node2-salt:
clusterFS-node4-salt:
clusterFS-node1-salt:
    2.2 [root@salt-server ~]# salt clusterFS-node* cmd.run 'systemctl enable glusterd' #设置开机启动
clusterFS-node4-salt:
    Created symlink from /etc/systemd/system/multi-user.target.wants/glusterd.service to /usr/lib/systemd/system/glusterd.service.
    2.3 [root@salt-server ~]# salt clusterFS-node* service.status glusterd #查看服务状态
clusterFS-node3-salt:
    True
clusterFS-node4-salt:
    True
clusterFS-node1-salt:
    True
clusterFS-node2-salt:
    True
  3. 存储主机加入信任存储池中（整合磁盘）：在任意其中一台gluster中添加其他的gluster到信任存储池中：
  [root@clusterFS-node1-salt ~]# gluster peer probe clusterFS-node2-salt.jack.com
peer probe: success.
[root@clusterFS-node1-salt ~]# gluster peer probe clusterFS-node3-salt.jack.com
peer probe: success.
[root@clusterFS-node1-salt ~]# gluster peer probe clusterFS-node4-salt.jack.com
peer probe: success.
  4. 任意一台gluster中查看其他gluster的状态：
  [root@clusterFS-node2-salt ~]# gluster peer status
Number of Peers: 3

Hostname: 192.168.1.32
Uuid: be55a468-9d4f-4211-961d-2cfbd9d9aa6d
State: Peer in Cluster (Connected)

Hostname: clusterFS-node3-salt.jack.com
Uuid: 1ffc6e81-af6f-448d-8579-fc69761280f7
State: Peer in Cluster (Connected)

Hostname: clusterFS-node4-salt.jack.com
Uuid: 0b4e5407-ec4e-40e9-b41c-fbb46086bc12
State: Peer in Cluster (Connected)
  5. centos6安装xfs文件系统，对添加的硬盘进行xfs格式化:yum install -u xfsprogs,centos7系统自带可不用安装(因为ext4文件系统最大支持16TB，而xfs文件系统支持PB级。)
  6. 官网文档对新硬盘要进行分一个区，实际操作不进行分区也没什么问题。系统盘要做RAID,gluster数据盘不用做RAID
  7. 使用xfs格式化硬盘：[root@salt-server ~]# salt clusterFS-node* cmd.run 'mkfs.xfs /dev/sdb'
  8. [root@salt-server ~]# salt clusterFS-node* cmd.run 'mkdir -p /storage/brick1 && mount /dev/sdb /storage/brick1'
  9. 查看挂载情况：
  [root@salt-server ~]# salt clusterFS-node* cmd.run 'df -h'                      clusterFS-node4-salt:
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/sda2        15G  1.6G   14G  11% /
    devtmpfs        909M     0  909M   0% /dev
    tmpfs           920M   12K  920M   1% /dev/shm
    tmpfs           920M  8.8M  911M   1% /run
    tmpfs           920M     0  920M   0% /sys/fs/cgroup
    /dev/sda1      1014M  140M  875M  14% /boot
    tmpfs           184M     0  184M   0% /run/user/0
    /dev/sdb         10G   33M   10G   1% /storage/brick1
  10. [root@salt-server ~]# salt  clusterFS-node* cmd.run 'echo /dev/sdb /storage/brick1 xfs defaults 0 0 >> /etc/fstab'
  11. [root@salt-server ~]#  salt clusterFS-node* cmd.run 'mount -a'
  12. 分布式文件系统卷：
    1. 分布卷
    2. 复制卷
    3. 条带卷
    4. 分布式条带卷（服务器必须是2的倍数）
    5. 分布式复制卷（服务器必须是2的倍数）这种卷用得最多
  13. 创建分布卷：
  [root@clusterFS-node1-salt ~]# gluster volume create gv1 clusterFS-node1-salt.jack.com:/storage/brick1 clusterFS-node2-salt.jack.com:/storage/brick1 force
  volume create: gv1: success: please start the volume to access data
  14. 启动卷：[root@clusterFS-node1-salt ~]# gluster volume start gv1
  volume start: gv1: success
  （创建gluster1和gluster2的gv1卷，在gluster3和其他都可以查看到）
  15. [root@salt-server ~]# salt clusterFS-node3* cmd.run 'gluster volume info' #其他gluster上查看卷的信息
clusterFS-node3-salt:
    Volume Name: gv1
    Type: Distribute  #分布式的卷
    Volume ID: 0c530420-b9fc-4381-8668-2a316a7c6509
    Status: Started
    Snapshot Count: 0
    Number of Bricks: 2
    Transport-type: tcp
    Bricks:
    Brick1: clusterFS-node1-salt.jack.com:/storage/brick1
    Brick2: clusterFS-node2-salt.jack.com:/storage/brick1
    Options Reconfigured:
    transport.address-family: inet
    nfs.disable: on
  16. 信任池中任意一台gluster都可挂载：
[root@clusterFS-node3-salt ~]# mount -t glusterfs 127.0.0.1:/gv1 /mnt
  17. 查看挂载情况：
[root@clusterFS-node3-salt ~]# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        15G  1.6G   14G  11% /
devtmpfs        909M     0  909M   0% /dev
tmpfs           920M   12K  920M   1% /dev/shm
tmpfs           920M  8.8M  911M   1% /run
tmpfs           920M     0  920M   0% /sys/fs/cgroup
/dev/sda1      1014M  140M  875M  14% /boot
/dev/sdb         10G   33M   10G   1% /storage/brick1
tmpfs           184M     0  184M   0% /run/user/0
127.0.0.1:/gv1   20G  270M   20G   2% /mnt
  18. [root@clusterFS-node1-salt ~]# mount -t glusterfs 127.0.0.1:/gv1 /mnt
  19. 任意一台gluster服务器挂载卷后都可能进行文件拷坝，而且每台gluster服务器都会进行同步数据
  20. 用nfs方式挂载gluster卷：mount -t nfs -o mountproto=tcp 192.168.1.37:/gv1 /mnt
  21. 创建复制卷：
[root@clusterFS-node1-salt ~]# gluster volume create gv2 replica 2 clusterFS-node3-salt.jack.com:/storage/brick1 clusterFS-node4-salt.jack.com:/storage/brick1 force #replica为复制卷，后面的2为复制两个，如果复制3个则后面为3
volume create: gv2: success: please start the volume to access data
  22. 查看所有卷：
  [root@clusterFS-node1-salt ~]# gluster volume info
Volume Name: gv1
Type: Distribute
Volume ID: 0c530420-b9fc-4381-8668-2a316a7c6509
Status: Started
Snapshot Count: 0
Number of Bricks: 2
Transport-type: tcp
Bricks:
Brick1: clusterFS-node1-salt.jack.com:/storage/brick1
Brick2: clusterFS-node2-salt.jack.com:/storage/brick1
Options Reconfigured:
transport.address-family: inet
nfs.disable: on

Volume Name: gv2
Type: Replicate
Volume ID: 34f461e7-91ec-496f-a6d4-e48ba5fc08ac
Status: Created
Snapshot Count: 0
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: clusterFS-node3-salt.jack.com:/storage/brick1
Brick2: clusterFS-node4-salt.jack.com:/storage/brick1
Options Reconfigured:
transport.address-family: inet
nfs.disable: on
performance.client-io-threads: off
  23. 启动复制卷gv2:
  [root@clusterFS-node1-salt ~]# gluster volume start gv2
volume start: gv2: success
  24. 挂载：
  [root@clusterFS-node1-salt ~]# mount -t glusterfs 127.0.0.1:/gv2 /opt
  25. 查看挂载情况：
  [root@clusterFS-node1-salt ~]# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        15G  1.6G   14G  11% /
devtmpfs        909M     0  909M   0% /dev
tmpfs           920M   12K  920M   1% /dev/shm
tmpfs           920M  8.9M  911M   1% /run
tmpfs           920M     0  920M   0% /sys/fs/cgroup
/dev/sda1      1014M  140M  875M  14% /boot
tmpfs           184M     0  184M   0% /run/user/0
/dev/sdb         10G   33M   10G   1% /storage/brick1
127.0.0.1:/gv1   20G  270M   20G   2% /mnt
127.0.0.1:/gv2   10G  135M  9.9G   2% /opt
！！注意：当挂载卷时目录挂载错了，需要更换目录时，最好是把之前的硬盘重新格式化重新建卷重新挂载，因为挂卷后有gluster的配置隐藏文件，再重新挂载会影响以后的gluster使用。 
{
危险操作：
删除卷并重新格式化硬盘：
1. [root@clusterFS-node1-salt ~]# gluster volume stop gv1 #停止卷的工作
Stopping volume will make its data inaccessible. Do you want to con              y
volume stop: gv1: success
2. [root@clusterFS-node1-salt ~]# gluster volume delete gv1  #删除卷
Deleting volume will erase all information about the volume. Do you              inue? (y/n) y
volume delete: gv1: success
3. [root@salt-server ~]# salt clusterFS-node* cmd.run 'umount /dev/sdb'  #卸载硬盘
4. [root@salt-server ~]# salt clusterFS-node* cmd.run 'mkfs -t xfs -f /dev/sdb '  #格式化sdb硬盘
5. [root@salt-server ~]# salt clusterFS-node* cmd.run 'mount /dev/sdb /storage/brick1 '  #重新挂载
clusterFS-node1-salt:
clusterFS-node3-salt:
clusterFS-node4-salt:
clusterFS-node2-salt:
}

##分布式条带卷
#条带卷：
1. [root@clusterFS-node1-salt ~]# gluster volume create gv1 stripe 2 clusterFS-node1-salt.jack.com:/storage/brick1 clusterFS-node2-salt.jack.com:/storage/brick1 force #新建条带卷
volume create: gv1: success: please start the volume to access data
2. [root@clusterFS-node1-salt ~]# gluster volume start gv1 #启动卷
volume start: gv1: success
查看条带卷：
[root@clusterFS-node1-salt ~]# gluster volume info
Volume Name: gv1
Type: Stripe
Volume ID: bc0219b4-8967-4928-9a17-226fe86d2a90
Status: Started
Snapshot Count: 0
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: clusterFS-node1-salt.jack.com:/storage/brick1
Brick2: clusterFS-node2-salt.jack.com:/storage/brick1
Options Reconfigured:
transport.address-family: inet
nfs.disable: on

3. 挂载卷：
[root@salt-server ~]# salt clusterFS-node* cmd.run "mkdir /gv1 && mount -t glusterfs 127.0.0.1:gv1 /gv1  "
clusterFS-node2-salt:
clusterFS-node1-salt:
clusterFS-node4-salt:
clusterFS-node3-salt:
4. [root@clusterFS-node1-salt gv1]# dd if=/dev/zero bs=1024 count=10000 of=/gv1/10M
10000+0 records in
10000+0 records out
10240000 bytes (10 MB) copied, 1.26171 s, 8.1 MB/s
5. [root@clusterFS-node1-salt gv1]# ll -h
total 9.8M
-rw-r--r-- 1 root root 9.8M Jan 13 19:16 10M
6. 查看
[root@clusterFS-node1-salt gv1]# ll -h /storage/brick1/
total 4.9M
-rw-r--r-- 2 root root 4.9M Jan 13 19:16 10M
[root@salt-server ~]# salt clusterFS-node2* cmd.run "ls -lh /storage/brick1 "
clusterFS-node2-salt:
    total 4.9M
    -rw-r--r-- 2 root root 4.9M Jan 13 19:16 10M
[root@salt-server ~]# salt clusterFS-node3* cmd.run "ls -lh /storage/brick1 "
clusterFS-node3-salt:
    total 0
[root@salt-server ~]# salt clusterFS-node4* cmd.run "ls -lh /storage/brick1 "
clusterFS-node4-salt:
    total 0

#分布式条带卷：
[root@clusterFS-node1-salt gv1]# gluster volume stop gv1
[root@clusterFS-node1-salt gv1]# gluster volume add-brick gv1 stripe 2 clusterFS-node3-salt.jack.com:/storage/brick1 clusterFS-node4-salt.jack.com:/storage/brick1 force #增加两个卷到gv1这个条带卷中使之成为分布式条带卷
 gluster volume remove-brick gv1 stripe 2 clusterFS-node3-salt.jack.com:/storage/brick1 clusterFS-node4-salt.jack.com:/storage/brick1 force


3. 查看分布式条带卷信息：
[root@clusterFS-node1-salt gv1]# gluster volume info
Volume Name: gv1
Type: Distributed-Stripe
Volume ID: bc0219b4-8967-4928-9a17-226fe86d2a90
Status: Started
Snapshot Count: 0
Number of Bricks: 2 x 2 = 4
Transport-type: tcp
Bricks:
Brick1: clusterFS-node1-salt.jack.com:/storage/brick1
Brick2: clusterFS-node2-salt.jack.com:/storage/brick1
Brick3: clusterFS-node3-salt.jack.com:/storage/brick1
Brick4: clusterFS-node4-salt.jack.com:/storage/brick1
Options Reconfigured:
transport.address-family: inet
nfs.disable: on

[root@clusterFS-node3-salt gv1]# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        15G  1.6G   14G  11% /
devtmpfs        909M     0  909M   0% /dev
tmpfs           920M   12K  920M   1% /dev/shm
tmpfs           920M  8.8M  911M   1% /run
tmpfs           920M     0  920M   0% /sys/fs/cgroup
/dev/sda1      1014M  140M  875M  14% /boot
tmpfs           184M     0  184M   0% /run/user/0
/dev/sdb         10G   33M   10G   1% /storage/brick1
127.0.0.1:gv1    40G  559M   40G   2% /gv1

[root@salt-server ~]# salt clusterFS-node* cmd.run "ls -lh /storage/brick1"
clusterFS-node4-salt:
    total 0
clusterFS-node1-salt:
    total 9.8M
    -rw-r--r-- 2 root root 4.9M Jan 13 20:18 10M
    -rw-r--r-- 2 root root 4.9M Jan 13 20:29 10M-10
    -rw-r--r-- 2 root root    5 Jan 13 20:09 tripe.txt
clusterFS-node3-salt:
    total 0
clusterFS-node2-salt:
    total 9.8M
    -rw-r--r-- 2 root root 4.9M Jan 13 20:18 10M
    -rw-r--r-- 2 root root 4.9M Jan 13 20:29 10M-10
    -rw-r--r-- 2 root root    0 Jan 13 20:09 tripe.txt
！！注意从上面看出新增加的数据还是没有添加到新添加的卷中，需要做磁盘平衡后才能添加到新添加的卷中。

#磁盘平衡：
当你添加了卷到条带卷或者复制卷中组成了分布式的卷，都需要做磁盘平衡，否则新增加的或者以前的数据都不会同步到新增加的卷中。
磁盘平衡：
[root@clusterFS-node1-salt gv1]# gluster volume rebalance gv1 start
volume rebalance: gv1: success: Rebalance on gv1 has been started successfully. Use rebalance status command to check status of the rebalance process.
ID: 4635c875-75f3-4f04-9c9e-d6d7eaaa2ca3
查看硬盘平衡的工作状态：
[root@clusterFS-node1-salt gv1]# gluster volume rebalance gv1 status
                                    Node Rebalanced-files          size       scanned      failures       skipped               status  run time in h:m:s
                               ---------      -----------   -----------   -----------   -----------   -----------         ------------     --------------
                               localhost                2         9.8MB             3             0             0            completed        0:00:01
           clusterFS-node2-salt.jack.com                0        0Bytes             0             0             0            completed        0:00:00
           clusterFS-node3-salt.jack.com                0        0Bytes             1             0             0            completed        0:00:00
           clusterFS-node4-salt.jack.com                0        0Bytes             0             0             0            completed        0:00:00
volume rebalance: gv1: success

做完磁盘平衡后把原先的条带卷数据平均到另外的一个条带卷中：
[root@salt-server ~]# salt clusterFS-node* cmd.run "ls -lh /storage/brick1"
clusterFS-node4-salt:
    total 4.9M
    -rw-r--r-- 2 root root 4.9M Jan 13 20:18 10M
    -rw-r--r-- 2 root root    0 Jan 13 20:09 tripe.txt
clusterFS-node2-salt:
    total 4.9M
    -rw-r--r-- 2 root root 4.9M Jan 13 20:29 10M-10
clusterFS-node1-salt:
    total 4.9M
    -rw-r--r-- 2 root root 4.9M Jan 13 20:29 10M-10
clusterFS-node3-salt:
    total 4.9M
    -rw-r--r-- 2 root root 4.9M Jan 13 20:18 10M
    -rw-r--r-- 2 root root    5 Jan 13 20:09 tripe.txt

##分布式复制卷：
创建复制卷：
1. [root@clusterFS-node1-salt ~]# gluster volume create gv2 replica 2 clusterFS-node3-salt.jack.com:/storage/brick1 clusterFS-node4-salt.jack.com:/storage/brick1 force #replica为复制卷，后面的2为复制两个，如果复制3个则后面为3
启动复制卷gv2:
2. [root@clusterFS-node1-salt ~]# gluster volume start gv2
volume start: gv2: success
增加卷到复制卷中使之成为分布式复制卷：
3. [root@clusterFS-node1-salt ~]#gluster volume add-brick gv2 replica 2 clusterFS-node1-salt.jack.com:/storage/brick1 clusterFS-node2-salt.jack.com:/storage/brick1 force #增加两个卷到gv2这个条带卷中使之成为分布式复制卷
4. [root@clusterFS-node1-salt ~]# gluster volume rebalance gv2 start #磁盘平衡使gluster3,gluster4复制卷的数据平均一点到gluster1,gluster2复制卷中，
5. [root@clusterFS-node1-salt ~]# gluster volume rebalance gv2 status #可查看磁盘平衡的工作状态

移除卷：
1. [root@clusterFS-node1-salt ~]# gluster volume stop gv2
2. [root@clusterFS-node1-salt ~]#gluster volume remove-brick gv2 replica 2 clusterFS-node1-salt.jack.com:/storage/brick1 clusterFS-node2-salt.jack.com:/storage/brick1 force
3. [root@clusterFS-node1-salt ~]# gluster volume start gv2
注意：之前平均到gluster1,gluster2复制卷的数据将在卷中丢失，但数据依旧在底层clusterFS-node1-salt.jack.com:/storage/brick1和clusterFS-node2-salt.jack.com:/storage/brick1中，重新添加挂载即可
！！注意：移除卷只能移除复制卷，不能移除条带卷

删除卷：
[root@clusterFS-node1-salt /]# gluster volume delete gv1
！！注意：gv1是分布式复制卷，第一次新建gluster1,gluster2为复制卷，然后加入了gluster3,gluster4复制卷进去，所以以后要想恢复数据必需要先新建gluster1,gluster2为复制卷，然后加入了gluster3,gluster4复制卷进去，顺序不能变，否则会失败。注意在每个/storage/brick1目录下都有gluster的配置文件，不要删除和更改，应该变个是关系到你能是否恢复数据的关键，对于分布式条带卷来说更至关重要。

添加卷并恢复数据：
1. [root@clusterFS-node1-salt /]# gluster volume create gv1 replica 2 clusterFS-node1-salt.jack.com:/storage/brick1 clusterFS-node2-salt.jack.com:/storage/brick1 force
2. [root@clusterFS-node1-salt /]# gluster volume add-brick gv1 replica 2 clusterFS-node3-salt.jack.com:/storage/brick1 clusterFS-node4-salt.jack.com:/storage/brick1 force
3. [root@clusterFS-node1-salt /]# gluster volume start gv1
4. [root@clusterFS-node1-salt /]# ll -h /gv1/  #看出数据还在
total 36M
-rw-r--r-- 1 root root 9.8M Jan 13 22:10 10M
-rw-r--r-- 1 root root  20M Jan 13 22:11 20M
-rw-r--r-- 1 root root    3 Jan 13 22:11 aa
-rw-r--r-- 1 root root    0 Jan 13 22:17 cc
-rw-r-xr-- 1 root root 6.6M Jan 13 22:29 image123.JPG
-rw-r--r-- 1 root root    3 Jan 13 22:11 tt

！！注意：当添加分布式复制卷成功时，新添加的复制卷默认会同步之前卷的文件夹，之前卷的其他文件不会同步，当你再平衡时文件才会重新平均到其他复制卷中


#构建企业级分布式存储
1.硬件选型
一般2U的机型，SATA磁盘4T，I/O要求高可选SSD，为了充分保证系统稳定性和性能，要求所有gluster服务器配置尽量一致，尤其是硬盘数量和大小。机器的RAID卡需要带电池，缓存越大，性能越好，一般情况下做RAID10，出于空间考虑RAID5也可以，但是热备盘要1-2块。
2.系统要求及分区划分
系统要求centos6.x，安装完成后升级到最新版本，安装的时候不要使用lvm,建议/boot分区大小200M,/分区100G，swap分区和内存大小一样，剩余空间给gluster使用，划分单独的硬盘空间，除了基本的管理软件和开发工具，其他一律不要安装。
3.网络环境
网络要求全部千兆，条件好的话可以配置万兆网络，服务器配置万兆，服务器最少两张网卡，一块给gluster使用，一块给管理使用。
4.服务器摆放分布
服务器主备机器放在不同的机柜，连接不同的交换机。
5.构建高性能、高可用存储
一般企业中，采用分布式复制卷，因为有数据备份，数据相对安全。分布式条带卷目前对gluster来说没有完全成熟，存在一定的风险。
6.开启防火墙端口
一般在企业中linux防火墙是打开的，24007:24011和49152:49162（不做raid的10块硬盘数据通道数）这些端口要放行，这样才能开通gluster服务器之间的访问。/etc/glusterfs/glusterd.vol文件能改变端口49152的端口值，因为当与kvm一起时，kvm也有这个端口，此时需要改变这个端口值。
 
###glusterfs文件系统优化
参数			说明			缺省值			合法值
Auth.allow	ip访问权	 	*(allow all)	ip地址
Cluster.min-free-disk	剩余磁盘空间阈值	10%		百分比
Cluster.stripe-block-size	条带大小		128KB		字节
Network.frame-timeout		请求等待时间		1800s		0-1800
Network.ping-timeout		客户端等待时间		42s		0-42
Nfs.disabled	关闭NFS服务	off		off|on
Performance.io-thread-count		IO线程数		16		0-65
Performance.cache-refresh-timeout	缓存检验周期		1s	0-61
Performance.cache-size	读缓存大小	32MB	字节

Performance.quick-read:优化读取小文件的性能。
Performance.read-ahead:用预读的方式提高读取的性能，有利于应用频繁持续性的访问文件，当应用完成当前数据块读取的时候，下一个数据块就已经准备好了。
Performance.write-behind:在写数据时，先写入缓存内，在写入硬盘，以提高写入的性能。
Performance.io-cache:缓存已经被读过的。
调整方法：
例如：
gluster volume set gv1 Performance.io-thread-count 20

##监控及日常维护
使用zabbix自带模板即可。监控CPU，内存，主机存活，磁盘空间，主机运行时间，系统load等。日常情况要查看服务器的监控值，遇到报警要及时处理。（例如：df -h命令截取到挂载的gluster目录，使用脚本对这个目录进行写，如果不能写zabbix则触发动作）
查看主机状态：gluster peer status
在分布式复制卷下执行的：
查看卷状态：gluster volume status gv2
启动完全修复：gluster volume heal gv2 full(当分布式文件系统上网线断了一个小时时启动完全修复)
查看需要修复的文件：gluster volume heal gv2 info
查看修复成功的文件：gluster volume heal gv2 info healed
查看修复失败的文件：gluster volume heal gv2 info heal-failed
查看脑裂的文件：gluster volume heal gv2 info split-brain
如何修复脑裂？：人为判断哪一个文件为标准，手动删除另外的错误文件，gluster以标准文件来同步其他文件
激活quota功能：gluster volume quota gv2 enable
关闭quota功能：gluster volume quota gv2 disable
限制gv2卷下目录data的大小为30MB:mkdir /gv2/date && gluster volume quota gv2 limit-usage /data 30MB
查看quota信息列表状态：gluster volume quota gv2 list
删除/data目录的限制：gluster volume quota gv2 remove /data
注意：quota是对卷下的目录进行限制，不是对整个卷进行限制

##硬盘故障
两张情况：
第一种：底层做了RAID的机器一块硬盘损坏，如何恢复？
直接用RAID的特性对硬盘进行跟换即可。

第二种：当gluster storage1和storage2两台服务器中复制卷storage2服务器/storage/brick2硬盘坏掉时，此时还不会丢失文件，因为storage1服务器/storage/brick2硬盘是好的，怎么恢复处理？
1. 先移除storage2坏的那块硬盘，然后添加同规格的硬盘，进行xfs文件格式化、挂载之前相同目录。
2. 停掉gluster服务
3. 在storage1服务器使用命令：getfattr -d -m '.*' /storage/brick2 获取隐藏的gluster配置文件详细信息（-n trusted.glusterfs.volume-id -v 0slEaIKclQQ0GpwUXSYvtHqw== /storage/brick2）
4. 在storage2服务器/storage/brick2目录上（复制卷的挂载目录）执行：setfattr -n trusted.glusterfs.volume-id -v 0slEaIKclQQ0GpwUXSYvtHqw== /storage/brick2 使新硬盘恢复隐藏的gluster配置文件，
5. 在使用命令：getfattr -d -m '.*' /storage/brick2 可查看设置的参数信息
6. 重试上面的步骤，把gluster想关的隐藏文件一一恢复，不管gluster文件的顺序，quota限额这项可不用复制
7. gluster volume status查看volume的状态时，发现节点2的brick是N，需要删除重建brick，我们需要手动的删掉节点2的brick，在重新建立
8. 手动删除brick:glustervolume remove-brick gv1  replica 1 clusterFS-node3-salt.jack.com:/storage/brick1 force
9. 手动添加brick:glustervolume add-brick gv1  replica 2 clusterFS-node3-salt.jack.com:/storage/brick1 force
10. 这样新更换上的硬盘就会有坏掉那块硬盘上的数据了。

##一台主机故障
系统挂了，需要重新安装系统和gluster的软件，建议保存gluster的安装软件，以包以后可以同版本安装
a) 物理故障
b) 磁盘阵列多块硬盘丢失，使数据丢失
c) 系统坏了

解决办法：
1. 准备一台服务器跟坏的服务器配置一样，至少硬盘大小和数量一样，然后安装系统和gluster软件。
2. 再在其他健康的节点上使用命令gluster peer status查看所有的节点UUID，包括坏的那台服务器节点UUID，可以在新安装的这台服务器上修改文件:/var/lib/glusterd/glusterd.info的UUID成之前坏的那台UUID。
3. 然后格式化和挂载硬盘。
4. 手动先删除复制卷中的无效birck块
5. 然后再手动删除信任存储池中的故障主机
6. 再重新添加故障主机到信任存储池中
7. 最后再添加brick块即可
8. 最后自己同步数据到新添加的硬盘当中

！！注意：如果硬盘没坏，只是系统坏的话，就在修改为UUID，底层格式化和挂载硬盘后直接在gluster中添加之前的硬盘，因为硬盘下有gluster的隐藏配置文件，直接添加即可。
！！新装的系统UUID必须和坏的系统UUID一致
！！卸载gluster软件时要把cluster相关的软件一并删除掉

！！注意：0.0.0.0:49152  10211/glusterfsd 这个服务是当执行：gluster volume start disk后才开启的。

总结：GlusterFS支持三种客户端类型。Gluster Native Client、NFS和CIFS。Gluster Native Client是在用户空间中运行的基于FUSE的客户端，官方推荐使用Native Client，可以使用GlusterFS的全部功能。
1. 安装Gluster Native Client软件包：
#yum install glusterfs glusterfs-fuse attr -y

#查看I/O信息
--Profile Command 提供接口查看一个卷中的每一个brick的IO信息
gluster volume profile test-volume start
gluster volume profile test-volume info


 </pre>


