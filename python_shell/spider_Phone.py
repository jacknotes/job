#爬取电话号码
import requests
import re
headers = {
	"User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
}
response = requests.get("https://changyongdianhuahaoma.51240.com/",headers=headers).text
pat1 = r'<tr bgcolor="#EFF7F0">[\s\S]*?<td>(.*?)</td>[\s\S]*?<td>[\s\S]*?</td>[\s\S]*?</tr>'
pat2 = r'<tr bgcolor="#EFF7F0">[\s\S]*?<td>[\s\S]*?</td>[\s\S]*?<td>(.*?)</td>[\s\S]*?</tr>'
pattern1 = re.compile(pat1)
pattern2 = re.compile(pat2)
data1 = pattern1.findall(response)
data2 = pattern2.findall(response)
resultList = []
for i in range(0,len(data1)):
	resultList.append(data1[i]+data2[i])
print(resultList)