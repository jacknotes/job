#! /usb/bin/env python
# -*- coding: utf-8 -*-
#9ku.com douyin spider
import requests
from lxml import etree
import re
import json
import os 
import random
 
path = '抖音1'
os.chdir('d:/python/music/9ku_music')
if not os.path.isdir(path):
    os.mkdir(path) 
url = "http://www.9ku.com/douyin/"
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
xpath_title_list.extend(html.xpath('//a[@class="songName " or @class="songName"]/text()'))
xpath_title_list.extend(html.xpath('//ul[@class="rankR rankRmusic clearfix" or @class="rankR clearfix"]/li/a/text()'))
xpath_url_list.extend(html.xpath('//a[@class="songName " or @class="songName"]/@href'))
xpath_url_list.extend(html.xpath('//ul[@class="rankR rankRmusic clearfix" or @class="rankR clearfix"]/li/a/@href'))
# print(xpath_title_list)
# print(xpath_url_list)
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
        userAgent = random.choice(headers)
        head = {"User-Agent": userAgent}
        res = requests.get(json_URL,headers=head).text
        print(head)
        str_to_json = json.loads(res[1:-1])
        down_musicURL = str_to_json["wma"]
        data = requests.get(down_musicURL).content
        num += 1
        print("开始下载第"+ str(num) +"首:", down_musicTITLE + ".mp3")
        with open(path + '/%s.mp3' % down_musicTITLE,'wb') as f:
            f.write(data)
    except Exception as e:
        print(e)
print('全部音乐下载完成')



