#!/bin/bash  
#describe: Shell Command For Backup MySQL Database Everyday Automatically By Crontab  
#type: full backup
#author: jack
#date: 2020-08-20
   
USER=root  
PASSWORD="jackli"  
DATABASE="travelproduct flight_manager"  
HOSTNAME="localhost"  
   
BACKUP_DIR=/backup/mysql/database  #备份文件存储路径  
LOGFILE=/backup/mysql/mysql_backup.log #日记文件路径  
DATE=`date '+%Y%m%d-%H%M%S'` #日期格式（作为文件名）  
DUMPFILE=pro-$DATE.sql #备份文件名  
ARCHIVE=$DUMPFILE.tar.gz #压缩文件名  
OPT='--single-transaction --master-data=2 --databases'
OPTIONS="-h$HOSTNAME -u$USER -p$PASSWORD $OPT $DATABASE"    
#判断备份文件存储目录是否存在，否则创建该目录  
if [ ! -d $BACKUP_DIR ] ;  
then  
        mkdir -p "$BACKUP_DIR"  
fi  
#开始备份之前，将备份信息头写入日记文件   
echo "———————————————–———————————————–" >> $LOGFILE  
echo "BACKUP DATE:" $(date +"%y-%m-%d %H:%M:%S") >> $LOGFILE  
echo "———————————————–———————————————– " >> $LOGFILE  
   
#切换至备份目录  
cd $BACKUP_DIR  
#使用mysqldump 命令备份制定数据库，并以格式化的时间戳命名备份文件  
echo "full backup databases ${DATABASE}" >> $LOGFILE
mysqldump $OPTIONS > $DUMPFILE 2> /dev/null 
#判断数据库备份是否成功  
if [[ $? == 0 ]]; then  
    #创建备份文件的压缩包  
    tar czvf $ARCHIVE $DUMPFILE >& /dev/null 
    #输入备份成功的消息到日记文件  
    if [ $? == 0 ];then
    	echo “[$ARCHIVE] Backup Successful!” >> $LOGFILE 
    else
	echo “[$ARCHIVE] Backup Failure!” >> $LOGFILE 
    fi
    #删除原始备份文件，只需保 留数据库备份文件的压缩包即可  
    rm -f $DUMPFILE  
else  
    echo “Database Backup Fail!” >> $LOGFILE  
fi  
#输出备份过程结束的提醒消息  
echo “Backup Process Done >> $LOGFILE 
echo " " >> $LOGFILE  
