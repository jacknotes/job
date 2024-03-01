# -*- coding: utf-8 -*-

from git import Repo
import os, shutil
import requests

class Repositories(object):
	def __init__(self, cfg, source_projects):
		super(Repositories, self).__init__()
		self.source_api = 'http://%s/api/v3/projects/%s/repository/tree'
		# self.api = 'http://%s/%s.git'
		self.api = 'git@%s:%s.git'
		self.source = cfg['source']
		self.target = cfg['target']
		self.source_projects = source_projects
		self.dirpath = 'tmp/repos/'

	def run(self):
		# self.clean()
		# for project in self.source_projects:
		for i,project in enumerate(self.source_projects):
			# 加了if语句，主要用于调试时使用
			if i+1 >= 0:
				print("[INFO] number %s" % str(i+1))

				request_status = requests.get(
					self.source_api % (self.source['address'], project['id']),
					headers = self.source['headers'])

				# 用于判断项目是否为空，如果为空则不对此项目进行克隆和上传动作，如果为空进行上传的动作时会报错
				if request_status.status_code == 404:
					print("[INFO] project %s content is Null" % project['path_with_namespace'])
					continue

				groupdir = '%s%s' % (self.dirpath, project['namespace']['path'])
				if not os.path.exists(groupdir):
					os.makedirs(groupdir)

				# 因为老版本gitlab有Public的群组，而新版本gitlab不支持创建名为Public的群组，所以做了 'Public' + 'New'特殊处理
				if project['namespace']['path'] == 'Public':
					self.push(project['namespace']['path'] + 'New' + '/' + project['path'], 
						'%s/%s' % (groupdir, project['path']))
				else:
					self.push(project['path_with_namespace'], 
						'%s/%s' % (groupdir, project['path']))

	def push(self, uri, to_path):
		# 因为老版本gitlab有Public的群组，而新版本gitlab不支持创建名为Public的群组，所以做了 'Public' + 'New'特殊处理
		source_url = self.api % ('%s' % self.source['address'], str(uri).replace('New',''))
		target_url = self.api % (self.target['address'], uri)
		print('[INFO] Clone:', source_url)
		repo = Repo.clone_from(url = source_url, to_path = to_path, bare = True)
		print('[INFO] Push:', target_url)
		gitlab = repo.create_remote('gitlab', target_url)
		print('[INFO] push all')
		# 在windows环境下运行此脚本，有些项目会报UnicodeDecodeError: 'gbk' codec can't decode byte 0xae in position 86: illegal multibyte sequence
		# 在Linux环境下运行此脚本无此问题
		gitlab.push(all = True)
		print('[INFO] push tags')
		gitlab.push(tags = True)

	def clean(self):
		if os.path.exists(self.dirpath):
			shutil.rmtree(self.dirpath, onerror = self.onerror)

	def onerror(self, func, path, exec_info):
		import stat
		if not os.access(path, os.W_OK):
			os.chmod(path, stat.S_IWUSR)
			func(path)
		else:
			raise
