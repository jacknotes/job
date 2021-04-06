#!/bin/sh
# del backup network files.
# date: 202104061329

export PATH=/root/.pyenv/plugins/pyenv-virtualenv/shims:/root/.pyenv/shims:/root/.pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/local/axel/bin:/usr/local/go/bin:/root/bin
DIRNAME=/var/lib/tftpboot
BACKUPDIR=/windows/192.168.13.236/network/
DATETIME=`date +'%Y%m%d%H%M%S'`

/shell/network/cisco-telnet.sh 192.168.13.252 switch_core01 ${DATETIME}
/shell/network/cisco-telnet.sh 192.168.13.253 switch_core02 ${DATETIME} 
/shell/network/huaweiFirewall-ssh.sh 192.168.1.1 hda1_vrpcfg.zip ${DATETIME} 

if [ $? == 0 ];then
	echo "`date +'%Y-%m-%d %T:' `backup network files successful." >> /var/log/custom_logs.txt
	sleep 1
	#copy file to backup
	cp -ar ${DIRNAME}/*${DATETIME} ${BACKUPDIR} && echo "`date +'%Y-%m-%d %T:' `copy new backup network files successful." >> /var/log/custom_logs.txt || echo "`date +'%Y-%m-%d %T:' `copy new backup network files failure." >> /var/log/custom_logs.txt

	for i in switch_core* hda*;do
		find ${DIRNAME} -name "$i" -mtime +7 -exec rm -f {} \;
	done
	[ $? == 0 ] && echo "`date +'%Y-%m-%d %T:' `del old backup network files successful." >> /var/log/custom_logs.txt || echo "`date +'%Y-%m-%d %T:' `del old backup network files failure." >> /var/log/custom_logs.txt 
else 
	echo "`date +'%Y-%m-%d %T:' `backup network files failure." >> /var/log/custom_logs.txt
fi
