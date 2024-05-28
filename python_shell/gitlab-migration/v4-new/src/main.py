# -*- coding: utf-8 -*-

import os, sys, config, base
from datetime import datetime
from users import Users
from groups import Groups
from groups_members import GroupsMembers
from webhook import Webhook
# from projects import Projects
# from repositories import Repositories
from projects_v3 import Projects
from repositories_v3 import Repositories

def execute(cfg):
	# 下载user group member project为json文件存储
	users = Users(cfg).run()
	base.storage('users', users)

	groups = Groups(cfg).run()
	base.storage('groups', groups)

	members = GroupsMembers(cfg, users, groups).run()
	base.storage('groups-members', members)

	projects = Projects(cfg, users['target'], groups['target']).run()
	base.storage('projects', projects)

	# # 用于测试时使用，当本地已经有json文件时，可不用在去下载json文件，节省时间开销
	# projects = base.read_from_storage('projects')

	# 从旧git pull项目、push项目到新git上
	Repositories(cfg, projects['source']).run()

	# # 用于独立使用，插入webhook
	# target_groups = Groups(cfg).get_target()
	# base.storage('target_groups', target_groups)
	# webhook = Webhook(cfg, target_groups).run()
	# base.storage('webhook', webhook)



if __name__ == '__main__':
	env = sys.argv[1:]
	if env:
		env = env[0]
	else:
		env = 'test'

	tmppath = 'tmp'
	if not os.path.exists(tmppath):
		os.makedirs(tmppath)

	cfg = {
		'source': config.SOURCE,
		'target': config.TARGET.get(env, config.TARGET['test'])
	}

	print(str(datetime.now()), '[INFO]Migrator configuration:')
	for key in cfg:
		cfg[key]['headers'] = { 'PRIVATE-TOKEN': cfg[key]['access_token'] }
		print(str(datetime.now()), '[INFO]%s:' % key)
		print(cfg[key])
	cfg['per_page'] = 100
	
	execute(cfg)
