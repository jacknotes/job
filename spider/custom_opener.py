#基本的urlopen()方法不支持代理、cookie等其它的HTTP/HTTPS高级功能，
#所以要支持就需要通过request.build_opener()方法创建自定义opener对象，
#使用自定义的opener对象，调用open()方法发送请求。
#如果程序所有请求都使用自定义opener，可以使用request.install_opener()
#将自定义的opener对象定义为全局opener，表示之后凡是调用urlopen,都将使用
#这个opener(根据需求需要选择)

from urllib import request


#构建HTTP处理器对象（专门处理HTTP请求的对象）
http_handler = request.HTTPHandler()

#创建自定义opener
opener = request.build_opener(http_handler)

#创建自定义请求对象
req = request.Request(r'http://www.baidu.com')

#发送请求，获取响应
#response = opener.open(req).read().decode('utf-8')

#把自定义opener设置为全局
request.install_opener(opener)

response = request.urlopen(req).read().decode('utf-8')

print(response)