#!/bin/sh

BACKUPDIR=/home/backup
LOG=/home/backup/mysql_backup.log
DESTINATION=/mnt

echo " " >> ${LOG}
echo "copy ${BACKUPDIR} data to ${DESTINATION} dir storage" >> ${LOG}
ls ${BACKUPDIR} | egrep -v '*.log'| xargs -I {} rsync -avPz {} ${DESTINATION}
if [ $? == 0 ];then
	echo "copy ${BACKUPDIR} data to ${DESTINATION} dir storage: SUCCESS" >> ${LOG}
	echo "delete ${BACKUPDIR} great 30 day data" >> ${LOG}
	find ${BACKUPDIR}/* -mtime +30 -exec rm -f {} \; >& /dev/null
	[ $? == 0 ] && echo "delete ${BACKUPDIR} great 30 day data: SUCCESS" >> ${LOG} ||  echo "delete ${BACKUPDIR} great 30 day data: FAILURE" >> ${LOG}
else 
	echo "copy ${BACKUPDIR} data to ${DESTINATION} dir storage: FAILURE" >> ${LOG}
fi
