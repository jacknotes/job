import requests
import requests.auth
import json
import time
import re


'''
使用场景：
    0. UserTokenVar在JenkinsUI中个人中心生产
    1. 用于自动批量参数化构建jenkins任务
    2. JobList为job列表
    3. jsonVar为参数化构建时传入的变量, 需对应调整参数达到预期效果
'''

UserNameVar='0799'
# 生成的token
UserTokenVar='1198f0510f05f48fa60ea9d5f6561e890e'
JenkinsCrumbIssuerAddressVar='http://newjenkins.hs.com/crumbIssuer/api/json'
JenkinsJobAddressVar = 'http://newjenkins.hs.com/job/'
JenkinsJobBuildUrlVar = '/build?delay=0sec'
JenkinsJobLastBuildNumberUrlVar='/lastBuild/buildNumber'
JenkinsJobLastSuccessfulBuildNumberUrlVar='/lastSuccessfulBuild/buildNumber'
JobList=[
    'nginx-bg.hs.com',
    'nginx.hs.com',
]
status_pat=r'20'
SleepSecond=30

HeadersVar = {
	"Content-Type": "application/x-www-form-urlencoded",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
}

jsonVar={
        "parameter": [
        {
            "name": "GitBranchName",
            "value": "release"
        },
        {
            "name": "DeployENV",
            "value": "homsom-hs"
        },
        {
            "name": "PublishEnvironment",
            "value": "uat"
        },
        {
            "name": "PublishPassword",
            # 此处经过post请求，会将此参数的'+'号变成'空',需要注意，将+用%2B替代
            "value": "homsom%2B4006123123"
        }
    ],
    "Jenkins-Crumb": ""
}

    

def SetJenkinsCrumbFunc():
    # 获取 "Jenkins-Crumb"
    response = requests.request("get",JenkinsCrumbIssuerAddressVar,auth=requests.auth.HTTPBasicAuth(UserNameVar,UserTokenVar))
    global JenkinsCrumb,JenkinsData
    JenkinsCrumb = json.loads(response.text)['crumb']
    # 替换 "Jenkins-Crumb
    jsonVar["Jenkins-Crumb"] = JenkinsCrumb
    JenkinsData="json="+str(jsonVar)


def ExecJenkinsBuildJobFunc(jobname):
    url = JenkinsJobAddressVar + jobname + JenkinsJobBuildUrlVar
    response = requests.request("post",url,auth=requests.auth.HTTPBasicAuth(UserNameVar,UserTokenVar),data=JenkinsData,headers=HeadersVar)
    if re.findall(status_pat,str(response.status_code)):
        print("[INFO] {} job(" .format(time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time())))+ jobname + ") building..... ")
    else:
        print("[INFO] {} job(" .format(time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time())))+ jobname + ") build failure")


def GetJenkinsJobStatusFunc(jobname):
    url = JenkinsJobAddressVar + jobname + JenkinsJobLastBuildNumberUrlVar
    lastBuildNumber = requests.request("post",url,auth=requests.auth.HTTPBasicAuth(UserNameVar,UserTokenVar),data=JenkinsData,headers=HeadersVar)

    url = JenkinsJobAddressVar + jobname + JenkinsJobLastSuccessfulBuildNumberUrlVar
    lastSuccessfulBuildNumber = requests.request("post",url,auth=requests.auth.HTTPBasicAuth(UserNameVar,UserTokenVar),data=JenkinsData,headers=HeadersVar)

    if str(lastBuildNumber.text) == str(lastSuccessfulBuildNumber.text):
        print("[INFO] {} job(".format(time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()))) + jobname + ") build successful")
    else:
        print("[INFO] {} job(" .format(time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()))) + jobname + ") build failure".format(time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()))),)

if __name__ == '__main__':
    SetJenkinsCrumbFunc()
    for i in JobList:
        ExecJenkinsBuildJobFunc(i)
    
    print("[INFO] {} please wait {} second display building status.".format(time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time())),SleepSecond))
    time.sleep(SleepSecond)
    for i in JobList:
        GetJenkinsJobStatusFunc(i)
