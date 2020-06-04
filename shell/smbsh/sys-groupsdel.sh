#!bin/bash


for group in `cat /Share/mysh/sys-groupsinfo`
do 
	groupdel $group
done

chmod 700 /Share/mysh/sys-groupsdel.sh 
