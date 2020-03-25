#爬取豆瓣电影排行榜
import urllib.request
import re
headers = {
	"User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
}
url = "https://movie.douban.com/j/chart/top_list?type=11&interval_id=100%3A90&action=&start=0&limit=20"
req = urllib.request.Request(url,headers=headers)
response = urllib.request.urlopen(req).read().decode()
#"rating":["9.7","50"]
#"title":"肖申克的救赎"
pat1 = r'"rating":\["(.*?)","\d+"\]'
pat2 = r'"title":"(.*?)"'
pettern1 = re.compile(pat1,re.I)
pettern2 = re.compile(pat2,re.I)
data1 = pettern1.findall(response)
data2 = pettern2.findall(response)
for i in range(0,len(data2)):
	print("排名:",i+1,"电影名:",data2[i],"豆瓣评分:",data1[i])
