#!/usr/bin/env python3
#filename: zabbixBaseAPI.py
#author: jack
#datetime:20200419

import json
import urllib.request 

class zabbixBaseAPI(object):
    def __init__(self,url = "http://127.0.0.1:8081/zabbix/api_jsonrpc.php" ,header = {"Content-Type": "application/json"}):
        self.url = url
        self.header = header

    # post request
    def post_request(self,url, data, header):
        request = urllib.request.Request(url, data, header) 
        result = urllib.request.urlopen(request)
        response = json.loads(result.read())
        result.close()
        return response

    # json data process
    def json_data(self,method,params,authid):
        data = json.dumps(
        {
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "auth": authid,
            "id": 1
        })
        request_info = self.post_request(self.url, data.encode('utf-8'), self.header)
        return request_info

    # login authentication 
    def authid(self,user,password): 
        data = json.dumps(
        {
            "jsonrpc": "2.0",
            "method": "user.login",
            "params": {
                "user": user,
                "password": password
            },
            "id": 1
        })
        authid = self.post_request(self.url, data.encode('utf-8'), self.header)
        try:
            return authid['result']
            print('认证成功')
        except KeyError:
            print ('认证失败,用户名或密码错误')
            exit()

    #ip file process
    def text_process(self,file):
        import re
        find = re.compile(r"^#")
        text_info = []
        f = open(file, "r")
        text = f.readlines()
        f.close()
        for i in text:
           t = i.strip()
           if len(t) >= 6:
              if find.search(t.rstrip("\n")) == None:
                text_info.append(t.rstrip("\n"))
        return text_info

    # logout authentication
    def login_out(self,authid):
        data = json.dumps(
        {
            "jsonrpc": "2.0",
            "method": "user.logout",
            "params": [],
            "id": 1,
            "auth": authid
        })
        a = self.post_request(self.url, data.encode('utf-8'), self.header)
        return '认证信息已注销'
