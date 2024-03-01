# -*- coding: utf-8 -*-

import requests

class Groups(object):
	def __init__(self, cfg):
		super(Groups, self).__init__()
		# self.source_api = 'http://%s/api/v3/groups'
		self.source_api = 'http://%s/api/v4/groups'
		self.target_api = 'http://%s/api/v4/groups'
		self.source = cfg['source']
		self.target = cfg['target']

	def run(self):
		source = self.get()
		target = self.inserts(source)
		
		return { 'source': source, 'target': target }

	def get_target(self):
		resp = requests.get(
			self.target_api % self.target['address'], 
			headers = self.target['headers'])

		target_groups = sorted(resp.json(), key = lambda x:x['id'], reverse = False)

		print('[INFO] Total groups: %d' % len(target_groups))
		return target_groups

	def get(self):
		resp = requests.get(
			self.source_api % self.source['address'], 
			headers = self.source['headers'])

		groups = sorted(resp.json(), key = lambda x:x['id'], reverse = False)

		print('[INFO] Total groups: %d' % len(groups))
		return groups

	def inserts(self, groups):
		new_groups = []
		for group in groups:
			if group['name'] == 'Public':
				data = {
				"name": "PublicNew",
				"path": "PublicNew",
				"description": group['description'],
				# "visibility_level": group['visibility_level'],		# v3
				"visibility": group['visibility'],						# v4
				"lfs_enabled": 0
			}
			else:
				data = {
					"name": group['name'],
					"path": group['path'],
					"description": group['description'],
					# "visibility_level": group['visibility_level'],		# v3
					"visibility": group['visibility'],  					# v4
					"lfs_enabled": 0
				}
			resp = requests.post(
				self.target_api % self.target['address'], 
				headers = { 'PRIVATE-TOKEN': self.target['access_token'] }, 
				data = data)
			new_groups.append(resp.json())

		print('[INFO] Create new group: %d' % len(new_groups))

		return new_groups
