# -*- coding:utf-8 -*-

import re
import urllib.request

def get_content(url):
  html = urllib.request.urlopen(url)
  info = html.read()
  html.close()
  return info
  
def download(info):
  """doc.<img pic_type="1" src="https://imgsa.baidu.com/forum/w%3D580/sign=08021e66ca95d143da76e42b43f18296/80ec08fa513d2697134bfa3857fbb2fb4316d83f.jpg" 
  pic_ext="jpeg" class="BDE_Image" height="600" width="560">"""
  regex = r'pic_type="1" src="(.+?\.jpg)"'
  pat = re.compile(regex)  
  image_code = re.findall(pat,info.decode('utf-8'))
  i = 1 
  for image_url in image_code:
    print(image_url)
    print(i)
    # resp = urllib.request.urlopen(image_url)
    # resphtml = resp.read()
    # picfile = open('%s.jpg' % i,'wb')
    # picfile.write(resphtml)
    urllib.request.urlretrieve(image_url, '%s.jpg' % i)
    i += 1
  print(len(image_code))
info = get_content('https://tieba.baidu.com/p/2798043647')	
print(download(info))