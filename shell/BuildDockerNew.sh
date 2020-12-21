#!/bin/sh
#describe: .net core build docker and push private registory
#author: TerryTang
#datetime: 2020-07-16-10:17

#init variables
JobName=${JOB_NAME}
ProjectName=${PublishEnvironment}
MirrorName=${JOB_NAME}
TagName="v"$(date +"%y%m%d%H%M")
Username='jenkins'
Password='Homsom+4006'
Repository='192.168.13.235:8000'
shelldir="/shell"
DateFile="${shelldir}/.date"
CurrentDate=$(date +"%d")

#init Date Parameter,use whether delete clear_docker
group=`ls -l -d /shell | awk '{print $4}'`
[ ${group} == 'jenkins' ] || (sudo /usr/bin/chown -R root:jenkins ${shelldir}; sudo /usr/bin/chmod -R 770 ${shelldir})
[ -f ${DateFile} ] || (sudo /usr/bin/touch ${DateFile}; sudo /usr/bin/chown jenkins:jenkins ${DateFile}; sudo /usr/bin/chmod 770 ${DateFile})
[ -z ${DateFile} ] && echo $(date +"%d") > ${DateFile}
Date=$(cat ${DateFile})

if [[ ${PublishEnvironment} == 'pro' ]] && [[ ${PublishPassword}  != 'homsom+4006123123' ]]; then
	echo "ERROR: PublishPassword wrong" 
	exit 6
fi

#clear docker container and image cache
clear_docker(){
	#delete docker container is Exited.
	echo "delete docker container is Exited.------------------------------"
	Exited_Containers=$(sudo docker ps -a | grep -v CONTAINER | grep 'Exited' |  awk '{print $1}')
	for i in ${Exited_Containers};do
		echo "Delete Exited Container $i ........."
		sudo docker rm $i 
		if [ $? == 0 ];then
			echo "INFO: Exited Status Container ${i} Delete Succeed" 
		else
			echo "ERROR: Exited Status Container ${i} Delete Failure" 
		fi
	done
	
	#delete local name is <none> image
	echo "delete local name is <none> image---------------------------"
	NoNameImage=$(sudo docker image ls | grep '<none>' | awk '{print $3}') #if not delete name is <none> image,annotation can be. 
	for i in ${NoNameImage};do
		echo "delete local not name image $i ........."
		sudo docker image rm $i 
		if [ $? == 0 ];then
			echo "INFO: Local not name Image ${i} Delete Succeed" 
		else
			echo "ERROR: Local not name Image ${i} Delete Failure" 
		fi
	done
}

#change to workspace
cd /var/lib/jenkins/workspace/${JobName}

#build docker image
echo "build docker image---------------------------------"
echo "build image ${ProjectName}/${MirrorName}:${TagName}........"
sudo docker build -t ${ProjectName}/${MirrorName}:${TagName} . 
if [ $? == 0 ];then
	echo "INFO: Docker Build Image Succeed" 
else
	echo "ERROR: Docker Build Image Failure" 
	clear_docker
	exit 6
fi

#login private repository
echo "login private repository-----------------------------"
echo "login ${Repository}........."
sudo docker login -u ${Username} -p ${Password} ${Repository} 
if [ $? == 0 ];then
	echo "INFO: Login Succeed"
else
	echo "ERROR: Login Failure"
	exit 6
fi

#tag image 
echo "tag image---------------------------------"
echo "tag image ${ProjectName}/${MirrorName}:${TagName} to ${Repository}/${ProjectName}/${MirrorName}:${TagName}........"
sudo docker tag ${ProjectName}/${MirrorName}:${TagName} ${Repository}/${ProjectName}/${MirrorName}:${TagName} 
if [ $? == 0 ];then
	echo "INFO: Tag Image Succeed" 
else
	echo "ERROR: Tag Image Failure" 
	exit 6
fi

#push local image to remote repository
echo "push local image to remote repository----------------------------"
echo "push local image ${Repository}/${ProjectName}/${MirrorName}:${TagName} to remote repository ${Repository}......."
sudo docker push ${Repository}/${ProjectName}/${MirrorName}:${TagName} 
if [ $? == 0 ];then
	echo "INFO: Push ${Repository}/${ProjectName}/${MirrorName}:${TagName} Image To Remote Repository Succeed" 
else
	echo "ERROR: Push ${Repository}/${ProjectName}/${MirrorName}:${TagName} Image To Romote Repository Failure" 
	exit 6
fi

#logout private repository
echo "logout ${Repository}-------------------------------"
sudo docker logout ${Repository} 
if [ $? == 0 ];then
	echo "INFO: Logout Succeed" 
else
	echo "ERROR: Logout Failure" 
	exit 6
fi


#delete local build and push image
echo "delete local build and push image------------------------------"
echo "delete local image ${ProjectName}/${MirrorName}:${TagName} and ${Repository}/${ProjectName}/${MirrorName}:${TagName}........"
sudo docker image rm ${ProjectName}/${MirrorName}:${TagName} ${Repository}/${ProjectName}/${MirrorName}:${TagName} 
if [ $? == 0 ];then
	echo "INFO: Local Image ${ProjectName}/${MirrorName}:${TagName} ${Repository}/${ProjectName}/${MirrorName}:${TagName} Delete Succeed" 
else
	echo "ERROR: Local Image ${ProjectName}/${MirrorName}:${TagName} ${Repository}/${ProjectName}/${MirrorName}:${TagName} Delete Failure" 
	exit 6
fi

#call clear_docker function	
if [[ ${CurrentDate} != ${Date} ]];then
	clear_docker
	#insert new date
	echo $(date +"%d") > ${DateFile}
fi
