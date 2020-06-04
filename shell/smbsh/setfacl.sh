#!/bin/bash
for acl in Department Finance GoodsCenter HR Info International Market NewDerelop OperationCenter Risk
do 
	setfacl -d -m g:$acl:rwx $acl
	chmod 2774 $acl
done
