#!/bin/bash
for acl in Department Finance GoodsCenter HR Info International Market NewDerelop OperationCenter Risk
do 
	getfacl  $acl
done
