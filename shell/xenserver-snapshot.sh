#!/bin/sh
#author: jack.li
#datetime: 20210226-14:34
#description: cron make snapshot and clean history snapshot

export PATH=/opt/xensource/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

DATE=`date +"%Y%m%d%H%M%S"`
REAL_HOST_UUID=`xe vm-list | awk BEGIN{RS=EOF}'{gsub(/\n/," ");print}' | grep Control | awk -F ':' '{print $2}' | awk '{print $1}'`
VIR_HOST_UUID=`xe vm-list | awk BEGIN{RS=EOF}'{gsub(/\n/," ");print}' | grep -v Control | awk -F ':' '{print $2}' | awk '{print $1}' | sort`
SNAPSHOT_LOG="/tmp/snapshot-`hostname`.log"
NUM=0 

# make snapshot
echo "HOSTNAME: `hostname`" > ${SNAPSHOT_LOG}
echo "DATE: `date +"%Y%m%d%H%M%S"`:" >> ${SNAPSHOT_LOG}
for i in ${VIR_HOST_UUID};do
	Current_VM_Name=`xe vm-list | awk BEGIN{RS=EOF}'{gsub(/\n/," ");print}' | grep "${i}" | awk -F ':' '{print $3}' | awk '{print $1}'`
	echo "VM_NAME: ${Current_VM_Name}" >> ${SNAPSHOT_LOG}
	echo "CREATE SNAPSHOT:" >> ${SNAPSHOT_LOG}
	#create snapshot
	echo "CREATE_SNAPSHOT_UUID: `xe vm-snapshot "uuid=${i}" new-name-label="${Current_VM_Name}-${DATE}"`" >> ${SNAPSHOT_LOG}

	if [ $? == 0 ];then
		echo "CREATE_SNAPSHOT_NAME: ${Current_VM_Name}-${DATE} Create Successful!" >> ${SNAPSHOT_LOG}
		NUM=1 
	else
		echo "CREATE_SNAPSHOT_NAME: ${Current_VM_Name}-${DATE} Create Failure!" >> ${SNAPSHOT_LOG}
	fi

	TmpSnapshotUUID=`xe snapshot-list params=uuid,name-label,snapshot-of | awk BEGIN{RS=EOF}'{gsub(/\n/," ");print}' | grep "${i}" | grep -v "${DATE}" | awk -F ':' '{print $2}' | awk '{print $1}'`

	if [ $NUM == 1 ];then
		for j in ${TmpSnapshotUUID};do
			echo "DELETE SNAPSHOT:" >> ${SNAPSHOT_LOG}
			TmpSnapshotName=`xe snapshot-list params=uuid,name-label,snapshot-of | awk BEGIN{RS=EOF}'{gsub(/\n/," ");print}' | grep "${j}" |  awk -F ':' '{print $3}' | awk '{print $1}'`
			xe snapshot-destroy uuid="${j}"
			[ $? == 0 ] && echo "SNAPSHOT_NAME: ${TmpSnapshotName} Destroy Successful!" >> ${SNAPSHOT_LOG} || echo "SNAPSHOT_NAME: ${TmpSnapshotName} Destroy Failure!" >> ${SNAPSHOT_LOG} 
		done
	else
		echo "Snapshot Create Failure,Cannot Delete Old Snapshot!!!"
	fi
	echo ""  >> ${SNAPSHOT_LOG}
done

