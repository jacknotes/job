#!/bin/sh
USER='jack'
PASSWORD='jackli'

# add route 
ip route add 192.168.10.0/24 via 192.168.13.254
ip route add 172.168.2.0/24 via 192.168.13.254
ip route add 192.168.1.0/24 via 192.168.13.254
ip route add 192.168.3.0/24 via 192.168.13.254

/usr/bin/expect << EOF
set timeout 10
spawn /usr/sbin/openvpn --config /etc/openvpn/client/client.conf
expect {
"*Username*" { send "$USER\n"; exp_continue }
"*Password*" { send "$PASSWORD\n"; exp_continue }
}
expect eof
EOF


