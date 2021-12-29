#获取会话登录
import requests
import re

headers = {
	"User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
}

def get_authenticity_token():
    firstURL="http://gitlab.hs.com/users/sign_in"
    response = requests.request("get",firstURL,headers=headers)
    pat = r'name="csrf-token" content="(.*?)" />'
    result = re.findall(pat,response.text)
    return result[0]
#建立form_data数据
authenticity_token = get_authenticity_token()
print(authenticity_token)
data = {"user[login]":"0748", "user[password]": "homsom","authenticity_token": authenticity_token,"utf8":"✓","user[remember_me]":"0"}
#创建session对象
ses = requests.session()
login = ses.post("http://gitlab.hs.com/users/sign_in",headers=headers,data=data)
#获取登录后才能获取的链接
headers2 = {
    "Host": "gitlab.hs.com",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
    "Referer": "http://gitlab.hs.com/u/0748",
    "Accept-Encoding": "gzip, deflate",
    "Accept-Language": "zh-CN,zh;q=0.9",
    "Cookie": "_gitlab_session=ff27f0ac0c2afff7d83c798d216b60ef"  #cookie一定要有，否则无法获取管理权限
}
print(login.cookies)
response = ses.get("http://gitlab.hs.com/admin",headers=headers2)
print(response.text)

