#!/usr/bin/env python3
import pika  
import random  
#input loginname and password 
credentials = pika.PlainCredentials('admin', 'password')  
#ip,port,vhost
parameters = pika.ConnectionParameters('192.168.43.202',5672,'/',credentials)    
connection = pika.BlockingConnection(parameters)    
channel = connection.channel()    
#create or declare queue,set name and durable
channel.queue_declare(queue="homsom",durable=True)    
#create or declare exchange,set name and durable
channel.exchange_declare("homsom","direct",durable=True)    
#1.queue name 2.exchange name
channel.queue_bind("homsom","homsom",routing_key="hm")
#'hm' name is routing key ,it already biding homsom queue  
for i in range(0,1000):
  number = random.randint(0,1000)  
  body = 'hello world:%s' % number  
  channel.basic_publish(exchange='homsom',
                      routing_key='hm',    
                      body=body,properties=pika.spec.BasicProperties(delivery_mode=2)) #delivery_mode=2 is persistent,equle 1 is transient
  print(" [x] Sent %s" % body)
connection.close()
