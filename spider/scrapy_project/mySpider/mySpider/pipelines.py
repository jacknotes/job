# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://docs.scrapy.org/en/latest/topics/item-pipeline.html

#管理文件，负责item的后期处理或保存，yield item的对象会返回到这个类中
class MyspiderPipeline(object):
	def __init__(self):  #定义一些需要初始化的参数(可以省略)
		self.file = open('music.txt','a') #因为yield item不是一次性传完，所以使用追加

	def process_item(self, item, spider): #管理每次接收到item后执行的方法(必须实现)
		content = str(item)+"\n"
		self.file.write(content)  #写入数据到本地
		return item   #return item必须要有

	# def close_spider(self, spider): #当爬取结束时执行的方法(可以省略)
	# 	self.spider.close()
