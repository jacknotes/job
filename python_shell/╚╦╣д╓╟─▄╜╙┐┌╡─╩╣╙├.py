#人工智能接口的使用
#识别图片文字
#注册百度AI智能 识别通用文字模块的接口
#pip install baidu-aip  #安装百度python AI库
from aip import AipOcr
import re
APP_ID = '18822271'
API_KEY = '5oicld6LaNbN0OxpUDmxcy1i'
SECRET_KEY = 'f3pS8ouVibUta5hDruRXRsTfhxS3IZWO1'
client = AipOcr(APP_ID,API_KEY,SECRET_KEY)
with open('d:/python/test/3.jpg','rb') as f:
	image = f.read()
data = str(client.basicGeneral(image)).replace(' ','')
pat = re.compile(r"words':'(.*?)'")
result = re.findall(pat,data)[0]
print(result)
-----------方法2--------
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
-----------------------
#模拟验证码识别
from aip import AipOcr
import re
import requests
APP_ID="15725370"
API_KEY="t85bppstXXudNNSU0klALWgj"
SECRET_KEY="Zt7z61AXutINgWS1lqWe3xsWp9uePSFF"
client=AipOcr(APP_ID,API_KEY,SECRET_KEY)
data=requests.get(r"http://127.0.0.1:8020/登陆验证码/login.html").text
pat=re.compile(r'<img src="(.*?)" style')
url="http://127.0.0.1:8020/登陆验证码/"+pat.findall(data)[0]
image=requests.get(url).content
data=str(client.basicGeneral(image)).replace(" ","")
pat=re.compile(r"{'words':'(.*?)'}")
result=pat.findall(data)[0]
print(result)