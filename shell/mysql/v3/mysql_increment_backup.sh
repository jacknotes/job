#!/bin/bash
#Describe: Shell Command For Backup MySQL Database Everyday Automatically By Crontab  
#Type: Increment Backup
#mysql_info: mysql5.7
#Author: JackLi
#Date: 2020-12-08

#----user authrization
#grant select,lock tables,replication client,show view,trigger,reload,execute,super,process on *.* to dbbackup@'localhost';
#[root@salt ~]# openssl rand -base64 5
#hZH3oCw=
#alter user dbbackup@'localhost' identified by "hZH3oCw=";
#flush privileges;

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:/usr/local/mysql/bin
export LANG=en_US.UTF-8

ENV=Pro
TYPE=Increment
USER=dbbackup
HOSTNAME="localhost"
PASSWORD="s4ytieZbkqc="
BACKUP_DIR=/data/backup  #备份文件存储路径  
LOGFILE=${BACKUP_DIR}/mysql_backup.log #日记文件路径  
DATE=`date '+%Y%m%d_%H%M%S'` #日期格式（作为文件名）  
DATE_FILE="date +%Y%m%d_%H%M%S" #日期格式（作为文件名） 
DATE_YEAR=`date '+%Y'`
DATE_MONTH=`date '+%m'`
FORMAT=${ENV}_${TYPE}_${DATE}
BACKUP_DIR_CHILD="${DATE_YEAR}/${DATE_MONTH}/${FORMAT}"
DUMPFILE_INFO=${FORMAT}.sql.info #备份数据库信息名称  
ARCHIVE=${FORMAT}.tar.gz #压缩文件名  
MYSQL_BINLOG_INDEX=`mysql -h${HOSTNAME} -u${USER} -p${PASSWORD} -e "show global variables like 'log_bin_index';" | awk '{print $2}' | tail -n 1`
MYSQL_BINLOG_BASENAME="dirname `mysql -h${HOSTNAME} -u${USER} -p${PASSWORD} -e "show global variables like 'log_bin_basename';" | awk '{print $2}' | tail -n 1`"

##判断备份文件存储目录和二进制存储目录是否存在，否则创建该目录  
if [ ! -d "${BACKUP_DIR}/${BACKUP_DIR_CHILD}" ]; then mkdir -p "${BACKUP_DIR}/${BACKUP_DIR_CHILD}"; fi

#开始备份之前，将备份信息头写入日记文件   
echo " " >> $LOGFILE
echo "———————————————–————————————————————————" >> $LOGFILE
echo "BACKUP DATETIME: "${DATE} >> $LOGFILE
echo "———————————————–————————————————————–———" >> $LOGFILE

#对binlog进行存档
cd ${BACKUP_DIR}/${BACKUP_DIR_CHILD} && echo "Increment_Backup_Databases.........." >> $LOGFILE

#mysql日志切割
mysqladmin -h${HOSTNAME} -u${USER} -p${PASSWORD} flush-logs 2> /dev/null
if [[ $? == 0 ]]; then
    #存放binlog文件名变量数组
    VAR_BINLOG_NAME_LONG=(`cat ${MYSQL_BINLOG_INDEX} | sed "s#^.#$(${MYSQL_BINLOG_BASENAME})#g" | sort | head -n -1`)
    VAR_BINLOG_NAME_SHORT=(`cat ${MYSQL_BINLOG_INDEX} | sed "s#^./##g" | sort | head -n -1`)

    #循环复制binlog日志到备份目录
    echo "Copy_Binlog_To_BackupDir.........." >> $LOGFILE
    for i in `seq 0 ${#VAR_BINLOG_NAME_LONG[*]}`;do
        if [ "${i}" != "${#VAR_BINLOG_NAME_LONG[*]}" ];then
		\cp -ar ${VAR_BINLOG_NAME_LONG[$[i]]} ${VAR_BINLOG_NAME_SHORT[${i}]}_${ENV}_${TYPE}_`${DATE_FILE}`
        fi
    done

    #删除之前旧binlog
    if [[ $? == 0 ]]; then
        echo "Copy_Binlog_To_BackupDir: Success" >> $LOGFILE
        PURGE_BINARY_LOGS="purge binary logs to `mysql -h${HOSTNAME} -u${USER} -p${PASSWORD} -e 'show binary logs;' | tail -n 1 | awk '{print $1}'`"
        PURGE_BINARY_LOGS_RESULT=`echo ${PURGE_BINARY_LOGS} | sed -e 's/to /to \"/g' | sed -e 's/$/\"/g'`
        echo "Delete_Old_Binlog.........." >> ${LOGFILE}
        mysql -h${HOSTNAME} -u${USER} -p${PASSWORD} -e "${PURGE_BINARY_LOGS_RESULT}"
        if [[ $? == 0 ]];then
	    echo "Delete_Old_Binlog: Success" >> ${LOGFILE} 
	else
	    echo "Delete_Old_Binlog: Failure" >> ${LOGFILE}
        fi
    else
        echo "Copy_Binlog_To_BackupDir: Failure" >> $LOGFILE
    fi

    #创建备份文件的压缩包  
    echo "Create_Compression_File.........." >> ${LOGFILE}
    cd .. && tar czf ${ARCHIVE} ${FORMAT} >& /dev/null

    #判断压缩是否成功
    if [ $? == 0 ];then
        echo "Create_Compression_File: Success" >> ${LOGFILE}

        #删除原始备份文件，只需保留数据库备份文件的压缩包即可  
        echo "Delete_Source_Backup_files.........." >> ${LOGFILE}
        rm -rf ${FORMAT}
        if [ $? == 0 ];then
	    echo "Delete_Source_Backup_files: Success" >> ${LOGFILE} 
            echo "[${ARCHIVE}] Backup_Succeed!" >> ${LOGFILE}
            echo "Increment_Backup_Databases: Success" >> $LOGFILE
	else 
	    echo "Delete_Source_Backup_files: Failure" >> ${LOGFILE}
        fi
    else
        echo "Create_Compression_File: Failure" >> ${LOGFILE}
        echo "[${ARCHIVE}] Backup_Failure!" >> ${LOGFILE}
    fi
else
    echo "Increment_Backup_Databases: Failure" >> $LOGFILE
fi

