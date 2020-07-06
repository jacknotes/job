#!/bin/sh
#
CURRENT_DIR=$(/bin/pwd)
LOGFILE=${CURRENT_DIR}/log.txt
CURRENT_TIME='/usr/bin/date +"%Y-%m-%d-%T"'
ORACLE_ROOT=/usr/local/oracle
ORACLE_INSTALL_HOME=${ORACLE_ROOT}/oracle
ORACLE_DATA_HOME=${ORACLE_ROOT}/oradata
ORACLE_DATA_BACK_HOME=${ORACLE_ROOT}/oradata_back
ORACLE_INVENTORY_HOME=${ORACLE_ROOT}/oraInventory
ORACLE_USER=oracle
ORACLE_GROUP=oinstall

#create directory
/usr/bin/mkdir -p ${ORACLE_INSTALL_HOME}
/usr/bin/mkdir -p ${ORACLE_DATA_HOME}
/usr/bin/mkdir -p ${ORACLE_DATA_BACK_HOME}
/usr/bin/mkdir -p ${ORACLE_INVENTORY_HOME}

/usr/bin/chown  -R ${ORACLE_USER}:${ORACLE_GROUP} ${ORACLE_INSTALL_HOME} ${ORACLE_DATA_HOME} ${ORACLE_INVENTORY_HOME} 
/usr/bin/chmod -R 755 ${ORACLE_INSTALL_HOME} ${ORACLE_DATA_HOME} ${ORACLE_INVENTORY_HOME}

echo '--------------' >> ${LOGFILE}
/usr/bin/echo $(${CURRENT_TIME}) >> ${LOGFILE};
[ $? == 0 ] && echo "oracle directory config succeesful" >> ${LOGFILE} || echo "oracle directory config failure" >> ${LOGFILE}
echo '--------------' >> ${LOGFILE}
grep "oracle directory config succeesful" ${LOGFILE} &> /dev/null  || exit 1


