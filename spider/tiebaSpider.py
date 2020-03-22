from urllib import request
import urllib 
import time

#https://tieba.baidu.com/f?kw=python&ie=utf-8&pn=0 第一页 (0-1)*50
#https://tieba.baidu.com/f?kw=python&ie=utf-8&pn=50 第二页 (2-1)*50
#https://tieba.baidu.com/f?kw=python&ie=utf-8&pn=100 第三页 (3-1)*50

headers = {
	"User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
}

def loadPage(fullurl,filename):
	print("now download", filename)
	req = request.Request(fullurl,headers=headers)
	response = request.urlopen(req).read()
	return response

def writePage(html,filename):
	print("now save", filename)
	with open(filename,'wb') as f:
		f.write(html)
	print("-------------------")

def tiebaSpider(url,startPage,endPage,kw):
	for i in range(startPage,endPage+1):
		pn = (i-1)*50
		fullurl = url + "&pn=" + str(pn)
		filename = "d:/" + kw + "第" + str(i) + "页.html"
		html = loadPage(fullurl,filename)
		writePage(html,filename)

if __name__ == "__main__":
	kw = input('请输入贴吧名称:')
	startPage = int(input('请输入起始页:'))
	endPage = int(input('请输入结束页:'))
	url = r"https://tieba.baidu.com/f?"
	key = urllib.parse.urlencode({"kw": kw})
	url = url+key

	tiebaSpider(url,startPage,endPage,kw)