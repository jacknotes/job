#!/usr/bin/env python3
import pika  
import random  
        
credentials = pika.PlainCredentials('admin', 'password')  
parameters = pika.ConnectionParameters('192.168.43.202',5672,'/',credentials)    
connection = pika.BlockingConnection(parameters)    
channel = connection.channel()    
#down 'homsom' is queue name  
for method_frame, properties, body in channel.consume('homsom'):
    # Display the message parts and acknowledge the message
    print(method_frame, properties, body)
    channel.basic_ack(method_frame.delivery_tag)
    # Escape out of the loop after 10 messages
    if method_frame.delivery_tag == 1000:
        break
# Cancel the consumer and return any pending messages
requeued_messages = channel.cancel()
print('Requeued %i messages' % requeued_messages)
connection.close()
