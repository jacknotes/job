#!/usr/bin/env python3
#import zabbix_base_api  # import custom class for zabbix_base_api.py
import zabbixBaseAPI
import time 
import re

#write zabbix API address replace old address
z_api_con = zabbixBaseAPI.zabbixBaseAPI(url='http://192.168.43.201/zabbix/api_jsonrpc.php')

# get host id function
def hostGet(method,ip,authid):
    data = {
        "output": ["hostid", "host"],
        "filter": {
            "ip": ip
        },
        "selectInterfaces": ["ip"],
        "selectParentTemplates": ["name"]

    }
    responses = z_api_con.json_data(method, data, authid)
    return responses

#will mouse move zabbix web front hostGroup,template can get id
def hostCreate(method,ip,hostname,serverType,authid):
    data = {
        "host": hostname,
        #"proxy_hostid": 13323,                    #proxy id
        "interfaces": [
            {
                "type": 1,
                "main": 1,
                "useip": 1,
                "ip": ip,			    #zabbix agent ip
                "dns": "",
                "port": "10050"                     #zabbix agent port 
            }
        ],
        "groups": [
            {
                "groupid": 2                        #host group id
            }
        ],
        "tags": [
            {
                "tag": hostname,
                "value": serverType
            }
        ],
        "templates": [
            {
                "templateid": 10001                 #require join of template id
            }
        ]
    }

    responses = z_api_con.json_data(method, data, authid)
    return responses

def hostDelete(method,authid,*hostids):
    data = hostids 
    responses = z_api_con.json_data(method, data, authid)
    return responses

#get all proxyAgent info(proxyAgent id,name.....)
def proxyGet(method,authid):
    data = {
        "output": "extend",
        "selectInterface": "extend"
    }
    responses = z_api_con.json_data(method, data, authid)
    return responses

#update proxyAgent manager of host
def proxyUpdate(method,hostid,authid):
    data = {
        "proxyid": 10255,              #proxyAgent id 
        "hosts": [
            hostid
        ]
    }
    responses = z_api_con.json_data(method, data, authid)
    return responses

def main_all(authid):
    #call text_process function
    lists = z_api_con.text_process('zabbix-agent-ip.txt')
    add_file = open("zabbix-process.txt","a+")
    for list in lists:
        rlist = re.split(r'\s+',list)
        ip = rlist[0]
        hostname = rlist[1]
        serverType = rlist[2]
        hostget = hostGet("host.get",ip,authid)["result"]
    #judge host whether exist,if exist will 'hostid' and 'host name' write file 'zabbix_process.txt'
        if hostget:
            print("info: " + ip + '  This host already exist!')
            hostid = hostget[0]["hostid"]
            host = hostget[0]["host"]
            add_file.writelines(hostid+"\t"+host+"\n")
    # else will ip write file 'zabbix_process.txt'
        else:
            print('info: Create host  ' + ip)
            hostcreate = hostCreate("host.create",ip,hostname,serverType,authid)
            add_file.writelines(ip+"\n")
    add_file.close()
    #file.close()


if __name__ == "__main__":
    starttime = time.time()
    print ("Process is running...")
    authid = z_api_con.authid('Admin', 'zabbix')
    main_all(authid)
    z_api_con.login_out(authid)
    endtime = time.time()
    print (endtime-starttime)
