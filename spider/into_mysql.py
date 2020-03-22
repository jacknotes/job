# #插入数据库
# #pip install pymysql
# import pymysql
# db = pymysql.Connect(host="localhost",port=3306,user="root",passwd='root@password',db='spider',charset='utf8')
# cursor = db.cursor() #新建游标对象
# sql = "insert into tel (name,phone) values ('单位','000')"
# cursor.execute(sql)  #用游标对象执行sql语句
# db.commit() #提交事务
# db.close() #关闭连接资源
#-----------
# import pymysql
# import requests
# import re
# db = pymysql.Connect(host="localhost",port=3306,user="root",passwd='root@password',db='spider',charset='utf8')
# cursor = db.cursor() #新建游标对象
# headers = {
# 	"User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
# }
# response = requests.get("https://changyongdianhuahaoma.51240.com/",headers=headers).text
# pat1 = r'<tr bgcolor="#EFF7F0">[\s\S]*?<td>(.*?)</td>[\s\S]*?<td>[\s\S]*?</td>[\s\S]*?</tr>'
# pat2 = r'<tr bgcolor="#EFF7F0">[\s\S]*?<td>[\s\S]*?</td>[\s\S]*?<td>(.*?)</td>[\s\S]*?</tr>'
# pattern1 = re.compile(pat1)
# pattern2 = re.compile(pat2)
# data1 = pattern1.findall(response)
# data2 = pattern2.findall(response)
# sql1 = 'delete from tel'  #清空表
# cursor.execute(sql1)
# db.commit()
# resultList = []
# for i in range(0,len(data1)):
#     resultList.append(data1[i]+data2[i])
#     sql = "insert into tel (name,phone) values ('"+data1[i]+"','"+str(data2[i])+"')"
#     cursor.execute(sql)  #用游标对象执行sql语句
# print(resultList)
# db.commit() #提交事务
# db.close() #关闭连接资源