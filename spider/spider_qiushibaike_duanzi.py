#spider qiushibaike duanzi
import requests
from lxml import etree
import re
import time

url = r'http://www.qiushibaike.net/index(2005).html'
headers = {
	"User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
	"Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8"
}
html = requests.get(url,headers=headers).content.decode('gbk')
Html = etree.HTML(html)
href = Html.xpath('//dd//a[@target="_blank"]/@href')
url2 = 'http://www.qiushibaike.net/'
pat = r'</a><br />(.*?)</h1>'
c = re.compile(pat)
for i in href:
	str = ''
	xurl = url2+i
	response = requests.get(xurl).content.decode('gbk')
	h = etree.HTML(response)
	result = h.xpath('//div[@class="content"]/p')
	title = re.findall(c,response)
	str = str + title[0].center(250)+"\n"  #string1.rjust(50)  string1.ljust(50)
	for j in range(0,len(result)):
		str = str + result[j].text
	print("正在写入 "+title[0]+'.txt')
	with open('d:/text/'+title[0]+'.txt','wb') as f:
		f.write(str.encode())
	time.sleep(0.5)
print("全部爬取完成!")
