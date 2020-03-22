#requests POST方法
import requests
import re
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
response = requests.request("post",url,headers=headers,data=formdata)
pat = r'"tgt":"(.*?)"}]]}'
result = re.findall(pat,response.text)
print(result)