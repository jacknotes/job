import requests
import json
import re
import time


class Login(object):
    def __init__(self, loginUrl, username, password):
        self.loginUrl = loginUrl
        self.username = username
        self.password = password
        self.session = requests.session()
        self.loginStation()

    #登录habor
    def loginStation(self):
        session_id = self.get_head_info()
        self.header = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
            "Cookie": "_xsrf=V1hHWXRzSzNCTm9LNTdleFp2UUR5eXg4NjFpaXNHUFY=|1640755411661192914|57d1891687210efd2ffd5f929841756373606e9d; " + session_id,
            "X-Xsrftoken": "WXGYtsK3BNoK57exZvQDyyx861iisGPV"
        }
        data = {
            "principal": self.username, 
            "password": self.password
        }
        response=self.session.post(self.loginUrl, headers=self.header, data=data)
        print(f"statusCode = {response.status_code}")
        if response.status_code == 200:
            print("[INFO] login successful!")
        else:
            print("[ERROR] login failed!")
            exit(1)

     #获取cookies中的session信息
    def get_head_info(self):
        cookies_info = ''
        response = requests.request("get",self.loginUrl)
        for i in response.cookies: 
            cookies_info = str(i.name) + "=" + str(i.value)
        return cookies_info

class ClearHarbor(object):
    def __init__(self, harbor_domain, username, password, schema="http"):
        self.schema = schema
        self.harbor_domain = harbor_domain
        self.harbor_url = self.schema + "://" + self.harbor_domain
        self.login_url = self.harbor_url + "/c/login"
        self.api_url = self.harbor_url + "/api"
        self.pro_url = self.api_url + "/projects"
        self.repos_url = self.api_url + "/repositories"
        self.manual_gc_url= self.api_url + "/system/gc/schedule"
        self.username = username
        self.password = password
        self.tag_number = 30
        self.client = Login(self.login_url, self.username, self.password)

    #获取项目列表
    def __fetch_pros_obj(self):
        self.pros_obj = self.client.session.get(self.pro_url).json()
        return self.pros_obj

    #从项目列表获取项目ID
    def fetch_pros_id(self):
        self.pros_id = []
        pro_res = self.__fetch_pros_obj()
        for i in pro_res:
            #print('pro_res:',i)
            self.pros_id.append(i['project_id'])
        return self.pros_id

    #获取需要删除的仓库名称
    def fetch_del_repos_name(self, pro_id):
        self.del_repos_name = []
        repos_res = self.client.session.get(self.repos_url, params={"project_id": pro_id})
        for repo in repos_res.json():
            if repo["tags_count"] > self.tag_number: 
                self.del_repos_name.append(repo['name'])
        return self.del_repos_name

    #删除仓库中的镜像
    def fetch_del_repos(self, repo_name):
        self.del_res = []
        cookies="ASDASHHSJFSHDFHNVNHSHSBDFDSF=97700a965658428895c7874a0cb02924; hsToken=; Token=; Emppoplist=%7C1%7C2%7C3%7C4%7C5%7C6%7C7%7C8%7C9%7C10%7C11%7C12%7C13%7C14%7C15%7C16%7C17%7C18%7C19%7C20%7C21%7C22%7C23%7C24%7C25%7C26%7C27%7C; Empnumber=0000; Empname=%E6%9D%8E%E6%A0%87; " + self.client.header['Cookie']
        self.client.header['Cookie']=cookies
        tag_url = self.repos_url + "/" + repo_name + "/tags"
        tags = self.client.session.get(tag_url).json()
        tags_sort = sorted(tags, key=lambda a: a["created"])
        del_tags = tags_sort[0:len(tags_sort) - self.tag_number]
        for tag in del_tags:
            del_repo_tag_url = tag_url + "/" + tag['name']
            # print(del_repo_tag_url)
            del_res = self.client.session.delete(del_repo_tag_url,headers=self.client.header)
            if re.match(r'.*200.*>', f"{del_res}"):
                print(f"[INFO] delete sucessful: {del_repo_tag_url}")
            else:
                print(f"[ERROR] delete failed: {del_repo_tag_url}")
            self.del_res.append(del_res)
        return self.del_res

    def manual_clear_gc(self):
        data = {
            "schedule": {
                "type": "Manual"
            }
        }
        #post json请求
        res=self.client.session.post(url=self.manual_gc_url,headers=self.client.header, data=json.dumps(data))
        print(res)
        if re.match(r'.*20.*>', f"{res}"):
            print(f"[INFO] schedule clear gc sucessful")
        else:
            print(f"[ERROR] schedule clear gc failed")

if __name__ == "__main__":
    harbor_domain = "harbor.hs.com" 
    username='username'
    password = "password"
    # 从返回结果来看，有登录成功
    obj = ClearHarbor(harbor_domain, username, password)
    for i in obj.fetch_pros_id():
        # 获取所有tag超过30的repos
        repos = obj.fetch_del_repos_name(i) 
        for repo in repos:
            del_repos = obj.fetch_del_repos(repo)
            # print(del_repos)
    #调度清理GC        
    time.sleep(1)
    obj.manual_clear_gc()
