# GitLab Community Edition数据迁移

使用`gitlab-ce` API进行私有仓库数据迁移，从`15.11.13`迁至`16.6.6`。因版本不同，无法使用`gitlab-rake`工具进行`backup`/`restore`。

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
