lang en_US
keyboard us
timezone Asia/Shanghai
rootpw --iscrypted $default_password_crypted
text
install
url --url=$tree
bootloader --location=mbr
zerombr
clearpart --all --initlabel
part /boot --fstype xfs --size 1024 --ondisk sda
part / --fstype xfs --size 1 --grow --ondisk sda
auth --useshadow --enablemd5
$SNIPPET('network_config')
reboot
firewall --disabled
selinux --disabled
skipx
%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
$SNIPPET('pre_anamon')
%end

%packages
@base
@core
tree
sysstat
iptraf
ntp
lrzsz
ncurses-devel
openssl-devel
zlib-devel
OpenIPMI-tools
mysql
nmap
screen
tree
gcc 
glibc
gcc-c++
pcre-devel
openssl-devel
net-tools
%end
%post
systemctl disable postfix.service
rm -f /etc/yum.repos.d/*

cat >>/etc/yum.repos.d/salt-py3-2019.2.repo<<eof 
[salt-py3-2019.2]
name=SaltStack 2019.2 Release Channel for Python 3 RHEL/Centos
baseurl=https://repo.saltstack.com/py3/redhat/7/x86_64/2019.2
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/saltstack-signing-key, file:///etc/pki/rpm-gpg/centos7-signing-key
eof

cat >> /tmp/.init.sh <<eof
#!/bin/sh
yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
yum install -y salt-minion
echo 'master: 192.168.15.199' > /etc/salt/minion
systemctl start salt-minion
systemctl enable salt-minion
sed -i 's@/tmp/.init.sh@@' /etc/rc.local
sed -i 's@/tmp/.init.sh@@' /etc/rc.d/rc.local
eof

chmod 777 /tmp/.init.sh
echo /tmp/.init.sh >> /etc/rc.local
chmod a+x /etc/rc.local

$yum_config_stanza
%end
