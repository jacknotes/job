-----------
#xpath介绍和lxml安装 
#xpath只能处理html,处理起来很简单。正则表达式什么文字都可以处理。较复杂。
#xpath:先将HTML文件转换成XML文档。然后用xpath查找HTML节点或元素。
#我们需要安装lxml模块来支持xPath的操作
#pip install lxml  #安装lxml以支持xpath
text = '''
     					<li><a href="/List.aspx?cid=14">室内设计</a></li>
                        <li><a href="/List.aspx?cid=390">室外设计</a></li>
                        <li><a href="/List.aspx?cid=28">影视动画</a></li>
                        <li><a href="/List.aspx?cid=35">机械设计</a></li>
                        <li><a href="/List.aspx?cid=471">工业自动</a></li>
                        <li><a href="/List.aspx?cid=451">程序开发</a></li>
                        <li><a href="/List.aspx?cid=18">网页设计</a>
'''
from lxml import etree
html = etree.HTML(text) #把html文档转换成etree类
print(type(html))  #html是一个etree类，便以使用xpath处理
result = etree.tostring(html,encoding='utf-8').decode() #将etree类再转换成字符串，就是序列化
print(result)
-----------
#解析本地html
#爬虫中页面处理方式：
#1，在爬虫中，数据获取和数据清洗一体，HTML()
#2，数据获取和数据清洗分开，parse()
from lxml import etree 
#获取本地html文档
html = etree.parse(r"d:\file\hello.html")
result = etree.tostring(html,encoding='utf-8').decode()
print(result)
-----------
#获取html中指定标签数组内容
from lxml import etree
#获取本地html文档
html = etree.parse(r"d:\file\hello.html")
result = html.xpath("//a")  #查找所有a标签的内容，返回结果是一个list
print(result[0].text) #打印result列表第一个数据
-----------
#获取指定属性的标签
from lxml import etree
html = etree.parse(r"d:\file\hello.html")
result = html.xpath("//li/a[@href='link2.html']") #获取li标签中的a标签中的属性为href='link2.html'的内容
print(result[0].text) #结果是个list
-----------
#通过标签获取属性信息
from lxml import etree
html = etree.parse(r"d:\file\hello.html")
result = etree.xpath("//li/a/@href")  #攻取li标签中属性是class的值
for i in result:   #通过for循环来获取所有a标签中链接的内容
	requests.get(i)
-----------
#获取子标签
#主要用法区别是在于//和/,//表示多级的意思，/表示单级的意思
from lxml import etree
html = etree.parse(r"d:\file\hello.html")
result1 = html.xpath("//li/a")  #获取li标签下一组长a标签所有的内容
result2 = html.xpath("//li//span") #获取li标签中所有(包括多级子标签)span标签的内容
print(result2)
result3 = html.xpath("//li/a/@class") #获取li标签的下一级a标签的所有（不包括多级子标签）class属性的值
result4 = html.xpath("//li/a//@class") #获取li标签下一组a标签中所有（包括多级子标签）class属性的值
print(result4)
-----------
#获取标签内容和标签名
from lxml import etree
html = etree.parse(r"d:\file\hello.html")
# result = html.xpath("//li[last()-1]/a")  #[last()-1] 倒数第二个li标签a标签的值
# print(result[0].text)
result1 = html.xpath("//li/a")  
print(result1[-2].text) #倒数第二个值
#获取class值为bold的标签名
result2 = html.xpath("//*[@class='bold']")
print(result2[0].tag)  #.tag表示获取标签名，.text表示获取标签内容
-----------
#爬取网络段子
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
-----------

-----------

-----------