#! /usb/bin/env python3.7
# -*- coding: utf-8 -*-
#9ku.com 'from singer download misic' spider
import requests
from lxml import etree
import re
import json
import os 
import random
import datetime

headers = [
    "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5",
    "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.835.163 Safari/535.1",
    "Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko",
    "Mozilla/5.0 (Linux; Android 8.1; PAR-AL00 Build/HUAWEIPAR-AL00; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/57.0.2987.132 MQQBrowser/6.2 TBS/044304 Mobile Safari/537.36 MicroMessenger/6.7.3.1360(0x26070333) NetType/WIFI Language/zh_CN Process/tools",
    "Mozilla/5.0 (Linux; Android 6.0.1; OPPO A57 Build/MMB29M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/63.0.3239.83 Mobile Safari/537.36 T7/10.13 baiduboxapp/10.13.0.10 (Baidu; P1 6.0.1)"
]

def get_singer_music_info(singer_url):
    singer_music_name = [] #歌手音乐名
    singer_music_url = []  #歌手音乐播放地址
    for i in range(0,len(singer_url)):
        userAgent = random.choice(headers)
        head = {"User-Agent": userAgent}
        response = requests.get(singer_url[i],headers=head).content.decode()
        html = etree.HTML(response)
        xpath1 = html.xpath('//div/div[@class="singerMusic clearfix"]/ol/li/div/a[@class="songNameA"]/*/text()') #ol[@id="fg"]
        xpath2 = html.xpath('//div/div[@class="singerMusic clearfix"]/ol/li/div/a[@class="songNameA"]/@href')
        singer_music_name.extend([xpath1])
        singer_music_url.extend([xpath2])
    return singer_music_name, singer_music_url

def get_singer_info(url): #返回歌手姓名和歌手详情页，类型都是list
    singer_name = [] #歌手姓名
    singer_url = [] #歌手URL 
    userAgent = random.choice(headers)
    head = {"User-Agent": userAgent}
    response = requests.get(url,headers=head).content.decode()
    html = etree.HTML(response)
    singer_name.extend(html.xpath('//li/a[@class="t-t"]/text()'))
    singer_url.extend( [ 'http://www.9ku.com' + i for i in html.xpath('//li/a[@class="t-t"]/@href') ] )
    return singer_name, singer_url

def download_music(singer_music_name,singer_music_url,singer_name,path):
    pat = re.compile(r'/play/(.*?).htm')
    num = 0  #歌曲序列
    down_url_q = 'http://www.9ku.com/html/playjs/'
    os.chdir(path)
    for i in range(0,len(singer_name)):
        if not os.path.isdir(singer_name[i]):
            os.mkdir(singer_name[i])
            print(datetime.datetime.now().strftime('%Y-%m-%d %H-%M-%S'),"开始下载歌手", singer_name[i], "的歌曲到" + path + '/' + singer_name[i], '\n')
            for j in range(0,len(singer_music_name[i])):
                try:
                    down_musicTITLE = singer_music_name[i][j]
                    id_pat = pat.findall(singer_music_url[i][j])
                    json_url_z = int(id_pat[0][0:3]) + 1
                    json_URL = down_url_q + str(json_url_z) + '/' + str(id_pat[0]) + '.js'
                    userAgent = random.choice(headers)
                    head = {"User-Agent": userAgent}
                    res = requests.get(json_URL,headers=head).text
                    str_to_json = json.loads(res[1:-1]) #裁剪json
                    down_musicURL = str_to_json["wma"]
                    data = requests.get(down_musicURL,head).content
                    num += 1
                    print(datetime.datetime.now().strftime('%Y-%m-%d %H-%M-%S'),"开始下载第"+ str(num) +"首:", down_musicTITLE + ".mp3")
                    with open(singer_name[i] + '/%s.mp3' % down_musicTITLE.replace('/','_'),'wb') as f:
                        f.write(data)
                except OSError as e:
                    result = re.findall(r'Errno (.*?)]',e)
                    if result == 28:
                        print(e)
                        print("磁盘空间不足")
                        exit(1)
                    else:
                        print(e)
            print(datetime.datetime.now().strftime('%Y-%m-%d %H-%M-%S'),singer_name[i] + '全部音乐下载完成' + '\n')
        else:
            print("此目录已存在", singer_name[i],'\n')

def main():
    path = 'd:/python/music/9ku_music/all_singer'
    for i in range(0,2):
        url = "http://www.9ku.com/geshou/all-all-all/" + str(i+1) + ".htm"
        singer_name, singer_url = get_singer_info(url)
        singer_music_name, singer_music_url = get_singer_music_info(singer_url)
        download_music(singer_music_name,singer_music_url,singer_name,path)
    print('全部音乐下载完成')

if __name__ == "__main__":
    main()











