#!/bin/sh
curl -s -H'Content-Type:application/json' -d'{
  "query": {
    "bool": {
      "must": [
        {
          "match_all": {}
        }
      ],
      "filter": {
        "range": {
          "time": {
            "time_zone": "+08:00",
            "lt":"now-30d"
          }
        }
      }
    }
  }
}
' -XPOST "http://127.0.0.1:9200/clog/_delete_by_query?scroll_size=3000"

