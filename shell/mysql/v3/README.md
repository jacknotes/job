# Manual
<pre>
mysqldump备份数据恢复流程:
1.先对所有需要恢复的数据库进行master文件和position截取并记录到文件
2.对记录的文件进行比对master文件和position位置，如果master文件和position位置一样，则为同一批恢复数据组。不同批为单独组。
3.判断给定的增量数据目录中除开本身binlog文件外并且大于本身binlog索引的binlog是否存在，如果存在则记录绝对文件名到通用恢复的增量文件中，用作最后通用binlog文件回放。
用法：
1.先对给定的全量和增量两个目录进行binlog转换
2.恢复时使用restore和给定的全量和增量目录进行恢复。恢复先会对数据库进行分组，然后进行全量恢复，自定义增量恢复，然后进行数据库重命名，依照如此完成多批次的全量和增量恢复，最后判断是否有通用的增量数据，如果有则先把之前重命名数据库的名称重命名回去，然后回放通用增量数据文件，最后在进行数据库重命名。如果没有则忽略通用数据恢复步骤。

ALERT: 
1. mysql backup(full,increment) shell require follow mysql restore shell match use.
2. restore database data file.


Usage:
1. Privileges: mysql cli client or third party client apply privileges
grant select,lock tables,replication client,show view,trigger,reload,execute,super,process on *.* to dbbackup@'localhost';
[root@salt ~]# openssl rand -base64 5
hZH3oCw=
alter user dbbackup@'localhost' identified by "hZH3oCw=";
flush privileges;

2. crontab backup: mysql backup in /etc/crontab
"*/5 * * * * mysql_restore.sh"

Usage: { ./mysql_restore.sh { [ drop | generator ] datadir } | { rename source_database target_database } | { [ convert | restore ] full_backup_directory increment_backup_directory } }
Eexample: ./resotre_fullDB.sh rename db01 db01_backup
Eexample: ./resotre_fullDB.sh drop /tmp/mysql-restore/Pro_Full_20210509_010002
Eexample: ./resotre_fullDB.sh generator /tmp/mysql-restore/Pro_Full_20210509_010002
Eexample: ./resotre_fullDB.sh convert /tmp/mysql-restore/Pro_Full_20210509_010002 /tmp/mysql-restore/Pro_Increment_20210509_030001
Eexample: ./resotre_fullDB.sh restore /tmp/mysql-restore/Pro_Full_20210509_010002 /tmp/mysql-restore/Pro_Increment_20210509_030001

</pre>

