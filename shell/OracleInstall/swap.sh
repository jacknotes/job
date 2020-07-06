#!/bin/sh
#
CURRENT_DIR=$(/bin/pwd)
LOGFILE=${CURRENT_DIR}/log.txt
CURRENT_TIME='/usr/bin/date +"%Y-%m-%d-%T"'
SWAPFILE=/swap

INSTALL_SWAP(){
	/usr/bin/dd if=/dev/zero of=${SWAPFILE} bs=2M count=1024 &>> ${LOGFILE} 
        /usr/sbin/mkswap ${SWAPFILE} >> ${LOGFILE}
        /usr/bin/chmod -R 0600 ${SWAPFILE}
        /usr/bin/echo "/swap /swap swap defaults 0 0" >> /etc/fstab
        /usr/bin/mount -a >> ${LOGFILE} 
        /usr/sbin/swapon ${SWAPFILE}
}

#swap
echo '--------------' >> ${LOGFILE}
/usr/bin/echo $(${CURRENT_TIME}) >> ${LOGFILE};
if [ `free -b | grep -i swap | awk '{print $2}'` -gt 0 ];then
	/usr/bin/echo "current machine swap memory is enabled!" >> ${LOGFILE}; 
else 
	[ -e /swap ] && echo "/swap already exists.will exit." >> ${LOGFILE} && exit 1
	INSTALL_SWAP;
	[ $? == 0 ] && /usr/bin/echo "install swap successful" >> ${LOGFILE}  || /usr/bin/echo "install swap failure" >> ${LOGFILE}
fi
echo '--------------' >> ${LOGFILE}
/bin/grep 'install swap successful' ${LOGFILE} &> /dev/null || exit 1


