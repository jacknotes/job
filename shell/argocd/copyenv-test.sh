#!/bin/sh
# Author: JackLi
# DATE: 20230728
# Description: fat and uat gitops init shell

init_args(){
	# change current path
	PROJECT_HOME='/root/k8s/git/k8s-deploy/'
	DEST_LANGUATE="${1,,}"
	DEST_DOMAIN="${2,,}"
	DEST_HEALTH_PATH="${3,,}"
	DEST_DOMAIN_APPID="${4,,}"
	CLUSTER_FIRST_PORT=30000
	ARGOCD_CLUSTER='k8s-pro'
	TMP_DIR='/tmp/gittmp/'

	cd ${PROJECT_HOME} || exit 1

	if [ "$1" == 'java' ];then
		SRC_DOMAIN='vccApplication.service.hs.com'
		SRC_HEALTH_PATH='/k8s/health'
	elif [ "$1" == 'dotnet' ];then
		SRC_DOMAIN='tripapplicationform.api.hs.com'
		SRC_HEALTH_PATH='/index.html'
	elif [ "$1" == 'frontend' ];then
		SRC_DOMAIN='vccoperation.hs.com'
		SRC_HEALTH_PATH='/NO-PATH'
	else
		echo '[ERROR] args LANGUAGE not legal'
		exit 10
	fi
	if ! [ -n "`echo $4 | sed -n '/^[0-9][0-9][0-9][0-9]$/p'`" ];then
		echo '[ERROR] args APPID not legal'
		exit 10
	fi

	#echo '[SUCCESSFUL] OK'
	#exit 10

	# process env
	format_src_domain=$(echo "${SRC_DOMAIN}" | sed 's/\./\\\./g')
	format_src_name=$(echo ${DEST_LANGUATE}-`echo "${SRC_DOMAIN}" | sed 's/\./-/g'`)
	format_dst_name=$(echo ${DEST_LANGUATE}-`echo "${DEST_DOMAIN}" | sed 's/\./-/g'`)
	format_src_health_path=$(echo "${SRC_HEALTH_PATH}" | sed 's/\./\\\./g')
}


copy_template(){
	if [ -d "${format_dst_name}" ]; then
		cd ${format_dst_name} 
		if [ $? == 0 ];then 
			echo "[INFO] current Directory: ${PROJECT_HOME}${format_dst_name}" 
		else 
			echo '[ERROR] change dir failure'
			exit 10
		fi
		
		# delete old files
		git checkout -b test && \
		mkdir -p ${TMP_DIR} && \
		ls | xargs -I {} mv {} ${TMP_DIR} && \
		rm -rf ${TMP_DIR}
		if [ $? == 0 ];then
                        echo "[INFO] delete file for ${TMP_DIR} SUCCESSFUL" 
                else
                        echo "[ERROR] delete file for ${TMP_DIR} FAILURE"
                        exit 10
                fi
		
		# copy template files
		echo '[INFO] copy template file'
		for i in `ls ../init/testenv/${DEST_LANGUATE}`;do
			\cp -a ../init/testenv/${DEST_LANGUATE}/$i . || exit 10
		done
	else
		echo "[ERROR] project: ${PROJECT_HOME}${format_dst_name} PRO_ENV not create"
		exit 10
	fi
}


## replace_str function
# replace_str filename src_str dst_str
replace_str(){
	# I ignore-case
	sed -i "s@${2}@${3}@Ig" $1 
	if [ $? == 0 ];then
		echo "[INFO] replace $2 to $3 of file $1 success."
	else
		echo "[ERROR] replace $2 to $3 of file $1 fail."
	fi
}

## do replace
replace(){
	# format ENV
	# exclude .git dir
	rep_files=(`find . -maxdepth 3 -type f -exec echo {} \; | grep -v .git`)
	let files_num=${#rep_files[*]}-1
	rep_strs=("${format_src_domain}|${DEST_DOMAIN}" "${format_src_health_path}|${DEST_HEALTH_PATH}" "${format_src_name}|${format_dst_name}")
	let strs_num=${#rep_strs[*]}-1

	for i in `seq 0 ${files_num}`;do
		for j in `seq 0 ${strs_num}`;do
			src_str=$(echo "${rep_strs[$j]}" | awk -F'|' '{print $1}')
			dest_str=$(echo "${rep_strs[$j]}" | awk -F'|' '{print $2}')
			grep -i ${src_str} ${rep_files[$i]} &> /dev/null && \
			replace_str ${rep_files[$i]} ${src_str} ${dest_str}
		done
	done
}


replace_port(){
	let fat_port=${DEST_DOMAIN_APPID}*10+${CLUSTER_FIRST_PORT}
	let uat_port=${DEST_DOMAIN_APPID}*10+1+${CLUSTER_FIRST_PORT}
	
	rep_files_fat=`find . -maxdepth 3 -type f -exec echo {} \; | grep 'patch-service' | grep fat`
	rep_files_uat=`find . -maxdepth 3 -type f -exec echo {} \; | grep 'patch-service' | grep uat`
	
	sed -i "s@value: .*@value: ${fat_port}@g" ${rep_files_fat} && \
	sed -i "s@value: .*@value: ${uat_port}@g" ${rep_files_uat}
	if [ $? == 0 ];then
		echo "[INFO] fat_port: ${fat_port}	uat_port: ${uat_port}" 
	else
		echo "[ERROR] change service port FAILUE" 
	fi
}


push_repo(){
	# push to test branch
	git add -A && \
	git commit -m "init" && \
	git push origin test && \
	git branch -a
}

apply_rollout(){
	ezctl checkout ${ARGOCD_CLUSTER} && \
	kubectl apply -f rollout-project.yaml -f rollout-application-fat.yaml -f rollout-application-uat.yaml 
	if [ $? == 0 ];then
		echo "[INFO] apply argocd rollout SUCCESSFUL"
	else
		echo "[ERROR] apply argocd rollout FAILUE"
		exit 10
	fi
}

case $1 in
	replace)
		if ! [ "$#" -eq 5 ];then echo '[ERROR] args not equals 5'; exit 5; fi
		init_args $2 $3 $4 $5
		copy_template
		replace
		replace_port
		push_repo
		apply_rollout
		;;
    *)    
      	echo "Usage: $0 replace { java | dotnet | frontend } DEST_DOMAIN DEST_HEALTH_PATH DEST_DOMAIN_APPID" 
		echo "Example: [java] $0 replace java DFlightRFlightMaster.service.hs.com /doc.html 1344"
		echo "Example: [dotnet] $0 replace dotnet tripapplicationform.api.hs.com /index.html 1298"
		echo "Example: [frontend] $0 replace frontend vccoperation.hs.com /NO-PATH 1312"
        exit 1
		;;
esac

