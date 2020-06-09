#!/usr/bin/python3
import smtplib
from email.mime.text import MIMEText
#from email.mime.multipart import MIMEMultipart
from email.header import Header

mail_host='smtp.126.com'
mail_port=25
mail_user='jacknotes@126.com'
mail_pass='TEZVGXVCSWXZZROG'
sender = 'jacknotes@126.com'
receivers = ['jacknotes@163.com', 'jacknotes@126.com'] 
 
# 三个参数：第一个为文本内容，第二个 plain 设置文本格式，第三个 utf-8 设置编码
#message = MIMEMultipart()
#message.attach(MIMEText('Python邮件', 'plain', 'utf-8'))
message = MIMEText('Python', 'plain', 'utf-8')
message['From'] = sender    
subject = 'alert'
message['Subject'] = Header(subject, 'utf-8')
for i in range(0,len(receivers)):
    message['To'] =  receivers[i]        
    try:
        smtpObj = smtplib.SMTP()
        smtpObj.connect(mail_host, mail_port)
        smtpObj.login(mail_user, mail_pass)
        smtpObj.sendmail(sender, receivers[i], message.as_string())
        print ("发送邮件" + receivers[i] +"成功")
    except smtplib.SMTPException:
        print ("Error: 发送邮件"+ receivers[i] +"失败")
