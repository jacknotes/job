#!bin/bash
users_info=`grep -v 'group1' /Share/mysh/testinfo`;
for user_line in $users_info
do
	echo $user_line
	group1=`echo $user_line | awk -F ':' '{print $1}'`
	group2=`echo $user_line | awk -F ':' '{print $2}'`
	user=`echo $user_line | awk -F ':' '{print $3}'`
	name=`echo $user_line | awk -F ':' '{print $4}'`
	for grp in $group1 ;do
		groupadd $grp
	done
my_password=`mkpasswd -l 10`
case $group2 in 
	"x")
		useradd -G $group1 -s /sbin/nologin -M $user
		;;
	*)
		
		useradd -G $group1,$group2 -s /sbin/nologin -M $user
		;;
esac

echo $my_password | passwd  $user --stdin
echo -e "$my_password\n$my_password" | pdbedit -t -a $user
echo "$user:$name:$my_password:$group1:$group2:" >>/Share/mysh/test.txt
done
chmod 700 /Share/mysh/test.sh
	
