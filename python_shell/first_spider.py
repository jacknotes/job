import urllib.request
#from urllib import request
import re
import random

url = r'http://www.baidu.com/'
Agent1='Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36'
Agent2='Mozilla/5.0 (Linux; U; Android 8.1.0; zh-cn; BLA-AL00 Build/HUAWEIBLA-AL00) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/57.0.2987.132 MQQBrowser/8.9 Mobile Safari/537.36'
Agent3='Mozilla/5.0 (Linux; Android 6.0.1; OPPO A57 Build/MMB29M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/63.0.3239.83 Mobile Safari/537.36 T7/10.13 baiduboxapp/10.13.0.10 (Baidu; P1 6.0.1)'
Agent4='Mozilla/5.0 (Linux; Android 8.1; EML-AL00 Build/HUAWEIEML-AL00; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/53.0.2785.143 Crosswalk/24.53.595.0 XWEB/358 MMWEBSDK/23 Mobile Safari/537.36 MicroMessenger/6.7.2.1340(0x2607023A) NetType/4G Language/zh_CN'
Agent5='Mozilla/5.0 (Linux; U; Android 4.1.2; zh-cn; HUAWEI MT1-U06 Build/HuaweiMT1-U06) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 baiduboxapp/042_2.7.3_diordna_8021_027/IEWAUH_61_2.1.4_60U-1TM+IEWAUH/7300001a/91E050E40679F078E51FD06CD5BF0A43%7C544176010472968/1'

List1=[Agent1,Agent2,Agent3,Agent4,Agent5]
#随机选择一个User-Agent
Agent = random.choice(List1) 
print(Agent)
header={
	"User-Agent": Agent 
}
#创建自定义请求对象，可以传入Cooking,User-Agent等信息，可以对抗反爬机制
#反爬虫机制1：判断用户是否是浏览器访问
#应对机制：可以通过伪装浏览器进行访问
req = urllib.request.Request(url,headers=header)

#发送请求,读取响应信息,解码
response = urllib.request.urlopen(req).read().decode('utf-8')  
#正则匹配
pat = r'<title>(.*?)</title>'
#使用正则查找解码的响应信息
data = re.findall(pat,response)
print(data[0])