#!/bin/sh
#
#install cobbler
## remove: yum remove -y httpd dhcp tftp cobbler cobbler-web pykickstart xinetd

ip=192.168.15.199
echo "1.安装启动"
yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
yum install -y httpd dhcp tftp cobbler cobbler-web pykickstart xinetd 
systemctl start httpd
systemctl start cobblerd
systemctl enable httpd
systemctl enable cobblerd
echo "2.cobbler check"
cobbler check
echo "3.修改cobbler配置"
sed -i "s/next_server: 127.0.0.1/next_server: ${ip}/g" /etc/cobbler/settings   #ip地址一定要跟当前服务器一样，否则cobbler命令会用不了，会报错
sed -i "s/server: 127.0.0.1/server: ${ip}/g" /etc/cobbler/settings
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings
sed -i '/disable/{s/yes/no/;}' /etc/xinetd.d/tftp
echo "4.获取cobbler引导文件#运行获取cobbler所需的文件"
cobbler get-loaders 
echo "5.启动tftp and rsyncd"
systemctl start xinetd
systemctl enable xinetd
systemctl start rsyncd
systemctl enable rsyncd
echo "6.set root of password"
passwd=$(openssl passwd -1 -salt 'cobbler' 'cobbler888')
str1='default_password_crypted: "'
str2=\"
full_passwd=${str1}${passwd}${str2}
sed -i '/default_password_crypted/{d}' /etc/cobbler/settings  #先删除默认密码
echo ${full_passwd} >> /etc/cobbler/settings  #再添加系统密码
echo "7.更改dhcp模板"
sed -i '/subnet 192/{s/192.168.1.0/192.168.15.0/}' /etc/cobbler/dhcp.template
sed -i '/option routers/{s/192.168.1.5/192.168.15.1/}' /etc/cobbler/dhcp.template
sed -i '/option domain-name-servers/{s/192.168.1.1/8.8.8.8/}' /etc/cobbler/dhcp.template
sed -i '/option subnet-mask/{s/255.255.0.0/255.255.255.0/}' /etc/cobbler/dhcp.template
sed -i '/range dynamic-bootp/{s/192.168.1.100/192.168.15.50/;s/192.168.1.254/192.168.15.90/}' /etc/cobbler/dhcp.template
sleep 1
echo "8.重载cobbler配置并启动dhcp"
systemctl restart cobblerd   #在cobbler同步之前重新启动下cobbler服务，重载下配置，使其生效
sleep 1
cobbler sync   #这一步很重要，不同步可能导致dhcpd服务启动不起来，就是从cobbler同步dhcp配置到dhcpd服务中去
sleep 1
systemctl start dhcpd
systemctl enable dhcpd


#剩余步骤手工处理：导入镜像
#cobbler import --path=/mnt/ --name=CentOS-7-x86_64 --arch=x86_64
#导入后的镜像路径在/var/www/cobbler/ks_mirror/下,/mnt/路径是已经挂载的系统镜像，必需要挂载才能读)
#cobbler profile report name=CentOS-7-x86_64,查看配置信息
#指定kickstart文件：cobbler profile edit --name=CentOS-7-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.ks (作用是指定CentOS7系统镜像的kickstart文件配置，事先要导入到这个默认位置，下面有配置)
#cobbler profile edit --name=CentOS-7-x86_64 --kopts='net.ifnames=0 biosdevname=0'  使自动化安装Centos7更改linux内核参数，使网卡名称为eth0、eth1
#cobbler sync  同步更改后的配置
#新购买服务器得知MAC地址后接入装机vlan后自动化安装并设置网络、主机名信息：
#[root@node1 kickstarts]# cobbler system add --name=node2 --mac=00:50:56:3A:D3:03 --profile=CentOS-7-x86_64 --ip-address=192.168.15.201 --subnet=255.255.255.0 --gateway=192.168.15.1 --interface=eth0 --name-servers=8.8.8.8 --static=1 --hostname=node2 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.ks
#[root@localhost kickstarts]# cobbler system add --name=node3 --mac=00:50:56:39:96:7D --profile=CentOS-7-x86_64 --ip-address=192.168.15.202 --subnet=255.255.255.0 --gateway=192.168.15.1 --interface=eth0 --name-servers=8.8.8.8 --static=1 --hostname=node3 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.ks
