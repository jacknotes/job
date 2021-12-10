<pre>
一．  安装
参考链接：http://www.cnblogs.com/kerrycode/p/6933024.html
#下载对应软件包
cd /usr/local/src/
wget https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.9/binary/tarball/percona-xtrabackup-2.4.9-Linux-x86_64.tar.gz 

#解压并重命名
tar -zxvf percona-xtrabackup-2.4.9-Linux-x86_64.tar.gz -C /usr/local
cd .. &&  mv percona-xtrabackup-2.4.9-Linux-x86_64/   xtrabackup

#设置环境变量并生效
echo "export PATH=\$PATH:/usr/local/xtrabackup/bin" >> /etc/profile
source /etc/profile

二．使用说明
参考链接：https://www.cnblogs.com/zhoujinyi/p/5893333.html

三．自动化压缩备份脚本
./xtrabackup full | incr


</pre>