# -*- coding: utf-8 -*-
import scrapy
import re
from lxml import etree
from mySpider.items import MyspiderItem

class MusicspiderSpider(scrapy.Spider):
    name = 'musicSpider'  #表示爬虫识别的名称
    allowed_domains = ['www.htqyy.com']  #表示能够爬取的范围
    start_urls = ['http://www.htqyy.com/top/musicList/hot?pageIndex=0&pageSize=20']  #表示爬取的起始URL
    def parse(self, response):
        data = response.body.decode()  #获取响应内容并解码
        # items = []  #存放音乐信息的列表
        titles = re.findall(r'target="play" title="(.*?)" sid=',data)  #获取所有歌曲名
        html = etree.HTML(data)  #获取所有艺术家
        artists = html.xpath('//span[@class="artistName"]/a')
        for i in range(0,len(titles)):
            item = MyspiderItem()  #item对象是dict类型
            item["title"] = titles[i]
            item["artist"] = artists[i].text
            yield item  #使用生成器去返回每一个对象dict,比使用列表返回所有dict更快速
            # items.append(item)
        # return items
        #1.获取当前请求的url,提取出页码信息
        beforeurl = response.url
        pat = r"pageIndex=(\d)"
        page = re.search(pat,beforeurl).group(1)
        page = int(page)+1
        #2.构造下一页url
        if page < 5:
            nexturl = "http://www.htqyy.com/top/musicList/hot?pageIndex="+str(page)+"&pageSize=20"
            #yield关键字表示是一个生成器，使用回调函数调用parse(),并传入下一页url
            yield scrapy.Request(nexturl,callback=self.parse)   #执行回调函数，回调函数中的response参数就是url GET请求所获取的响应