#!/bin/sh

LOGFILE=/vmfs/volumes/datastore1/jackli/autosnapshot.log
DAY=1

echo "start time: $(date +'%Y%m%d%H%M%S')" >> $LOGFILE

for vmid in $(vim-cmd vmsvc/getallvms | grep 'testnginx.esxi01.rack05.hs.com-192.168.13.230' | awk '{print $1}' | grep -e "[0-9]")
do
	#create snapshot step
	SNAPSHOT_TIME_OF_NAME=$(date +'%Y%m%d%H%M%S')
	echo "CREATE SNAPSHOT for VMID: $vmid of SNAPSHOTNAME: $SNAPSHOT_TIME_OF_NAME......" >> $LOGFILE
	vim-cmd vmsvc/snapshot.create $vmid $SNAPSHOT_TIME_OF_NAME autosnapshot 1 1 > /dev/null
	a=0;
	while [ $a == 0 ];do
		vim-cmd vmsvc/snapshot.get $vmid | grep $SNAPSHOT_TIME_OF_NAME > /dev/null
		if [ $? == 0 ];then 
			let a++
		fi;
		sleep 1;
	done	
	
	#delete snapshot step
	SNAPSHOT_COUNT=$(vim-cmd vmsvc/snapshot.get $vmid | grep 'Snapshot Id' | wc -l)
	if [ $SNAPSHOT_COUNT -gt $DAY ]; then
		let NUM=$SNAPSHOT_COUNT-$DAY
		OLD_SNAPSHOT_ID=$(vim-cmd vmsvc/snapshot.get $vmid | grep 'Snapshot Id' | head -$NUM | awk -F: '{print $2}')
		for single_snapshot_id in $OLD_SNAPSHOT_ID
		do
			echo "DELETE VMID: $vmid for SNAPSHOT ID: $single_snapshot_id....." >> $LOGFILE
			vim-cmd vmsvc/snapshot.remove $vmid $single_snapshot_id > /dev/null
			[ $? == 0 ] && echo "DELETE Succeeded" >> $LOGFILE || echo "DELETE Failed" >> $LOGFILE
		done
	fi
done

echo "end time: $(date +'%Y%m%d%H%M%S')" >> $LOGFILE
echo "" >> $LOGFILE
