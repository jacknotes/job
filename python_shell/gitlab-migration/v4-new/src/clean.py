# -*- coding: utf-8 -*-

import requests, config
from datetime import datetime
import time

# 清除测试(test)目标的数据
cfg = config.TARGET["prod"]
address = 'http://%s/api/v4' % cfg['address']
headers = { 'PRIVATE-TOKEN': cfg['access_token'] }
print(str(datetime.now()), "[INFO] ",address, headers)
sleep_time=10
print(str(datetime.now()), "[INFO] " + str(sleep_time) + "秒后开始清理！")
time.sleep(sleep_time)


def removeGroups():
	url = '%s/groups' % address
	resp = requests.get(url, headers = headers)
	groups = resp.json()
	print(str(datetime.now()), '[INFO] Remove groups: %d' % len(groups))

	for g in groups:
		requests.delete('%s/%s' % (url, g['id']), headers = headers)

def removeUsers():
	url = '%s/users' % address
	resp = requests.get(url, headers = headers, 
		params = { 'per_page': 500 })
	users = resp.json()
	print(str(datetime.now()), '[INFO] Remove users: %d' % len(users))

	for u in users:
		if u['username'] != 'root':
			requests.delete('%s/%s' % (url, u['id']), 
				headers = headers, params = { 'hard_delete': True })

def removeProjects():
	url = '%s/projects' % address
	projects = requests.get(url, headers = headers,
		params = { 'order_by': 'updated_at', 'per_page': 100, 'page': 1})

	X_Next_Page = projects.headers.get('X-Next-Page')		
	project_list = []
	for project in projects.json():
		project_list.append(project)

	while X_Next_Page != '' or X_Next_Page is None:
		# 老版本gitlab最大支持每页展示100个对象，故这里写的是100
		projects = requests.get(url, headers = headers,
			params = { 'order_by': 'updated_at', 'per_page': 100, 'page': X_Next_Page})

		for project in projects.json():
			project_list.append(project)
		
		X_Next_Page = projects.headers.get('X-Next-Page')	

	print(str(datetime.now()), '[INFO] Remove projects: %d' % len(project_list))
	for p in project_list:
		requests.delete('%s/%s' % (url, p['id']), headers = headers)

class Clean(object):
	def __init__(self):
		super(Clean, self).__init__()
		removeGroups()
		removeUsers()
		removeProjects()

if __name__ == '__main__':
	Clean()

