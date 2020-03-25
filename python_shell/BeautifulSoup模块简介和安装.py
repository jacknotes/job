#BeautifulSoup模块简介和安装
#功能和lxml的xpath()用法一样，用来解析html和xml数据,css样式表，重点关注html
#pip install beautifulsoup4

from bs4 import BeautifulSoup
import re

html = """
<html><head><title>The Dormouse's story</title><title>The Dormouse's story2</title></head>
<body>
<p class="title" name="dromouse"><b>The Dormouse's story</b><b>The Dormouse's story2</b></p>
<p class="story">Once upon a time there were three little sisters; and their names were
<a href="http://example.com/elsie" class="sister" id="link1"><!-- Elsie --></a>,
<a href="http://example.com/lacie" class="sister" id="link2">Lacie</a> and
<a href="http://example.com/tillie" class="sister" id="link3">Tillie</a>;
and they lived at the bottom of a well.</p>
<p class="story" id="link1">...</p>
"""
#解析字符串形式的html
# soup = BeautifulSoup(html,'lxml') #会自动补全html的基础语法错误，底层还是lxml
#print(soup.prettify())  #让soup对象内容格式化输出

#解析本地html文件
#soup2 = BeautifulSoup(open('index.html'))
#---------
# soup = BeautifulSoup(html,'lxml')
#用BeautifulSoup4 解析字符串形式的html
# print(soup.title) #获取soup对象的整个title
# print(soup.title.string)  #获取soup对象的title内容
# print(soup.title.name)  #通过标签名获取标签名，比较鸡肋
# print(soup.p.attrs['name']) #获取第一个p标签内所有属性
# print(soup.head.contents) #获取指定标签的所有内容，以标签为隔为list
# print(soup.head.children)  #返回的是一个迭代器列表,以标签为一组数据
# for i in soup.head.children:
# 	print(i)
# print(soup.p.descendants)  #返回结果是生成器对象,遍历内容和标签、内容
# for i in soup.p.descendants:
# 	print(i)
# --------
#搜索文档树
#实际就是find_all()方法
#搜索所有a标签，返回结果是bs4.element.resultSet(结果集),里面是标签对象
# data = soup.find_all('a')
# print(type(data[0])) #返回的是bs4.element.Tag,标签对象
# for i in data:
# 	print(i)  #遍历所有标签对象，使用i.string可以输出标签对象内容
# --------
#根据正则表达式查找标签
# soup = BeautifulSoup(html,'lxml')
# data = soup.find_all(re.compile('^b'))
# for i in data:
# 	print(i.string)
#根据属性查找标签
# data = soup.find_all(id='link2')
# for i in data:
# 	print(i)
#根据内容查找标签
#text表示是查找内容，内容类型是列表，也可以用正则表达式查找内容
# data = soup.find_all(text='Tillie')  
# data2 = soup.find_all(text=re.compile('Do')) #利用正则表达式查找
# for i in data2:
# 	print(i)
# --------
#CSS选择器
#主要用select()方法
#CSS选择器类型：标签选择器，类选择器，id选择器
soup = BeautifulSoup(html,'lxml')
#标签选择器
# data = soup.select('a') #返回结果是list
# for i in data:
# 	print(i)
#类选择器
# data = soup.select('.sister') #.表示类查找
# for i in data:
# 	print(i)
#id选择器
# data = soup.select('p#link1') #查找p标签相id=link1的结果
# for i in data:
# 	print(i)
#通过其他属性查找
data = soup.select('a[href="http://example.com/elsie"]')
for i in data:
	print(i)
# -----------