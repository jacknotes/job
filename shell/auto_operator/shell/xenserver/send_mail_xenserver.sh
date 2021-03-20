#!/bin/sh

SCHTASKS_LIST="/tmp/xenserver-snapshot-status.log"
JOB_FILE="/tmp/job-xenserver.txt"

for i in ${SCHTASKS_LIST};do
	dos2unix ${i} >& /dev/null
	cat ${i} >> ${JOB_FILE}
	echo "" >> ${JOB_FILE}
done

#send mail
cat ${JOB_FILE} | mail -s "xenserver snapshot status" jack.li@homsom.com
[ $? == 0 ] && rm -rf ${JOB_FILE}
