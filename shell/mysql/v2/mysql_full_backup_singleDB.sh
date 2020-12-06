#!/bin/bash  
#Describe: Shell Script For Backup MySQL Database Everyday Automatically By Crontab  
#Type: Single_Database_Full_Backup
#mysql_info: mysql5.7
#Author: JackLi
#Date: 2020-12-04
#set -e

#----user authrization
#grant select,lock tables,replication client,show view,trigger,reload,execute,super on *.* to dbbackup@'localhost';
#[root@salt ~]# openssl rand -base64 5
#hZH3oCw=
#alter user dbbackup@'localhost' identified by "hZH3oCw=";
#flush privileges;

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:/usr/local/mysql/bin
export LANG=en_US.UTF-8
   
ENV=Dev
TYPE=Full
USER=dbbackup 
HOSTNAME="localhost"  
PASSWORD="hZH3oCw="  
DATABASE=(car_platform flight_manager hotelresource payorder travelproduct)
IPADDR=`ip add show | grep 192 | awk '{print $2}' | awk -F '/' '{print $1}'`
BACKUP_DIR=/home/backup  #备份文件存储路径  
LOGFILE=${BACKUP_DIR}/mysql_backup.log #日记文件路径  
MYSQL_CONF=/etc/my.cnf   #mysql配置文件路径
MYSQL_BOOT_SHELL=/etc/init.d/mysqld  #mysql启动脚本路径
MYSQL_CONF_NAME=`basename ${MYSQL_CONF}`   #mysql配置文件名称
MYSQL_BOOT_SHELL_NAME=`basename ${MYSQL_BOOT_SHELL}`  #mysql启动脚本名称
DATE=`date +%Y%m%d_%H%M%S` #日期格式（作为目录名）  
DATE_FILE="date +%Y%m%d_%H%M%S" #日期格式（作为文件名） 
DATE_YEAR=`date '+%Y'`
DATE_MONTH=`date '+%m'`
FORMAT=${ENV}_${TYPE}_${DATE}
BACKUP_DIR_CHILD="${DATE_YEAR}/${DATE_MONTH}/${FORMAT}"
DUMPFILE_INFO=${FORMAT}.sql.info #备份数据库信息名称  
MYSQL_DATADIR=`mysql -h${HOSTNAME} -u${USER} -p${PASSWORD} -e "show global variables like 'datadir';" | awk '{print $2}' | tail -n 1`
INNODB_VERSION=`mysql -h${HOSTNAME} -u${USER} -p${PASSWORD} -e "show global variables like 'innodb_version';" | awk '{print $2}' | tail -n 1`
BASE_DIR=`mysql -h${HOSTNAME} -u${USER} -p${PASSWORD} -e "show global variables like 'basedir';" | awk '{print $2}' | tail -n 1`
OPT="--single-transaction --master-data=2 --databases "
OPTIONS="-h${HOSTNAME} -u${USER} -p${PASSWORD} ${OPT}"    

##判断备份文件存储目录和二进制存储目录是否存在，否则创建该目录  
if [ ! -d "${BACKUP_DIR}/${BACKUP_DIR_CHILD}" ]; then mkdir -p "${BACKUP_DIR}/${BACKUP_DIR_CHILD}"; fi
cd ${BACKUP_DIR}/${BACKUP_DIR_CHILD}

#开始备份之前，将备份信息头写入日记文件   
echo " " >> $LOGFILE
echo "———————————————–————————————————————————" >> $LOGFILE  
echo "BACKUP DATETIME:" ${DATE} >> $LOGFILE  
echo "———————————————–————————————————————–———" >> $LOGFILE  

#开始备份
for i in `seq 0 ${#DATABASE[*]}`;do
	if [ ${i} != ${#DATABASE[*]} ];then
		DUMPFILE=${ENV}_${TYPE}_`${DATE_FILE}`_${DATABASE[${i}]}.sql #备份文件名
		echo "Full_Backup_Databases: ${DATABASE[${i}]}.........." >> $LOGFILE
		mysqldump ${OPTIONS} ${DATABASE[${i}]} > ${DUMPFILE} 2> /dev/null 
		#判断数据库备份是否成功  
		if [[ $? == 0 ]]; then  
    		echo "Full_Backup_Databases ${DATABASE[${i}]}: Success" >> $LOGFILE
		else  
    		echo "Full_Backup_Databases ${DATABASE[${i}]}: Falure" >> ${LOGFILE}  
		fi  
	fi
done

#对配置文件和启动脚本进行存档
echo "Copy_Mysql_Config_File_and_Boot_Shell_To_Bakcup_Dir.........." >> ${LOGFILE}  
\cp -ar ${MYSQL_CONF} ${BACKUP_DIR}/${BACKUP_DIR_CHILD}/${FORMAT}_${MYSQL_CONF_NAME}  && \cp -ar ${MYSQL_BOOT_SHELL} ${BACKUP_DIR}/${BACKUP_DIR_CHILD}/${FORMAT}_${MYSQL_BOOT_SHELL_NAME}
[ $? == 0 ] && echo "Copy_Mysql_Config_File_and_Boot_Shell_To_Bakcup_Dir: Success" >> ${LOGFILE} || echo "Copy_Mysql_Config_File_and_Boot_Shell_To_Bakcup_Dir: Failure" >> ${LOGFILE} 

#写入信息到文件
echo "———————————————–————————————————————————" >> ${DUMPFILE_INFO}
echo "MYSQL_INFO" >> ${DUMPFILE_INFO}
echo "———————————————–————————————————————–———" >> ${DUMPFILE_INFO}
echo "BACKUP_HOST: ${IPADDR}" >> ${DUMPFILE_INFO}
echo "BACKUP_ENV: ${ENV}" >> ${DUMPFILE_INFO}
echo "BACKUP_TYPE: ${TYPE}" >> ${DUMPFILE_INFO}
echo "BACKUP_DATABASE: ${DATABASE[@]}" >> ${DUMPFILE_INFO}
echo "BACKUP_DATABASE_VERSION: ${INNODB_VERSION}" >> ${DUMPFILE_INFO}
echo "BACKUP_DATABASE_BASE_DIR: ${BASE_DIR}" >> ${DUMPFILE_INFO}
echo "BACKUP_DATABASE_DATA_DIR: ${MYSQL_DATADIR}" >> ${DUMPFILE_INFO}
echo "BACKUP_DATABASE_CONF: ${MYSQL_CONF}" >> ${DUMPFILE_INFO}
echo "BACKUP_DATABASE_START_SHELL: ${MYSQL_BOOT_SHELL}" >> ${DUMPFILE_INFO}
echo "  " >> ${DUMPFILE_INFO}
echo "———————————————–————————————————————————" >> ${DUMPFILE_INFO}
echo "MYSQL_BACKUP_LOG" >> ${DUMPFILE_INFO}
sed -n "/${DATE}/,/Bakcup_Dir:/p" ${LOGFILE} >> ${DUMPFILE_INFO}

#创建备份文件的压缩包  
echo "Create_Compression_File.........." >> ${LOGFILE}  
ARCHIVE=${FORMAT}.tar.gz #压缩文件名  
cd .. && tar czf ${ARCHIVE} ${FORMAT} >& /dev/null 
#判断压缩是否成功  
if [ $? == 0 ];then
	echo "Create_Compression_File: Success" >> ${LOGFILE}
    	#删除原始备份文件，只需保留数据库备份文件的压缩包即可  
	echo "Delete_Source_Backup_files.........." >> ${LOGFILE}
	rm -rf ${FORMAT}
	[ $? == 0 ] && echo "Delete_Source_Backup_files: Success" >> ${LOGFILE} || echo "Delete_Source_Backup_files: Failure" >> ${LOGFILE}
	echo "[${ARCHIVE}] Backup_Succeed!" >> ${LOGFILE} 
else
	echo "Create_Compression_File: Failure" >> ${LOGFILE}
	echo "[${ARCHIVE}] Backup_Failure!" >> ${LOGFILE} 
fi

#输出备份过程结束的提醒消息  
echo "Backup_Process_Done" >> ${LOGFILE}
echo "  " >> ${LOGFILE}  
