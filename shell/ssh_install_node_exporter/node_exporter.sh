#!/bin/sh
#description: batch install node_exporter to linux server.
#date:2020-08-28
#author: jack

#create system user
GROUP_NAME=prometheus
GROUP_GID=9090
USER_NAME=prometheus
USER_UID=9090
groupadd -g ${GROUP_GID} ${GROUP_NAME}
useradd -g ${GROUP_GID} -u ${USER_UID} -M -s /sbin/nologin ${USER_NAME}

#make target private file
cat > ~/.id_rsa << EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAuJ0UwYmrFAkp5HqiJeSorhPr6J93OqRV9JPFoSgkGVnQxRVh
1J8QsujTQ/Jsn4z21cLj+srQN+gtgQnr44ZQSBRPgVAlRN/NgZ8QrdkOGDgSgj+8
4BGNGRvhp1slMteI/Xy/qmGP8swQmM9Chv6VHkRwXUwF9MMBG/g6oORr0Jj8GyGM
0/06cmY1USnrXz2q17sEO9DZTEvob9z+tB6NflzfO/ms4Fo1di9BYJsz/kXDDh9w
V8WnVJ3LqaPL7vdhzipG+Vqj1//dQG8/D2MQ0BgI1xkfDVz8yKatAyChVmZcPzjC
2uPEWhMyVSLOoMFlxGg6PAF8cj9isj3gHFdFlQIDAQABAoIBAGcyF1ogNGtcu/gl
vOHlsYytQh+klCdJmWq/96cgIx2woQyp6SfLSrBXiVDgAGwnhgrziDC2kjHOLTGG
dD+Y4uOHxvGH9W1MlTmxyscDH+fV4DLCoje2V+MDPN4qCt8isEbSJul849Ra0aQ5
pvyC7qQeqZjdWC77mnEiDtPFG6dcCbuf08c85RkipYSfmpnbMqRFqC9KEdyr5LhR
C2UzerNmBwL4u81o/WqytRRiHU2g7pY/rfhAhtX8DuT9SRMwDrMBNKE+srmKgslr
P7rL2tvz5UxgREJjgDvfaGNLhZY9EWQN/989/4/l4dq21jpP2X43eyf4l43uwP6j
cRxiOsECgYEA4vUlD1omHS2R0eAsYJGBjIztKbt3Aqq6XQx4XAfBxXzW9uyyH3VT
7DBLh6hETKHLk7jfX+U88wfLhihrbXPIQxgKS/uVR3GQvtpVFCx8igh66VQ+DsCC
/idNfi62x87F4fTHUsmbGIrllJm73qwcP+J+Qi3OlyES0HOz9u+Yr2kCgYEA0DzM
X+i4zD/QYv/N4AwucHKFpl0r3O3dnt6UekRGwXHtezu6jmU4DJ50hPBRv69XAW1i
lWqXlMteXJYAWjqpm3DKS6wOtSkcwV/eXqrb+hkIfh0Ha1mOtxAnPpqUwAoBVabQ
uiyNWBC3SEcvpC7pL1gE4JfrwsO4T8rQS9G5C00CgYBMkWPlYAaHxX3yjmyqT6yj
HFBOyf4Gmk6xYamhcsR+ufVT7NrTHiQoBMsWg0A3kkY6Gh7SHWaIn1Kcejpz/KHN
cOjYZZIhPkEVAle9rJx/fQjqew9MrsoCsIPGVEA5/Jpp9sjgNz/p8cIudgcZwnrt
Wp45+XY/KltMlBxc7MxYMQKBgQCVw4RBXkC6NRMMgGlyv5AOs27Hza6kQDbp8a7b
mItCyUtBHB36F3YOLVAj5CsHL3XlwuPqDjVigDknYYJzYkllT+NONTqGtEDIGsj1
UPDQmHxxJzOU014+7tEqx0ZAL3HyRf1MSIqHUc5fn0L2U/7FXAp19Q1MkDLYwEa6
oOTy6QKBgAnq6Zs9CKq3CyDk3otkWq0VQzv6oo3Lg8pXG0pFke9Km1cQdTKPPiDx
y/JWphfG26rncK4tZOWSBZ8OXMeGpGwX4PtUSbkmNDJ738QATNSL+ejPv7wW0YKP
PwPcYU7TuUkCV/gu5DnnoY3ppyUMnJMId8rQ1zU3/tY2c3cxH8VI
-----END RSA PRIVATE KEY-----
EOF
chmod 0600 ~/.id_rsa

#install node_exporter software
scp -o StrictHostKeyChecking=no -P 22 -i ~/.id_rsa jack@172.168.2.222:/home/jack/node_exporter-1.0.1.linux-amd64.tar.gz .
tar xf ~/node_exporter-1.0.1.linux-amd64.tar.gz  -C /usr/local/
chown -R ${GROUP_NAME}:${GROUP_NAME} /usr/local/node_exporter-1.0.1.linux-amd64/
ln -s /usr/local/node_exporter-1.0.1.linux-amd64/ /usr/local/node_exporter

#if [ `cat /etc/redhat-release | awk '{print $3}' | awk -F. '{print $1}'` == '6' -o `cat /etc/redhat-release | awk '{print $4}' | awk -F. '{print $1}'` == '6' ];then
if [ `cat /etc/redhat-release | awk '{print $4}' | awk -F. '{print $1}'` == '7' ];then
# make centos7 starting up
cat > /usr/lib/systemd/system/node_exporter.service << EOF
[Unit]
Description=https://prometheus.io
After=network-online.target

[Service]
User=${GROUP_NAME}
Group=${GROUP_NAME}
Type=simple
ExecStart=/usr/local/node_exporter/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
# start node_exporter and enable starting up
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

#elif [ `cat /etc/redhat-release | awk '{print $3}' | awk -F. '{print $1}'` == '6' -o `cat /etc/redhat-release | awk '{print $4}' | awk -F. '{print $1}'` == '6' ];then
elif [ `cat /etc/redhat-release | awk '{print $3}' | awk -F. '{print $1}'` == '6' ];then
# make centos6 starting up
nohup /usr/local/node_exporter/node_exporter >& /dev/null &
RESULT=`grep 'node_exporter' /etc/rc.d/rc.local >& /dev/null && echo 0 || echo 1`
if [ ${RESULT} -ne 0 ];then
	echo 'nohup /usr/local/node_exporter/node_exporter >& /dev/null &' >> /etc/rc.d/rc.local
fi
chmod +x /etc/rc.d/rc.local
fi
