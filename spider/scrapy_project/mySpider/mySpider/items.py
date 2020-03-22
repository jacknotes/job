# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# https://docs.scrapy.org/en/latest/topics/items.html

import scrapy

#定义目标数据的字段
class MyspiderItem(scrapy.Item):
	title = scrapy.Field()  #歌曲名
	artist = scrapy.Field()  #艺术家
