#!/bin/bash

HOST='monitor.hs.com'
USER='0799'
PASSWORD='homsom'
APIKEY_NAME=`openssl rand -hex 10`
APIKEY_TIME='600'
BACKUP_DIR='/etc/grafana/shell'

SETCOLOR_SUCCESS="echo -en \\033[0;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"
SETCOLOR_TITLE_PURPLE="echo -en \\033[0;35m" # purple

# usage log "string to log" "color option"
function log_success() {
   if [ $# -lt 1 ]; then
       ${SETCOLOR_FAILURE}
       echo "Not enough arguments for log function! Expecting 1 argument got $#"
       exit 1
   fi

   timestamp=$(date "+%Y-%m-%d %H:%M:%S %Z")

   ${SETCOLOR_SUCCESS}
   printf "[${timestamp}] $1\n"
   ${SETCOLOR_NORMAL}
}


function log_failure() {
   if [ $# -lt 1 ]; then
       ${SETCOLOR_FAILURE}
       echo "Not enough arguments for log function! Expecting 1 argument got $#"
       exit 1
   fi

   timestamp=$(date "+%Y-%m-%d %H:%M:%S %Z")

   ${SETCOLOR_FAILURE}
   printf "[${timestamp}] $1\n"
   ${SETCOLOR_NORMAL}
}

function log_title() {
   if [ $# -lt 1 ]; then
       ${SETCOLOR_FAILURE}
       log_failure "Not enough arguments for log function! Expecting 1 argument got $#"
       exit 1
   fi

   ${SETCOLOR_TITLE_PURPLE}
   printf "|-------------------------------------------------------------------------|\n"
   printf "|$1|\n";
   printf "|-------------------------------------------------------------------------|\n"
   ${SETCOLOR_NORMAL}
}


function export(){
	RES_JSON=`curl -sS -X POST -H "Content-Type: application/json" -d '{"name":"'${APIKEY_NAME}'", "role": "Viewer", "secondsToLive": '${APIKEY_TIME}'}' http://${USER}:${PASSWORD}@${HOST}/api/auth/keys`
	APIKEY=`echo $RES_JSON | jq -r '.key'`
	cd ${BACKUP_DIR} 
	./grafana-exporter.sh ${HOST} "$APIKEY"
	./grafana-exporter-raw.sh ${HOST} "$APIKEY"
}

function delete_apikey(){
	GET_RES_JSON=`curl -sS -X GET http://${USER}:${PASSWORD}@${HOST}/api/auth/keys?name=${APIKEY_NAME}`
	APIKEY_ID=`echo $GET_RES_JSON | jq -r '.[] | .id'`
	if [ ! "${APIKEY_ID}" ];then
		log_failure "get apikey id failure\t\t name=\"${APIKEY_NAME}\" key=\"${APIKEY}\" "
		exit 1
	fi

	DELETE_RES_JSON=`curl -sS -X DELETE http://${USER}:${PASSWORD}@${HOST}/api/auth/keys/${APIKEY_ID}`
	DELETE_MESSAGE=`echo $DELETE_RES_JSON | jq -r '.message'`
	echo $DELETE_MESSAGE | grep 'API key deleted' >& /dev/null
	if [ $? = 0 ];then
		log_success "delete apikey success\t\t id=\"${APIKEY_ID}\" name=\"${APIKEY_NAME}\" key=\"${APIKEY}\" "
	else
		log_failure "delete apikey failure\t\t id=\"${APIKEY_ID}\" name=\"${APIKEY_NAME}\" key=\"${APIKEY}\" "
	fi
}

main(){
	log_title "----------------- Start Auto Exporter Grafana Dashboard -----------------"
	log_success "BACKUP_DIR=\"${BACKUP_DIR}\" "
	export
	delete_apikey
	log_title "------------------------------ FINISHED ---------------------------------"
}

main
