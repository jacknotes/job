#!/bin/sh
#
GROUP1=oinstall
GROUP2=dba
USER=oracle
CURRENT_DIR=$(/bin/pwd)
LOGFILE=${CURRENT_DIR}/log.txt
CURRENT_TIME='/usr/bin/date +"%Y-%m-%d-%T"'


echo '--------------' >> ${LOGFILE}
/usr/bin/echo $(${CURRENT_TIME}) >> ${LOGFILE};
/usr/sbin/groupadd ${GROUP1}
/usr/sbin/groupadd ${GROUP2}
/usr/sbin/useradd -g ${GROUP1} -G ${GROUP2} -m ${USER}
/usr/bin/echo 'oracle' | passwd --stdin ${USER}

#${USER} environment
[ $? == 0 ] && /usr/bin/cat >> /home/${USER}/.bash_profile << EOF
export ORACLE_BASE=/usr/local/oracle/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/db_1
export ORACLE_SID=orcl
export PATH=\$PATH:\$ORACLE_HOME/bin:\$HOME/bin
EOF

[ $? == 0 ] && echo "oracle user and user environment config succeesful" >> ${LOGFILE} || echo "oracle user and user environment config failure" >> ${LOGFILE}
echo '--------------' >> ${LOGFILE}
/bin/grep 'oracle user and user environment config succeesful' ${LOGFILE} &> /dev/null || exit 1 

