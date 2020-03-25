#spider的异常处理
from urllib import request
list1 = [
	"http://www.baidu.com/",
	"http://www.baidu.com/",
	"http://www.bajackliskldfidu.com/",
	"http://www.baidu.com/",
	"http://www.baidu.com/",
]
i = 0
for url in list1:
	i=i+1
	try:
		request.urlopen(url)
	except Exception as e:
		print(e)
	finally:
		print("第"+str(i)+"次请求")
