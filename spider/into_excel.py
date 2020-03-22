# #往excel插入数据
# #安装相关模块：pip install xlsxwriter
# import xlsxwriter
# #创建文件，并添加一个工作表
# workbook = xlsxwriter.Workbook('C:/Users/Jackli/desktop/demo.xlsx') #创建表
# worksheet = workbook.add_worksheet() #增加sheet 
# worksheet.write('A1','我要自学网')
# worksheet.write('A2','python爬虫')
# #关闭表格文件
# workbook.close()
#------------------
###爬虫写入EXCEL
# #爬取电话号码
# import requests
# import re
# import xlsxwriter
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
# resultList = []
# workbook = xlsxwriter.Workbook('C:/Users/Jackli/desktop/demo2.xlsx')
# worksheet = workbook.add_worksheet()
# for i in range(0,len(data1)):
#     resultList.append(data1[i]+data2[i])
#     worksheet.write('A' + str(i+1),data1[i])
#     worksheet.write('B'+str(i+1),data2[i])
# print(resultList)
# workbook.close()
