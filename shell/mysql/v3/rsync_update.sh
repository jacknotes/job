#!/bin/sh
#author: jack
#date: 2020-12-08

#source dir
BACKUPDIR=/data/backup
LOG=${BACKUPDIR}/mysql_backup.log
#destination dir
DESTINATION=/mnt

echo " " >> ${LOG}
echo "———————————————–————————————————————————" >> ${LOG}
echo "StartTime: `date +'%Y-%m-%d-%T'`" >> ${LOG}
echo "———————————————–————————————————————–———" >> ${LOG}
cd ${BACKUPDIR}
ls ${BACKUPDIR} | egrep -v '*.log'| xargs -I {} rsync -avPz {} ${DESTINATION}
if [ $? == 0 ];then
	echo "copy ${BACKUPDIR} data to ${DESTINATION} dir storage: Success" >> ${LOG}
	find ${BACKUPDIR}/* -mtime +30 -exec rm -f {} \; >& /dev/null
	[ $? == 0 ] && echo "delete ${BACKUPDIR} great 30 day data: Success" >> ${LOG} ||  echo "delete ${BACKUPDIR} great 30 day data: Failure" >> ${LOG}
else 
	echo "copy ${BACKUPDIR} data to ${DESTINATION} dir storage: Failure" >> ${LOG}
fi
echo "EndTime: `date +'%Y-%m-%d-%T'`" >> ${LOG}
