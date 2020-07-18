#!/bin/sh
#
Repository="192.168.15.200:8888"
Project="k8s"
Kubernetes_domain="k8s.gcr.io"

#batch docker pull
function pull_k8s_FromAliyun(){
	kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v1.15.11 	
}

function untag_k8s_FromAliyun(){
	aliyun=(`docker image ls | grep aliyuncs | awk '{ sub(/\ +/,":"); print $1}' | sort`) #error point
	google=(`docker image ls | grep aliyuncs | awk '{ sub(/\ +/,":"); print $1}' | awk -F '/' '{print "k8s.gcr.io/"$3}' | sort`)
	let k8s_sum=${#aliyun[@]}-1
	for i in `seq 0 ${k8s_sum}`;do
		docker tag ${aliyun[$i]} ${google[$i]}
	done
	[ $? == 0 ] && echo "tag aliyun name to google name successful" || echo "tag aliyun to google failure"
}

#batch docker tag 
function tag_ToPriRegistry(){
	for i in `docker image ls  | grep registry | grep -v REPOSITORY | awk '{ sub(/\ +/,":"); print $1}' `;do docker tag $i ${Repository}/${Project}/${Kubernetes_domain}/`echo ${i} | awk -F '/' '{print $3}'`;done
}

#batch docker push
function push_ToPriRegistry(){
	for i in `docker image ls  | grep 192 | grep -v REPOSITORY | awk '{ sub(/\ +/,":"); print $1}'`;do docker push $i;done
}

function pull_FromPriRegistry(){
	docker pull 192.168.15.200:8888/k8s/k8s.gcr.io/coredns:1.3.1
	docker pull 192.168.15.200:8888/k8s/k8s.gcr.io/pause:3.1
	docker pull 192.168.15.200:8888/k8s/k8s.gcr.io/kube-scheduler:v1.15.11
	docker pull 192.168.15.200:8888/k8s/k8s.gcr.io/kube-proxy:v1.15.11
	docker pull 192.168.15.200:8888/k8s/k8s.gcr.io/kube-controller-manager:v1.15.11
	docker pull 192.168.15.200:8888/k8s/k8s.gcr.io/kube-apiserver:v1.15.11
	docker pull 192.168.15.200:8888/k8s/k8s.gcr.io/etcd:3.3.10
}

#batch docker untag
function untag_FromPriRegisty(){
	list1=(`docker image ls  | grep 192 | grep -v REPOSITORY | awk '{ sub(/\ +/,":"); print $1}' | sort`)
	list2=(`docker image ls  | grep 192 | grep -v REPOSITORY | awk '{ sub(/\ +/,":"); print $1}' | sort | sed 's#192.168.15.200\:8888\/k8s\/##g'`)
	let sum=${#list1[@]}-1
	for i in `seq 0 ${sum}`;do
		docker tag ${list1[$i]} ${list2[$i]}
	done
}

case $1 in
	pull_k8s_FromAliyun)
		pull_k8s_FromAliyun;;
	untag_k8s_FromAliyun)
		untag_k8s_FromAliyun;;
	tag_ToPriRegistry)
		tag_ToPriRegistry;;
	push_ToPriRegistry)
		push_ToPriRegistry;;
	pull_FromPriRegistry)
		pull_FromPriRegistry;;
	untag_fromPriRegisty)
		untag_FromPriRegisty;;
	*)
		echo "Usage: $0 (pull_k8s_FromAliyun | untag_k8s_FromAliyun | tag_ToPriRegistry | push_ToPriRegistry | pull_FromPriRegistry | untag_FromPriRegisty)"
esac
