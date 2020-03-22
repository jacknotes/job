#spider photo for baidutieba
import urllib
from urllib import request
from lxml import etree

# https://tieba.baidu.com/f?kw=java
# https://tieba.baidu.com/f?kw=java&pn=50
# https://tieba.baidu.com/f?kw=java&pn=100

# <div class="threadlist_lz clearfix">
#                 <div class="threadlist_title pull_left j_th_tit ">
#     <a rel="noreferrer" href="/p/6537990679" title="咋了，这是啥鬼？" target="_blank" class="j_th_tit ">咋了，这是啥鬼？</a>

# <img class="BDE_Image" pic_type="0" width="560" height="212" src="http://tiebapic.baidu.com/forum/w
# %3D580/sign=48ea3e6eaf0e7bec23da03e91f2fb9fa/737bfa1f3a292df591158674ab315c6035a87316.jpg" size="41508" style="cursor: url(&quot;http://tb2.bdstatic.com/tb/static-pb/img/cur_zin.cur&quot;), pointer;">

class Spider(object):
	def __init__(self,tiebaName,beginPage,endPage):
		self.tiebaName = tiebaName
		self.beginPage = beginPage
		self.endPage = endPage
		self.url = "http://tieba.baidu.com/f?"
		#用IE9.0用户代理可以规避服务器的反爬虫，之前使用谷歌浏览器的用户代理始终xpath不到数据。原因就在这
		self.ua_header = {"User-Agent" : "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1 Trident/5.0;"}
		self.filename = 1

	#构造url
	def tiebaSpider(self):
		for page in range(self.beginPage,self.endPage+1):
			pn = (page-1)*50
			word = {"pn":pn,"kw":self.tiebaName}
			encodeWord = urllib.parse.urlencode(word)
			url = self.url + encodeWord
			self.loadPage(url)

	#爬取页面内容
	def loadPage(self,url):
		req = request.Request(url,headers=self.ua_header)
		data = request.urlopen(req).read()
		html = etree.HTML(data)
		tz = html.xpath('//div[@class="threadlist_lz clearfix"]/div/a/@href')
		for i in tz:
			tzUrl = "http://tieba.baidu.com" + i
			self.loadImages(tzUrl)

	#爬取帖子详情页,获得图片的链接
	def loadImages(self,tzUrl):
		req = request.Request(tzUrl,headers=self.ua_header)
		data = request.urlopen(req).read()
		html = etree.HTML(data)
		imageUrls = html.xpath('//img[@class="BDE_Image"]/@src')
		for imageUrl in imageUrls:
			self.saveImage(imageUrl)

	#保存图片到本地
	def saveImage(self,imageUrl):
		print("正在保存图片：",str(self.filename)+".jpg.....")
		imagedata = request.urlopen(imageUrl).read()
		file = open('d:/python/photo/'+str(self.filename)+".jpg",'wb')
		file.write(imagedata)
		file.close()
		self.filename  += 1

if __name__ == '__main__':
	tiebaName = input("请输入贴吧名称：")
	beginPage = int(input("请输入开始页数："))
	endPage = int(input("请输入结束页数："))
	mySpider=Spider(tiebaName,beginPage,endPage)
	mySpider.tiebaSpider()