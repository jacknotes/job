#!/bin/sh
#author: jackli
#email: jacknotes@163.com

NODE_IP='
172.168.2.24
172.168.2.25
172.168.2.26
'
UPGRADE_PACKATE_DIR='/root/upgrade-kubernetes/kubernetes/server/bin'
K8S_EXECUTE_DIR='/usr/local/bin'


echo "[INFO]: start upgrade node"
cd ${UPGRADE_PACKATE_DIR}

for i in ${NODE_IP};do
	echo "[INFO]: start cordon and drain node ${i}"
	kubectl drain ${i} --force --ignore-daemonsets --delete-emptydir-data
	if [ $? == 0 ];then
		echo "[INFO]: stop kubelet.service kube-proxy.service"
		ansible ${i} -m shell -a 'systemctl stop kubelet.service kube-proxy.service'
		if [ $? == 0 ];then
			echo "[INFO]: scp kubelet kube-proxy to ${K8S_EXECUTE_DIR}, and restart kubelet.service kube-proxy.service"
			scp kubelet kube-proxy ${i}:${K8S_EXECUTE_DIR}/ && ansible ${i} -m shell -a "systemctl start kubelet.service kube-proxy.service"
			if [ $? == 0 ];then
				kubectl uncordon ${i}
			else	
				echo "[ERROR]: upgrade node ${i} is FAIL"
				exit 1
			fi
		else
			echo "[ERROR]: stop kubelet.service kube-proxy.service is FAIL"
			exit 1
		fi
	else
		echo "[ERROR]: cordon and drain node ${i} is FAIL"
		exit 1
	fi
done
echo "[INFO]: upgrade node successful"
