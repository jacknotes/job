1.×¼±¸×öRAIDµÄ´ÅÅÌ£¬¶Ô´ÅÅÌ½øĞĞLVM·ÖÇø£¨ÔÚLinuxÏµÍ³ÖĞ£¬ÀıÈçCentOS,ÓÃfdisk /dev/sdaÃüÁî½øÈë£¬ĞÂ½¨Ò»¸ö·ÖÇø²¢Ö¸¶¨´óĞ¡£¬
È»ºó°´t°Ñ·ÖÇø¸ñÊ½ÓÉ83¸Ä³ÉLVMµÄ¸ñÊ½8e£¬×îºó°´w±£´æ²¢ÍË³ö£¬ÍË³öºóÓÃÃüÁîpartprobe»òÖØÆôÊ¹·ÖÇøÁ¢¼´ÉúĞ§£©
2.·ÖÇø½¨Á¢ºÃºó£¬¾ÍÒªĞÂ½¨pvÁË£¬ÓÃpvcreate /dev/sda7;ÓÉÓÚÒÑ¾­ÓĞLVM·ÖÇøÁË£¬ËùÒÔ¾Í²»ÓÃvgcreateĞÂ½¨ÁË£¬ÒªÓÃvgextendÌí¼Óµ½ÏÖÓĞ
µÄvgÖĞ£¬Ê¹ÓÃpvdisplay,vgdisplay²é¿´pv,vg×´Ì¬£¬ÒªÏë×îºó³É¹¦Ìí¼Óµ½LVM,ÔòÒª×îºóÌí¼Óµ½lv,Ê¹ÓÃlvresize -L +12.58G /dev/myvg/mylv
À´Ìí¼Ó12.58GÈİÁ¿µ½ÏÖÓĞµÄmylvÖĞ£¬×îºóÊ¹ÓÃresize2fsÀ´À©Õ¹ÎÄ¼şÏµÍ³
3.°²×°samba,samba-client,samba-commonÈı¸öÈí¼ş£¬²¢ÉèÖÃ¿ªÆô×Ô¶¯Æô¶¯smb,nmb·şÎñ£¬chkconfig --level 35 smb on; 
chkconfig --level 35 nmb on;È»ºóÊ¹ÓÃ½Å±¾ÉèÖÃlinuxÕÊ»§ºÍsmbÕÊ»§£¬Ê×ÏÈ´´½¨ĞèÒªµÄÈº×é£¬Ê¹ÓÃsys-groups.sh¿É´´½¨£¬sys-groupsdel.sh
¿ÉÉ¾³ıÈº×é£¬ÉèÖÃlinuxÕÊ»§Ê±²»Òª´´½¨¼ÒÄ¿Â¼£¬´´½¨ÃÜÂëÊ±Ê¹ÓÃmkpassword´´½¨Ëæ»úÃÜÂë£¬ÕâÀïÊ¹ÓÃ½Å±¾sys-users.sh¿ÉÒÔ×Ô¶¯´´½¨£¬
Òà¿ÉÊ¹ÓÃsys-usersdel.sh×Ô¶¯É¾³ılinuxÕÊ»§ºÍsmbÕÊ»§£¬Ê×ÏÈµÃ´´½¨ÓÃ»§ĞÅÏ¢ÔÚsys-usersinfoÀïÃæ¡£
4.±à¼­smbÅäÖÃÎÄ¼ş/etc/samba/smb.cnfÎÄ¼ş£¬ÉèÖÃ
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
[ĞÅÏ¢²¿]			#¹²ÏíÃû³Æ
        comment = Information	#ÃèÊöĞÅÏ¢
        path = /Share/Info	#ÕæÊµÄ¿Â¼Â·¾¶
        browseable = yes
        writable = yes
        valid users = @Info	#ÓĞĞ§Èº×é
        create mode = 0664
        directory mode = 0775

²¢ÒÀÀıĞÅÏ¢²¿ÉèÖÃ¸÷²¿ÃÅÎÄ¼ş¼Ğ£¬ÉèÖÃÌØ¶¨µÄ²¿ÃÅÈº×é¿É¶ÁĞ´£¬ĞÂ½¨ÎÄµµÄ¬ÈÏÈ¨ÏŞ£¬ĞÂ½¨Ä¿Â¼Ä¬ÈÏÈ¨ÏŞ¡£
5.Ê¹ÓÃtestparmÀ´²âÊÔÅäÖÃÎÄ¼şÊÇ·ñÕıÈ·£¬¿ÉÒÔÅÅ½â£¬Òà¿ÉÊ¹ÓÃtestparm -vÀ´ÏêÏ¸²âÊÔ£¬»¹Òª¶Ô¹²ÏíµÄÄ¿Â¼½øĞĞsetfaclÀ´ÉèÖÃ¸úsmb.cnf
ÎÄ¼şÖĞÒ»ÑùµÄÈ¨ÏŞ£¬ÕâÑù²ÅÄÜÊ¹smb·şÎñÈ¨ÏŞÉúĞ§£¬·ñÔò»áÔì³ÉÎŞ·¨Ğ´Èë£¬Íêºó³ÉÓÃ»§¿ÉÒÔÊ¹ÓÃ\\IPµÄ·½Ê½À´·ÃÎÊsmb·şÎñÆ÷ÁË£¬
¶øsmb·şÎñÆ÷¿ÉÒÔÊ¹ÓÃsmbstatusÀ´¹Û²ì¿Í»§¶ËÇé¿ö¡£

×¢Òâ£ºÊ¹ÓÃsmbpasswordÀ´¸ü¸ÄsmbÕÊ»§ÃÜÂë£¬Ê¹ÓÃpdbedit -a user --Ôö¼Ó¡¢pdbedit -x user --É¾³ı



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
description: ¿¿¿¿¿-d¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿user,group,other¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿g:smb01:rwx¿mask¿¿¿¿¿¿¿¿¿¿¿mask¿rx¿¿¿¿ACL¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿
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
[root@salt ~/k8s/root]# setfacl -b k8s/    --¿¿ACL¿¿¿¿
[root@salt ~/k8s/root]# getfacl k8s
# file: k8s
# owner: root
# group: smb02
user::rwx
group::r-x
other::r-x
--¿¿¿¿acl¿¿:
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
¿¿¿¿¿¿¿¿¿rx¿¿¿¿¿¿¿¿ACL¿¿¿¿¿¿¿
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
¿¿mask¿¿¿¿¿¿ 
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
¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿
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
[root@salt ~/k8s/root]# setfacl -x g:smb02 k8s/   --¿¿¿¿¿¿¿¿ACL
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


