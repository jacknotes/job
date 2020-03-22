# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# https://docs.scrapy.org/en/latest/topics/items.html

import scrapy


class SunspiderItem(scrapy.Item):
    #标题
    title = scrapy.Field()
    #内容 
    content = scrapy.Field()
    #url地址
    url = scrapy.Field()
