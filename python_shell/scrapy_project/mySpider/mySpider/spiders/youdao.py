# -*- coding: utf-8 -*-
import scrapy
import random
class YoudaoSpider(scrapy.Spider):
    name = 'youdao'
    allowed_domains = ['fanyi.youdao.com']
    def start_requests(self): #start_urls变成start_requests请求了，因为这里是POST请求
        url = "http://fanyi.youdao.com/translate?smartresult=dict&smartresult=rule" #变量要定义在里面
        UserAgents = [
            "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
        ]
        UserAgent = random.choice(UserAgents)
        headers = { "User-Agent": UserAgent }
        yield scrapy.FormRequest( #执行POST请求对象方法
            url = url,
            headers = headers,
            formdata = {
		        "i": "你好",
				"from": "AUTO",
				"to": "AUTO",
				"smartresult": "dict",
				"client": "fanyideskweb",
				"salt": "15836715282289",
				"sign": "d931eac21fb068b7eb0e0e624dbedfa4",
				"ts": "1583671528228",
				"bv": "04578d470e7a887288dc80a9420e88ec",
				"doctype": "json",
				"version": "2.1",
				"keyfrom": "fanyi.web",
				"action": "FY_BY_REALTlME"
            },
            callback = self.parse #执行回调函数，回调函数中的response参数就是url和formdata POST请求所获取的响应
        )

    def parse(self, response):
        print('---------------')
        print(response.body)
