1.准备做RAID的磁盘，对磁盘进行LVM分区（在Linux系统中，例如CentOS,用fdisk /dev/sda命令进入，新建一个分区并指定大小，
然后按t把分区格式由83改成LVM的格式8e，最后按w保存并退出，退出后用命令partprobe或重启使分区立即生效）
2.分区建立好后，就要新建pv了，用pvcreate /dev/sda7;由于已经有LVM分区了，所以就不用vgcreate新建了，要用vgextend添加到现有
的vg中，使用pvdisplay,vgdisplay查看pv,vg状态，要想最后成功添加到LVM,则要最后添加到lv,使用lvresize -L +12.58G /dev/myvg/mylv
来添加12.58G容量到现有的mylv中，最后使用resize2fs来扩展文件系统
3.安装samba,samba-client,samba-common三个软件，并设置开启自动启动smb,nmb服务，chkconfig --level 35 smb on; 
chkconfig --level 35 nmb on;然后使用脚本设置linux帐户和smb帐户，首先创建需要的群组，使用sys-groups.sh可创建，sys-groupsdel.sh
可删除群组，设置linux帐户时不要创建家目录，创建密码时使用mkpassword创建随机密码，这里使用脚本sys-users.sh可以自动创建，
亦可使用sys-usersdel.sh自动删除linux帐户和smb帐户，首先得创建用户信息在sys-usersinfo里面。
4.编辑smb配置文件/etc/samba/smb.cnf文件，设置
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

并依例信息部设置各部门文件夹，设置特定的部门群组可读写，新建文档默认权限，新建目录默认权限。
5.使用testparm来测试配置文件是否正确，可以排解，亦可使用testparm -v来详细测试，还要对共享的目录进行setfacl来设置跟smb.cnf
文件中一样的权限，这样才能使smb服务权限生效，否则会造成无法写入，完后成用户可以使用\\IP的方式来访问smb服务器了，
而smb服务器可以使用smbstatus来观察客户端情况。

注意：使用smbpassword来更改smb帐户密码，使用pdbedit -a user --增加、pdbedit -x user --删除



#202104211550
<pre>
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
--靠靠acl靠:
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
靠mask靠靠靠 
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

</pre>


