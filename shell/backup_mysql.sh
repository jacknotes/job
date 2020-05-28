#!/bin/bash
#Backup MySQL Database For MYISAM Or innoDB Storage Engine
#date: 20200526
#Author: Jack li
#Email: jacknotes@163.com

USER="homsom"
PASSWORD="homsom"
HOSTNAME="localhost"
BACKUP_DIR=/backup/mysql/$DATABASE #备份文件存储路径
LOGFILE=$BACKUP_DIR/backup.log #记录日记文件 
DATE=`date '+%Y%m%d-%H%M%S'` #日期格式（作为文件名）
DUMPFILE="$2-$DATE.sql" #备份文件名
ARCHIVE=$DUMPFILE.tar.gz #压缩文件名

main(){
	OPT=$1
	DATABASE=$2
	OPTIONS="-h$HOSTNAME -u$USER -p$PASSWORD $OPT $DATABASE"

	#判断备份文件存储目录是否存在，否则创建该目录
	if [ ! -d $BACKUP_DIR ];then
	        mkdir -p "$BACKUP_DIR"
	fi
	
	#开始备份之前，将备份信息头写入日记文件
	echo "----------------------------------------" >> $LOGFILE
	echo "BACKUP DATE:" $(date +"%Y-%m-%d %H:%M:%S") >> $LOGFILE
	echo "----------------------------------------" >> $LOGFILE
	
	#切换至备份目录
	cd $BACKUP_DIR
	
	#使用mysqldump 命令备份制定数据库，并以格式化的时间戳命名备份文件
	mysqldump $OPTIONS > $DUMPFILE
	
	#判断数据库备份是否成功
	if [[ $? == 0 ]]; then
	    echo $(date +"%Y-%m-%d %H:%M:%S") [$DUMPFILE] Database Backup Successful! >> $LOGFILE
	    #创建备份文件的压缩包
	    tar czvf $ARCHIVE $DUMPFILE >> /dev/null 2>&1
	    #输入备份成功的消息到日记文件
	    echo $(date +"%Y-%m-%d %H:%M:%S") [$ARCHIVE] tar.gz Successful! >> $LOGFILE
	    #删除原始备份文件，只需保留数据库备份文件的压缩包即可
	    rm -f $DUMPFILE
	else
	    echo $(date +"%Y-%m-%d %H:%M:%S") Database Backup Failure! >> $LOGFILE
	fi
	#输出备份过程结束的提醒消息
	echo $(date +"%Y-%m-%d %H:%M:%S") Database Backup Done >> $LOGFILE
}

case $1 in 
	myisam|MYISAM)
	    if [ -z $2 ];then 
		echo "DATABASE_NAME is null,This Required!" &> $LOGFILE
		echo "DATABASE_NAME is null,This Required!"
		exit 2
	    else
		main "--lock-all-tables --flush-logs --master-data=2 --database" $2
	    fi
		;;
	innodb|INNODB)
	    if [ -z $2 ];then 
		echo "DATABASE_NAME is null,This Required!" &> $LOGFILE
		echo "DATABASE_NAME is null,This Required!"
		exit 2
	    else
		main "--single-transaction --flush-logs --master-data=2 --database" $2
	    fi
		;;
	*)
		echo "Usage: $0 {(myisam|MYISAM) | (innodb|INNODB)} DATABASE_NAME"
		;;
esac
