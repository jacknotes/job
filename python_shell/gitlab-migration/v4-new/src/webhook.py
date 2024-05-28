# -*- coding: utf-8 -*-

import requests
from datetime import datetime

class Webhook(object):
	def __init__(self, cfg, target_groups):
		super(Webhook, self).__init__()
		self.target_group_projects_api = 'http://%s/api/v4/groups/%s/projects'
		self.target_api = 'http://%s/%s/-/hooks'
		self.target = cfg['target']
		self.per_page = cfg['per_page']
		self.target_groups = target_groups

	def run(self):
		target_group_projects = self.get(self.target_groups)
		self.inserts(target_group_projects)

		return { 'target_group_projects': target_group_projects }

	def get(self, target_groups):
		project_list = []
		# 仅匹配GROUP: k8s-deploy
		custom_group='k8s-deploy'
		for group in target_groups:
			if group['path'] == custom_group:
				projects = requests.get(
					self.target_group_projects_api % (self.target['address'], group['id']), 
					headers = self.target['headers'], 
					params = { 'order_by': 'updated_at', 'per_page': self.per_page, 'page': 1})

				X_Next_Page = projects.headers.get('X-Next-Page')		
				for project in projects.json():
						project_list.append(project)

				# gitlab最大支持每页展示100个对象，故有大于100的项目无法获取，所以这里加了一些代码，从而获取所有的项目列表
				while X_Next_Page != '' or X_Next_Page is None:
					projects = requests.get(
						self.target_group_projects_api % (self.target['address'], group['id']), 
						headers = self.target['headers'], 
						params = { 'order_by': 'updated_at', 'per_page': self.per_page, 'page': X_Next_Page})

					for project in projects.json():
						project_list.append(project)

					X_Next_Page = projects.headers.get('X-Next-Page')		
		
		print(str(datetime.now()), '[INFO] ' + custom_group + ' Group Total projects:', len(project_list))	
		target_group_projects = sorted(project_list, key = lambda x:x['id'], reverse = False)
		return target_group_projects

	def inserts(self, target_group_projects):
		target_response_project_info = []
		# 手动添加Cookie 和 authenticity_token 值
		self.target['headers']['Cookie']="_ga=GA1.1.679089771.1713506698; _ga_GHE6HQHFEF=GS1.1.1714457872.1.1.1714458055.0.0.0; _ga_RBVT2WN157=GS1.1.1714474730.2.0.1714474730.0.0.0; preferred_language=zh_CN; _gitlab_session=91cc28c99f5f2f74611eaf07a37ab77c; hsToken=; Token=; Emppoplist=%7C1%7C2%7C3%7C4%7C5%7C6%7C7%7C8%7C9%7C10%7C11%7C12%7C13%7C14%7C15%7C16%7C17%7C18%7C19%7C20%7C21%7C22%7C23%7C24%7C25%7C26%7C33%7C; Empnumber=0799; Empname=%E6%9D%8E%E6%A0%87; event_filter=all; _ga_YFKNQX5E65=GS1.1.1716261956.49.0.1716261956.0.0.0; ASDASHHSJFSHDFHNVNHSHSBDFDSF=323cac8350964ff5b1541f8c2d60508d"
		params = {
			'authenticity_token': 'V3mAy5p8qKZnR-J5xBKC_rfzUTL2jwJ4UGR_xx9H5n6Y8tvRFDJnMvqgp-ikFVf2WUn5GyMkwcls6fyddK8qrw',
			'hook[url]': 'https://argocd.test.k8s.hs.com/api/webhook',		# webhook的URL
			'__BVID__8': 'false',
			'hook[token]': 'uv6uHEyPI6Xbvh7I4b5tDfdNs1bBBtOL',				# webhook的token
			'hook[push_events]': 'true',
			'hook[branch_filter_strategy]': 'all_branches',
			'hook[enable_ssl_verification]': 0								# webhook是否开启SSL
		}
		for project in target_group_projects:
			resp = requests.post(
				self.target_api % (self.target['address'], project['path_with_namespace']),
				headers = self.target['headers'], 
				params = params)
			target_response_project_info.append(resp)

		print(str(datetime.now()), '[INFO] Create webhook project: %d' % len(target_response_project_info))
