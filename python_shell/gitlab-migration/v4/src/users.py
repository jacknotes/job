# -*- coding: utf-8 -*-

import requests

class Users(object):
	def __init__(self, cfg):
		super(Users, self).__init__()
		# self.source_api = 'http://%s/api/v3/users'
		self.source_api = 'http://%s/api/v4/users'
		self.target_api = 'http://%s/api/v4/users'
		self.source = cfg['source']
		self.target = cfg['target']
		self.params = { 'per_page': cfg['per_page'], 'sort': 'asc' }

	def run(self):
		source = self.get()
		target = self.inserts(source)

		return { 'source': source, 'target': target }

	def get(self):
		resp = requests.get(self.source_api % self.source['address'], 
			headers = self.source['headers'], params = self.params)
		
		users = sorted(resp.json(), key = lambda x:x['id'], reverse = False)
		print('[INFO] Total accounts: %d' % len(users))

		return users

	def inserts(self, users):
		new_users = []
		for user in users:
			uname = user['username']
			if uname == 'ghost':
				continue

			if uname == 'root':
				resp = requests.get(
					'%s/1' % (self.target_api % self.target['address'], ), 
					headers = self.target['headers'], params = self.params)
				new_users.append(resp.json())
			else:
				data = {
					'email': user.get('email'),
					'password': 'wVHEfDW7DemFTZrx',
					'username': user.get('username'),
					'name': user.get('name'),
					'skype': user.get('skype'),
					'linkedin ': user.get('linkedin '),
					'twitter': user.get('twitter'),
					'website_url': user.get('website_url'),
					'organization': user.get('organization'),
					'bio': user.get('bio'),
					'location': user.get('location'),
					'admin': user.get('is_admin'),
					'skip_confirmation': True
				}
				resp = requests.post(self.target_api % self.target['address'], 
					headers = self.target['headers'], data = data)
				new_users.append(resp.json())

		size = len(new_users)
		print('[INFO] Create new user: %d' % (size - 1))
		print('[INFO] Total new user: %d' % size)

		return new_users
