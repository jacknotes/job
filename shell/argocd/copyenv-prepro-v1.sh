#!/bin/bash


PRO_CLUSTER='https://kubernetes.default.svc'
PREPRO_CLUSTER='https://192.168.13.90:6443'

branch_copy(){
	git pull origin pro && git checkout -b prepro
	if [ $? != 0 ];then
		echo "[ERROR] branch_copy"
		exit 10
	fi
}

replace(){
	sed -i -e "s/name\:\ pro/name\:\ prepro/g" -e "s@${PRO_CLUSTER}@${PREPRO_CLUSTER}@g" -e  's/project\:\ homsom/project\:\ prepro-homsom/g' -e 's/targetRevision\:\ pro/targetRevision\:\ prepro/g' rollout-application.yaml && sed -i 's/192.168.13.31/192.168.13.90/g' README.md  && sed -i -e 's/maxReplicas.*/maxReplicas: 1/g' -e 's/minReplicas.*/minReplicas: 1/g' -e 's/averageUtilization.*/averageUtilization: 200/g' deploy/04-hpa.yaml && sed -i -e 's/initialDelaySeconds:.*/initialDelaySeconds: 40/g' -e 's/replicas:.*/#replicas: 2/g' deploy/01-rollout.yaml
	if [ $? != 0 ];then
		echo "[ERROR] replace"
		exit 10
	fi
}

apply(){
	git add -A && git commit -m "update" && git push origin prepro && kubectl apply -f rollout-application.yaml
	if [ $? != 0 ];then
                echo "[ERROR] apply"
                exit 10
        fi
	git branch -a
}

main(){
	branch_copy
	replace
	apply
}

main
