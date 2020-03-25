#处理POST请求，如果Request()方法里面有data参数，那么这个请求是POST，否则是GET
from urllib import request
import urllib
import re

#http://fanyi.youdao.com/translate_o?smartresult=dict&smartresult=rule

key = "你好"
url = "http://fanyi.youdao.com/translate?smartresult=dict&smartresult=rule"
headers = {
	"User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
}

formdata={
	"i": key,
	"from": "AUTO",
	"to": "AUTO",
	"smartresult": "dict",
	"client": "fanyideskweb",
	"salt": "15836715282289",
	"sign": "d931eac21fb068b7eb0e0e624dbedfa4",
	"ts": "1583671528228",
	"bv": "04578d470e7a887288dc80a9420e88ec",
	"doctype": "json",
	"version": "2.1",
	"keyfrom": "fanyi.web",
	"action": "FY_BY_REALTlME"
}

data = urllib.parse.urlencode(formdata).encode('utf-8')
req = request.Request(url,data=data,headers=headers)
response = request.urlopen(req).read().decode('utf-8')
pat = r'"tgt":"(.*?)"}]]'
result = re.findall(pat,response)
print(result[0])