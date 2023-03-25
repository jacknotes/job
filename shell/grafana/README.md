# Usage Method


## generate grafana api key
1. to grafana settings -> 'Api Key' -> generate 
2. Usage Api Key exporter/import grafana dashboard

## expoter
```
./grafana-exporter.sh 'monitor.hs.com' 'eyJrIjoiNXJPUzCJpZCI6MX0='
```

## import
```
./grafana-import.sh -p test/ -t monitor.hs.com -k 'eyJrIaW4tcnciLCJpZCI6MX0='
```

## exporter raw format, can manual import to grafana
```
./grafana-exporter-raw.sh 'monitor.hs.com' 'eyJrIjoiNXJPUzCJpZCI6MX0='
```
