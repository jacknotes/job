#!/bin/sh
#datetime: 2021-05-19 17:06
#author: jackli
#description: mysql database full and increment backup file restore.

DATADIR=$2
LOGIN_STATEMENT="mysql -uroot -phomsom "
DATABASE_MASTER_INDEX_FILE=${DATADIR}/master_index_file.txt
DATABASE_INCREMENT_FILENAME=${DATADIR}/increment_filename.txt
DATETIME="date +'%Y-%m-%d %T'"
MYSQLBINLOG_COMMAND=/usr/local/mysql/bin/mysqlbinlog
PATTERN_STR='_[0-9][0-9][0-9][0-9][0-9][0-9]_'

#from full directory drop database
drop_database(){
	for i in `ls ${DATADIR}| grep '^Pro_Full.*sql$' | awk -F "." '{print $1}'| awk -F "${PATTERN_STR}" '{print $2}'`;do
		echo '---'
		echo "`eval ${DATETIME}`: start drop database ${i}"
                ${LOGIN_STATEMENT} -e "drop database if exists ${i}"
                [ $? == 0 ] && echo "`eval ${DATETIME}`: drop database ${i} successful." || echo "`eval ${DATETIME}`: drop database ${i} failure."
		echo '---'
	done
}

#generator database start restore logfile and positon
generator_index_file(){
	if [ -e ${DATABASE_MASTER_INDEX_FILE} ];then
		mv ${DATABASE_MASTER_INDEX_FILE}{,.bak}
		rm -rf ${DATABASE_MASTER_INDEX_FILE}
	fi
	# filter database name
	for i in `ls ${DATADIR}| grep '^Pro_Full.*sql$' | awk -F "." '{print $1}'| awk -F "${PATTERN_STR}" '{print $2}'`;do
		echo '---'
		# get database name
		RESTORE_DB_NAME=`ls ${DATADIR}| grep "${i}.sql$"`
		CURRENT_DATABASE_NAME=$(grep 'CREATE DATABASE' ${RESTORE_DB_NAME} | awk -F '`' '{print $2}')
                MASTER_LOG_FILE=`grep 'CHANGE MASTER' ${RESTORE_DB_NAME} | awk -F "'" '{print $2}'`
                MASTER_LOG_POS=`grep 'CHANGE MASTER' ${RESTORE_DB_NAME} | awk -F "=" '{print $3}' | sed 's/;//g'`
		echo "`eval ${DATETIME}`: record database ${CURRENT_DATABASE_NAME} master_log_file and master_log_position"
		echo "${CURRENT_DATABASE_NAME} ${MASTER_LOG_FILE} ${MASTER_LOG_POS}" >> ${DATABASE_MASTER_INDEX_FILE} 
		[ $? == 0 ] && echo "`eval ${DATETIME}`: record database ${CURRENT_DATABASE_NAME} master_log_file and master_log_position successful." || echo "`eval ${DATETIME}`: record database ${CURRENT_DATABASE_NAME} master_log_file and master_log_position failure."
		echo '---'
	done
}

#full restore database
full_restore(){
	if [ -e ${DATABASE_MASTER_INDEX_FILE} ];then
		mv ${DATABASE_MASTER_INDEX_FILE}{,.bak}
		rm -rf ${DATABASE_MASTER_INDEX_FILE}
	fi
	# filter database name
	for i in `ls ${DATADIR}| grep '^Pro_Full.*sql$' | awk -F "." '{print $1}'| awk -F "${PATTERN_STR}" '{print $2}'`;do
		echo '---'
		${LOGIN_STATEMENT} -e "create database if not exists ${i}"
		[ $? == 0 ] && echo "`eval ${DATETIME}`: create database ${i} successful." || echo "`eval ${DATETIME}`: create database ${i} failure."

		# get database name
		RESTORE_DB_NAME=`ls ${DATADIR}| grep "${i}.sql$"`
		echo "`eval ${DATETIME}`: full restore database from ${RESTORE_DB_NAME}"
		${LOGIN_STATEMENT} ${i} < ${DATADIR}/${RESTORE_DB_NAME}	
		[ $? == 0 ] && echo "`eval ${DATETIME}`: full restore database ${i} successful." || echo "`eval ${DATETIME}`: full resotre database ${i} failure."

		CURRENT_DATABASE_NAME=$(grep 'CREATE DATABASE' ${DATADIR}/${RESTORE_DB_NAME} | awk -F '`' '{print $2}')
		MASTER_LOG_FILE=`grep 'CHANGE MASTER' ${DATADIR}/${RESTORE_DB_NAME} | awk -F "'" '{print $2}'`
		MASTER_LOG_POS=`grep 'CHANGE MASTER' ${DATADIR}/${RESTORE_DB_NAME} | awk -F "=" '{print $3}' | sed 's/;//g'`
		echo "`eval ${DATETIME}`: record database ${CURRENT_DATABASE_NAME} master_log_file and master_log_position TO [${DATABASE_MASTER_INDEX_FILE}]"
		echo "${CURRENT_DATABASE_NAME} ${MASTER_LOG_FILE} ${MASTER_LOG_POS}" >> ${DATABASE_MASTER_INDEX_FILE} 
		[ $? == 0 ] && echo "`eval ${DATETIME}`: record database ${CURRENT_DATABASE_NAME} master_log_file and master_log_position successful." || echo "`eval ${DATETIME}`: record database ${CURRENT_DATABASE_NAME} master_log_file and master_log_position failure."
		echo '---'
	done
}

#increment restore database
increment_restore(){
	if [ ! -e ${DATABASE_MASTER_INDEX_FILE} ];then
		echo "`eval ${DATETIME}`: ${DATABASE_MASTER_INDEX_FILE} is not exists."
		echo "`eval ${DATETIME}`: please use: $0 generator 'FullBackup_datadir'"
		exit 5
	fi

	#get master_index_file number.
	RESTORE_DATABASE_NUMBER=`cat ${DATABASE_MASTER_INDEX_FILE} | sed '/^\s*$/d' | wc -l`
	TMP_MASTER_INDEX_FILE=${DATABASE_MASTER_INDEX_FILE}.tmp
	TMP_VAR='0 0 0'
	TAG=0

	if [ -e ${DATABASE_INCREMENT_FILENAME} ];then
		rm -rf ${DATABASE_INCREMENT_FILENAME}
	elif [ -e ${TMP_MASTER_INDEX_FILE} ];then
		rm -rf ${TMP_MASTER_INDEX_FILE}
	fi

	#sort by master_index name
	cat ${DATABASE_MASTER_INDEX_FILE} | sort -t ' ' -k 2 -n > ${TMP_MASTER_INDEX_FILE}

	#binlog convert to sqlFile.
	for i in `seq 1 ${RESTORE_DATABASE_NUMBER}`;do
		echo '---'
		CURRENT_RESTORE_DATABASE_INFO=`sed -n "${i}p" ${TMP_MASTER_INDEX_FILE}`
		CURRENT_RESTORE_DATABASE_NAME=`echo ${CURRENT_RESTORE_DATABASE_INFO} | awk '{print $1}'`
		CURRENT_RESTORE_DATABASE_FILE=`echo ${CURRENT_RESTORE_DATABASE_INFO} | awk '{print $2}'`
		CURRENT_RESTORE_DATABASE_POSITION=`echo ${CURRENT_RESTORE_DATABASE_INFO} | awk '{print $3}'`
		TMP_RESTORE_DATABASE_NAME=`echo ${TMP_VAR} | awk '{print $1}'`
		TMP_RESTORE_DATABASE_FILE=`echo ${TMP_VAR} | awk '{print $2}'`
		TMP_RESTORE_DATABASE_POSITION=`echo ${TMP_VAR} | awk '{print $3}'`
		TMP_CURRENT_INCREMENT_FILE=`ls ${DATADIR} | grep ${CURRENT_RESTORE_DATABASE_FILE} | grep -Ev '*.(sql)'`
		CURRENT_INCREMENT_FILE=${DATADIR}/${TMP_CURRENT_INCREMENT_FILE}
		CURRENT_DIRECTORY_ALL_MASTER_INDEX=`ls ${DATADIR}| grep 'master-bin.*_Pro.*' | awk -F "_Pro" '{print $1}' | sed 's/master-bin.//g' |sort -u`
		CURRENT_EXCUTE_MASTER_INDEX=`echo ${CURRENT_RESTORE_DATABASE_FILE} | awk -F '.' '{print $2}'`
		# if exists. echo already exists.
		if [ -e "${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql" ];then
			echo "`eval ${DATETIME}`: ${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql already exists."
		#if equal index_file and position. excute soft link
		elif [ "${CURRENT_RESTORE_DATABASE_FILE}" == "${TMP_RESTORE_DATABASE_FILE}" -a "${CURRENT_RESTORE_DATABASE_POSITION}" == "${TMP_RESTORE_DATABASE_POSITION}" ];then
				OLD_RESTORE_DATABASE_INFO=$(sed -n "`expr ${i} - 1`p" ${TMP_MASTER_INDEX_FILE})
				OLD_RESTORE_DATABASE_NAME=`echo ${OLD_RESTORE_DATABASE_INFO} | awk '{print $1}'`
				OLD_EXCUTE_MASTER_INDEX=`echo ${OLD_RESTORE_DATABASE_INFO} | awk '{print $2}' | awk -F '.' '{print $2}'`
				OLD_RESTORE_DATABASE_POSITION=`echo ${OLD_RESTORE_DATABASE_INFO} | awk '{print $3}'`
				ln -s ${OLD_RESTORE_DATABASE_NAME}-${OLD_EXCUTE_MASTER_INDEX}-${OLD_RESTORE_DATABASE_POSITION}.sql ${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql
				[ $? == 0 ] && echo "`eval ${DATETIME}`: soft link ${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql --> ${OLD_RESTORE_DATABASE_NAME}-${OLD_EXCUTE_MASTER_INDEX}-${OLD_RESTORE_DATABASE_POSITION}.sql successful. " || echo "`eval ${DATETIME}`: soft link ${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql --> ${OLD_RESTORE_DATABASE_NAME}-${OLD_EXCUTE_MASTER_INDEX}-${OLD_RESTORE_DATABASE_POSITION}.sql failure. "
		#else convert custom binlog
		else
			echo "`eval ${DATETIME}`: custom binlog convert"
			echo "${MYSQLBINLOG_COMMAND} --no-defaults --start-position='${CURRENT_RESTORE_DATABASE_POSITION}' ${CURRENT_INCREMENT_FILE} > ${DATADIR}/${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql..."
			${MYSQLBINLOG_COMMAND} --no-defaults --start-position="${CURRENT_RESTORE_DATABASE_POSITION}" ${CURRENT_INCREMENT_FILE} > ${DATADIR}/${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql
			if [ $? == 0 ];then
				echo "`eval ${DATETIME}`: custom binlog convert successful. [${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql]"
			else
				echo "`eval ${DATETIME}`: custom binlog convert failure. [${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql]"
				exit 5
			fi
		fi

		for j in ${CURRENT_DIRECTORY_ALL_MASTER_INDEX};do
			if [ ${CURRENT_EXCUTE_MASTER_INDEX} -lt ${j} -a ${TAG} == 0 ];then 
				TMP_CURRENT_INCREMENT_FILE=`ls ${DATADIR} | grep ${j} | grep -Ev '*.(sql|sh)'`
				CURRENT_INCREMENT_FILE=${DATADIR}/${TMP_CURRENT_INCREMENT_FILE}
				echo "${CURRENT_INCREMENT_FILE}.sql" >> ${DATABASE_INCREMENT_FILENAME}
				if [ -e "${CURRENT_INCREMENT_FILE}.sql" ];then
					echo "`eval ${DATETIME}`: ${CURRENT_INCREMENT_FILE}.sql already exists."
					continue
				else
					echo "`eval ${DATETIME}`: universal binlog convert ${CURRENT_INCREMENT_FILE}..." 
					${MYSQLBINLOG_COMMAND} --no-defaults  ${CURRENT_INCREMENT_FILE} > ${CURRENT_INCREMENT_FILE}.sql
				fi

				if [ $? == 0 ];then
					echo "`eval ${DATETIME}`: universal binlog convert successful. [${CURRENT_INCREMENT_FILE}.sql]"
				else
					echo "`eval ${DATETIME}`: universal binlog convert failure. [${CURRENT_INCREMENT_FILE}.sql]"
					exit 5
				fi

			fi
		done
		#set current info to old info
		TMP_VAR=${CURRENT_RESTORE_DATABASE_INFO}
		TAG=1
		echo '---'
	done

	# restore custom increment database backup
	for i in `seq 1 ${RESTORE_DATABASE_NUMBER}`;do
		echo '---'
		CURRENT_RESTORE_DATABASE_INFO=`sed -n "${i}p" ${TMP_MASTER_INDEX_FILE}`
		CURRENT_RESTORE_DATABASE_NAME=`echo ${CURRENT_RESTORE_DATABASE_INFO} | awk '{print $1}'`
		CURRENT_EXCUTE_MASTER_INDEX=`echo ${CURRENT_RESTORE_DATABASE_INFO} | awk '{print $2}' | awk -F '.' '{print $2}'`
		CURRENT_RESTORE_DATABASE_POSITION=`echo ${CURRENT_RESTORE_DATABASE_INFO} | awk '{print $3}'`
		echo "`eval ${DATETIME}`: restore custom increment database backup ${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql..."
		${LOGIN_STATEMENT} -e "use ${CURRENT_RESTORE_DATABASE_NAME};source ${DATADIR}/${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql;"
		if [ $? == 0 ];then
			echo "`eval ${DATETIME}`: custom increment database backup ${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql restore successful."
		else
			echo "`eval ${DATETIME}`: custom increment database backup ${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql restore failure."
			exit 5
		fi
		echo '---'
	done

	# restore universal increment database backup
	if [ -e ${DATABASE_INCREMENT_FILENAME} ];then
		DATABASE_UNIVERSAL_INCREMENT_FILENAME_NUMBER=`cat ${DATABASE_INCREMENT_FILENAME} | sed '/^\s*$/d' | wc -l`
		for i in `seq 1 ${DATABASE_UNIVERSAL_INCREMENT_FILENAME_NUMBER}`;do
			echo '---'
			DATABASE_UNIVERSAL_INCREMENT_FILENAME=`sed -n "${i}p" ${DATABASE_INCREMENT_FILENAME}`
			echo "`eval ${DATETIME}`: restore universal increment database backup ${DATABASE_UNIVERSAL_INCREMENT_FILENAME}..."
			${LOGIN_STATEMENT} -e "source ${DATABASE_UNIVERSAL_INCREMENT_FILENAME}"
			if [ $? == 0 ];then
				echo "`eval ${DATETIME}`: universal increment database backup ${DATABASE_UNIVERSAL_INCREMENT_FILENAME} restore successful."
			else
				echo "`eval ${DATETIME}`: universal increment database backup ${DATABASE_UNIVERSAL_INCREMENT_FILENAME} restore failure."
				exit 5
			fi
			echo '---'
		done
	fi

	#delete tmp file.
	rm -rf ${TMP_MASTER_INDEX_FILE}
	rm -rf ${DATABASE_INCREMENT_FILENAME}
}


case $1 in 
	drop)
		if [ -z "${DATADIR}" ];then
			echo 'args $2 is null' 
			exit 5 
		else
			drop_database
		fi
		;;		

	generator)
		if [ -z "${DATADIR}" ];then
			echo 'args $2 is null' 
			exit 5 
		else
			generator_index_file
		fi
		;;		

	full)
		if [ -z "${DATADIR}" ];then
			echo 'args $2 is null' 
			exit 5 
		else
			full_restore
		fi
		;;

	increment)
		if [ -z "${DATADIR}" ];then
			echo 'args $2 is null' 
			exit 5 
		else
			increment_restore
		fi
		;;

	*)
		echo "Usage: $0 [ full | increment | drop | generator ] datadir ]"
		echo "Eexample: ./resotre_fullDB.sh full /tmp/mysql-restore/Pro_Full_20210509_010002"
		echo "Eexample: ./resotre_fullDB.sh drop /tmp/mysql-restore/Pro_Full_20210509_010002"
		echo "Eexample: ./resotre_fullDB.sh generator /tmp/mysql-restore/Pro_Full_20210509_010002"
		echo "Eexample: ./resotre_fullDB.sh increment /tmp/mysql-restore/Pro_Increment_20210509_030001"
		;;
esac
