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
		self.target['headers']['Cookie']="visitor_id=7150fcea-28a3-4152-a1fc-e16953de244d; sidebar_collapsed=false; preferred_language=zh_CN; hide_auto_devops_implicitly_enabled_banner_204=false; hide_auto_devops_implicitly_enabled_banner_306=false; hide_auto_devops_implicitly_enabled_banner_3216=false; known_sign_in=T1c0RnUrcWlSNFJBTnMwUXY1dDR5QTZ5V0tMN25BUjdydTVWdWMwcThORi9pY2ExalgrVHdMZjBMVW43ZWlDcUxadUZFRy9DM3ZFc1c3LzZ2dVBCdlczeWNUQU1kcnZKMUQrcDE1NEFjZndkOGtibHdVSUlNbko4aVo0UTNCbk4tLWtxdklZK2JkaVpnc2VZOUsvTnFNc2c9PQ%3D%3D--10271fb60010acc2659daf93dfb222b5ec969330; _gitlab_session=80b58eec69dd52d83b0b6c24a68ac767; event_filter=team"
		params = {
			'authenticity_token': 'K0tEIKFYJnJJqh7jOfvgXRnOnf3l3aglTZAzRonUqDXvnsZZNTpBI9-wHIjOhwyVv4zsUsd1HLhEfnPuBzrrEA',
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
