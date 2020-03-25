# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://docs.scrapy.org/en/latest/topics/item-pipeline.html


class SunspiderPipeline(object):
    def __init__(self):
        self.filename = open(r'sun.txt','a',encoding='utf-8')
    def process_item(self, item, spider): #返回的item对象到这里来，是dict类型
        content = str(item)+'\r\n'
        self.filename.write(content)
        return item  #这个必须要写

    
