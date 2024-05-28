# -*- coding: utf-8 -*-

import requests
from datetime import datetime

class Projects(object):
	def __init__(self, cfg, target_users, target_groups):
		super(Projects, self).__init__()
		# self.source_api = 'http://%s/api/v3/projects/all'
		self.source_api = 'http://%s/api/v4/projects'
		self.target_api = 'http://%s/api/v4/projects'
		self.source = cfg['source']
		self.target = cfg['target']
		self.per_page = cfg['per_page']
		self.target_users = target_users
		self.target_groups = target_groups

	def run(self):
		source = self.get()
		target = self.inserts(source)
		
		return { 'source': source, 'target': target }

	def get(self):
		projects = requests.get(
			self.source_api % self.source['address'], 
			headers = self.source['headers'],
			params = { 'order_by': 'updated_at', 'per_page': self.per_page, 'page': 1})

		X_Next_Page = projects.headers.get('X-Next-Page')		
		project_list = []
		for project in projects.json():
				project_list.append(project)

		# 老版本gitlab最大支持每页展示100个对象，故有大于100的项目无法获取，所以这里加了一些代码，从而获取所有的项目列表
		while X_Next_Page != '' or X_Next_Page is None:
			projects = requests.get(
				self.source_api % self.source['address'], 
				headers = self.source['headers'],
				params = { 'order_by': 'updated_at', 'per_page': self.per_page, 'page': X_Next_Page})

			for project in projects.json():
				project_list.append(project)
			
			X_Next_Page = projects.headers.get('X-Next-Page')		
		
		print(str(datetime.now()), '[INFO] Total projects:', len(project_list))	
		return project_list

	def inserts(self, projects):
		new_projects = []
		for project in projects:
			npn = project['namespace']['path']
			try:
				np = next(x for x in self.target_groups if x['path'] == npn)
				data = {
					"name": project['name'],
					"path": project['path'],
					"namespace_id": np['id'],
					"description": project['description'],
					"visibility": project['visibility'],
					"lfs_enabled": 0
				}
				resp = requests.post(
					self.target_api % self.target['address'], 
					headers = self.target['headers'], 
					data = data)
				new_projects.append(resp.json())
			except Exception as e:
				np = next(x for x in self.target_users if x['username'] == npn)
				data = {
					"name": project['name'],
					"path": project['path'],
					"user_id": np['id'],
					"description": project['description'],
					"visibility": project['visibility'],
					"lfs_enabled": 0
				}
				resp = requests.post(
					'%s/user/%s' % (self.target_api % self.target['address'], np['id']), 
					headers = self.target['headers'], 
					data = data)
				new_projects.append(resp.json())

		print(str(datetime.now()), '[INFO] Create new project: %d' % len(new_projects))

		return new_projects
