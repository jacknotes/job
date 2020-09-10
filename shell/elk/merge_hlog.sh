#!/bin/sh
curl -s -H'Content-Type:application/json' -XPOST "http://127.0.0.1:9200/clog/_forcemerge?only_expunge_deletes=true&max_num_segments=1"
