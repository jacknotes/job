#!/bin/sh

EXPORT_ES_INDEX_NAME="youyouhotel_en_db_pro youyouroom_db_pro youyouhotel_db_pro"
EXPORT_ES_ADDRESS="192.168.13.160:9200"
IMPORT_ES_ADDRESS="192.168.13.239:9201"
INDEX_SUFFIX="_test"
SPEED_LIMIE="1000"

for i in ${EXPORT_ES_INDEX_NAME};do
	echo $i
	docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=http://${EXPORT_ES_ADDRESS}/${i}  --output=/tmp/${i}-mapping.json  --type=mapping
	docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=http://${EXPORT_ES_ADDRESS}/${i}  --output=/tmp/${i}-20210125_0_8-data.json   --type=data --limit=${SPEED_LIMIE} --searchBody='{"query":{"range":{"updateTime":{"gte":"2021-01-25T00:00:00.000+0800","lte":"2021-01-25T08:00:00.000+0800"}}}}'
	docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=/tmp/${i}-mapping.json --output=http://${IMPORT_ES_ADDRESS}/${i}${INDEX_SUFFIX} --type=mapping
	docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=/tmp/${i}-20210125_0_8-data.json  --output=http://${IMPORT_ES_ADDRESS}/${i}${INDEX_SUFFIX} --type=data --limit=${SPEED_LIMIE}
done
