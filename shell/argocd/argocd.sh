#!/bin/sh
# description: argocd rollback
# date: 202207151410
# author: jackli

ARGOCD_SERVER_ADDRESS=argocd.k8s.hs.com

list(){
	# list application have date label 
	kubectl get application --show-labels -A -l date
}

login(){
	argocd login ${ARGOCD_SERVER_ADDRESS} --grpc-web --insecure
}

sync_off(){
	for i in `argocd app list -l $1 | awk 'NR>1{print $1}'`;do
		argocd app set $i --sync-policy none --grpc-web --insecure
	done	
}

argocd_rollback(){
	for i in `argocd app list -l $1 | awk 'NR>1{print $1}'`;do
		argocd app rollback $i --prune --grpc-web --insecure
	done
}

sync_on(){
	for i in `argocd app list -l $1 | awk 'NR>1{print $1}'`;do
		argocd app set $i --sync-policy auto --auto-prune --self-heal --sync-option Validate=false --sync-option CreateNamespace=true --sync-option PrunePropagationPolicy=foreground --sync-option PruneLast=true --sync-retry-limit 5 --sync-retry-backoff-duration 5s --sync-retry-backoff-factor 2 --sync-retry-backoff-max-duration 3m --grpc-web --insecure
	done
}

case "$1" in
	list)
		$1;;
	login)
		$1;;
	sync_off)
		if [ "$#" -lt 2 ];then 
			echo 'args must is 2'
			exit 10
		else
			$1 $2
		fi
		;;
	argocd_rollback)
		if [ "$#" -lt 2 ];then 
			echo 'args must is 2'
			exit 10
		else
			$1 $2
		fi
		;;
	sync_on)
		if [ "$#" -lt 2 ];then 
			echo 'args must is 2'
			exit 10
		else
			$1 $2
		fi
		;;
	*)
		echo "Usage: $0 { list | login | sync_off LABEL | argocd_rollback LABEL | sync_on LABEL }"
		exit 10
esac
