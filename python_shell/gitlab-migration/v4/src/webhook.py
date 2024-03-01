# -*- coding: utf-8 -*-

import requests

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
		for group in target_groups:
			if group['path'] == 'k8s-deploy':
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
		
		print('[INFO] Total projects:', len(project_list))	
		target_group_projects = sorted(project_list, key = lambda x:x['id'], reverse = False)
		return target_group_projects

	def inserts(self, target_group_projects):
		target_response_project_info = []
		# 手动添加Cookie 和 authenticity_token 值
		self.target['headers']['Cookie']="_ga=GA1.1.1697340207.1693811818; _ga_E0Y9LD940L=GS1.1.1698055038.1.1.1698055054.0.0.0; event_filter=team; _ga_YFKNQX5E65=GS1.1.1706262662.198.0.1706262662.0.0.0; preferred_language=zh_CN; known_sign_in=NUpSblNpa2JzNGlEc3JpSlZKSDQ4bGxkUkJiQktXYWY3WUJFTXc5TGZBRW9jWU1oOXBqU1E3NzdsMnlOaFRFdmZFK2x5Q2tzdlFlVmo5OGJQMnQ0bVo1QUxNckZDQXFwTmpsQVZSSzZONXA2RW01aktXQlFyZ0lSQTlVM0NVME0tLXhSM1ZDME0xY1JYV0RvS2I4RldkK2c9PQ%3D%3D--4868ae47988194c5fe2c83b949d38a3daf0daae2; _gitlab_session=05e93fffff53bbc525ba90aaa2a49558; visitor_id=c268bbb5-30b3-4c8e-8471-735074132f79; super_sidebar_collapsed=false; hide_auto_devops_implicitly_enabled_banner_805=false"
		params = {
			'authenticity_token': '7307M-1swKKkr4PN5DeuAkCBEs7gy-f9tjdvj5KA16sTSMeQ3XDG1sCzzWyFK-b61kPoAGrUaGBP1L2l7XeaCw',
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

		print('[INFO] Create webhook project: %d' % len(target_response_project_info))
