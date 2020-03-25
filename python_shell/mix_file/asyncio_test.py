import asyncio

#@asyncio.coroutine  #python3.4使用此语法
#python3.5及以后使用
async def wget(host):
    print('wget %s...' % host)
    connect = asyncio.open_connection(host, 80)
    #reader, writer = yield from connect #python3.4使用此语法
    reader, writer = await connect #python3.5及以后使用
    header = 'GET / HTTP/1.0\r\nHost: %s\r\n\r\n' % host
    writer.write(header.encode('utf-8'))
    #yield from writer.drain()  #python3.4使用此语法
    await writer.drain()  #python3.5及以后使用
    while True:
        #line = yield from reader.readline()  #python3.4使用此语法
        #python3.5及以后使用
        line = await reader.readline()   
        if line == b'\r\n':
            break
        print('%s header > %s' % (host, line.decode('utf-8').rstrip()))
    # Ignore the body, close the socket
    writer.close()

loop = asyncio.get_event_loop()
tasks = [wget(host) for host in ['www.sina.com.cn', 'www.sohu.com', 'www.163.com']]
loop.run_until_complete(asyncio.wait(tasks))
loop.close()