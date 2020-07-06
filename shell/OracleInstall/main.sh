#!/bin/sh
#
#BASE ENVIRONMENTS
CURRENT_DIR=$(/bin/pwd)
LOGFILE=${CURRENT_DIR}/log.txt
CURRENT_TIME='/usr/bin/date +"%Y-%m-%d-%T"'

#init log file
[ -e ${LOGFILE} ] && /usr/bin/echo > ${LOGFILE} && chmod 777 ${LOGFILE}
[ ! -e ${LOGFILE} ] && touch ${LOGFILE} && chmod 777 ${LOGFILE}

#call require shell
#swap.sh
[ -x ${CURRENT_DIR}/swap.sh ] && /bin/bash ${CURRENT_DIR}/swap.sh
#hosts.sh
[ -x ${CURRENT_DIR}/hosts.sh ] && /bin/bash ${CURRENT_DIR}/hosts.sh
#user.sh and user home .bash_profile configuraiton
[ -x ${CURRENT_DIR}/user.sh ] && /bin/bash ${CURRENT_DIR}/user.sh
#conffile.sh
[ -x ${CURRENT_DIR}/conffile.sh ] && /bin/bash ${CURRENT_DIR}/conffile.sh
/usr/sbin/sysctl -p && source /etc/profile
#oracledir.sh
[ -x ${CURRENT_DIR}/oracledir.sh ] && /bin/bash ${CURRENT_DIR}/oracledir.sh

/usr/bin/echo $(${CURRENT_TIME}) >> ${LOGFILE};
echo "shell configuration succeesful" >> ${LOGFILE} || echo "shell configuration failure" >> ${LOGFILE} 
echo '--------------' >> ${LOGFILE} 
grep "shell configuration succeesful" ${LOGFILE} &> /dev/null  || exit 1 

#dependency package install
echo '--------------' >> ${LOGFILE}
/usr/bin/echo $(${CURRENT_TIME}) >> ${LOGFILE};
/usr/bin/yum install -y binutils compat-libstdc++-33 elfutils-libelf elfutils-libelf-devel elfutils-libelf-devel-static kernel-headers glibc-headers gcc gcc-c++ glibc glibc-devel libaio libaio-devel libgcc libstdc++ libstdc++-devel libXext libXtst libX11 libXau libXi make sysstat unixODBC unixODBC-devel libXp libXp.so.6 libgomp compat-libcap1 ksh bc
[ $? == 0 ] && echo "dependency package install succeesful" >> ${LOGFILE} || echo "dependency package install failure" >> ${LOGFILE}
echo '--------------' >> ${LOGFILE}
grep "dependency package install succeesful" ${LOGFILE} &> /dev/null  || exit 1


#ENVIRONMENTS
ORACLE_INSTALL_BASE=/usr/local/oracle
ORACLE_USER=oracle
####UNZIP_ORACLE_SOURCE environment variable require change to adapt your config
UNZIP_ORACLE_SOURCE=/download/database
SOURCE_DB_INSTALL_FILE=${CURRENT_DIR}/oracle/db_install.rsp.default
TARGET_DB_INSTALL_FILE=${UNZIP_ORACLE_SOURCE}/response/db_install.rsp
SOURCE_DBCA_FILE=${CURRENT_DIR}/oracle/dbca.rsp.default
TARGET_DBCA_FILE=${UNZIP_ORACLE_SOURCE}/response/dbca.rsp
####HOSTNAME environment variable require change to adapt your config
#config db_install.rsp and dbca.rsp files require environment
HOSTNAME=node2
####TOTAL_MEMORY environment variable require change to adapt your config
# Unit: G
TOTAL_MEMORY=1
# Convert Unit: M
USE_MEMORY=$(echo ${TOTAL_MEMORY}*0.8*1024 | /usr/bin/bc | awk -F '.' '{print $1}')

#db_install.rsp zone
echo '--------------' >> ${LOGFILE}
/usr/bin/echo $(${CURRENT_TIME}) >> ${LOGFILE};
#replace db_install.rsp file
\/usr/bin/cp -ar ${SOURCE_DB_INSTALL_FILE} ${TARGET_DB_INSTALL_FILE}
#change hostname to db_install.rsp file
/usr/bin/sed -i "s/{{HOST_NAME}}/${HOSTNAME}/g" ${TARGET_DB_INSTALL_FILE}
#change available memeory to db_install.rsp file
/usr/bin/sed -i "s/{{MEMORY_LIMIT}}/${USE_MEMORY}/g" ${TARGET_DB_INSTALL_FILE}


##run install program
/usr/bin/su - ${ORACLE_USER} -c "${UNZIP_ORACLE_SOURCE}/runInstaller -silent -ignorePrereq -ignoreSysPrereqs -responseFile ${TARGET_DB_INSTALL_FILE}" 
while true;do 
	if [ `find ${ORACLE_INSTALL_BASE}/oraInventory/logs/* -name 'installActions*' -exec grep 'Shutdown Oracle Database 11g Release 2 Installer' {} \; 2> /dev/null | wc -l` == 1 ] ;then
		${ORACLE_INSTALL_BASE}/oraInventory/orainstRoot.sh
                ${ORACLE_INSTALL_BASE}/oracle/product/11.2.0/db_1/root.sh
		[ $? == 0 ] && echo 'install program succeesful' >> ${LOGFILE} || echo 'install program failure' >> ${LOGFILE}
		break
	fi
	sleep 1
done
echo '--------------' >> ${LOGFILE}
/bin/grep 'install program succeesful' ${LOGFILE} &> /dev/null || exit 1

#install config listening
echo '--------------' >> ${LOGFILE}
/usr/bin/echo $(${CURRENT_TIME}) >> ${LOGFILE};
/usr/bin/su - ${ORACLE_USER} -c "netca /silent /responsefile ${UNZIP_ORACLE_SOURCE}/response/netca.rsp && echo 'install config listening successful' >> ${LOGFILE} || echo 'install config listening failure' >> ${LOGFILE} "
echo '--------------' >> ${LOGFILE}
/bin/grep 'install config listening successful' ${LOGFILE} &> /dev/null || exit 1

#dbca.rsp zone
echo '--------------' >> ${LOGFILE}
/usr/bin/echo $(${CURRENT_TIME}) >> ${LOGFILE};
#replace dbca.rsp file
\/usr/bin/cp -ar ${SOURCE_DBCA_FILE} ${TARGET_DBCA_FILE}
#change oracle available memory to dbca.rsp file
/usr/bin/sed -i "s/{{ORACLE_USE_MEMORY}}/${USE_MEMORY}/g" ${TARGET_DBCA_FILE}
#install oracle database instance
/usr/bin/su - ${ORACLE_USER} -c "dbca -silent -responseFile ${TARGET_DBCA_FILE} && echo 'install oracle database instance successful' >> ${LOGFILE} || echo 'install oracle database instance failure' >> ${LOGFILE}" 
echo '--------------' >> ${LOGFILE}
/bin/grep 'install oracle database instance successful' ${LOGFILE} &> /dev/null || exit 1
