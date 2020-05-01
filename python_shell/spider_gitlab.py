import requests
import re
from lxml import etree
import xlsxwriter

def get_head_info(headers):
    cookies = ''
    firstURL="http://gitlab.hs.com/users/sign_in"
    response = requests.request("get",firstURL,headers=headers)
    for i in response.cookies:  #获取cookies信息
        cookies = str(i.name) + "=" + str(i.value)
    pat = r'name="csrf-token" content="(.*?)" />'
    result = re.findall(pat,response.text)
    return result[0],cookies

def get_projects_info(ses,PageNumber): #获取项目名称和a链接URL
    nameLIST = []
    urlLIST = []
    for i in range(0,PageNumber):
        response = ses.get("http://gitlab.hs.com/admin/projects?page="+str(i+1))
        reditList  = response.history
        if len(reditList) > 0:   #认证结果返回代码
            code = re.findall(r'<Response \[(.*?)\]>',str(reditList[0]))
            if code[0] != 200:
                print("认证失败！")   
                exit(1)
        result = response.text
        html = etree.HTML(result)
        project_url = html.xpath('//section[@class="col-md-9"]/div[@class="panel panel-default"]/ul[@class="well-list"]/li/div[@class="list-item-name"]/a/@href') 
        project_name = html.xpath('//section[@class="col-md-9"]/div[@class="panel panel-default"]/ul[@class="well-list"]/li/div[@class="list-item-name"]/a/text()') 
        nameLIST.extend(project_name)
        urlLIST.extend(project_url)
    print("认证成功,正在查询写入中！")
    return nameLIST,urlLIST

def get_projects_fullurl(project_url): #拼接项目完整URL
    fullUrl = [] 
    url = "http://gitlab.hs.com"
    for i in project_url:
        fullUrl.append(url + i)
    return fullUrl

def get_projects_permission_url(projects_fullurl,ses): #获取项目权限管理URL
    projects_permission_url = []
    for i in projects_fullurl:
        response = ses.get(url=i)
        result = response.text
        html = etree.HTML(result)
        permissionURL = html.xpath('//div[@class="container-fluid container-limited"]/div[@class="content"]/div[@class="clearfix"]/div[@class="row"]/div[@class="col-md-6"]/div[@class="panel panel-default"]/div[@class="panel-heading"]/div[@class="pull-right"]/a/@href')
        projects_permission_url.append(str(permissionURL[1]))
    return projects_permission_url

def get_projects_permission_list(projects_permission_url,project_name,ses): #获取用户权限列表：姓名，登录ID，权限角色
    usernameDICT = {}
    loginidDICT = {}
    permissionDICT = {}
    for i in range(0,len(projects_permission_url)):
        response = ses.get(url=projects_permission_url[i])
        result = response.text
        html = etree.HTML(result)
        username = html.xpath('//div[@class="content"]/div[@class="clearfix"]/\
            div[@class="project-members-page prepend-top-default"]/div[@class="panel panel-default"]/\
            ul[@class="content-list"]/li/span/strong/a/text()')
        loginid = html.xpath('//div[@class="content"]/div[@class="clearfix"]/\
            div[@class="project-members-page prepend-top-default"]/div[@class="panel panel-default"]/\
            ul[@class="content-list"]/li/span/span[@class="cgray"]/text()')
        permission = html.xpath('//div[@class="content"]/div[@class="clearfix"]/\
            div[@class="project-members-page prepend-top-default"]/div[@class="panel panel-default"]/\
            ul[@class="content-list"]/li/span[@class="pull-right"]/strong/text()')
        if len(permission) != len(username): #权限跟用户名数据不一致问题时，让其他值为null,注意下面for循环时不用跟你循环变量同名，例如下面j不能设成上面的i变量
            yushu = len(username) - len(permission)
            for j in range(0,yushu):
                permission.append('null')
        usernameDICT[project_name[i]] = username
        loginidDICT[project_name[i]] = loginid
        permissionDICT[project_name[i]] = permission
    return usernameDICT,loginidDICT,permissionDICT

def write_file(usernameDICT,loginidDICT,permissionDICT,file_path,excel_path,project_name): #写入txt文件
    for i in range(0,len(project_name)):
        with open(file_path,'a+') as f:  #只能是a+模式，不能是ab+，因为str不是bytes
            f.write(project_name[i])
        for j in range(0,len(usernameDICT[project_name[i]])):
            project = "project: " + str(project_name[i].replace(" ",""))
            username = "\t\t\tusername: " + str(usernameDICT[project_name[i]][j])
            loginid = "\t\t\tloginid: " + str(loginidDICT[project_name[i]][j])
            permission = "\t\t\tpermission: " + str(permissionDICT[project_name[i]][j]) + "\n"
            data = project \
                + username\
                + loginid\
                + permission
            with open(file_path,'a+') as f:  #只能是a+模式，不能是ab+，因为str不是bytes
                f.write(data)
    print("写入.txt完成")

def write_excel(usernameDICT,loginidDICT,permissionDICT,excel_path,project_name):
    sum = 0  #计算总次数
    workbook = xlsxwriter.Workbook(excel_path)#创建一个excel文件
    worksheet = workbook.add_worksheet(u'gitlab')#在文件中创建一个名为gitlab的sheet,不加名字默认为sheet1
    worksheet.set_column('A:A',40)#设置第一列宽度为40像素
    worksheet.set_column('B:B',20)#设置第二列宽度为20像素
    worksheet.set_column('C:C',20)#设置第三列宽度为20像素
    worksheet.set_column('D:D',20)#设置第四列宽度为20像素
    bold= workbook.add_format({'bold':True})#设置一个加粗的格式对象
    worksheet.write('A1','Project',bold)#在A1单元格写上Project
    worksheet.write('B1','Username',bold)#在B1单元格写上Username
    worksheet.write('C1','LoginID',bold)#在C1单元格写上LoginID
    worksheet.write('D1','Permission',bold)#在D1单元格写上Permission
    for i in range(0,len(project_name)):
        for j in range(0,len(usernameDICT[project_name[i]])):
            projectValue = str(project_name[i].replace(" ",""))
            usernameValue = str(usernameDICT[project_name[i]][j])
            loginidValue = str(loginidDICT[project_name[i]][j])
            permissionValue = str(permissionDICT[project_name[i]][j])
            row = sum + 1
            column = 0
            worksheet.write(row,column,projectValue)#使用行列的方式写上projectValue值
            worksheet.write(row,column + 1,usernameValue)#使用行列的方式写上usernameValue值
            worksheet.write(row,column + 2,loginidValue)#使用行列的方式写上loginidValue值
            worksheet.write(row,column + 3,permissionValue)#使用行列的方式写上permissionValue值
            sum = sum + 1 
    workbook.close()
    print("写入Excel完成")

def main():
    headers = {
	    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
    }
    #获取authenticity_token和cookie
    authenticity_token,cookies = get_head_info(headers)
    #定义含cookie的HEAD
    headers_cookies = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
        "Cookie": cookies
    }
    #defined formdata
    data = {"user[login]":"0748", "user[password]": "homsom+4006","authenticity_token": authenticity_token,"utf8":"?","user[remember_me]":"0"}
    #创建session对象
    ses = requests.session()
    ses.post("http://gitlab.hs.com/users/sign_in",headers=headers_cookies,data=data)
    # file_path = 'e:/gitlab.txt'
    excel_path = 'e:/gitlab.xlsx'
    PageNumber = 8
    project_name,project_url=get_projects_info(ses,PageNumber)  #获取项目名称和a链接URL
    projects_fullurl = get_projects_fullurl(project_url)  #获取完整a链接URL
    projects_permission_url = get_projects_permission_url(projects_fullurl,ses) #获取项目权限管理url地址
    usernameDICT,loginidDICT,permissionDICT = get_projects_permission_list(projects_permission_url,project_name,ses) #获取用户权限列表：姓名，登录ID，权限角色
    write_excel(usernameDICT,loginidDICT,permissionDICT,excel_path,project_name) #写入到excel
    # write_file(usernameDICT,loginidDICT,permissionDICT,file_path,project_name) #写入到txt
    exit(0)

if __name__ == "__main__":
    main()

