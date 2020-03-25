#requests模块获取cookiejar
import requests
response = requests.get("http://www.baidu.com")

#1.获取返回的cookiejar对象，包含了cookie信息，打印出来不对直接使用
cookiejar = response.cookies
#2.将cookiejar转换成字典形式
cookiedict = requests.utils.dict_from_cookiejar(cookiejar)
print(cookiejar)
print(cookiedict)  #获取响应的信息