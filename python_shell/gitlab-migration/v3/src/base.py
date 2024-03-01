# -*- coding: utf-8 -*-

import json

def storage(name, data):
	with open('tmp/%s.json' % name, 'w', encoding = 'UTF-8') as f:
		json.dump(data, f, sort_keys = False, indent = 2, ensure_ascii = False)

# 用于测试从文件读取Json数据到对象，可以快速测试，不用从头再落数据
def read_from_storage(name):
	with open('tmp/%s.json' % name, 'r', encoding = 'UTF-8') as f:
		return json.load(f)
