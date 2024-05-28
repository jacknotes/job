# GitLab Community Edition数据迁移

使用`gitlab-ce` API进行私有仓库数据迁移，从`15.11.13`迁至`16.6.6`。因版本不同，无法使用`gitlab-rake`工具进行`backup`/`restore`。

使用`gitlab-ce` API进行私有仓库数据迁移，从`8.9.2`迁至`16.6.6`。因版本不同，无法使用`gitlab-rake`工具进行`backup`/`restore`，使用project_v3.py和repositories_v3.py。

## 配置

`src/config.py`:

- `SOURCE`: 老版本GitLab地址(端口`80`)与访问令牌

- `TARGET`: 新版本GitLab(`test`/`prod`)地址与访问令牌

## 迁移数据列表

- [X] Users
- [X] Groups
- [X] Group members
- [X] Projects
- [X] Repositories
- [ ] Issues
- [ ] Merge requests
- [X] Webhook

## 用法


- 前期准备
```sh
# 1. 本地缓存目标主机检验码，/root/.ssh/known_hosts
ssh source_gitlab@192.168.3.11
ssh target_gitlab@192.168.3.11

# 2. 在旧git上和新git上创建Personal Access Token，并授予权限

# 3. 在新git上root用户添加ssh key,使迁移主机具有push权限到新git，此root用户必须具有所有组的push权限，一般owner权限最好
```



- 安装依赖
```sh
pip3 install GitPython
```

- 迁移
``` sh
$ python3 src/main.py [test | prod]
```

- 清除测试目标库中的数据
``` sh
$ python3 src/clean.py
```

- webhook添加
```sh
# 取消注释webhook代码块
target_groups = Groups(cfg).get_target()
base.storage('target_groups', target_groups)
webhook = Webhook(cfg, target_groups).run()
base.storage('webhook', webhook)

# 注释def execute(cfg):下其它代码块

# 运行
$ python3 src/main.py prod
```