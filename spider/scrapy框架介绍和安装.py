#scrapy框架介绍和安装
#scrapy框架专门用来实现爬虫的。为了爬取网站数据、提取结构性数据而编写的应用框架，
#用途非常广泛，框架的优势在于，用户只需要定制开发几个模块就可以轻松的实现一个爬虫。
#用来抓取网页内容以及各种图片，非常之方便。
#安装：pip install scrapy
# 制作 Scrapy 爬虫 一共需要4步：
# 新建项目 (scrapy startproject xxx)：新建一个新的爬虫项目
# 明确目标 （编写items.py）：明确你想要抓取的目标
# 制作爬虫 （spiders/xxspider.py）：制作爬虫开始爬取网页
# 存储内容 （pipelines.py）：设计管道存储爬取内容
##创建项目
# PS D:\Python\scrapy_project> scrapy startproject mySpider
# New Scrapy project 'mySpider', using template directory 'd:\programdata\anaconda3\lib\site-packages\scrapy\templates\project', created in:
#     D:\Python\scrapy_project\mySpider

# You can start your first spider with:
#     cd mySpider
#     scrapy genspider example example.com
# PS D:\Python\scrapy_project>
##下面来简单介绍一下各个主要文件的作用：
# scrapy.cfg ：项目的配置文件
# mySpider/ ：项目的Python模块，将会从这里引用代码
# mySpider/items.py ：项目的目标文件
# mySpider/pipelines.py ：项目的管道文件
# mySpider/settings.py ：项目的设置文件
# mySpider/spiders/ ：存储爬虫代码目录

##入门案例
#爬取url:http://www.htqyy.com/top/hot
#1. 把要爬取的目标确定下来并写到新建项目下的mySpider\mySpider\items.py中，例：
# import scrapy
# #定义目标数据的字段
# class MyspiderItem(scrapy.Item):
# 	title = scrapy.Field()  #歌曲名
# 	artist = scrapy.Field()  #艺术家
#2. 要在项目根目录下执行命令生成爬虫文件，就是我们要写爬虫的地方，目录在：mySpider\mySpider\spiders\musicSpider.py
#PS D:\Python\scrapy_project\mySpider> scrapy genspider musicSpider 'http://www.htqyy.com/'
# Created spider 'musicSpider' using template 'basic' in module:
#   mySpider.spiders.musicSpider
##mySpider\mySpider\spiders\musicSpider.py文件内容
# -*- coding: utf-8 -*-
# import scrapy
# class MusicspiderSpider(scrapy.Spider):
#     name = 'musicSpider'  #表示爬虫识别的名称,运行爬虫是需要指定这个名称
#     allowed_domains = ['http://www.htqyy.com/']  #表示能够爬取的范围,只允许爬取这个URL下的资源
#	  start_urls = ['http://www.htqyy.com/top/musicList/hot?pageIndex=0&pageSize=20']  #表示爬取的起始URL

#     def parse(self, response):  #这个response就是scrapy框架帮我们拿到的数据，我们只在编写爬虫在这个函数即可
#         pass
##入门案例2
###编写parse函数
## -*- coding: utf-8 -*-
# import scrapy
# class MusicspiderSpider(scrapy.Spider):
#     name = 'musicSpider'  #表示爬虫识别的名称
#     allowed_domains = ['http://www.htqyy.com/']  #表示能够爬取的范围
#     start_urls = ['http://www.htqyy.com/top/musicList/hot?pageIndex=0&pageSize=20']  #表示爬取的起始URL

#     def parse(self, response):
#         filename = 'music.html'  #不写根路径，文件是建立在项目的根路径下
#         data = response.body  #获取响应内容
#         open(filename,'wb').write(data)  #写入文件
#然后在mySpider项目的根目录下执行命令进行执行爬虫，例：
#cd scrapy_Project\mySpider;
#PS D:\Python\scrapy_project\mySpider> scrapy crawl musicSpider  #运行一个爬虫
#然后可以打开scrapy_Project\music.html了
##入门案例3:数据清洗
# -*- coding: utf-8 -*-
# import scrapy
# import re
# from lxml import etree
# from mySpider.items import MyspiderItem

# class MusicspiderSpider(scrapy.Spider):
#     name = 'musicSpider'  #表示爬虫识别的名称
#     allowed_domains = ['http://www.htqyy.com/']  #表示能够爬取的范围
#     start_urls = ['http://www.htqyy.com/top/musicList/hot?pageIndex=0&pageSize=20']  #表示爬取的起始URL

#     def parse(self, response):
#         data = response.body.decode()  #获取响应内容并解码
#         items = []  #存放音乐信息的列表
#         titles = re.findall(r'target="play" title="(.*?)" sid=',data)  #获取所有歌曲名
#         html = etree.HTML(data)  #获取所有艺术家
#         artists = html.xpath('//span[@class="artistName"]/a')
#         for i in range(0,len(titles)):
#         	item = MyspiderItem()  #item对象是dict类型
#         	item["title"] = titles[i]
#         	item["artist"] = artists[i].text
#         	items.append(item)
#         return items
###执行spider并输出为json格式文件
###PS D:\Python\scrapy_project\mySpider> scrapy crawl musicSpider -o my.json
#####最后新建解析json的python脚本进行解析
# import json

# with open(r"D:\Python\scrapy_project\mySpider\my.json","rb") as f:
# 	data = json.load(f)
# print(data)
###入门案例4：pipelines管道
#mySpider\mySpider\pipelines.py文件
#管理文件，负责item的后期处理或保存，yield item的对象会返回到这个类中
# class MyspiderPipeline(object):
# 	def __init__(self):  #定义一些需要初始化的参数(可以省略)
# 		self.file = open('music.txt','w')
		
#     def process_item(self, item, spider): #管理每次接收到item后执行的方法
#         return item

#     def close_spider(self,spider): #当爬取结束时执行的方法
#     	self.spider.close()
####入门案例5:管道的具体实现
#更改项目设置文件：mySpider\mySpider\settings.py
# #设置管道的优先级，0-1000，需要去除注释，这样才能使文件写入本地
# ITEM_PIPELINES = {
#    'mySpider.pipelines.MyspiderPipeline': 300,
# }
#管理文件，负责item的后期处理或保存，yield item的对象会返回到这个类中
# class MyspiderPipeline(object):
# 	def __init__(self):  #定义一些需要初始化的参数(可以省略)
# 		self.file = open('music.txt','a') #因为yield item不是一次性传完，所以使用追加

# 	def process_item(self, item, spider): #管理每次接收到item后执行的方法(必须实现)
# 		content = str(item)+"\n"
# 		self.file.write(content)  #写入数据到本地
# 		return item   #return item必须要有

# 	def close_spider(self,spider): #当爬取结束时执行的方法(可以省略)
# 		self.spider.close()
######6：利用scrapy自动翻页
# # -*- coding: utf-8 -*-
# import scrapy
# import re
# from lxml import etree
# from mySpider.items import MyspiderItem

# class MusicspiderSpider(scrapy.Spider):
#     name = 'musicSpider'  #表示爬虫识别的名称
#     allowed_domains = ['www.htqyy.com']  #表示能够爬取的范围
#     start_urls = ['http://www.htqyy.com/top/musicList/hot?pageIndex=0&pageSize=20']  #表示爬取的起始URL
#     def parse(self, response):
#         data = response.body.decode()  #获取响应内容并解码
#         # items = []  #存放音乐信息的列表
#         titles = re.findall(r'target="play" title="(.*?)" sid=',data)  #获取所有歌曲名
#         html = etree.HTML(data)  #获取所有艺术家
#         artists = html.xpath('//span[@class="artistName"]/a')
#         for i in range(0,len(titles)):
#             item = MyspiderItem()  #item对象是dict类型
#             item["title"] = titles[i]
#             item["artist"] = artists[i].text
#             yield item  #使用生成器去返回每一个对象dict,比使用列表返回所有dict更快速
#             # items.append(item)
#         # return items
#         #1.获取当前请求的url,提取出页码信息
#         beforeurl = response.url
#         pat = r"pageIndex=(\d)"
#         page = re.search(pat,beforeurl).group(1)
#         page = int(page)+1
#         #2.构造下一页url
#         if page < 5:
#             nexturl = "http://www.htqyy.com/top/musicList/hot?pageIndex="+str(page)+"&pageSize=20"
#             #yield关键字表示是一个生成器，使用回调函数调用parse(),并传入下一页url
#             yield scrapy.Request(nexturl,callback=self.parse) 
###7：scrapy 发送POST请求
# # -*- coding: utf-8 -*-
# import scrapy
# class YoudaoSpider(scrapy.Spider):
#     name = 'youdao'
#     allowed_domains = ['fanyi.youdao.com']
#     def start_requests(self): #start_urls变成start_requests请求了，因为这里是POST请求
#         url = "http://fanyi.youdao.com/translate?smartresult=dict&smartresult=rule"
#         yield scrapy.FormRequest( #执行POST请求对象方法
#         	url = url,
#         	formdata = {
# 		        "i": "你好",
# 				"from": "AUTO",
# 				"to": "AUTO",
# 				"smartresult": "dict",
# 				"client": "fanyideskweb",
# 				"salt": "15836715282289",
# 				"sign": "d931eac21fb068b7eb0e0e624dbedfa4",
# 				"ts": "1583671528228",
# 				"bv": "04578d470e7a887288dc80a9420e88ec",
# 				"doctype": "json",
# 				"version": "2.1",
# 				"keyfrom": "fanyi.web",
# 				"action": "FY_BY_REALTlME"
#             },
#             callback = self.parse #执行回调函数，回调函数中的response参数就是url和formdata POST请求所获取的响应
#         )

#     def parse(self, response):
#         print('---------------')
#         print(response.body)
##mySpider\settings.py
# Obey robots.txt rules
#ROBOTSTXT_OBEY = True #ROBOTSTXT_OBEY要设为false，注释就是false
###8：scrapy框架添加请求头
# # -*- coding: utf-8 -*-
# import scrapy
# import random
# class YoudaoSpider(scrapy.Spider):
#     name = 'youdao'
#     allowed_domains = ['fanyi.youdao.com']
#     def start_requests(self): #start_urls变成start_requests请求了，因为这里是POST请求
#         url = "http://fanyi.youdao.com/translate?smartresult=dict&smartresult=rule" #变量必须要定义在里面
#         UserAgents = [
#             "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
#             "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
#             "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
#         ]
#         UserAgent = random.choice(UserAgents)
#         headers = { "User-Agent": UserAgent }
#         yield scrapy.FormRequest( #执行POST请求对象方法
#             url = url,
#             headers = headers,
#             formdata = {
# 		        "i": "你好",
# 				"from": "AUTO",
# 				"to": "AUTO",
# 				"smartresult": "dict",
# 				"client": "fanyideskweb",
# 				"salt": "15836715282289",
# 				"sign": "d931eac21fb068b7eb0e0e624dbedfa4",
# 				"ts": "1583671528228",
# 				"bv": "04578d470e7a887288dc80a9420e88ec",
# 				"doctype": "json",
# 				"version": "2.1",
# 				"keyfrom": "fanyi.web",
# 				"action": "FY_BY_REALTlME"
#             },
#             callback = self.parse #执行回调函数，回调函数中的response参数就是url和formdata POST请求所获取的响应
#         )

#     def parse(self, response):
#         print('---------------')
#         print(response.body)
