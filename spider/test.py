import requests 
import base64
import re
# client_id 为官网获取的AK， client_secret 为官网获取的SK
host = 'https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=5oicld6LaNbN0OxpUDmxcy1i&client_secret=f3pS8ouVibUta5hDruRXRsTfhxS3IZWO'
response = requests.get(host)
token = response.json()["access_token"]
request_url = "https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic"
# 二进制方式打开图片文件
f = open('d:/python/test/2.jpg', 'rb')
img = base64.b64encode(f.read())
params = {"image":img}
access_token = token
request_url = request_url + "?access_token=" + access_token
headers = {'content-type': 'application/x-www-form-urlencoded'}
response = requests.post(request_url, data=params, headers=headers)
list1 = response.json()["words_result"]
for i in range(0,len(list1)):
	print(list1[i]["words"].replace(' ',''))