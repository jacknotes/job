#!/bin/bash
#Destination Host Ip
IP="
172.168.2.22
172.168.2.23
172.168.2.26
"
for node in ${IP};do
        sshpass -p homsom ssh-copy-id ${node} -o StrictHostKeyChecking=no
        if [ $? -eq 0 ];then
                echo "${node} secret copy successful."
        else
                echo "${node} secret copy failed."
        fi
done
