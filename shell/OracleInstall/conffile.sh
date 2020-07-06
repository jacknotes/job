#!/bin/sh
#
CURRENT_DIR=$(/bin/pwd)
LOGFILE=${CURRENT_DIR}/log.txt
CURRENT_TIME='/usr/bin/date +"%Y-%m-%d-%T"'

echo '--------------' >> ${LOGFILE}
/usr/bin/echo $(${CURRENT_TIME}) >> ${LOGFILE};

#/etc/sysctl.conf configure
/usr/bin/cat >> /etc/sysctl.conf << EOF

fs.file-max = 6815744
fs.aio-max-nr = 1048576
kernel.shmall = 2097152
kernel.shmmax = 2147483648
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 4194304
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF

#/etc/security/limits.conf configure
[ $? == 0 ] && /usr/bin/cat >> /etc/security/limits.conf << EOF

oracle           soft    nproc           2047
oracle           hard    nproc           16384
oracle           soft    nofile          1024
oracle           hard    nofile          65536
oracle           soft    stack           10240
EOF

#/etc/pam.d/login configure
[ $? == 0 ] && /usr/bin/cat >> /etc/pam.d/login << EOF

session required /lib64/security/pam_limits.so
session required pam_limits.so
EOF


#/etc/profile.d/oracle.sh configure
[ $? == 0 ] && /usr/bin/cat >> /etc/profile.d/oracle.sh << EOF
if [ $USER = "oracle" ]; then
	if [ $SHELL = "/bin/ksh" ]; then
		ulimit -p 16384
		ulimit -n 65536
	else
		ulimit -u 16384 -n 65536
	fi
fi
EOF

[ $? == 0 ] && echo "oracle in linux system optimize file config succeesful" >> ${LOGFILE} || echo "oracle in linux system optimize file config failure" >> ${LOGFILE}
echo '--------------' >> ${LOGFILE}
/bin/grep 'oracle in linux system optimize file config succeesful' ${LOGFILE} &> /dev/null || exit 1

