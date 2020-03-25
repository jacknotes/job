# #线程回顾
# import threading
# import time

# def run(name):
# 	print(name,"线程执行了")
# 	time.sleep(5)
# #创建线程
# t1 = threading.Thread(target=run,args=("t1",))
# t2 = threading.Thread(target=run,args=("t2",))
# #启动子线程
# t1.start()
# t2.start()
# #等待子线程执行完毕后再执行join()后面的内容
# t1.join()
# t1.join()
# #主线程
# print("执行完毕")
# ------------
# #创建线程类
# import threading
# import time
# #创建线程类
# class myThread(threading.Thread):
# 	"""myThread"""
# 	def __init__(self,name):
# 		threading.Thread.__init__(self)
# 		self.name = name

# 	def run(self):
# 		print("开始线程：",self.name)
# 		print("线程执行中--1")
# 		time.sleep(1)
# 		print("线程执行中--2")
# 		time.sleep(1)
# 		print("线程执行中--3")
# 		time.sleep(1)
# 		print("线程执行中--4")
# 		time.sleep(1)
# 		print("线程执行中--5")
# 		time.sleep(1)
# 		print("线程结束：",self.name)
# #创建线程
# t1 = myThread("t1")
# t2 = myThread("t2")
# t3 = myThread("t3")
# #启动子线程
# t1.start()
# t2.start()
# t3.start()
# #等待子线程结束
# t1.join()
# t2.join()
# t3.join()
# print("主线程结束")
# ---------
#队列
#实现线程安全，先进先出的数据结构，用来生产者和消费者线程之间的信息传递
#常用于多线程使用。python原生的list,dict是非线程安全的，而queue是线程安全的
import queue
q = queue.Queue(maxsize=10) #maxsize表示队列最大放多少个对象，不写则对队列没有限制
for i in range(1,11):
	q.put(i)  #往队列放值
while not q.empty():  #判断队列是否不为空
	print(q.get())  #先进先出规则取值
 # ---------
