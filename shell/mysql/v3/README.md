# Manual
<pre>
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
