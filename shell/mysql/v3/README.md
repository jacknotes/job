# Manual
ALERT: mysql backup(full,increment) shell require follow mysql restore shell match use.

Usage:

1. Privileges: mysql cli client or third party client apply privileges
grant select,lock tables,replication client,show view,trigger,reload,execute,super,process on *.* to dbbackup@'localhost';
[root@salt ~]# openssl rand -base64 5
hZH3oCw=
alter user dbbackup@'localhost' identified by "hZH3oCw=";
flush privileges;

2. crontab backup: mysql backup in /etc/crontab


3. restore backup method drop_db,generator_index_file,full_restore,increment_restore
in target directory, drop match database name of DB.
Example: ./resotre_fullDB.sh drop /tmp/mysql-restore/Pro_Full_20210509_010002

in target directory, generator restore time require info, match database name of binlog filename with binlog position.
./resotre_fullDB.sh generator /tmp/mysql-restore/Pro_Full_20210509_010002


in target directory, full restore match database name of DB.
./resotre_fullDB.sh full /tmp/mysql-restore/Pro_Full_20210509_010002

in target directory, increment restore match database name of DB. full and increment data can in the equal directory.
./resotre_fullDB.sh full /tmp/mysql-restore/Pro_Full_20210509_010002

