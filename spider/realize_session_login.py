#获取会话登录
import requests
headers = {
	"User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
}
#创建session对象
ses = requests.session()
#建立form_data数据
data = {"loginName":"jackli_RN", "password": "testpassword"}
#红网论坛
ses.post("https://passport.rednet.cn/passport/login?client_id=99039d48f5b9457d8a2a0194e5694689&redirect_uri=https%3A%2F%2Fbbs.rednet.cn%2F",headers=headers,data=data)
#获取登录后才能获取的链接
response = ses.get("https://bbs.rednet.cn/home.php?mod=space&uid=5973434")
print(response.text)