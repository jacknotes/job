#!bin/bash
users_info=`grep -v 'group1' /Share/testinfo`;
for user_line in $users_info
do
	echo $user_line
	group1=`echo $user_line | awk -F ':' '{print $1}'`
	group2=`echo $user_line | awk -F ':' '{print $2}'`
	user=`echo $user_line | awk -F ':' '{print $3}'`
	name=`echo $user_line | awk -F ':' '{print $4}'`
	for grp in $group1 ;do
		groupdel $grp
	done
userdel -rf $user
pdbedit -x $user
echo "$user:$name:$my_password:$group1:$group2:" >>/Share/mysh/test.txt
done
chmod 700 /Share/mysh/testdel.sh
	
