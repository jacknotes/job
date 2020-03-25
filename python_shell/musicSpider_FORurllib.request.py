#musicSpider for requests METHOD --use proxy
import requests
import re
import time
import random
#第一页    
#http://www.htqyy.com/top/musicList/hot?pageIndex=0&pageSize=20
#第二页
#http://www.htqyy.com/top/musicList/hot?pageIndex=1&pageSize=20
#第三页
#http://www.htqyy.com/top/musicList/hot?pageIndex=2&pageSize=20
#歌曲URL
#http://www.htqyy.com/play/33
#http://f2.htqyy.com/play7/33/mp3/3
#正则匹配URL： target="play" title="牧羊曲" sid="108">
#临时url
#http://www.htqyy.com/genre/musicList/5?pageIndex=1&pageSize=20&order=hot
pageurl1= "http://www.htqyy.com/genre/musicList/5?pageIndex="
pageurl2= "&pageSize=20&order=hot"
downurl1="http://f2.htqyy.com/play7/"
downurl2="/mp3/3"
songName = []
songID = []
proxyList = {
	"http": "116.196.85.166:3128",
	# "http": "119.237.73.133:3128"
}
spage = int(input("开始爬取的页数："))
page = int(input("最终爬取的页数："))
for i in range(spage-1,page):
	url = pageurl1 + str(i) + pageurl2
	#print(url)
	strr = requests.request("get",url,proxies=proxyList).text
	pat1 = r'target="play" title="(.*?)" sid='
	pat2 = r'" sid="(.*?)"'
	titlelist = re.findall(pat1,strr)
	sidlist = re.findall(pat2,strr)
	songName.extend(titlelist)
	songID.extend(sidlist)
#print(songName,songID)
for i in range(0,len(songID)):
	songurl = downurl1+str(i)+downurl2
	songmingzi = songName[i]
	data = requests.request("get",songurl,proxies=proxyList).content
	if (i+1) % 50 == 0:
		print("睡眠5秒")
		time.sleep(5)
	print("正在下载第"+str(i+1)+"首",songmingzi+".mp3")
	with open("d:/python/music/china_music/{}.mp3".format(songmingzi),"wb") as f:
		f.write(data)
	#time.sleep(0.5)
print("全部下载完成")
