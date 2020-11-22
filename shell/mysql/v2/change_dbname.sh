#!/bin/bash
SDB="'jack'"
DDB=jack123
USER=root
PASSWORD=homsom
SQL="select table_name from information_schema.TABLES where TABLE_SCHEMA=${SDB}"

mysql -u${USER} -p${PASSWORD} -e "create database if not exists ${DDB}"
list_table=$(mysql -u${USER} -p${PASSWORD} -Nse "${SQL}")

for table in $list_table
do
    mysql -u${USER} -p${PASSWORD} -e "rename table `echo ${SDB} | sed s"/'//"g`.$table to ${DDB}.$table"
done
