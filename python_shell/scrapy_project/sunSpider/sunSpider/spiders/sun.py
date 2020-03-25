# -*- coding: utf-8 -*-
import scrapy
from sunSpider.items import SunspiderItem

class SunSpider(scrapy.Spider):
    name = 'sun'
    allowed_domains = ['wz.sun0769.com']
    url = 'http://wz.sun0769.com/political/index/politicsNewest?id=1&page='
    offset = 1
    start_urls = [url+str(offset)]

    def parse(self, response):
        url2 = 'http://wz.sun0769.com'
        links = response.xpath('//a[@class="color-hover"]/@href').extract() #提取链接,返回类型list
        for link in links:
            #请求详情页链接获取response并最后传入到self.parse_item函数处理数据
            yield scrapy.Request(url2 + link,callback=self.parse_item) 
        if self.offset <= 5:
            self.offset += 1
            #翻页url放到回调函数self.parse中，然后继续获取详情页URL
            yield scrapy.Request(self.url+str(self.offset),callback=self.parse)
    # 爬取帖子内容
    def parse_item(self,response):
        item = SunspiderItem()
        #url
        item["url"] = response.url
        #标题
        item["title"] = response.xpath('//p[@class="focus-details"]/text()').extract()[0]
        #内容
        item["content"] = "".join(response.xpath('//div[@class="details-box"]/pre/text()').extract())
        yield item