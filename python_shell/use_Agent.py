#反爬虫机制2： 判断请求来源的ip地址
#应对机制：使用代理ip地址
#找代理ip，例如：百度搜索代理Ip

#ip:118.81.45.29:9797	

from urllib import request
import random

#构建代理ip列表
proxyList = [
	{"http": "118.81.45.29:9797"},
	{"http": "118.81.45.29:9797"}
]
#随机选择一个代理ip
proxy = random.choice(proxyList)

#构建代理处理器对象
proxy_handler = request.ProxyHandler(proxy)
#创建自定义opener(可以传入proxy处理器对象/http处理器对象)
opener = request.build_opener(proxy_handler)

req = request.Request("http://www.baidu.com/")
#设置全局opener
request.install_opener(opener)

response = request.urlopen(req).read().decode('utf-8')

print(response)
