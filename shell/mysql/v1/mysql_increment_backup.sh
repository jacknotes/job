#!/bin/bash
#describe: Shell Command For Backup MySQL Database Everyday Automatically By Crontab  
#type: increment backup
#author: jack
#date: 2020-08-20

export LANG=en_US.UTF-8
BakDir=/backup/mysql/binlogs
BinDir=/data/mysql
LogFile=/backup/mysql/binlog.log
BinFile=/data/mysql/mysql-binlog.index
user=root
host=localhost
password=jackli
#flush logs
mysqladmin -h ${host} -u${user} -p${password} flush-logs 2> /dev/null

Counter=`wc -l $BinFile |awk '{print $1}'`
NextNum=0

#这个for循环用于比对$Counter,$NextNum这两个值来确定文件是不是存在或最新的。
if [ ! -d ${BakDir} ];then
	mkdir -p ${BakDir}
fi

for file in `cat $BinFile`
do
    base=`basename $file`
    NextNum=`expr $NextNum + 1`
    if [ $NextNum -eq $Counter ];then
        echo $base skip! >> $LogFile
    else
        dest=$BakDir/$base
        if(test -e $dest);then
            echo $base exist! >> $LogFile
        else
            cp $BinDir/$base $BakDir
            echo $base copying >> $LogFile
        fi
    fi
done
echo `date +"%Y年%m月%d日 %H:%M:%S"` Backup success! >> $LogFile
