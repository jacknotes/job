#!/bin/sh

start(){
	brctl addbr docker_jack0 
	ip address add 172.20.0.1/24 dev docker_jack0
	ip link set dev docker_jack0 up
}

stop(){
	ip link set dev docker_jack0 down
	brctl delbr docker_jack0
}

case "$1" in 
	start)
	$1;;

	stop)
	$1;;

	*)
	echo "Usage: $0 {start | stop}"
esac

