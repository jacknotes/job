#!/bin/sh
#datetime: 2021-05-24 17:33
#author: jackli
#version: v2
#description: mysql database binlog file convert and restore.
#Step:
#1. ./mysql_restore.sh convert full increment
#2. ./mysql_restore.sh restore full increment


DATADIR=$2
LOGIN_STATEMENT="mysql -uroot -phomsom123 "
DATABASE_MASTER_INDEX_FILE=master_index_file.txt
DATABASE_INCREMENT_FILENAME=${DATADIR}/increment_filename.txt
DATETIME="date +'%Y-%m-%d %T'"
DATETIME_DBNAME=`date +'%Y%m%d%H%M%S'`
MYSQLBINLOG_COMMAND=/usr/local/mysql/bin/mysqlbinlog
PATTERN_STR='_[0-9][0-9][0-9][0-9][0-9][0-9]_'

#change source dbname to target dbname
# usage: for i in db01 db02 db03; do ./mysql_restore.sh rename ${i} ${i}_backup;done
rename_mysql_dbname(){
	SOURCE_DATABASE="\"$1\""
	TARGET_DATABASE=$2
	FORMAT_SOURCE_DATABASE_NAME=`echo ${SOURCE_DATABASE} | sed 's/"//g'`
        GET_TABLE_SQL="select table_name from information_schema.TABLES where TABLE_SCHEMA=${SOURCE_DATABASE};"
        LIST_TABLE=$(${LOGIN_STATEMENT} -Nse "${GET_TABLE_SQL}")
	echo "`eval ${DATETIME}`: create database ${TARGET_DATABASE}..."
	${LOGIN_STATEMENT} -e "create database ${TARGET_DATABASE}" 2> /dev/null
	[ $? == 0 ] && echo "`eval ${DATETIME}`: create database ${TARGET_DATABASE} successful." || echo "`eval ${DATETIME}`: database ${TARGET_DATABASE} already exists, create database failure."
	#start rename table
	echo "`eval ${DATETIME}`: rename database ${FORMAT_SOURCE_DATABASE_NAME} TO ${TARGET_DATABASE}..."
        for table in ${LIST_TABLE};do
		${LOGIN_STATEMENT} -e "rename table ${FORMAT_SOURCE_DATABASE_NAME}.\`${table}\` to ${TARGET_DATABASE}.\`${table}\`"
		[ $? == 0 ] && echo "`eval ${DATETIME}`: rename table ${FORMAT_SOURCE_DATABASE_NAME}.\`${table}\` TO ${TARGET_DATABASE}.\`${table}\` successful." || echo "`eval ${DATETIME}`: rename table ${SOURCE_DATABASE}.\`${table}\` TO ${TARGET_DATABASE}.\`${table}\` failure."
        done
	TABLE_ROW_NUMBER=`${LOGIN_STATEMENT} -e "show tables from ${FORMAT_SOURCE_DATABASE_NAME}" | wc -l`
	[ ${TABLE_ROW_NUMBER} == 0 ] && ${LOGIN_STATEMENT} -e "drop database if exists ${FORMAT_SOURCE_DATABASE_NAME}"
}

#from full directory drop database
drop_database(){
	for i in `ls ${DATADIR}| grep '^Pro_Full.*sql$' | awk -F "." '{print $1}'| awk -F "${PATTERN_STR}" '{print $2}'`;do
		echo '---'
		echo "`eval ${DATETIME}`: start drop database ${i}..."
                ${LOGIN_STATEMENT} -e "drop database ${i}" 2> /dev/null
                [ $? == 0 ] && echo "`eval ${DATETIME}`: drop database ${i} successful." || echo "`eval ${DATETIME}`: database ${i} not exists, drop database failure."
		echo '---'
	done
}

#generator database start restore logfile and positon
generator_index_file(){
	echo '---'

	if [ -e ${DATABASE_MASTER_INDEX_FILE} ];then
		mv ${DATABASE_MASTER_INDEX_FILE}{,.bak}
		rm -rf ${DATABASE_MASTER_INDEX_FILE}
	fi

	# filter database name
	echo "`eval ${DATETIME}`: record info TO ${DATABASE_MASTER_INDEX_FILE}........"
	for i in `ls ${DATADIR}| grep '^Pro_Full.*sql$' | awk -F "." '{print $1}'| awk -F "${PATTERN_STR}" '{print $2}'`;do
		# get database name
		RESTORE_DB_NAME=${DATADIR}/`ls ${DATADIR}| grep "${i}.sql$"`
		CURRENT_DATABASE_NAME=$(grep 'CREATE DATABASE' ${RESTORE_DB_NAME} | awk -F '`' '{print $2}')
                MASTER_LOG_FILE=`grep 'CHANGE MASTER' ${RESTORE_DB_NAME} | awk -F "'" '{print $2}'`
                MASTER_LOG_POS=`grep 'CHANGE MASTER' ${RESTORE_DB_NAME} | awk -F "=" '{print $3}' | sed 's/;//g'`
		echo "`eval ${DATETIME}`: record database ${CURRENT_DATABASE_NAME} master_log_file and master_log_position..."
		echo "${CURRENT_DATABASE_NAME} ${MASTER_LOG_FILE} ${MASTER_LOG_POS}" >> ${DATABASE_MASTER_INDEX_FILE} 
		[ $? == 0 ] && echo "`eval ${DATETIME}`: record database ${CURRENT_DATABASE_NAME} master_log_file and master_log_position successful." || echo "`eval ${DATETIME}`: record database ${CURRENT_DATABASE_NAME} master_log_file and master_log_position failure."
	done
	echo "`eval ${DATETIME}`: record info TO ${DATABASE_MASTER_INDEX_FILE} END."
	echo '---'
}

convert_binlog(){
	#call function generator binlog file mastet relation info 
	generator_index_file 
	
	#set new DATADIR variables
	if [ -e "$2" ];then
		DATADIR=$2
	fi

        #get master_index_file number.
        RESTORE_DATABASE_NUMBER=`cat ${DATABASE_MASTER_INDEX_FILE} | sed '/^\s*$/d' | wc -l`
	TMP_MASTER_INDEX_FILE=${DATABASE_MASTER_INDEX_FILE}.tmp
	TMP_VAR='0 0 0'
	TAG=0
	#get all number of index in incerment directory
	CURRENT_DIRECTORY_ALL_MASTER_INDEX=`ls ${DATADIR}| grep 'master-bin.*_Pro.*' | awk -F "_Pro" '{print $1}' | sed 's/master-bin.//g' |sort -u`

	if [ -e ${DATABASE_INCREMENT_FILENAME} ];then
		rm -rf ${DATABASE_INCREMENT_FILENAME}
	fi
	if [ -e ${TMP_MASTER_INDEX_FILE} ];then
		rm -rf ${TMP_MASTER_INDEX_FILE}
	fi

	#sort by master_index name
	cat ${DATABASE_MASTER_INDEX_FILE} | sort -t ' ' -k 2 > ${TMP_MASTER_INDEX_FILE}

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
		if [ `ls ${DATADIR} | grep ${CURRENT_RESTORE_DATABASE_FILE}` ];then 
			#get valid binlog file
			CURRENT_INCREMENT_FILE=${DATADIR}/`ls ${DATADIR} | grep ${CURRENT_RESTORE_DATABASE_FILE} | grep -Ev '*.(sql)'`
		else
			echo "`eval ${DATETIME}`: in ${DATADIR} directory ${CURRENT_RESTORE_DATABASE_FILE} relation file not exists,"
			exit 6
		fi
		# get number of index in current execute database 
		CURRENT_EXCUTE_MASTER_INDEX=`echo ${CURRENT_RESTORE_DATABASE_FILE} | awk -F '.' '{print $2}'`
		# if exists. echo already exists.
		if [ -e "${DATADIR}/${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql" ];then
			echo "`eval ${DATETIME}`: ${DATADIR}/${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql already exists."
		#if current database index_file and position equal previous database. excute soft link
		elif [ "${CURRENT_RESTORE_DATABASE_FILE}" == "${TMP_RESTORE_DATABASE_FILE}" -a "${CURRENT_RESTORE_DATABASE_POSITION}" == "${TMP_RESTORE_DATABASE_POSITION}" ];then
				OLD_RESTORE_DATABASE_INFO=$(sed -n "`expr ${i} - 1`p" ${TMP_MASTER_INDEX_FILE})
				OLD_RESTORE_DATABASE_NAME=`echo ${OLD_RESTORE_DATABASE_INFO} | awk '{print $1}'`
				OLD_EXCUTE_MASTER_INDEX=`echo ${OLD_RESTORE_DATABASE_INFO} | awk '{print $2}' | awk -F '.' '{print $2}'`
				OLD_RESTORE_DATABASE_POSITION=`echo ${OLD_RESTORE_DATABASE_INFO} | awk '{print $3}'`
				echo "`eval ${DATETIME}`: database ${CURRENT_RESTORE_DATABASE_NAME} and ${OLD_RESTORE_DATABASE_NAME} of master_index_file,position equal,execut soft link... "
				cd ${DATADIR}
				ln -s ${OLD_RESTORE_DATABASE_NAME}-${OLD_EXCUTE_MASTER_INDEX}-${OLD_RESTORE_DATABASE_POSITION}.sql ${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql
				[ $? == 0 ] && echo "`eval ${DATETIME}`: soft link ${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql --> ${OLD_RESTORE_DATABASE_NAME}-${OLD_EXCUTE_MASTER_INDEX}-${OLD_RESTORE_DATABASE_POSITION}.sql successful. " || echo "`eval ${DATETIME}`: soft link ${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql --> ${OLD_RESTORE_DATABASE_NAME}-${OLD_EXCUTE_MASTER_INDEX}-${OLD_RESTORE_DATABASE_POSITION}.sql failure. "
				cd - &> /dev/null
		#else convert custom binlog
		else
			echo "`eval ${DATETIME}`: custom binlog convert..."
			echo "${MYSQLBINLOG_COMMAND} --no-defaults --start-position='${CURRENT_RESTORE_DATABASE_POSITION}' ${CURRENT_INCREMENT_FILE} > ${DATADIR}/${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql"
			${MYSQLBINLOG_COMMAND} --no-defaults --start-position="${CURRENT_RESTORE_DATABASE_POSITION}" ${CURRENT_INCREMENT_FILE} > ${DATADIR}/${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql
			if [ $? == 0 ];then
				echo "`eval ${DATETIME}`: custom binlog convert successful. [${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql]"
			else
				echo "`eval ${DATETIME}`: custom binlog convert failure. [${CURRENT_RESTORE_DATABASE_NAME}-${CURRENT_EXCUTE_MASTER_INDEX}-${CURRENT_RESTORE_DATABASE_POSITION}.sql]"
				exit 5
			fi
		fi

		#convert universal binlog
		for j in ${CURRENT_DIRECTORY_ALL_MASTER_INDEX};do
			#test current database execute index if greater than all universal binlog index, tag initial is 0, if tag greater than 0 then not execute 
			if [ ${CURRENT_EXCUTE_MASTER_INDEX} -lt ${j} -a ${TAG} == 0 ];then 
				CURRENT_INCREMENT_FILE=${DATADIR}/`ls ${DATADIR} | grep ${j} | grep -Ev '*.(sql|sh)'`
				#log universal binlog behend result name
				echo "${CURRENT_INCREMENT_FILE}.sql" >> ${DATABASE_INCREMENT_FILENAME}
				if [ -e "${CURRENT_INCREMENT_FILE}.sql" ];then
					echo "`eval ${DATETIME}`: ${CURRENT_INCREMENT_FILE}.sql already exists."
					continue
				else
					echo "`eval ${DATETIME}`: universal binlog convert ${CURRENT_INCREMENT_FILE}..." 
					${MYSQLBINLOG_COMMAND} --no-defaults  ${CURRENT_INCREMENT_FILE} > ${CURRENT_INCREMENT_FILE}.sql
					if [ $? == 0 ];then
						echo "`eval ${DATETIME}`: universal binlog convert successful. [${CURRENT_INCREMENT_FILE}.sql]"
					else
						echo "`eval ${DATETIME}`: universal binlog convert failure. [${CURRENT_INCREMENT_FILE}.sql]"
						exit 5
					fi
				fi
			fi
		done
		#set current info to old info
		TMP_VAR=${CURRENT_RESTORE_DATABASE_INFO}
		TAG=1
		echo '---'
	done
	#delete tmp file
	rm -rf ${TMP_MASTER_INDEX_FILE}
}


#full restore database
restore(){
	#call function
	generator_index_file

	#local variables.
	RESTORE_DATABASE_NUMBER=`cat ${DATABASE_MASTER_INDEX_FILE} | sed '/^\s*$/d' | wc -l`
	BATCH_TMP_DATABASE_FILE=batch_file.txt
	INCREMENT_DATADIR=$2
	
	# test file is exists?
	if [ -e ${BATCH_TMP_DATABASE_FILE} ];then
		> ${BATCH_TMP_DATABASE_FILE}
	else
		touch ${BATCH_TMP_DATABASE_FILE}
	fi

	#batch restore database backup 
	for i in `seq 1 ${RESTORE_DATABASE_NUMBER}`;do
		BATCH_MASTER_DATABASE=`sed -n "${i}p" ${DATABASE_MASTER_INDEX_FILE} | awk '{print $1}'`
		BATCH_MASTER_FILE=`sed -n "${i}p" ${DATABASE_MASTER_INDEX_FILE} | awk '{print $2}'`
		BATCH_MASTER_FILE_INDEX=`sed -n "${i}p" ${DATABASE_MASTER_INDEX_FILE} | awk '{print $2}' | awk -F '.' '{print $2}'`
		BATCH_MASTER_POSTION=`sed -n "${i}p" ${DATABASE_MASTER_INDEX_FILE} | awk '{print $3}'`

		# test database in ${BATCH_TMP_DATABASE_FILE} ?
		if [ `grep ${BATCH_MASTER_DATABASE} ${BATCH_TMP_DATABASE_FILE}` ];then
			echo "`eval ${DATETIME}`: ${BATCH_MASTER_DATABASE} already restore!"
			continue
		fi
		# insert me to ${BATCH_TMP_DATABASE_FILE}
		echo ${BATCH_MASTER_DATABASE} > ${BATCH_TMP_DATABASE_FILE}
		# insert equal database index and postion to ${BATCH_TMP_DATABASE_FILE}
		cat ${DATABASE_MASTER_INDEX_FILE} | grep -n "${BATCH_MASTER_FILE}.*${BATCH_MASTER_POSTION}" | grep -v "^${i}" | awk -F ":" '{print $2}' | awk '{print $1}' >> ${BATCH_TMP_DATABASE_FILE}

		echo '---'
		#batch restore database
		for i in `cat ${BATCH_TMP_DATABASE_FILE}`;do
			#create database
			echo "`eval ${DATETIME}`: create database ${i}..."
			${LOGIN_STATEMENT} -e "create database ${i}" 2> /dev/null
			[ $? == 0 ] && echo "`eval ${DATETIME}`: create database ${i} successful." || echo "`eval ${DATETIME}`: database ${i} already exists, create database failure."
			# get database file and restore
			RESTORE_DB_NAME=${DATADIR}/`ls ${DATADIR}| grep "${i}.sql$"`
			echo "`eval ${DATETIME}`: full restore database from ${RESTORE_DB_NAME}..."
			${LOGIN_STATEMENT} ${i} < ${RESTORE_DB_NAME}	
			[ $? == 0 ] && echo "`eval ${DATETIME}`: full restore database ${i} successful." || echo "`eval ${DATETIME}`: full resotre database ${i} failure."
		done

		#custom incremente database restore
		#get all database name from batch file
		CURRENT_EXECUTE_DATABASE_NAME=`cat ${BATCH_TMP_DATABASE_FILE} | xargs `
		#start restore custom binlog data file
                if [ -e "${INCREMENT_DATADIR}/${BATCH_MASTER_DATABASE}-${BATCH_MASTER_FILE_INDEX}-${BATCH_MASTER_POSTION}.sql" ];then
                        echo "`eval ${DATETIME}`: restore custom increment database file ${INCREMENT_DATADIR}/${BATCH_MASTER_DATABASE}-${BATCH_MASTER_FILE_INDEX}-${BATCH_MASTER_POSTION}.sql"
                        ${LOGIN_STATEMENT} -e "use ${BATCH_MASTER_DATABASE};source ${INCREMENT_DATADIR}/${BATCH_MASTER_DATABASE}-${BATCH_MASTER_FILE_INDEX}-${BATCH_MASTER_POSTION}.sql;"
                        if [ $? == 0 ];then
                                echo "`eval ${DATETIME}`: custom increment database file ${INCREMENT_DATADIR}/${BATCH_MASTER_DATABASE}-${BATCH_MASTER_FILE_INDEX}-${BATCH_MASTER_POSTION}.sql restore successful."
				echo "`eval ${DATETIME}`: database: ${CURRENT_EXECUTE_DATABASE_NAME} binlog restore successful. "
                        else
                                echo "`eval ${DATETIME}`: custom increment database file ${INCREMENT_DATADIR}/${BATCH_MASTER_DATABASE}-${BATCH_MASTER_FILE_INDEX}-${BATCH_MASTER_POSTION}.sql restore failure."
				echo "`eval ${DATETIME}`: database: ${CURRENT_EXECUTE_DATABASE_NAME} binlog restore failure. "
                                exit 5
                        fi
                else
                        echo "`eval ${DATETIME}`: ${INCREMENT_DATADIR}/${BATCH_MASTER_DATABASE}-${BATCH_MASTER_FILE_INDEX}-${BATCH_MASTER_POSTION}.sql is not exists, please convert binlog file."
                fi

		#rename database
		for i in ${CURRENT_EXECUTE_DATABASE_NAME};do
			rename_mysql_dbname ${i} ${i}_${DATETIME_DBNAME}
		done
		echo '---'
	done
	
	#test ${DATADIR}/increment_filename.txt file is exists?,if exists,will restore universal increment binlog.
	if [ -e ${DATABASE_INCREMENT_FILENAME} ];then
		#from rename_mysql_dbname function get new database suffix,example db01_20210523224916
		RENAME_DATABASE_SUFFIX=`echo ${TARGET_DATABASE} | awk -F "_" '{print $2}'`
		#again rename database, serve as restore universal binlog data file.
		for i in `seq 1 ${RESTORE_DATABASE_NUMBER}`;do
	                RENAME_CURRENT_DATABASE=`sed -n "${i}p" ${DATABASE_MASTER_INDEX_FILE} | awk '{print $1}'`
			rename_mysql_dbname ${RENAME_CURRENT_DATABASE}_${RENAME_DATABASE_SUFFIX} ${RENAME_CURRENT_DATABASE}
		done
	
		#call function for universal_increment_restore
		echo '---'
		echo "`eval ${DATETIME}`: start universal increment binlog restore..."
		universal_increment_restore 
		echo '---'
	
		#last rename database to current time suffix
		for i in `seq 1 ${RESTORE_DATABASE_NUMBER}`;do
	                RENAME_CURRENT_DATABASE=`sed -n "${i}p" ${DATABASE_MASTER_INDEX_FILE} | awk '{print $1}'`
	                rename_mysql_dbname ${RENAME_CURRENT_DATABASE} ${RENAME_CURRENT_DATABASE}_${RENAME_DATABASE_SUFFIX} 
	        done
	fi
	
	#clear tmp file
	rm -rf ${BATCH_TMP_DATABASE_FILE}
}

#universal increment restore database
universal_increment_restore(){
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
}


case $1 in 
	rename)
		if [ "$#" -gt 3 ];then echo 'args is great than 3, args must is 3' ; exit 5 
		elif [ -z "${2}" ];then echo 'args $2 is null' ; exit 5 
		elif [ -z "${3}" ];then echo 'args $3 is null' ; exit 5 
                else rename_mysql_dbname ${2} ${3} 
		fi 
                ;;

	drop)
		if [ "$#" -gt 2 ];then echo 'args is great than 2, args must is 2' ; exit 5 
		elif [ -z "${DATADIR}" ];then echo 'args $2 is null' ; exit 5 
		else drop_database
		fi
		;;		

	generator)
		if [ "$#" -gt 2 ];then echo 'args is great than 2, args must is 2' ; exit 5 
		elif [ -z "${DATADIR}" ];then echo 'args $2 is null' ; exit 5 
		else generator_index_file
		fi
		;;		

	convert)
		if [ "$#" -gt 3 ];then echo 'args is great than 3, args must is 3' ; exit 5 
		elif [ -z "${DATADIR}" ];then echo 'args $2 is null' ; exit 5 
		elif [ -z "$3" ];then echo 'args $3 is null' ; exit 5 
		else convert_binlog ${DATADIR} $3
		fi
		;;		

	restore)
		if [ "$#" -gt 3 ];then echo 'args is great than 3, args must is 3' ; exit 5 
		elif [ -z "${DATADIR}" ];then echo 'args $2 is null' ; exit 5 
		elif [ -z "$3" ];then echo 'args $3 is null' ; exit 5 
		else restore ${DATADIR} $3
		fi
		;;

	*)
		echo "BEGIN: "
		echo "Eexample: ./resotre_fullDB.sh convert /tmp/mysql-restore/Pro_Full_20210509_010002 /tmp/mysql-restore/Pro_Increment_20210509_030001"

		echo "AFTER: "
		echo "Usage: { $0 { [ drop | generator ] datadir } | { rename source_database target_database } | { [ convert | restore ] full_backup_directory increment_backup_directory } }"
		echo "Eexample: ./resotre_fullDB.sh drop /tmp/mysql-restore/Pro_Full_20210509_010002"
		echo "Eexample: ./resotre_fullDB.sh generator /tmp/mysql-restore/Pro_Full_20210509_010002"
		echo "Eexample: ./resotre_fullDB.sh rename db01 db01_backup"
		echo "Eexample: ./resotre_fullDB.sh restore /tmp/mysql-restore/Pro_Full_20210509_010002 /tmp/mysql-restore/Pro_Increment_20210509_030001"
		;;
esac
