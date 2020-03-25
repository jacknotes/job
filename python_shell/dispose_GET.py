#URL编码

from urllib import request
import urllib

#https://www.baidu.com/s?wd=%E5%8C%97%E4%BA%AC

wd = {"wd": "北京"}
url="https://www.baidu.com/s?"
#对wd进行url编码
wdd = urllib.parse.urlencode(wd)
url = url+wdd
req = request.Request(url)

http_handler = request.HTTPHandler()
opener = request.build_opener(http_handler)
request.install_opener(opener)
response = request.urlopen(req).read().decode('utf-8')
print(response)