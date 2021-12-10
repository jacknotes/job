#!/bin/sh
#xtrabackup method backup mysql5.7
#Description: 对于MySQL 5.7、5.6或5.5实例：安装Percona XtraBackup 2.4。对于MySQL 8.0实例，安装Percona XtraBackup 8.0
#XtraBackup2.4 URL: https://www.percona.com/doc/percona-xtrabackup/2.4/installation.html?spm=5176.19908310.help.46.44741450Xet10r
#XtraBackup8.0 URL: https://www.percona.com/doc/percona-xtrabackup/8.0/installation.html?spm=5176.19908310.help.47.44741450Xet10r

BACKUP_DATE=$(date +%Y-%m-%d_%H_%M_%S)
BACKUP_DIR=/data/mysql/backup
FULLBACKUP_PATH=$BACKUP_DIR/full
INCRBACKUP_PATH=$BACKUP_DIR/incr
BACKUP_LOG_PATH=$BACKUP_DIR/logs
BACKUP_KEEP_DAY=7
MYSQL_CONF=/etc/my.cnf
INNOBACKUPEX=/usr/local/xtrabackup/bin/innobackupex
MYSQL_CMD=/usr/bin/mysql
MYSQL_CONNECT="--host=****--user=**** --password=**** --port=3306"
MYSQL_DATABASE_NAMES="yjk  yjk_mall_2_0"
MAIL_FROM="root@`hostname`"
MAIL_TO="linge@hz-health.cn"
MAIL_TO_ERROR="linge@hz-health.cn"
 
error()
{
 echo "$1" 1>&2
 exit 1
}
 
#before the backup, check the system enviroment setting and mysql status and so on
mysql_backup_check()
{
 
    if [ ! -d $FULLBACKUP_PATH ];then
        mkdir -p $FULLBACKUP_PATH
    fi
 
    if [ ! -d $INCRBACKUP_PATH ];then
        mkdir -p $INCRBACKUP_PATH
    fi
 
    if [ ! -d $BACKUP_LOG_PATH ];then
        mkdir -p $BACKUP_LOG_PATH
    fi
 
 
    if [ ! -x $INNOBACKUPEX ];then
       error "$INNOBACKUPEX did not exists"
    fi
 
    if [ ! -x $MYSQL_CMD ];then
       error "mysql client did not exists!"
    fi
 
     mysql_status=`netstat -nl | awk 'NR>2{if ($4 ~ /.*:3306/) {print "Yes";exit 0}}'`
 
        if [ "$mysql_status" != "Yes" ];then
          error "MySQL did not start. please check it"
        fi
 
        if ! `echo 'exit' | $MYSQL_CMD -s $MYSQL_CONNECT` ; then
         error "please check the user and password is correct!"
        fi
}
 
 
xtra_backup()
{
  if [ $# = 2 ];then
        $INNOBACKUPEX --defaults-file=$MYSQL_CONF $MYSQL_CONNECT  --compress --compress-threads=8 --databases="${MYSQL_DATABASE_NAMES}" --no-timestamp  $1/full_$BACKUP_DATE>$2 2>&1
  elif [ $# = 3 ];then
        $INNOBACKUPEX  --defaults-file=$MYSQL_CONF $MYSQL_CONNECT --compress --compress-threads=8 --databases="${MYSQL_DATABASE_NAMES}" --no-timestamp --incremental  $1/incr_$BACKUP_DATE  --incremental-basedir $2 >$3 2>&1
  else
      error "the parameter is not correct"
  fi
}
 
 
lastest_fullback_dir()
{
    if [ -d $1 ]; then
        path=`ls -t $1 |head -n 1`
        if [  $path ]; then
            echo $path
        else
            error "lastest_fullback_dir(): 目录为空,没有最新目录"
        fi
    else
        error "lastest_fullback_dir(): 目录不存在或者不是目录"
    fi
}
 
 
mysql_full_backup()
{
    xtra_backup  $FULLBACKUP_PATH $BACKUP_LOG_PATH/full_$BACKUP_DATE.log
 
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        (echo "Subject: MySQL Backup Failed: MySQL Backup failed on `hostname`";
      cat ${BACKUP_LOG_PATH}/full_${BACKUP_DATE}.log;
    ) | /usr/sbin/sendmail -O NoRecipientAction=add-to -f${MAIL_FROM} ${MAIL_TO}
    else
      (echo "Subject: MySQL Backup Success: MySQL Backup Succeed on `hostname`";
      cat ${BACKUP_LOG_PATH}/full_${BACKUP_DATE}.log;
    ) | /usr/sbin/sendmail -O NoRecipientAction=add-to -f${MAIL_FROM} ${MAIL_TO}
    fi
 
 
    #cd $FULLBACKUP_PATH
 
    #ls -t | tail -n +$BACKUP_KEEP_DAY | xargs rm -rf
    find ${FULLBACKUP_PATH}  -mtime +$BACKUP_KEEP_DAY -name "*" -exec rm -rf {} \;
}
 
mysql_incr_backup()
{
 
  #在备份目录上查找目录，并显示目录深度最大和最小为1级，并且格式化输出只显示目录名不显示目录父路径，最终进行反向排序并输出第一行
  LATEST_FULL_BACKUP=`find $FULLBACKUP_PATH -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`
 
  #获取转换为纪元以来的秒数
  LATEST_FULL_BACKUP_TIME=`stat -c %Y $FULLBACKUP_PATH/$LATEST_FULL_BACKUP`
 
  if [ $LATEST_FULL_BACKUP ];then
        #不是第一次增量备份，以最新的增量备份目录为base_dir
        xtra_backup $INCRBACKUP_PATH  $FULLBACKUP_PATH/`lastest_fullback_dir $FULLBACKUP_PATH`  $BACKUP_LOG_PATH/incr_$BACKUP_DATE.log
  else
        # the first incremental backup need do full backup first
        xtra_backup $FULLBACKUP_PATH  $BACKUP_LOG_PATH/full_$BACKUP_DATE.log
 
        if [ "${PIPESTATUS[0]}" -ne 0 ]; then
                        (echo "Subject: MySQL Backup Failed: MySQL Backup failed on `hostname`";
                   cat ${BACKUP_LOG_PATH}/incr_${BACKUP_DATE}.log;
                    ) | /usr/sbin/sendmail -O NoRecipientAction=add-to -f${MAIL_FROM} ${MAIL_TO}
        fi
  fi
 
  #cd ${INCRBACKUP_PATH}
  #ls -t | tail -n +$BACKUP_KEEP_DAY | xargs rm -rf
  find ${INCRBACKUP_PATH}  -mtime +$BACKUP_KEEP_DAY -name "*" -exec rm -rf {} \;
 
}
 
 
 
case $1 in
 
        full)
          mysql_backup_check
          mysql_full_backup
          ;;
 
        incr)
          mysql_backup_check
          mysql_incr_backup
          ;;
 
        *)
          echo "Usage: $0 full | incr"
          ;;
esac
