#requests GET方法
import requests
headers = {
	"User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 \
	(KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
}
wd = {"wd":"中国"}
#get方法获取url,.text是返回一个字符串形式(unicode)的数据,.content是返回一个二进制形式的数据
#params参数可以直接使用不用编码，但在urllib.request中则需要编码拼凑
response = requests.get("https://www.baidu.com/s?",params=wd,headers=headers)\
print(response.content.decode())


