#!/bin/bash
# description: argocd onekey deploy and rollback.
# date: 202301121333
# author: jackli

AUTH_PASSWORD='homsom.com'
# rollback() and full_online() use
ARGO_ROLLOUT_PROJECT_NAME=(`kubectl argo rollouts list rollout -A | awk -F ' ' '{if($4=="Paused" && $5=="3/5") print $1,$2}'`)
let group_number=${#ARGO_ROLLOUT_PROJECT_NAME[*]}/2
# online() use
ARGO_ROLLOUT_PROJECT_NAME_FOR_ONLINE=(`kubectl argo rollouts list rollout -A | awk -F ' ' '{if($4=="Paused" && $5=="1/5") print $1,$2}'`)
let group_number_for_online=${#ARGO_ROLLOUT_PROJECT_NAME_FOR_ONLINE[*]}/2

auth(){
	read -s -t 30 -n 16 -p 'please input password:' CMD_PASSWORD
	if [ "${CMD_PASSWORD}" != "${AUTH_PASSWORD}" ];then
		echo -e '\n[ERROR]: password error!'
		exit 10
	else
		echo -e '\n'
	fi
}

list(){
	# list paused application
	echo '[INFO]: paused application list'
	kubectl argo rollouts list rollout -A | awk 'NR==1{print $0} {if($4=="Paused") print $0}'
}

online(){
	echo '[INFO]: application online'
	auth
	if [ $? == 0 ];then
		for i in `seq 1 ${group_number_for_online}`;do
			let sub_group1=${i}*2-2
			let sub_group2=${i}*2-1
			# promote application
			kubectl argo rollouts promote ${ARGO_ROLLOUT_PROJECT_NAME_FOR_ONLINE[${sub_group2}]} -n ${ARGO_ROLLOUT_PROJECT_NAME_FOR_ONLINE[${sub_group1}]}
		done
	fi
}

rollback(){
	echo '[INFO]: application rollback'
	auth
	if [ $? == 0 ];then
		for i in `seq 1 ${group_number}`;do
			let sub_group1=${i}*2-2
			let sub_group2=${i}*2-1
			# rollback application
			kubectl argo rollouts undo ${ARGO_ROLLOUT_PROJECT_NAME[${sub_group2}]} -n ${ARGO_ROLLOUT_PROJECT_NAME[${sub_group1}]}
		done
	fi
}

full_online(){
	echo '[INFO]: application full_online'
	auth
	if [ $? == 0 ];then
		DATETIME=`date +'%Y%m%d%H%M%S'`
		for i in `seq 1 ${group_number}`;do
			let sub_group1=${i}*2-2
			let sub_group2=${i}*2-1
 			# label application full online time
			#kubectl label application -n argocd ${ARGO_ROLLOUT_PROJECT_NAME[${sub_group2}]%-rollout} date- &> /dev/null && kubectl label application -n argocd ${ARGO_ROLLOUT_PROJECT_NAME[${sub_group2}]%-rollout} date=${DATETIME} &> /dev/null
			# promote full application
			kubectl argo rollouts promote --full ${ARGO_ROLLOUT_PROJECT_NAME[${sub_group2}]} -n ${ARGO_ROLLOUT_PROJECT_NAME[${sub_group1}]}
		done
	fi
}

case "$1" in
	list)
		$1;;
	online)
		$1;;
	rollback)
		$1;;
	full_online)
		$1;;
	*)    
      		echo "Usage: $0 { list | online | rollback | full_online }" 
        	exit 2 
esac
