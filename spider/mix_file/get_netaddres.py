# -*- coding:utf-8 -*-

import re
import urllib.request

def get_content(url):
  html = urllib.request.urlopen(url)
  info = html.read()
  html.close()
  return info
  
def download(info):
  """doc.<input type="text" class="thunderhref" value="thunder://QUFmdHA6Ly8yODpwdWJAczYuZ2JsLmE2Ny5jb206MjAyMi+158rTvucvMjAxNC8wNi8yOC9hNjfK1rv6tefTsGE2Ny5jb23Hp8311q7N9dbYs/a9rbr+MDJbaGQ0ODBwXS5tcDRaWg==" title="鼠标左键单击可全选后手动复制该条迅雷地址进行分享或其它操作" onclick="this.select()">"""
  regex = r'class="thunderhref" value="(.+)"'
  pat = re.compile(regex)  
  image_code = re.findall(pat,info.decode('utf-8'))
  i = 1 
  for image_url in image_code:
    print(image_url)
    # resp = urllib.request.urlopen(image_url)
    # resphtml = resp.read()
    # picfile = open('%s.jpg' % i,'wb')
    # picfile.write(resphtml)
    #urllib.request.urlretrieve(image_url, '%s.jpg' % i)
    i += 1
  print(len(image_code))
info = get_content('https://www.xigua110.com/tvb/qianwangzhiwangzhongchujianghu.htm')	
print(download(info))