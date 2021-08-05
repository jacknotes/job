#!/bin/sh
#description: auto backup gitlab to local and remote directory
#versionForGitlab: 8.9.11,source code compile installed. 
#date: 20210729
#author: JackLi

gitlabHome='/home/git/gitlab'
localBackupDirectory='/data/backup'
remoteBackupDirectory='/windows/gitlab'
logFile=${localBackupDirectory}/gitlabBackup.log
dateFormat="date +'%Y-%m-%d %H:%M:%S'"
backupFileSubfix='gitlab_backup.tar'

# mkdir local backup directory.
mkdir -p ${localBackupDirectory} && (chown -R root.git ${localBackupDirectory} && chmod -R 775 ${localBackupDirectory} ) || (echo "`eval ${dateFormat}`: create directory ${localBackupDirectory} and config prvileges failure." | tee -a ${logFile}; exit 10)

#test remote directory
df -h | grep /windows >& /dev/null || (echo "`eval ${dateFormat}`: ${remoteBackupDirectory} directory not exists." >> ${logFile}; exit 10)

#backup gitlab
echo "`eval ${dateFormat}`: start bakcup gitlab to local ${localBackupDirectory}......." >> ${logFile}
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
if [ $? == 0 ];then
	echo "`eval ${dateFormat}`: bakcup gitlab to local ${localBackupDirectory} success." >> ${logFile}
	echo "`eval ${dateFormat}`: start bakcup gitlab to remote ${remoteBackupDirectory}......." >> ${logFile}
	backupFileName=`ls ${localBackupDirectory} | grep ${backupFileSubfix} | sort -r | head -n 1`
	\cp -a ${localBackupDirectory}/${backupFileName} ${remoteBackupDirectory}
	if [ $? == 0 ];then
		echo "`eval ${dateFormat}`: bakcup gitlab to remote ${remoteBackupDirectory} success." >> ${logFile}
		for i in `ls ${localBackupDirectory} | grep ${backupFileSubfix} | grep -v ${backupFileName}`;do
			sudo rm -rf ${localBackupDirectory}/${i} 
			[ $? == 0 ] && echo "`eval ${dateFormat}`: delete local ${localBackupDirectory}/${i} success." >> ${logFile} || echo "`eval ${dateFormat}`: delete local ${localBackupDirectory}/${i} failure." >> ${logFile}
		done
	else
		echo "`eval ${dateFormat}`: bakcup gitlab to remote ${remoteBackupDirectory} failure." >> ${logFile}
		exit 10
	fi
else
	echo "`eval ${dateFormat}`: bakcup gitlab to local ${localBackupDirectory} failure." >> ${logFile}
	exit 10
fi

#backup secret file
if ! [ -e "${remoteBackupDirectory}/.secret" ];then
	echo "`eval ${dateFormat}`: bakcup gitlab secret file to remote ${remoteBackupDirectory} ......." >> ${logFile}
	sudo \cp -a ${gitlabHome}/.secret ${remoteBackupDirectory}
	[ $? == 0 ] && echo "`eval ${dateFormat}`: bakcup gitlab secret file to remote ${remoteBackupDirectory} success." >> ${logFile} || echo "`eval ${dateFormat}`: bakcup gitlab secret file to remote ${remoteBackupDirectory} failure." >> ${logFile}
else
	echo "`eval ${dateFormat}`: gitlab secret file already exists in remote ${remoteBackupDirectory}!" >> ${logFile}
fi

echo '' >> ${logFile}
