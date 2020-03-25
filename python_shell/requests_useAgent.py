#requests模块使用代理IP
import requests
#注意：urllib.request模块中代理ip变量是个数组，requests模块则是个字典
proxyList = {
	"http": "118.81.45.29:9797",
	"http": "118.81.45.29:9797"
}
response = requests.request("get","http://www.baidu.com",proxies=proxyList)
print(response.content.decode())