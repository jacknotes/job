#!/bin/sh

BACKUP_DIRECTORY="/data/backup/"
MYSQLBACKUP_LOG_FILE="${BACKUP_DIRECTORY}/mysql_backup.log"

grep -A 1000 "BACKUP DATETIME: `date +'%Y%m%d'`" ${MYSQLBACKUP_LOG_FILE} | mail -s "mysql backup status" jack.li@homsom.com

