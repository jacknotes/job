#! /usb/bin/env python
# -*- coding: utf-8 -*-
#9ku.com spider
import requests
from lxml import etree
import re
import json
import os 
import random
import time
"""
http://www.9ku.com/
<a title="今生爱上你" target="_1" href="/play/514192.htm" class="songName ">今生爱上你</a>
网络歌曲TOP60
f101
f102
2020抖音热歌
f103
新歌推荐
f1
好歌推荐120首
f104
f105
f106
f107
http://www.9ku.com/html/playjs/570/569801.js
"""
#板块分布
wlgqTOP60 = ['f101','f102']
dyrg = ['f103']
xgtj = ['f1']
hgtj120 = ['f104','f105','f106','f107']

ids = [] #所选板块id集合
flag = True
file_title = ''
while flag:
    gqxl = input('''
    1. 网络歌曲TOP60 请按‘1’
    2. 2020抖音热歌 请按‘2’
    3. 新歌推荐 请按‘3’
    4. 好歌推荐120首 请按‘4’
    ''')
    if gqxl == '1':
        ids.append(wlgqTOP60)
        file_title = file_title + '网络歌曲TOP60'
        flag = False
    elif gqxl == '2':
        ids.append(dyrg)
        file_title = file_title + '2020抖音热歌'
        flag = False
    elif gqxl == '3':
        ids.append(xgtj)
        file_title = file_title + '新歌推荐'
        flag = False
    elif gqxl == '4':
        ids.append(hgtj120)
        file_title = file_title + '好歌推荐120首'
        flag = False
    else:
        print("选择错误,重新选择")
        continue    
path = file_title
os.chdir('d:/python/music/9ku_music')
if not os.path.isdir(file_title):
    os.mkdir(path) 
url = "http://www.9ku.com/"
headers = [
    "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5",
    "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.835.163 Safari/535.1",
    "Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko",
    "Mozilla/5.0 (Linux; Android 8.1; PAR-AL00 Build/HUAWEIPAR-AL00; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/57.0.2987.132 MQQBrowser/6.2 TBS/044304 Mobile Safari/537.36 MicroMessenger/6.7.3.1360(0x26070333) NetType/WIFI Language/zh_CN Process/tools",
    "Mozilla/5.0 (Linux; Android 6.0.1; OPPO A57 Build/MMB29M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/63.0.3239.83 Mobile Safari/537.36 T7/10.13 baiduboxapp/10.13.0.10 (Baidu; P1 6.0.1)"
]
userAgent = random.choice(headers)
head = {"User-Agent": userAgent}
response = requests.get(url,headers=head).content.decode()
html = etree.HTML(response)
xpath_title_list = []
xpath_url_list = []
for i in ids[0]:
    xpath_title_list.extend(html.xpath('//div[@id="' + i + '"]/ul/li//a[@class="songName" or @class="songName "]/text()'))
    xpath_url_list.extend(html.xpath('//div[@id="' + i + '"]/ul/li//a[@class="songName" or @class="songName "]/@href'))

pat = re.compile(r'/play/(.*?).htm')
list1 = []
num = 0  #歌曲序列
down_url_q = 'http://www.9ku.com/html/playjs/'

for i in xpath_url_list:
    list1.append(pat.findall(i))

for j in range(0,len(xpath_title_list)):
    try:
        down_musicTITLE = xpath_title_list[j]
        json_url_z = int(list1[j][0][0:3]) + 1
        json_URL = down_url_q + str(json_url_z) + '/' + str(list1[j][0]) + '.js'
        res = requests.get(json_URL).text
        str_to_json = json.loads(res[1:-1])
        down_musicURL = str_to_json["wma"]
        data = requests.get(down_musicURL,headers=head).content
        print(head)
        num += 1
        print("开始下载第"+ str(num) +"首: " + down_musicTITLE + ".mp3")
        with open(file_title + '/%s.mp3' % down_musicTITLE,'wb') as f:
            f.write(data)
    except Exception as e:
        print(e)
print('全部音乐下载完成')



