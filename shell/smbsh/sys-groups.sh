#!bin/bash


for group in `cat /Share/mysh/sys-groupsinfo`
do 
	groupadd $group
done

chmod 700 /Share/mysh/sys-groups.sh 
