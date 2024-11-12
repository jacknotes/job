# Samba服务器安装



1. 准备做RAID的磁盘，对磁盘进行LVM分区（在Linux系统中，例如CentOS,用fdisk /dev/sda命令进入，新建一个分区并指定大小，然后按t把分区格式由83改成LVM的格式8e，最后按w保存并退出，退出后用命令partprobe或重启使分区立即生效）
2. 分区建立好后，就要新建pv了，用pvcreate /dev/sda7;由于已经有LVM分区了，所以就不用vgcreate新建了，要用vgextend添加到现有的vg中，使用pvdisplay,vgdisplay查看pv,vg状态，要想最后成功添加到LVM,则要最后添加到lv,使用lvresize -L +12.58G /dev/myvg/mylv来添加12.58G容量到现有的mylv中，最后使用resize2fs来扩展文件系统
3. 安装samba,samba-client,samba-common三个软件，并设置开启自动启动smb,nmb服务，chkconfig --level 35 smb on; chkconfig --level 35 nmb on;然后使用脚本设置linux帐户和smb帐户，首先创建需要的群组，使用sys-groups.sh可创建，sys-groupsdel.sh可删除群组，设置linux帐户时不要创建家目录，创建密码时使用mkpassword创建随机密码，这里使用脚本sys-users.sh可以自动创建，亦可使用sys-usersdel.sh自动删除linux帐户和smb帐户，首先得创建用户信息在sys-usersinfo里面。
4. 编辑smb配置文件/etc/samba/smb.cnf文件，设置如下，并依例信息部设置各部门文件夹，设置特定的部门群组可读写，新建文档默认权限，新建目录默认权限。
```bash
   [global] 
   	workgroup = jackligroup
           netbios name = jackliserver
           server string = Samba Server Version %v

        unix charset = utf8
        display charset = utf8
        dos charset = cp950
    
        unix password sync = yes
        passwd program = /usr/bin/passwd %u
        pam password change = yes
    log file = /var/log/samba/log.%m
        max log size = 50
    security = user
        passdb backend = tdbsam
    load printers = no
   [信息部]			#共享名称
        comment = Information	#描述信息
        path = /Share/Info	#真实目录路径
        browseable = yes
        writable = yes
        valid users = @Info	#有效群组
        create mode = 0664
        directory mode = 0775
```
5. 使用testparm来测试配置文件是否正确，可以排解，亦可使用testparm -v来详细测试，还要对共享的目录进行setfacl来设置跟smb.cnf
文件中一样的权限，这样才能使smb服务权限生效，否则会造成无法写入，完后成用户可以使用\\IP的方式来访问smb服务器了，
而smb服务器可以使用smbstatus来观察客户端情况。

> 注意：使用smbpassword来更改smb帐户密码，使用pdbedit -a user --增加、pdbedit -x user --删除





# 随手记

**202104211550**

```bash
[root@HOMSOM-LINUX01 files]# useradd -s /sbin/nologin jack
[root@HOMSOM-LINUX01 files]# smbpasswd -a jack
New SMB password:
Retype new SMB password:
[root@HOMSOM-LINUX01 files]# cat /etc/init.d/smb
-----------
#!/bin/sh
#
# chkconfig: - 91 35
# description: Starts and stops the Samba smbd daemon \
#	       used to provide SMB network services.
#
# pidfile: /var/run/samba/smbd.pid
# config:  /etc/samba/smb.conf


# Source function library.
if [ -f /etc/init.d/functions ] ; then
  . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
  . /etc/rc.d/init.d/functions
else
  exit 1
fi

# Avoid using root's TMPDIR
unset TMPDIR

# Source networking configuration.
. /etc/sysconfig/network

if [ -f /etc/sysconfig/samba ]; then
   . /etc/sysconfig/samba
fi

# Check that networking is up.
[ ${NETWORKING} = "no" ] && exit 1

# Check that smb.conf exists.
[ -f /etc/samba/smb.conf ] || exit 6

RETVAL=0


start() {
        KIND="SMB"
	echo -n $"Starting $KIND services: "
	daemon smbd $SMBDOPTIONS
	RETVAL=$?
	echo
	[ $RETVAL -eq 0 ] && touch /var/lock/subsys/smb || \
	   RETVAL=1
	return $RETVAL
}	

stop() {
        KIND="SMB"
	echo -n $"Shutting down $KIND services: "
	killproc smbd
	RETVAL=$?
	echo
	[ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/smb
	return $RETVAL
}	

restart() {
	stop
	start
}	

reload() {
        echo -n $"Reloading smb.conf file: "
	killproc smbd -HUP
	RETVAL=$?
	echo
	return $RETVAL
}	

rhstatus() {
	status -l smb smbd
	return $?
}	

configtest() {
	# First run testparm and check the exit status.
	# If it ain't 0, there was a problem, show them the testparm output.
	# Most of the time, though, testparm gives 0 - obvious problems
	# (like a missing config file) that testparm normally tells us about
	# have been checked for earlier in this script.
	/usr/bin/testparm -s &> /dev/null	
	RETVAL=$?
	if [ $RETVAL -ne 0 ]; then
		/usr/bin/testparm -s
		exit $RETVAL
	fi
	
	
	# Note: testparm returns 0 even if it has unknown parameters.
	# Check for the word 'unknown', and print the relevant section
	# if it appears. Return '3' because testparm doesn't usually
	# use that. 
	/usr/bin/testparm -s 2>&1 | grep -i unknown &> /dev/null 
	if [ $? -eq 0 ]; then
		RETVAL=3
		/usr/bin/testparm -s 2>&1 | grep -i unknown 
		exit $RETVAL
	fi
	
	# If testparm didn't fail and there weren't any unknowns, exit.
	echo Syntax OK
	return $RETVAL
}


# Allow status as non-root.
if [ "$1" = status ]; then
       rhstatus
       exit $?
fi

# Check that we can write to it... so non-root users stop here
[ -w /etc/samba/smb.conf ] || exit 4



case "$1" in
  start)
  	start
	;;
  stop)
  	stop
	;;
  restart)
  	restart
	;;
  reload)
  	reload
	;;
  status)
  	rhstatus
	;;
  configtest)
  	configtest
	;;
  condrestart)
  	[ -f /var/lock/subsys/smb ] && restart || :
	;;
  *)
	echo $"Usage: $0 {start|stop|restart|reload|configtest|status|condrestart}"
	exit 2
esac

exit $?
-----------
[root@HOMSOM-LINUX01 files]# cp /etc/samba/smb.conf{,.bak}
[root@HOMSOM-LINUX01 files]# vim /etc/samba/smb.conf
valid users = colin,jack
[root@HOMSOM-LINUX01 files]# /etc/init.d/smb configtest
[root@HOMSOM-LINUX01 files]# /etc/init.d/smb reload
[root@HOMSOM-LINUX01 files]# pdbedit -L
george:0:george
jack:9091:
imguser:500:

#setfacl,getfacl
[root@salt ~/k8s/root]# getfacl k8s
# file: k8s
# owner: root
# group: root
user::rwx
group::r-x
other::r-x
[root@salt ~/k8s/root]# groupadd smb01 
[root@salt ~/k8s/root]# setfacl -d -m g:smb01:rwx k8s/
[root@salt ~/k8s/root]# getfacl k8s
# file: k8s
# owner: root
# group: root
user::rwx
group::r-x
other::r-x
default:user::rwx
default:group::r-x
default:group:smb01:rwx
default:mask::rwx
default:other::r-x
[root@salt ~/k8s/root]# setfacl -d -m g::rwx k8s/
[root@salt ~/k8s/root]# getfacl k8s
# file: k8s
# owner: root
# group: root
user::rwx
group::r-x
other::r-x
default:user::rwx
default:group::rwx
default:group:smb01:rwx
default:mask::rwx
default:other::r-x
[root@salt ~/k8s/root]# setfacl -d -m o::rwx k8s/
[root@salt ~/k8s/root]# getfacl k8s/
# file: k8s/
# owner: root
# group: smb02
user::rwx
group::r-x
other::r-x
default:user::rwx
default:group::rwx
default:group:smb01:rwx
default:mask::rwx
default:other::rwx
[root@salt ~/k8s/root]# setfacl -b k8s/   
[root@salt ~/k8s/root]# getfacl k8s
# file: k8s
# owner: root
# group: smb02
user::rwx
group::r-x
other::r-x
[root@salt ~/k8s/root]# setfacl -m g:smb01:r k8s
[root@salt ~/k8s/root]# getfacl k8s/
# file: k8s/
# owner: root
# group: smb02
user::rwx
group::r-x
group:smb01:r--
mask::r-x
other::r-x
[root@salt ~/k8s/root]# setfacl -m g:smb01:rwx k8s
[root@salt ~/k8s/root]# getfacl k8s/
# file: k8s/
# owner: root
# group: smb02
user::rwx
group::r-x
group:smb01:rwx
mask::rwx
other::r-x
[root@salt ~/k8s/root]# setfacl -m m::r k8s
[root@salt ~/k8s/root]# getfacl k8s/
# file: k8s/
# owner: root
# group: smb02
user::rwx
group::r-x			#effective:r--
group:smb01:rwx			#effective:r--
mask::r--
other::r-x
[root@salt ~/k8s/root]# setfacl -m m::rwx k8s
[root@salt ~/k8s/root]# getfacl k8s/
# file: k8s/
# owner: root
# group: smb02
user::rwx
group::r-x
group:smb01:rwx
mask::rwx
other::r-x
[root@salt ~/k8s/root]# setfacl -m g:smb02:r k8s/
[root@salt ~/k8s/root]# getfacl k8s/
# file: k8s/
# owner: root
# group: smb02
user::rwx
group::r-x
group:smb01:rwx
group:smb02:r--
mask::rwx
other::r-x
[root@salt ~/k8s/root]# setfacl -x g:smb02 k8s/  
[root@salt ~/k8s/root]# getfacl  k8s/
# file: k8s/
# owner: root
# group: smb02
user::rwx
group::r-x
group:smb01:rwx
mask::rwx
other::r-x
```




# Samba

OS: ubuntu18


## 1.安装

```bash
root@repo:/data/syncthing# apt install samba samba-common cifs-utils smbclient -y
root@repo:/data/syncthing# samba -V
Version 4.7.6-Ubuntu

```


## 2. 配置Samba共享及权限

```bash
# 创建samba目录
root@repo:/data/syncthing# mkdir -p /data/syncthing/samba/iisbackup

# 创建用户组
root@repo:/data/syncthing/samba/iisbackup# groupadd -r ops

# 创建samba登录用户
root@repo:/data/syncthing# useradd smb_ops -s /usr/sbin/nologin
root@repo:/data/syncthing/samba/iisbackup# usermod -aG ops smb_ops 
root@repo:/data/syncthing/samba/iisbackup# id smb_ops
uid=9091(smb_ops) gid=9091(smb_ops) groups=9091(smb_ops),996(ops)
root@repo:/data/syncthing# smbpasswd -a smb_ops
New SMB password:					# 123456
Retype new SMB password:
Added user smb_ops.


# 安装setfacl、getfactl工具
root@repo:/data/syncthing/samba# apt install acl -y
root@repo:/data/syncthing/samba# getfacl iisbackup/
# file: iisbackup/
# owner: root
# group: root
user::rwx
group::r-x
other::r-x

# setfacl使用参数
-b 清空扩展访问控制列表策略  
-P 找到符号链接对应的文件
-m 更改文件访问控制列表策略
-d 应用到默认访问控制列表
-k 移除默认访问控制列表
-R 递归处理所有子文件
-x 根据文件中的访问控制列表移除指定策略
-L 跟踪符号链接文件
--vesion 显示版本信息
--help 显示帮助信息


# 配置目录权限，配置用户组ops具有rwx权限
root@repo:/data/syncthing/samba# setfacl -d -m g:ops:rwx iisbackup/
root@repo:/data/syncthing/samba# getfacl iisbackup/
# file: iisbackup/
# owner: root
# group: root
user::rwx
group::r-x
other::r-x
default:user::rwx
default:group::r-x
default:group:ops:rwx
default:mask::rwx
default:other::r-x

# 创建只读用户smb_dev
root@repo:/data/syncthing/samba# useradd smb_dev -s /usr/sbin/nologin
root@repo:/data/syncthing/samba# groupadd -r dev
root@repo:/data/syncthing/samba# usermod -aG dev smb_dev
root@repo:/data/syncthing/samba# id smb_dev
uid=9092(smb_dev) gid=9092(smb_dev) groups=9092(smb_dev),995(dev)
root@repo:/data/syncthing/samba# smbpasswd -a smb_dev
New SMB password:			# 666666
Retype new SMB password:
Added user smb_dev.
# 更改用户密码
root@repo:/data/syncthing/samba# smbpasswd smb_dev
New SMB password:			# 888888
Retype new SMB password:
root@repo:/data/syncthing/samba# setfacl -d -m g:dev:rx iisbackup/
root@repo:/data/syncthing/samba# getfacl iisbackup/
# file: iisbackup/
# owner: root
# group: root
user::rwx
group::r-x
other::r-x
default:user::rwx
default:group::r-x
default:group:dev:r-x
default:group:ops:rwx
default:mask::rwx
default:other::r-x

# 此时读写用户smb_ops，只读用户smb_dev不能在共享aliyun中创建任何文件
root@repo:/data/syncthing/samba# ll
total 0
drwxr-xr-x  3 root root      23 May 13 09:52 ./
drwxrwxr-x  4 root syncthing 43 May 13 09:52 ../
drwxr-xr-x+ 4 root root      28 May 13 15:33 iisbackup/		#此目录本身是755，而此时smb_ops和smb_dev是属于other的
# 配置此目录本身权限，使ops组有读写执行权限，此项配置好后共享才可正常使用，非常重要
root@repo:/data/syncthing/samba# setfacl -m g:ops:rwx iisbackup/
root@repo:/data/syncthing/samba# getfacl iisbackup/
# file: iisbackup/
# owner: root
# group: root
user::rwx
group::r-x
group:ops:rwx
mask::rwx
other::r-x
default:user::rwx
default:group::r-x
default:group:dev:r-x
default:group:ops:rwx
default:mask::rwx
default:other::r-x



# 删除特定用权限
root@repo:/data/syncthing/samba# getfacl iisbackup/
# file: iisbackup/
# owner: root
# group: root
user::rwx
group::r-x
group:ops:rwx
mask::rwx
other::r-x
default:user::rwx
default:user:smb_ops:rwx
default:group::r-x
default:group:dev:r-x
default:group:ops:rwx
default:mask::rwx
default:other::r-x
root@repo:/data/syncthing/samba# setfacl -d -R -x u:smb_ops iisbackup/
root@repo:/data/syncthing/samba# getfacl iisbackup/
# file: iisbackup/
# owner: root
# group: root
user::rwx
group::r-x
group:ops:rwx
mask::rwx
other::r-x
default:user::rwx
default:group::r-x
default:group:dev:r-x
default:group:ops:rwx
default:mask::rwx
default:other::r-x



```



## 3. 配置Samba服务

```bash
root@repo:/etc/samba# vim /etc/samba/smb.conf 

root@repo:/data/syncthing/samba# grep -Ev '#|^$|^;' /etc/samba/smb.conf
# map to guest = bad user不能配置，windows无法打开共享
[global]
   workgroup = WORKGROUP
   server string = %h server (Samba, Ubuntu)
   dns proxy = no
   log file = /var/log/samba/log.%m
   max log size = 1000
   syslog = 0
   panic action = /usr/share/samba/panic-action %d
   server role = standalone server
   passdb backend = tdbsam
   obey pam restrictions = yes
   unix password sync = yes
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = yes
   usershare allow guests = no
   ntlm auth = yes
[printers]
   comment = All Printers
   browseable = no
   path = /var/spool/samba
   printable = yes
   guest ok = no
   read only = yes
   create mask = 0700
[print$]
   comment = Printer Drivers
   path = /var/lib/samba/printers
   browseable = yes
   read only = yes
   guest ok = no
[aliyun]
   comment = local to aliyun share 
   path = /data/syncthing/samba/iisbackup
   browseable = yes
   writable = yes
   valid users = @ops,@dev
   create mode = 0664
   directory mode = 0775  

   
# 启动服务
root@repo:/etc/samba# systemctl start smbd
root@repo:/etc/samba# systemctl status smbd
* smbd.service - Samba SMB Daemon
   Loaded: loaded (/lib/systemd/system/smbd.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2024-05-13 14:22:53 CST; 1s ago
     Docs: man:smbd(8)
           man:samba(7)
           man:smb.conf(5)
 Main PID: 965 (smbd)
   Status: "smbd: ready to serve connections..."
    Tasks: 4 (limit: 4915)
   CGroup: /system.slice/smbd.service
           |-965 /usr/sbin/smbd --foreground --no-process-group
           |-979 /usr/sbin/smbd --foreground --no-process-group
           |-980 /usr/sbin/smbd --foreground --no-process-group
           `-985 /usr/sbin/smbd --foreground --no-process-group

May 13 14:22:53 repo.hs.com systemd[1]: Starting Samba SMB Daemon...
May 13 14:22:53 repo.hs.com systemd[1]: Started Samba SMB Daemon.
root@repo:/etc/samba# systemctl enable smbd
Synchronizing state of smbd.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable smbd

root@repo:/etc/samba# ss -tnlp | grep smbd
LISTEN   0         50                  0.0.0.0:139              0.0.0.0:*        users:(("smbd",pid=965,fd=35))                                                 
LISTEN   0         50                  0.0.0.0:445              0.0.0.0:*        users:(("smbd",pid=965,fd=34))                                                 
LISTEN   0         50                     [::]:139                 [::]:*        users:(("smbd",pid=965,fd=33))                                                 
LISTEN   0         50                     [::]:445                 [::]:*        users:(("smbd",pid=965,fd=32))      

```


## 4. 查看smbd状态

```bash
# 检测smbd配置文件
root@repo:/etc/samba# testparm 
Load smb config files from /etc/samba/smb.conf
WARNING: The "syslog" option is deprecated
Processing section "[printers]"
Processing section "[print$]"
Processing section "[aliyun]"
Loaded services file OK.
Server role: ROLE_STANDALONE

Press enter to see a dump of your service definitions

# Global parameters
[global]
	dns proxy = No
	log file = /var/log/samba/log.%m
	max log size = 1000
	ntlm auth = ntlmv1-permitted
	obey pam restrictions = Yes
	pam password change = Yes
	panic action = /usr/share/samba/panic-action %d
	passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
	passwd program = /usr/bin/passwd %u
	server role = standalone server
	server string = %h server (Samba, Ubuntu)
	syslog = 0
	unix password sync = Yes
	usershare allow guests = Yes
	idmap config * : backend = tdb


[printers]
	browseable = No
	comment = All Printers
	create mask = 0700
	path = /var/spool/samba
	printable = Yes


[print$]
	comment = Printer Drivers
	path = /var/lib/samba/printers


[aliyun]
	comment = local to aliyun share
	create mask = 0664
	directory mask = 0775
	path = /data/syncthing/samba/iisbackup
	read only = No
	valid users = @ops

# 查看smb状态
root@repo:/data/syncthing/samba# smbstatus --share

Samba version 4.7.6-Ubuntu
PID     Username     Group        Machine                                   Protocol Version  Encryption           Signing              
----------------------------------------------------------------------------------------------------------------------------------------
1853    9092         9092         192.168.13.182 (ipv4:192.168.13.182:61175) SMB2_10           -                    -                    
1444    smb_ops      smb_ops      172.168.2.219 (ipv4:172.168.2.219:12873)  SMB3_11           -                    partial(AES-128-CMAC)
2083    smb_ops      smb_ops      192.168.13.236 (ipv4:192.168.13.236:17922) NT1               -                    -                    

Service      pid     Machine       Connected at                     Encryption   Signing     
---------------------------------------------------------------------------------------------
aliyun       1444    172.168.2.219 Mon May 13 03:17:46 PM 2024 CST  -            -           
IPC$         2083    192.168.13.236 Mon May 13 03:56:12 PM 2024 CST  -            -           
aliyun       2083    192.168.13.236 Mon May 13 03:56:12 PM 2024 CST  -            -           
IPC$         1444    172.168.2.219 Mon May 13 03:07:43 PM 2024 CST  -            -           
aliyun       1853    192.168.13.182 Mon May 13 03:32:27 PM 2024 CST  -            -           

Locked files:
Pid          Uid        DenyMode   Access      R/W        Oplock           SharePath   Name   Time
--------------------------------------------------------------------------------------------------
1444         9091       DENY_NONE  0x100081    RDONLY     NONE             /data/syncthing/samba/iisbackup   .   Mon May 13 15:48:23 2024
1444         9091       DENY_NONE  0x100081    RDONLY     NONE             /data/syncthing/samba/iisbackup   .   Mon May 13 15:48:25 2024
1444         9091       DENY_NONE  0x100081    RDONLY     NONE             /data/syncthing/samba/iisbackup   .   Mon May 13 15:48:13 2024

root@repo:/data/syncthing/samba# smbstatus --shares

Service      pid     Machine       Connected at                     Encryption   Signing     
---------------------------------------------------------------------------------------------
aliyun       1444    172.168.2.219 Mon May 13 03:17:46 PM 2024 CST  -            -           
IPC$         2083    192.168.13.236 Mon May 13 03:56:12 PM 2024 CST  -            -           
aliyun       2083    192.168.13.236 Mon May 13 03:56:12 PM 2024 CST  -            -           
IPC$         1444    172.168.2.219 Mon May 13 03:07:43 PM 2024 CST  -            -           
aliyun       1853    192.168.13.182 Mon May 13 03:32:27 PM 2024 CST  -            -      

# kill共享会话1853
```





## 5.问题汇总

### 5.1服务器启用密码策略后带来的问题

* 提示密码过期，需要更改密码
* 使用smbpassword更改密码后，提示用户首次登录需要更改密码
* 再次使用passwd来更改密码

```bash
# 第一步更改用户密码
root@repo:~# echo smb_ops:ops@Linux111 | chpasswd
# 第二步更改smb密码后，即可正常访问
root@repo:~# smbpasswd smb_ops
New SMB password:
Retype new SMB password:
```

