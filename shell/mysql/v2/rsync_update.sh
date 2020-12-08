#!/bin/sh
#author: jack
#date: 2020-12-08

#source dir
BACKUPDIR=/data/backup
LOG=${BACKUPDIR}/mysql_backup.log
#destination dir
DESTINATION=/mnt

echo " " >> ${LOG}
echo "StartTime: `date +'%Y-%m-%d-%T'`" >> ${LOG}
echo "copy ${BACKUPDIR} data to ${DESTINATION} dir storage" >> ${LOG}
cd ${BACKUPDIR}
ls ${BACKUPDIR} | egrep -v '*.log'| xargs -I {} rsync -avPz {} ${DESTINATION}
if [ $? == 0 ];then
	echo "copy ${BACKUPDIR} data to ${DESTINATION} dir storage: SUCCESS" >> ${LOG}
	echo "delete ${BACKUPDIR} great 30 day data" >> ${LOG}
	find ${BACKUPDIR}/* -mtime +30 -exec rm -f {} \; >& /dev/null
	[ $? == 0 ] && echo "delete ${BACKUPDIR} great 30 day data: SUCCESS" >> ${LOG} ||  echo "delete ${BACKUPDIR} great 30 day data: FAILURE" >> ${LOG}
else 
	echo "copy ${BACKUPDIR} data to ${DESTINATION} dir storage: FAILURE" >> ${LOG}
fi
echo "EndTime: `date +'%Y-%m-%d-%T'`" >> ${LOG}
