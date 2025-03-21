# jenkins



环境规划：

1. 开发环境：开发者本地有自己的环境，运维需要设置的开发环境：大家共用的服务，例如：开发数据库mysql,其它：redis、memcached.
2. 测试环境：功能测试和性能测试
3. 预生产环境：生产环境集群中的某一个节点担任
4. 生产环境：直接对用户提供服务的环境

预生产环境产生的原因：
数据库不一致：测试环境和生产环境数据库肯定是不一样的
使用生产环境的联调接口。例如：支付接口



部署

例如：1个集群有10个节点

1. 实现一键部署这10个节点
2. 一键回滚到任意版本
3. 一键回滚到上一个版本

部署的问题：
1. 代码在哪里：git、gitlab、svn。
2. 获取什么版本代码？
	git+svn直接拉取某个分支
	git:指定标签（tag）
	svn:指定版本号
3. 差异解决：
	1. 配置文件未必一样：代码层面的计划任务crontab.xml导致节点配置不一样、预生产节点
	2. 代码仓库和实际的差异：配置文件是否放在代码仓库中？配置文件只在部署上有。单独的项目而言
4. 如何更新：java程序更新肯定要重启系统，例如java跑在tomcat下就需要重启
5. 测试：测试环境、预生产环境都测过了，还要进行测试（别的公司就遇到过预生产环境没问题一到生产环境就有问题情况），再检查一遍系统的主要功能，以防万一
6. 串行还是并行：分组部署
7. 如何执行：1. shell ./ 执行。	2. web界面执行

部署的流程：
1. 获取代码（直接拉取）
2. 编译（可选）
3. 配置文件放进去
4. 打包
5. scp到目标服务器
6. 将目标服务器移出集群
7. 解压
8. 放到webroot
9. scp差异文件
10. 重启（可选）[php解释型语言，可以不重启，但是如果php开启缓存就得重启]
11. 测试
12. 重新加入集群



## 自动化部署实战

用户：所有的web服务都应该使用普通用户。所有的web服务器都不应该开启80端口，除了负载均衡。（用命令给普通用户设一个suid并且可以启动80端口）

1. 每台机器建立用户：useradd www (给每一个用户设定一个指定的uid)

2. 选中一台为控制机器，用ssh-keygen -t rsa 生成秘钥，并且在所有目标机器包括本身机器的www用户下~/.ssh目录下建立文件authorized_keys文件，写入控制机器的公钥且权限设成600

3. 写部署脚本框架：

  ```bash
  [root@clusterFS-node4-salt deploy]# cat /home/www/deploy.sh
  #/bin/bash
  
  #Date/Time Env
  LOG_DATE='date +%Y-%m-%d'  //后获取日期
  LOG_TIME='date +%H-%M-%S'
  
  CDATE=$(date +%Y-%m-%d)  //先获取日期
  CTIME=$(date +%H-%M-%S)
  
  #Shell Env
  SHELL_NAME="deploy.sh"
  SHELL_DIR="/home/www"
  SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"
  
  #Code Env
  CODE_DIR="/deploy/code/web-demo"
  CODE_CONFIG="/deploy/config"
  CODE_TMP="/deploy/tmp"
  CODE_TAR="/deploy/tar"
  LOCK_FILE="/tmp/deploy.lock"
  
  #Fun
  usage(){
          echo $"Usage: $0 [ deploy | rollback ]"
  }
  
  writelog(){  //日志函数
          LOGINFO=$1
          echo "`${LOG_DATE}` `${LOG_TIME}` : ${SHELL_NAME} : ${LOGINFO}" >> ${SHELL_LOG}
  
  }
  
  shell_lock(){
          touch ${LOCK_FILE}
  }
  
  shell_unlock(){
          rm -f ${LOCK_FILE}
  }
  
  code_get(){
          writelog "code_get";  //调用日志函数并传当前函数做为参数传入
          cd $CODE_DIR && git pull
  }
  
  
  code_build(){
          echo code_build
  }
  
  code_config(){
          echo code_config
  
  }
  
  code_tar(){
          echo code_tar
  }
  
  code_scp(){
          echo code_scp
  
  }
  
  cluster_node_remove(){
          echo cluster_node_remove
  }
  
  code_deploy(){
          echo code_deploy
  }
  
  config_diff(){
          echo config_diff
  }
  
  code_test(){
          echo code_test
  }
  
  cluster_node_in(){
          echo cluster_node_in
  }
  
  rollback(){
          echo rollback
  }
  
  main(){
          if [ -f ${LOCK_FILE} ];then
                  echo "Deploy is running" && exit;
          fi
          DEPLOY_METHOD=$1
          case $DEPLOY_METHOD in
                  deploy)
                          shell_lock;
                          code_get;
                          code_build;
                          code_config;
                          code_tar;
                          code_scp;
                          cluster_node_remove;
                          code_deploy;
                          config_diff;
                          code_test;
                          cluster_node_in;
                          shell_unlock;
                          ;;
                  rollback)
                          shell_lock;
                          rollback;
                          shell_unlock;
                          ;;
                  *)
                          usage;
                          ;;
          esac
  }
  main $1
  ```

  linux锁文件目录：/var/run/lock下
  shell脚本中测试锁文件是否有效可用sleep 60 睡眠来测试

4. 自动化部署流程：
  ```bash
  4. ————————————————————————————————————————
  [www@clusterFS-node4-salt ~]$ cat deploy.sh
  #/bin/bash
  
  #Dir List
  #mkdir -p /deploy/code/web-demo
  #mkdir -p /deploy/config/web-demo/base
  #mkdir -p /deploy/config/web-demo/other
  #mkdir -p /deploy/tar
  #mkdir -p /deploy/tmp
  #mkdir /webroot
  #chown R www:www /deploy
  #chown R www:www /opt/webroot
  #chown R www:www /webroot
  
  #Node List Env
  PRE_LIST="192.168.1.31"
  GROUP1_LIST="192.168.1.37"
  
  #Date/Time Env
  LOG_DATE='date +%Y-%m-%d'
  LOG_TIME='date +%H-%M-%S'
  
  CDATE=$(date +%Y-%m-%d)
  CTIME=$(date +%H-%M-%S)
  
  #Shell Env
  SHELL_NAME="deploy.sh"
  SHELL_DIR="/home/www"
  SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"
  
  #Code Env
  PRO_NAME="web-demo"
  CODE_DIR="/deploy/code/web-demo"
  CONFIG_DIR="/deploy/config/web-demo"
  TMP_DIR="/deploy/tmp"
  TAR_DIR="/deploy/tar"
  LOCK_FILE="/tmp/deploy.lock"
  
  #Fun
  usage(){
          echo $"Usage: $0 [ deploy | rollback ]"
  }
  
  writelog(){
          LOGINFO=$1
          echo "`${LOG_DATE}` `${LOG_TIME}` : ${SHELL_NAME} : ${LOGINFO}"  >> ${SHELL_LOG}
  }
  
  shell_lock(){
          touch ${LOCK_FILE}
  }
  
  shell_unlock(){
          rm -f ${LOCK_FILE}
  }
  
  code_get(){
          writelog "code_get";
          cd $CODE_DIR && git pull
          /bin/cp -r ${CODE_DIR} ${TMP_DIR}/
          API_VER="123"
  }
  
  
  code_build(){
          echo code_build
  }
  
  code_config(){
          writelog "code_config"
          /bin/cp -r ${CONFIG_DIR}/base/* ${TMP_DIR}/"${PRO_NAME}"
          PKG_NAME="${PRO_NAME}"_"${API_VER}"_"${CDATE}-${CTIME}"
          cd ${TMP_DIR} && mv ${PRO_NAME} ${PKG_NAME}
  }
  
  code_tar(){
          writelog "code_tar"
          cd ${TMP_DIR} && tar -czf ${PKG_NAME}.tar.gz ${PKG_NAME}
          writelog "${PKG_NAME}.tar.gz"
  }
  
  code_scp(){
          writelog "code_scp"
          for node in $PRE_LIST;do
                  scp ${TMP_DIR}/${PKG_NAME}.tar.gz ${node}:/opt/webroot
          done
  
          for node in $GROUP1_LIST;do
                  scp ${TMP_DIR}/${PKG_NAME}.tar.gz ${node}:/opt/webroot
          done
  
  }
  
  url_test(){
          URL=$1
          curl -s --head $URL  | grep '200 OK'
          if [ $? -ne 0 ];then
                  shell_unlock;
                  writelog "test ERROR" && exit 0
          fi
  }
  
  pre_deploy(){
          writelog  "remove from cluster"
                  ssh ${PRE_LIST} "cd /opt/webroot && tar -xzf ${PKG_NAME}.tar.gz"
                  ssh ${PRE_LIST} "rm -f /webroot/web-demo && ln -s /opt/webroot/${PKG_NAME} /webroot/web-demo"
          scp ${CONFIG_DIR}/other/192.168.1.31.crontab.xml 192.168.1.31:/webroot/web-demo/crontab.xml
  }
  pre_test(){
          url_test "http://${PRE_LIST}/index.html"
          writelog  "add to cluster"
  }
  
  group1_deploy(){
          writelog  "remove from cluster"
          for node in $GROUP1_LIST;do
                  ssh ${node} "cd /opt/webroot && tar -xzf ${PKG_NAME}.tar.gz"
                  ssh ${node} "rm -f /webroot/web-demo && ln -s /opt/webroot/${PKG_NAME} /webroot/web-demo"
          done
  }
  group1_test(){
          url_test "http://192.168.1.37/index.html"
          writelog "add to cluster"
  }
  
  rollback(){
          writelog "rollback"
  }
  
  main(){
          if [ -f ${LOCK_FILE} ];then
                  echo "Deploy is running" && exit;
          fi
          DEPLOY_METHOD=$1
          case $DEPLOY_METHOD in
                  deploy)
                          shell_lock;
                          code_get;
                          code_build;
                          code_config;
                          code_tar;
                          code_scp;
                          pre_deploy;
                          pre_test;
                          group1_deploy;
                          group1_test;
                          shell_unlock;
                          ;;
                  rollback)
                          shell_lock;
                          rollback;
                          shell_unlock;
                          ;;
                  *)
                          usage;
                          ;;
          esac
  }
  main $1
  ```

  ```bash
  [root@clusterFS-node4-salt web-demo]# curl --head http://192.168.1.31/index.html -s | grep '200 OK'
  HTTP/1.1 200 OK
  [root@clusterFS-node4-salt web-demo]# echo $?  #过虑得到返回值为0
  0
  [root@clusterFS-node4-salt web-demo]# curl --head http://192.168.1.31/index.html -s | grep '200OK'
  [root@clusterFS-node4-salt web-demo]# echo $?	#过虑不到返回值为1
  1
  ```

5. 回滚流程：
一、普通回滚：
1.列出回滚版本
2.目标服务移除集群
3.执行回滚
4.重启和测试
5.加入集群

​		二、紧急回滚：
​		1.列出回滚版本
​		2.执行回滚（重启）

​		三、超紧急回滚：直接回滚上个版本（重启）

​		注意：秒级回滚的精髓在于软链接

```bash
ROLLBACK_LIST="192.168.1.31 192.168.1.37"

rollback_fun(){
        for node in $ROLLBACK_LIST;do
                ssh $node "if [ -d /opt/webroot/$1 ];then rm -f /webroot/web-demo && ln -s /opt/webroot/$1 /webroot/web-demo ;else echo '$1 not DIR' && exit ; fi"
        done
}

rollback(){
	    writelog "rollback"
        if [ -z $1 ];then
                shell_unlock
                echo "please input rollback version" && exit
        fi
        case $1 in
                list)
                        ls -l /opt/webroot/*.tar.gz
                        ;;
                *)
                        rollback_fun $1
        esac
}

main(){
        if [ -f ${LOCK_FILE} ];then
                echo "Deploy is running" && exit;
        fi
        DEPLOY_METHOD=$1
        ROLLBACK_VER=$2
        case $DEPLOY_METHOD in
                deploy)
                        shell_lock;
                        code_get;
                        code_build;
                        code_config;
                        code_tar;
                        code_scp;
                        pre_deploy;
                        pre_test;
                        group1_deploy;
                        group1_test;
                        shell_unlock;
                        ;;
                rollback)
                        shell_lock;
                        rollback $ROLLBACK_VER;
                        shell_unlock;
                        ;;
                *)
                        usage;
                        ;;
        esac
}
main $1 $2
```

6. 安装gitlab（git私有仓库）
	硬件最低配置：双核4G内存
	1. yum install -y policycoreutils-python
	2. 添加gitlab镜像:wget https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/gitlab-ce-10.0.0-ce.0.el7.x86_64.rpm
	3. 安装gitlab:rpm -i gitlab-ce-10.5.7-ce.0.el7.x86_64.rpm
	4. 修改gitlab配置文件指定服务器ip和自定义端口:vim  /opt/gitlab/etc/gitlab.rb  #external_url '192.168.1.235'
	5. 重置并启动GitLab:1 gitlab-ctl   reconfigure  2 gitlab-ctl   restart
	6. 克隆gitlab：git glone git@192.168.1.31:/web/web-demo.git
	7. 像git一样push、pull操作

```bash
[www@clusterFS-node4-salt ~]$ cat deploy.sh
#/bin/bash

#Dir List
#mkdir -p /deploy/code/$PRO_NAME
#mkdir -p /deploy/config/$PRO_NAME/base
#mkdir -p /deploy/config/$PRO_NAME/other
#mkdir -p /deploy/tar
#mkdir -p /deploy/tmp
#mkdir /home/www/${SHELL_NAME}.log
#mkdir /webroot
#chown R www:www /deploy
#chown R www:www /opt/webroot
#chown R www:www /webroot

#Node List Env
PRE_LIST="192.168.1.31"
GROUP1_LIST="192.168.1.37"
ROLLBACK_LIST="192.168.1.31 192.168.1.37"

#Date/Time Env
LOG_DATE='date +%Y-%m-%d'
LOG_TIME='date +%H-%M-%S'

CDATE=$(date +%Y-%m-%d)
CTIME=$(date +%H-%M-%S)

#Shell Env
SHELL_NAME="deploy.sh"
SHELL_DIR="/home/www"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"

#Code Env
PRO_NAME="web-demo"
CODE_DIR="/deploy/code/$PRO_NAME"
CONFIG_DIR="/deploy/config/$PRO_NAME"
TMP_DIR="/deploy/tmp"
TAR_DIR="/deploy/tar"
LOCK_FILE="/tmp/deploy.lock"

#Fun
usage(){
        echo "Usage: $0 { deploy | rollback [ list | version  ]}"
}

writelog(){
        LOGINFO=$1
        echo "`${LOG_DATE}` `${LOG_TIME}` : ${SHELL_NAME} : ${LOGINFO}"  >> ${SHELL_LOG}
}

shell_lock(){
        touch ${LOCK_FILE}
}

shell_unlock(){
        rm -f ${LOCK_FILE}
}

code_get(){
        writelog "code_get";
        cd $CODE_DIR && git pull origin master
        /bin/cp -r ${CODE_DIR} ${TMP_DIR}/
        API_VERL=`git show  | grep commit | cut -d ' ' -f2`
        API_VER="${API_VERL:0:6}"
}


code_build(){
        writelog "code_build"
}

code_config(){
        writelog "code_config"
        /bin/cp -r ${CONFIG_DIR}/base/* ${TMP_DIR}/${PRO_NAME}
        PKG_NAME="${PRO_NAME}"_"${API_VER}"_"${CDATE}-${CTIME}"
        cd ${TMP_DIR} && mv ${PRO_NAME} ${PKG_NAME}
}

code_tar(){
        writelog "code_tar"
        cd ${TMP_DIR} && tar -czf ${PKG_NAME}.tar.gz ${PKG_NAME}
}

code_scp(){
        writelog "code_scp"
        for node in $PRE_LIST;do
                scp ${TMP_DIR}/${PKG_NAME}.tar.gz ${node}:/opt/webroot
        done

        for node in $GROUP1_LIST;do
                scp ${TMP_DIR}/${PKG_NAME}.tar.gz ${node}:/opt/webroot
        done

}

url_test(){
        URL=$1
        curl -s --head $URL  | grep '200 OK'
        if [ $? -ne 0 ];then
                shell_unlock;
                writelog "test ERROR" && exit 0
        fi
}

pre_deploy(){
        writelog  "remove pre from cluster"
                ssh ${PRE_LIST} "cd /opt/webroot && tar -xzf ${PKG_NAME}.tar.gz"
                ssh ${PRE_LIST} "rm -f /webroot/$PRO_NAME && ln -s /opt/webroot/${PKG_NAME} /webroot/$PRO_NAME"
        scp ${CONFIG_DIR}/other/192.168.1.31.crontab.xml 192.168.1.31:/webroot/$PRO_NAME/crontab.xml
}
pre_test(){
        writelog "pre_test"
        url_test "http://${PRE_LIST}:8888/index.html"
        writelog  "add pre to cluster"
}

group1_deploy(){
        writelog  "remove group1 from cluster"
        for node in $GROUP1_LIST;do
                ssh ${node} "cd /opt/webroot && tar -xzf ${PKG_NAME}.tar.gz"
                ssh ${node} "rm -f /webroot/$PRO_NAME && ln -s /opt/webroot/${PKG_NAME} /webroot/$PRO_NAME"
        done
}
group1_test(){
        writelog "group1_test"
        url_test "http://$GROUP1_LIST/index.html"
        writelog "add group1 to cluster"
}

rollback_fun(){
        writelog "rollback"
        for node in $ROLLBACK_LIST;do
                ssh $node "if [ -d /opt/webroot/$1 ];then rm -f /webroot/$PRO_NAME && ln -s /opt/webroot/$1 /webroot/$PRO_NAME ;else echo '$1 not DIR' && exit ; fi"
        done
}

rollback(){
        if [ -z $1 ];then
                shell_unlock
                echo "please input rollback version" && exit
        fi
        case $1 in
                list)
                        ls -l /opt/webroot/*.tar.gz
                        ;;
                *)
                        rollback_fun $1
        esac
}

main(){
        if [ -f ${LOCK_FILE} ];then
                echo "Deploy is running" && exit;
        fi
        DEPLOY_METHOD=$1
        ROLLBACK_VER=$2
        case $DEPLOY_METHOD in
                deploy)
                        shell_lock;
                        code_get;
                        code_build;
                        code_config;
                        code_tar;
                        code_scp;
                        pre_deploy;
                        pre_test;
                        group1_deploy;
                        group1_test;
                        shell_unlock;
                        ;;
                rollback)
                        shell_lock;
                        rollback $ROLLBACK_VER;
                        shell_unlock;
                        ;;
                *)
                        usage;
                        ;;
        esac
}
main $1 $2
```


脚本解释：
按照自动化部署流程来编写脚本，总体相像，在部署时先拿一台预热节点来部署，当预热节点部署成功且测试通过时，即可继续部署剩余所有节点，当预热节点部署失败就退出脚本执行，此时剩余节点不会继续部署，只会导致预热节点失败，可保证不会大面积瘫焕。
回滚操作按照紧急回滚流程来操作，先列出回滚版本号，后回滚指定版本号



## 持续集成部分
持续集成：

1. git pull origin master 拉取最新的代码 	更新非常频繁，没有特别严格的项目管理。
2. git tag 获取指定的标签版本 更新没那么频繁，有一定的项目管理的团队。
3. 获取指定的commit id
	master分支	发布的版本
	dev分支	test的代码版本
	自己的分支
	DevOps:是一种文化，是开发、运维、测试之间沟通的一种文化	过程、方法、系统的统称。
	目标是一样的。为了让我们的软件、构建、测试、发布更加的敏捷、频繁、可靠。跟持续集成很像
	运维：需要掌控大局	或者掌控DevOps，运维没有能力是不行的	测试工具、方法、监控

持续集成：指在软件开发过程中，频繁地将代码集成到主干上，然后进行自动化测试。
持续交付：批在持续集成的基础上，将集成后的代码部署到更贴近真实运行环境的类生产环境。如果代码没有问题，可以继续手动部署到生产环境中。（手动部署到生产环境中是大部分公司用的）
持续部署：在持续交付的基础上，把部署到生产环境的过程自动化。
#OWASP(Open Web Application Security Project):运维必须会，因为这个涉及应用安全

持续集成之Jenkins安装部署实战：
1. 安装JDK：Jenkins是Java编写的，所以需要先安装JDK，这里采用yum安装，如果对版本有需求，可以直接在Oracle官网下载JDK。
[root@clusterFS-node3-salt ~]# yum install -y java-1.8.0
2. 安装jenkins:
[root@clusterFS-node3-salt ~]# wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
[root@clusterFS-node3-salt ~]# rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
[root@clusterFS-node3-salt ~]# yum install jenkins -y
[root@clusterFS-node3-salt ~]# systemctl start jenkins
[root@clusterFS-node3-salt ~]# netstat -tunlp | grep 8080  #jenkins默认启动8080端口
3. 在插件管理中搜索gitlab,安装gitlab plugin和gitlab hook plugin(用于gitlab和jenkins进行令牌认证时用)两个插件，因为要用jenkins和gitlab来集成。
4. jenkins最主要的是插件，添加插件可以在web上添加安装也可以在/var/lib/jenkins/plugins/目录下添加
5. 添加凭据：用于访问gitlab的仓库（把jenkins服务机器的公钥放置到gitlab deploy key（部署key，只读的，不同于用户key）上，把私钥放置到jenkins上这样可以使用jenkins来访问gitlab仓库）
6. 新建demo-sonar项目-设置源码从git获取-输入仓库地址、刚才添加的凭据、专门的分支-源码浏览器的URL、版本-然后保存
7. 立即构建并选写构建任务从控制台输出可查看任务执行情况



## 持续代码质量管理-Sonar部署

Sonar 是一个用于代码质量管理的开放平台。通过插件机制，Sonar 可以集成不同的测试工具，代码分析工具，以及持续集成工具。与持续集成工具（例如 Hudson/Jenkins 等）不同，Sonar 并不是简单地把不同的代码检查工具结果（例如 FindBugs，PMD 等）直接显示在 Web 页面上，而是通过不同的插件对这些结果进行再加工处理，通过量化的方式度量代码质量的变化，从而可以方便地对不同规模和种类的工程进行代码质量管理。

在对其他工具的支持方面，Sonar 不仅提供了对 IDE 的支持，可以在 Eclipse 和 IntelliJ IDEA 这些工具里联机查看结果；同时 Sonar 还对大量的持续集成工具提供了接口支持，可以很方便地在持续集成中使用 Sonar。
此外，Sonar 的插件还可以对 Java 以外的其他编程语言提供支持，对国际化以及报告文档化也有良好的支持。

Sonar部署（跟jenkins部署在同一台服务器）
需要mysql5.6，java1.8以上
Sonar的相关下载和文档可以在下面的链接中找到：http://www.sonarqube.org/downloads/。需要注意最新版的Sonar需要至少JDK 1.8及以上版本。
1. [root@clusterFS-node2-salt auto-deploy]# cd /usr/local/src
2. [root@clusterFS-node2-salt src]# wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-6.5.zip
3. [root@clusterFS-node2-salt src]# unzip sonarqube-6.5.zip
4. [root@clusterFS-node2-salt src]# mv sonarqube-6.5 /usr/local/
5. [root@clusterFS-node2-salt src]# ln -s sonarqube-6.5/ sonarqube
安装mysql数据库：
rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-2.noarch.rpm
禁用mysql80和mysql57:
sudo yum-config-manager --disable mysql80-community
sudo yum-config-manager --disable mysql57-community
启用mysql56:
sudo yum-config-manager --enable mysql56-community #sonar只能mysql5.6版本，其他版本报错
6. 准备Sonar数据库:
mysql> CREATE DATABASE sonar CHARACTER SET utf8 COLLATE utf8_general_ci;
mysql> GRANT ALL ON sonar.* TO 'sonar'@'localhost' IDENTIFIED BY 'sonar@pw';
mysql> GRANT ALL ON sonar.* TO 'sonar'@'%' IDENTIFIED BY 'sonar@pw';
mysql> FLUSH PRIVILEGES;
7. 配置sonar:
[root@clusterFS-node2-salt local]# cd /usr/local/sonarqube/conf/
[root@clusterFS-node2-salt conf]# ls
sonar.properties  wrapper.conf
8. 编写配置文件，修改数据库配置:
[root@clusterFS-node2-salt conf]# vim sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=salt
sonar.jdbc.url=jdbc:mysql://localhost:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance
配置Java访问数据库驱动(可选)
默认情况Sonar有自带的嵌入的数据库，那么你如果使用类是Oracle数据库，必须手动复制驱动类到${SONAR_HOME}/extensions/jdbc-driver/oracle/目录下，其它支持的数据库默认提供了驱动。其它数据库的配置可以参考官方文档：
http://docs.sonarqube.org/display/HOME/SonarQube+Platform
9. 启动Sonar:你可以在Sonar的配置文件来配置Sonar Web监听的IP地址和端口，默认是9000端口。
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.context=/sonarqube  #sonarqube为web的首页
10. [root@clusterFS-node3-salt conf]# /usr/local/sonarqube/bin/linux-x86-64/sonar.sh start #当sonar服务启动不来时看下与数据库连接是否正常，是个坑
11. http://192.168.1.37访问sonarqube ,默认帐户密码皆为admin
12. 手动下载插件可到github Sonaraube社区下载：https://github.com/SonarQubeCommunity，然后可放到/usr/local/sonarqube/extensions/plugins目录下，重启sonar服务即可 (sonar web中下载需要到update center中去安装)
13. 需要下载你要测试的语言包插件，例如python,java,php,css等，插件只是语言规则
14. 通过SonarQube Scanner来测试代码，需要安装SonarQube Scanner
15. 下载sonarQube Scanner:[root@clusterFS-node2-salt src]# wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip
16. 安装sonarQube Scanner:unzip sonar-scanner-cli-3.3.0.1492-linux.zip; mv sonar-scanner-cli-3.3.0.1492-linux /usr/local; ln -s sonar-scanner-cli-3.3.0.1492-linux sonar-scanner
17. 因为sonarQube Scanner跟sonarQube有关联,所以要修改配置文件:[root@clusterFS-node2-salt conf]# vim /usr/local/sonar-scanner/conf/sonar-scanner.properties如下： 
sonar.host.url=http://192.168.1.37:9000
sonar.sourceEncoding=UTF-8
sonar.jdbc.username=sonar
sonar.jdbc.password=salt
sonar.jdbc.url=jdbc:mysql://192.168.1.37:3306/sonar?useUnicode=true&characterEncoding=utf8
sonar.login=admin   #sonar.login和sonar.password在jenkins上使用sonar scanner进行扫描时需要用到
sonar.password=admin  
18. sonar官方提供代码测试地址：https://github.com/sonarSource/sonar-scanning-examples，下载下来
19. 在/usr/local/src/sonar-scanning-examples-master/sonarqube-scanner-build-wrapper-linux路径下（刚刚下载的文件），有sonar-project.properties配置文件，里面填写了有关编程语言的信息，使测试信息到sonarqube上,编辑配置文件如下：
[root@clusterFS-node3-salt sonarqube-scanner-build-wrapper-linux]# cat sonar-project.properties
sonar.projectKey=phpkey
sonar.projectName=php
sonar.projectVersion=1.0
sonar.sources=src
sonar.language=php
sonar.sourceEncoding=UTF-8
注：php测试有反应，java测试无反应。1. sonar-project.properties这个配置文件要么让开发写在代码里面，2. 要么手输在sonarqube-scanner里面。

20. 由于sonarqube-scanner需要跟jenkins相结合，所以要在jenkins上装sonarQube Plugin（或者sonarQube Scanner）插件，这样才能使用sonarqube-scanner
21. 在jenkins中添加sonarquber server:系统管理-系统设置-找到SonarQube servers，然后输入name和server URL,版本进行添加-保存
22. 然后在jenkins上设定sonarqube scanner的软件家目录：全局工具配置-找到SonarQube Scanner-新增SonarQube Scanner-输入Name和sonar运行的家目录-保存
23. 在jenkins上配置demo-sonar项目-在构建子菜单上设置sonar scanner为构建器，只填写Analysis properties的参数（填写sonar-project.properties文件的配置信息）-保存
24. 之前新建的项目demo-sonar现在可以从gitlab上获取代码并且可以用sonarqube scanner进行质量检测。下一步是提交质量检测通过的代码到机器上，可以在建立一个项目（为什么不和之前的项目一起？因为有时需要只检测代码质量）
25. 新建一个项目demo-deploy,让这个项目执行命令：sudo ssh www@192.168.1.31 "./deploy.sh deploy" ，这个脚本就是之前写的自动化部署脚本   #为什么用sudo?因为执行命令的用户是jenkins，而不是root。而jenkins又不在/etc/sudoers里面，需要在/etc/sudoers下加入jenkins的权限【jenkins ALL=(ALL) NOPASSWORD: /usr/bin/ssh】,这下jenkins可以用sudo获取root的权限了，但是root不能直接登录www用户，需要密码，所以需要把root的公钥放置到www的authorized_keys文件下即可。如果jenkins中报tty的错误，需要在/etc/sudoers文件中注释掉#Defaults requiretty即可
注：jenkins ALL=(ALL) NOPASSWORD: /usr/bin/ssh #意为jenkins用户能在所有主机上使用所有用户身份执行，不需要输入密码，只能执行ssh
26. 安装trigger parameterized plugin（参数触发插件用于项目之间的紧密联动）-进入第一个代码质量检测项目demo-sonar配置-在构建后操作子菜单中选择trigger parameterized build on other projects（意为在其他项目上触发参数化构建）-选择要构建的项目demo-deploy并保存-最后构建demo-sonar项目，成功后会自动执行demo-deploy项目 || 进入第一个代码质量检测项目demo-sonar-选择构建后操作-选择要构建的项目demo-deploy并保存-最后构建demo-sonar项目，成功后会自动执行demo-deploy项目
27. 视图：流水线插件安装：build pipeline plugin并重启jenkins服务 
28. 新建视图demo-pipeline并选择Build Pipeline View确定-设置名称demo-pipeline-选择初始的项目demo-sonar-设置显示构建的数量为5并保存-点runs运行即可。
29. jenkins跟gitlab的集成（在jenkins上操作）：
	需求：当我commit代码到gitlab仓库上，jenkins自动为我进行代码质量检测并自动部署。
	1. 安装gitlab hook plugin插件
	2. 触发远程构建需要令牌，所以需要安装Build Authorization Token Root插件，没有这个插件jenkins令牌与gitlab令牌无法完成认证
	3. 用linux系统openssl工具生成一个复杂的字符串用作token			
	[root@clusterFS-node3-salt plugins]# openssl rand -hex 10
	5be115c01d65ad008de6  #生成随机的十六进制10位数字，16进制每两个字节为1位数字
	4. 选择demo-sonar项目配置-构建触发器-勾选触发远程构建（粘添刚才生成的字符串）-勾选将更改推送到gitlab时构建（复制gitlab webhook url地址http://192.168.1.37:8080后面用）-保存
	5. 到gitlab上，进入admin area-system hooks（项目下的webhooks子菜单）-填写jenkins url:http://192.168.1.37:8080/buildByToken/build?job=demo-sonar&token=5be115c01d65ad008de6和token:5be115c01d65ad008de6-勾上push events选项（当push时会产生相应动作）-保存
	注：百度搜索build authorization token root plugin选择wiki结果可查看gitlab hook的使用方法【build?job=RevolutionTest&token=TacoTuesday】，这里是：http://192.168.1.37:8080/buildByToken/build?job=demo-sonar&token=5be115c01d65ad008de6
	6. gitlab上测试push event事件，如果成功则自动化部署成功了
	7. 在每个项目上配置构建后操作-当部署错误的时候发邮件通知信息



自动化脚本目录树

```bash
[root@saltsrv deploy]# tree /deploy/
/deploy/
├── code
│?? └── web-demo
│??     └── index.html
├── config
│?? └── web-demo
│??     ├── base
│??     │?? └── base.conf.txt
│??     └── other
│??         └── 192.168.1.231.crontab.xml.txt
├── tar
└── tmp
    ├── web-demo_724728_2019-09-08-17-18-17
    │?? ├── base.conf
    │?? └── index.html
    ├── web-demo_724728_2019-09-08-17-18-17.tar.gz
    ├── web-demo_c49dbe_2019-09-08-17-37-31
    │?? ├── base.conf.txt
    │?? └── index.html
    ├── web-demo_c49dbe_2019-09-08-17-37-31.tar.gz
    ├── web-demo_e731ea_2019-09-08-17-19-40
    │?? ├── base.conf
    │?? └── index.html
    └── web-demo_e731ea_2019-09-08-17-19-40.tar.gz
```



二次修改后脚本
-------------------------
```bash
[www@saltsrv ~]$ cat deploy.sh
#/bin/bash

#Description: 1.use www user run. 2.between www and www use private key and publice key authentication. 3.directory must use root permission before create.

#Shell Env
SHELL_NAME="deploy.sh"
SHELL_DIR="/home/www"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"
PRO_NAME="web-demo"

#Dir List
#mkdir -p /deploy/config/$PRO_NAME/base
#mkdir -p /deploy/config/$PRO_NAME/other
#mkdir -p /deploy/tar
#mkdir -p /deploy/tmp
#mkdir -p /webroot
#chown -R www:www /deploy
#chown -R www:www /opt/webroot
#chown -R www:www /webroot
if [ ! -f ${SHELL_LOG} ];then
        touch ${SHELL_LOG}
fi

#Node List Env
PRE_LIST="192.168.1.231"
#GROUP1_LIST="192.168.1.37"
ROLLBACK_LIST="192.168.1.231"

#Date/Time Env
LOG_DATE='date +%Y-%m-%d'
LOG_TIME='date +%H-%M-%S'

CDATE=$(date +%Y-%m-%d)
CTIME=$(date +%H-%M-%S)

#Code Env
CODE_DIR="/deploy/code/$PRO_NAME"
CONFIG_DIR="/deploy/config/$PRO_NAME"
TMP_DIR="/deploy/tmp"
TAR_DIR="/deploy/tar"
LOCK_FILE="/tmp/deploy.lock"

#Fun
usage(){
        echo "Usage: $0 { deploy | rollback [ list | version  ]}"
}

writelog(){
        LOGINFO=$1
        echo "`${LOG_DATE}` `${LOG_TIME}` : ${SHELL_NAME} : ${LOGINFO}"  >> ${SHELL_LOG}
}

shell_lock(){
        touch ${LOCK_FILE}
}

shell_unlock(){
        rm -f ${LOCK_FILE}
}

code_get(){
        writelog "code_get";
        cd $CODE_DIR && git pull origin master
        if [ $? = 0 ]; then
               /bin/cp -r ${CODE_DIR} ${TMP_DIR}/
                API_VERL=`git show  | grep commit | cut -d ' ' -f2`
                API_VER="${API_VERL:0:6}"
        fi
}


code_build(){
        writelog "code_build"
}

code_config(){
        writelog "code_config"
        /bin/cp -r ${CONFIG_DIR}/base/* ${TMP_DIR}/${PRO_NAME}
        PKG_NAME="${PRO_NAME}"_"${API_VER}"_"${CDATE}-${CTIME}"
        cd ${TMP_DIR} && mv ${PRO_NAME} ${PKG_NAME}
}

code_tar(){
        writelog "code_tar"
        cd ${TMP_DIR} && tar -czf ${PKG_NAME}.tar.gz ${PKG_NAME}
}

code_scp(){
        writelog "code_scp"
        for node in $PRE_LIST;do
                scp ${TMP_DIR}/${PKG_NAME}.tar.gz ${node}:/opt/webroot
        done

       # for node in $GROUP1_LIST;do
       #         scp ${TMP_DIR}/${PKG_NAME}.tar.gz ${node}:/opt/webroot
       # done

}

url_test(){
        URL=$1
        curl -s --head $URL  | grep '200 OK'
        if [ $? -ne 0 ];then
                shell_unlock;
                writelog "test ERROR" && exit 0
        fi
}

pre_deploy(){
        writelog  "remove pre from cluster"
                ssh ${PRE_LIST} "cd /opt/webroot && tar -xzf ${PKG_NAME}.tar.gz"
                ssh ${PRE_LIST} "rm -rf /webroot/$PRO_NAME && ln -s /opt/webroot/${PKG_NAME} /webroot/$PRO_NAME"
        scp ${CONFIG_DIR}/other/192.168.1.231.crontab.xml.txt 192.168.1.231:/webroot/$PRO_NAME/crontab.xml.txt
}
pre_test(){
        writelog "pre_test"
        url_test "http://${PRE_LIST}:8088/index.html"
        writelog  "add pre to cluster"
}

#group1_deploy(){

#        writelog  "remove group1 from cluster"

#        for node in $GROUP1_LIST;do

#                ssh ${node} "cd /opt/webroot && tar -xzf ${PKG_NAME}.tar.gz"

#                ssh ${node} "rm -f /webroot/$PRO_NAME && ln -s /opt/webroot/${PKG_NAME} /webroot/$PRO_NAME"

#               scp ${CONFIG_DIR}/other/crontab.xml ${node}:/webroot/$PRO_NAME/crontab.xml

#        done

#       }

#group1_test(){

#        writelog "group1_test"

#       for node in $GROUP1_LIST;do

#               url_test "http://$node/index.html"

#       done

#        writelog "add group1 to cluster"

#}

rollback_fun(){
        writelog "rollback"
        for node in $ROLLBACK_LIST;do
                ssh $node "if [ -d /opt/webroot/$1 ];then rm -f /webroot/$PRO_NAME && ln -s /opt/webroot/$1 /webroot/$PRO_NAME ;else echo '$1 not DIR' && exit ; fi"
        done
}

rollback(){
        if [ -z $1 ];then
                shell_unlock
                echo "please input rollback version" && exit
        fi
        case $1 in
                list)
                        ls -l ${TMP_DIR}/*.tar.gz 
                        #ls -l /opt/webroot/*.tar.gz
                        ;;
                *)
                        rollback_fun $1
        esac
}

main(){
        if [ -f ${LOCK_FILE} ];then
                echo "Deploy is running" && exit;
        fi
        DEPLOY_METHOD=$1
        ROLLBACK_VER=$2
        case $DEPLOY_METHOD in
                deploy)
                        shell_lock;
                        code_get;
                        code_build;
                        code_config;
                        code_tar;
                        code_scp;
                        pre_deploy;
                        pre_test;
                        #group1_deploy;
                        #group1_test;
                        shell_unlock;
                        ;;
                rollback)
                        shell_lock;
                        rollback $ROLLBACK_VER;
                        shell_unlock;
                        ;;
                *)
                        usage;
                        ;;
        esac
}

main $1 $2
```



## 使用jenkins来自动构建docker镜像

```bash
1.安装java-openJDK和jenkins服务并启动
[root@BuildImage ~]# yum install -y java-1.8.0-openjdk.x86_64
[root@localhost yum.repos.d]# sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
[root@localhost yum.repos.d]# sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
[root@localhost yum.repos.d]# yum install jenkins -y
[root@localhost yum.repos.d]# systemctl start jenkins
[root@localhost yum.repos.d]# systemctl enable jenkins
[root@localhost yum.repos.d]# netstat -tunlp | grep 8080  #jenkins默认启动8080端口
2.安装插件，gitlab、gitlab hook、Email Extension
3.配置邮件信息：
在系统管理---系统配置---Jenkins Location---系统管理员邮件地址:这里填写的邮件地址必须跟下面设置的发件用户名一致，否则邮件不会发送成功。
在系统管理---系统配置---Extended E-mail Notification中设置：
--smtp server:   smtp.homsom.com
--default user-email suffix:	@homsom
--点开高级设置，设置发件用户名、密码、及smtp端口，是否使用加密。
--default content type:	HTML(text/html)
--Default Subject：$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!

--Default Content：
-------------------------------------------------

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>${ENV, var="JOB_NAME"}-第${BUILD_NUMBER}次构建日志</title>
</head>


<body leftmargin="8" marginwidth="0" topmargin="8" marginheight="4"
    offset="0">
    <table width="95%" cellpadding="0" cellspacing="0"
        style="font-size: 11pt; font-family: Tahoma, Arial, Helvetica, sans-serif">
        <tr>
            <td><br />
            <b><font color="#0B610B">构建信息</font></b>
            <hr size="2" width="100%" align="center" /></td>
        </tr>
        <tr>
            <td>
                <ul>
                    <li>项目名称 ： ${PROJECT_NAME}</li>
                    <li>构建编号 ： 第${BUILD_NUMBER}次构建</li>
                    <li>触发原因： ${CAUSE}</li>
                    <li>构建日志： <a href="${BUILD_URL}console">${BUILD_URL}console</a></li>
                    <li>构建  Url ： <a href="${BUILD_URL}">${BUILD_URL}</a></li>
                    <li>工作目录 ： <a href="${PROJECT_URL}ws">${PROJECT_URL}ws</a></li>
                    <li>项目  Url ： <a href="${PROJECT_URL}">${PROJECT_URL}</a></li>
                </ul>
            </td>
        </tr>
        <tr>
            <td><b><font color="#0B610B">变更集</font></b>
            <hr size="2" width="100%" align="center" /></td>
        </tr>
        

        <tr>
            <td>${JELLY_SCRIPT,template="html"}<br/>
            <hr size="2" width="100%" align="center" /></td>
        </tr>


​       

    </table>

</body>

</html>

4.新建项目：systemlog.hs.com,风格：free stype
--源码管理：git
----Repository URL:git@gitlab.hs.com:Homsom/SystemLog.git
----Credentials:没有就在这里添加一个，domain为全局凭据，类型为SSH Username with private key,范围为全局，username设一个辩识名字(这里是jenkins)，PrivateKey设置先前在linux下的root用户生成的私钥(把私钥复制保存到这里来)，最后保存。
----Branches to build：refs/heads/master  #指定分支
--构建触发器：Build when a change is pushed to GitLab. GitLab webhook URL: http://172.168.2.223:8080/project/SystemLog.hs.com（这个http开头的地址用在gitlab中webhooks中的URL）
----Enabled GitLab triggers
------Push Events和Opened Merge Request Events这两个需要勾上。
------Rebuild open Merge Requests：Never
------Approved Merge Requests (EE-only)和Comments勾上。
----Enable [ci-skip]和Ignore WIP Merge Requests和Set build description to build cause (eg. Merge request or Git Push )这三个勾上。
----Allowed branches：Allow all branches to trigger this job
----Secret token：点击Generate生成一个token,这个token复制到gitlab上的webhooks中（写入webhooks中的TOKEN）。
--构建：执行shell
----命令：/Jenkins_WorkSpace/BuildDocker.sh  #脚本中需要让jenkins使用root的权限来运行dokcer,所以要编辑/etc/sudoers文件，并指定NOPASSWD:/usr/bin/docker来让jenkins使用。还有root的ssh私钥要复制到gitlab某个帐户下面。把私钥放到jenkins的凭据中，这样才能使jenkins git clone代码下来。gitlab中的用户必须对所有项目或者大部分项目有pull权限。
```



```bash
#!/bin/sh
#describe: .net core build docker and push private registory
#author: jackli
#datetime: 2020-06-04-10:17

#init variables
JobName=${JOB_NAME}
VersionFile=$1
ProjectName=
MirrorName=
TagName=
Username='jenkins'
Password='Homsom+4006'
Repository='192.168.13.235:8000'
shelldir="/shell"
DateFile="${shelldir}/.date"
CurrentDate=$(date +"%d")

#init Date Parameter,use whether delete clear_docker
group=`ls -l -d /shell | awk '{print $4}'`
[ ${group} == 'jenkins' ] || (sudo /usr/bin/chown -R root:jenkins ${shelldir}; sudo /usr/bin/chmod -R 770 ${shelldir})
[ -f ${DateFile} ] || (sudo /usr/bin/touch ${DateFile}; sudo /usr/bin/chown jenkins:jenkins ${DateFile}; sudo /usr/bin/chmod 770 ${DateFile})
[ -z ${DateFile} ] && echo $(date +"%d") > ${DateFile}
Date=$(cat ${DateFile})

info(){
	echo "---------Example Statement----------"
        echo "ProjectName:fat"
        echo "MirrorName:systemlog"
        echo "TagName:v1"
        echo "------------------------------------"
}

#clear docker container and image cache
clear_docker(){
	#delete docker container is Exited.
	echo "delete docker container is Exited.------------------------------"
	Exited_Containers=$(sudo docker ps -a | grep -v CONTAINER | grep 'Exited' |  awk '{print $1}')
	for i in ${Exited_Containers};do
		echo "Delete Exited Container $i ........."
		sudo docker rm $i 
		if [ $? == 0 ];then
			echo "INFO: Exited Status Container ${i} Delete Succeed" 
		else
			echo "ERROR: Exited Status Container ${i} Delete Failure" 
		fi
	done
	

	#delete local name is <none> image
	echo "delete local name is <none> image---------------------------"
	NoNameImage=$(sudo docker image ls | grep '<none>' | awk '{print $3}') #if not delete name is <none> image,annotation can be. 
	for i in ${NoNameImage};do
		echo "delete local not name image $i ........."
		sudo docker image rm $i 
		if [ $? == 0 ];then
			echo "INFO: Local not name Image ${i} Delete Succeed" 
		else
			echo "ERROR: Local not name Image ${i} Delete Failure" 
		fi
	done

}

#change to workspace
cd /var/lib/jenkins/workspace/${JobName}

#check ${JobName}/${VersionFile} file
echo "check ${JobName}/${VersionFile} file legal--------------------------------"
if [ -f $VersionFile ];then
	ProjectNameNum=$(grep -Ev '#|^$' $VersionFile | grep -i '^ProjectName' | wc -l)
	MirrorNameNum=$(grep -Ev '#|^$' $VersionFile | grep -i '^MirrorName' | wc -l)
	TagNameNum=$(grep -Ev '#|^$' $VersionFile | grep -i '^TagName' | wc -l)
	num=$((${ProjectNameNum}+${MirrorNameNum}+${TagNameNum}))
	if [ $num -gt 3 ];then
		echo "ERROR: $VersionFile only allow have one ProjectName,MirrorName,TagName"
		info
		exit 2
	else
		ProjectName=$(grep -Ev '#|^$' $VersionFile | awk '{sub(/^[[:blank:]]*/,"",$0);sub(/[[:blank:]]*$/,"",$0);gsub(/[[:blank:]]*/,"",$0);print $0}' | grep -i '^ProjectName' | awk -F : '{print $2}')
		[ -z $ProjectName ] && echo "Error: ProjectName value is null" && info && exit 2
		MirrorName=$(grep -Ev '#|^$' $VersionFile | awk '{sub(/^[[:blank:]]*/,"",$0);sub(/[[:blank:]]*$/,"",$0);gsub(/[[:blank:]]*/,"",$0);print $0}' | grep -i '^MirrorName' | awk -F : '{print $2}')
		[ -z $MirrorName ] && echo "Error: MirrorName value is null" && info && exit 2
		TagName=$(grep -Ev '#|^$' $VersionFile | awk '{sub(/^[[:blank:]]*/,"",$0);sub(/[[:blank:]]*$/,"",$0);gsub(/[[:blank:]]*/,"",$0);print $0}' | grep -i '^TagName' | awk -F : '{print $2}')
		[ -z $TagName ] && echo "Error: TagName value is null" && info && exit 2
	fi
else
	echo "Error: ${ProjectName}/${VersionFile} file does not exist"
	info
	exit 2;
fi

#build docker image
echo "build docker image---------------------------------"
echo "build image ${ProjectName}/${MirrorName}:${TagName}........"
sudo docker build -t ${ProjectName}/${MirrorName}:${TagName} . 
if [ $? == 0 ];then
	echo "INFO: Docker Build Image Succeed" 
else
	echo "ERROR: Docker Build Image Failure" 
	clear_docker
	exit 6
fi

#login private repository
echo "login private repository-----------------------------"
echo "login ${Repository}........."
sudo docker login -u ${Username} -p ${Password} ${Repository} 
if [ $? == 0 ];then
	echo "INFO: Login Succeed"
else
	echo "ERROR: Login Failure"
	exit 6
fi

#tag image 
echo "tag image---------------------------------"
echo "tag image ${ProjectName}/${MirrorName}:${TagName} to ${Repository}/${ProjectName}/${MirrorName}:${TagName}........"
sudo docker tag ${ProjectName}/${MirrorName}:${TagName} ${Repository}/${ProjectName}/${MirrorName}:${TagName} 
if [ $? == 0 ];then
	echo "INFO: Tag Image Succeed" 
else
	echo "ERROR: Tag Image Failure" 
	exit 6
fi

#push local image to remote repository
echo "push local image to remote repository----------------------------"
echo "push local image ${Repository}/${ProjectName}/${MirrorName}:${TagName} to remote repository ${Repository}......."
sudo docker push ${Repository}/${ProjectName}/${MirrorName}:${TagName} 
if [ $? == 0 ];then
	echo "INFO: Push ${Repository}/${ProjectName}/${MirrorName}:${TagName} Image To Remote Repository Succeed" 
else
	echo "ERROR: Push ${Repository}/${ProjectName}/${MirrorName}:${TagName} Image To Romote Repository Failure" 
	exit 6
fi

#logout private repository
echo "logout ${Repository}-------------------------------"
sudo docker logout ${Repository} 
if [ $? == 0 ];then
	echo "INFO: Logout Succeed" 
else
	echo "ERROR: Logout Failure" 
	exit 6
fi


#delete local build and push image
echo "delete local build and push image------------------------------"
echo "delete local image ${ProjectName}/${MirrorName}:${TagName} and ${Repository}/${ProjectName}/${MirrorName}:${TagName}........"
sudo docker image rm ${ProjectName}/${MirrorName}:${TagName} ${Repository}/${ProjectName}/${MirrorName}:${TagName} 
if [ $? == 0 ];then
	echo "INFO: Local Image ${ProjectName}/${MirrorName}:${TagName} ${Repository}/${ProjectName}/${MirrorName}:${TagName} Delete Succeed" 
else
	echo "ERROR: Local Image ${ProjectName}/${MirrorName}:${TagName} ${Repository}/${ProjectName}/${MirrorName}:${TagName} Delete Failure" 
	exit 6
fi

#call clear_docker function	
if [[ ${CurrentDate} != ${Date} ]];then
	clear_docker
	#insert new date
	echo $(date +"%d") > ${DateFile}

fi
```

--构建后操作：
----Editable Email Notification:
------Project Recipient List：test@test.com,test2@test.com  #这里填入收件人邮箱名单
------Project Reply-To List:发件人邮箱
------Content Type:HTML(text/html)
------Default Subject:$DEFAULT_SUBJECT
------Default Content:$DEFAULT_CONTENT
------Attach Build Log:do not attach build log
------点击advanced setting打开高级设置：
--------Pre-send Script：$DEFAULT_PRESEND_SCRIPT
--------Post-send Script：$DEFAULT_POSTSEND_SCRIPT
--------Triggers:选择Always类型，Sent To Recipient List(这个表示发送给前面设置的Project Recipient List收件人名单)
注：前面有好多是默认选项，只需要设置特定的信息即可。



## jenkins使用LDAP登录

例如:AD域（域登录和jenkins只能选其一，不能同时并存）

1. 安装LDAP插件
2. 然后在全局安全设置中设置LDAP认证。
	1. server: ldap://192.168.10.250:389
	2. root DN: DC=hs,DC=com  #DN表示一个对象，从大到小，精确到单元。这里是root的DN，所以只填写DC(域)的DN
	3. User search base: OU=技术部   #表示从root DN下的哪个组织单位查找用户
	4. User search filter: sAMAccountName={0}  #搜索用户过滤条件
	5. Group search base: OU=技术部   #表示从root DN下的哪个组织单位查找组
	6. Group membership：选择Search for LDAP groups containing user(Group membership filter不用填)
	7. Manager DN: CN=admin,OU=技术部,DC=hs,DC=com  #设置可以管理域用记的管理帐户，不能在Users默认组织单元下。CN表示域中用户名称的名称，不是用户的登录名，千万不要弄错，否则不会成功。
	8. Manager Password: 填写admin的域密码。
	9. 其他未提到的为默认。全部填写完后可以测试在User search base中的用户是否成功登录。
	    注：测试成功后就可以使用域帐户进行认证了。








## jenkins shell删除构建历史 
```bash
def jobName = "MobileService" //删除的项目名称
def maxNumber = 5000 // 保留的最小编号，意味着小于该编号的构建都将被删除

Jenkins.instance.getItemByFullName(jobName).builds.findAll {
it.number <= maxNumber
}.each {
it.delete()
}
```





## jenkins安装



### war包方式



#### 1. 下载jenkins.war包
[jenkins.war](https://get.jenkins.io/war-stable/2.222.3/jenkins.war)



#### 2. 安装jdk_1.8

[jdk-8u201](https://repo.huaweicloud.com/java/jdk/8u201-b09/jdk-8u201-linux-x64.tar.gz)

```bash
root@jenkins:/download# tar xf jdk-8u201-linux-x64.tar.gz -C /usr/local/
root@jenkins:/download# ln -sv /usr/local/jdk1.8.0_201/ /usr/local/jdk
root@jenkins:/usr/local/jdk# echo 'export PATH=$PATH:/usr/local/jdk/bin' > /etc/profile.d/jdk.sh
root@jenkins:/usr/local/jdk# . /etc/profile.d/jdk.sh
root@jenkins:/usr/local/jdk# java -version
java version "1.8.0_201"
Java(TM) SE Runtime Environment (build 1.8.0_201-b09)
Java HotSpot(TM) 64-Bit Server VM (build 25.201-b09, mixed mode)
```



#### 3. 运行war包

```bash
root@jenkins:/usr/local# cat /etc/security/limits.conf
*       soft        nofile  655350
*       hard        nofile  655350
*       soft        nproc   655350
*       hard        nproc   655350
root        soft        nofile  655350
root        hard        nofile  655350
root        soft        nproc   655350
root        hard        nproc   655350
root@jenkins:/usr/local/jdk# mkdir -p /usr/local/jenkins /var/lib/jenkins /var/log/jenkins
root@jenkins:/usr/local/jdk# mv /download/jenkins.war /usr/local/jenkins/
root@jenkins:/usr/local/jdk# groupadd -r -g 8080 jenkins
root@jenkins:/usr/local/jdk# useradd -r -g jenkins -u 8080 -s /sbin/nologin jenkins
root@jenkins:/usr/local/jdk# chown -R root.jenkins /usr/local/jenkins/ /var/lib/jenkins /var/log/jenkins/
root@jenkins:/usr/local/jenkins# chmod -R 2774 /usr/local/jenkins/ /var/lib/jenkins /var/log/jenkins/

# -Djava.awt.headless=true 开启headless功能
# -Dcom.sun.akuma.Daemon=daemonized 以后台程序运行
# --prefix参数是 headless模式特有的，配置多个jenkins，使用前缀来区分，不能使用'/'
root@jenkins:/usr/local/jenkins# cat /lib/systemd/system/jenkins.service
[Unit]
Description=https://www.jenkins.io/
After=network-online.target

[Service]
User=jenkins
Group=jenkins
Type=forking
ExecStart=/usr/local/jdk/bin/java -DJENKINS_HOME=/var/lib/jenkins -jar /usr/local/jenkins/jenkins.war --logfile=/var/log/jenkins/jenkins.log --webroot=/usr/local/jenkins/war --daemon --httpPort=8
Restart=on-failure

[Install]
WantedBy=multi-user.target


root@jenkins:/usr/local/jenkins# systemctl daemon-reload
root@jenkins:/usr/local/jenkins# ps -ef | grep jenkins
root       2150    671  0 13:21 pts/0    00:00:00 systemctl restart jenkins
jenkins    2152      1 36 13:21 ?        00:00:23 /usr/local/jdk/bin/java -DJENKINS_HOME=/var/lib/jenkins -jar /usr/local/jenkins/jenkins.war --logfile=/var/log/jenkins/jenkins.log --webroot=/usr/local/jenkins/war --daemon --httpPort=8080 --debug=5 --handlerCountMax=100 --handlerCountMaxIdle=20
root       2195   2042  0 13:22 pts/1    00:00:00 grep --color=auto jenkins
```



#### 4. 访问jenkins并输入初始密码
GET http://172.168.2.13:8080/login?from=%2F
root@jenkins:~# cat /var/lib/jenkins/secrets/initialAdminPassword
4e9ca59a8bc8414ead6ae9955779f1b2



### docker方式

使用docker部署jenkins，后续并使用docker-in-docker构建镜像

```bash
# 配置宿主机目录权限，使容器用户jenkins(id:1000)具有读写权限
[root@jenkins ~]# mkdir -p /data/jenkins/datadir && chown -R 1000:1000 /data/jenkins
[root@jenkins ~]# ll /data/jenkins
total 0
drwxr-xr-x 2 1000 1000 6 Nov 22 14:33 datadir

# 安装docker
# 8080: web端口，5000: slave端口
# /var/jenkins_home为jenkins工作目录，里面有job、user、secrets、plugin等全部重要信息在此
# /var/jenkins_home/war为jenkins WEBAPP目录
[root@jenkins ~]# docker run -d --name jenkins --privileged=true -p 8080:8080 -p 50000:50000 -v /etc/localtime:/etc/localtime:ro -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -v /data/jenkins/datadir:/var/jenkins_home harborrepo.hs.com/ops/jenkins:2.222.3-centos7
# 获取初始化密码
[root@jenkins /data/jenkins/datadir]# cat /data/jenkins/datadir/secrets/initialAdminPassword
ba38061cadd14a00bddf949754b00119
```



#### 解决jenkins用户无法使用docker权限问题


```bash
# 以root用户运行配置jenkins用户隶属于docker组
[root@jenkins ~]# grep docker /etc/group
docker:x:993:
[root@jenkins /data/jenkins/datadir]# docker exec -it -u root jenkins bash
[root@b0665d55f951 ~]# groupadd docker -g 993		# 和宿主机保持一致
[root@b0665d55f951 ~]# gpasswd -a jenkins docker	# 或者 usermod -G docker jenkins
[root@b0665d55f951 ~]# id jenkins
uid=1000(jenkins) gid=1000(jenkins) groups=1000(jenkins),993(docker)
# jenkins用户打开新bash，此时有了docker运行权限
[root@jenkins /data/jenkins]# docker exec -it jenkins /bin/sh
sh-4.2$ id
uid=1000(jenkins) gid=1000(jenkins) groups=1000(jenkins),993(docker)
sh-4.2$ docker ps -a
CONTAINER ID   IMAGE                                           COMMAND                  CREATED         STATUS         PORTS                                              NAMES
eb2fec61ac29   harborrepo.hs.com/ops/jenkins:2.222.3-centos7   "/sbin/tini -- /usr/…"   2 minutes ago   Up 2 minutes   0.0.0.0:8080->8080/tcp, 0.0.0.0:50000->50000/tcp   jenkins
```







## jenkins备份和恢复

`建议恢复环境和备份环境强一制，系统必须一样`



### 手动方式

#### 1. 备份老jenkins

`users: 用户数据`
`plugins: 插件目录，跟*pluggin*.xml对应，必须拷坝`
`secrets: jenkins使用git操作所需要的凭据，非常重要`
`*.xml: 全局配置和其它插件配置`
`userContent：用户相关内容信息`

```bash
[root@BuildImage /shell]# cat jenkins_backup.sh 
#!/bin/bash  

BACKUP_DIR='/winbackup/192.168.13.214'
COMPILE_ENV="${BACKUP_DIR}/compile.env"
COMPILE_TOOLS="${BACKUP_DIR}/tools"

# mkdir
mkdir -p ${COMPILE_TOOLS}


#  Jenkins Configuraitons Directory  
cd /var/lib/jenkins
  
#  Add general configurations, job configurations, and user content  
rsync -avPz *.xml users plugins secrets userContent /etc/sudoers /shell ${BACKUP_DIR}
#\cp -a *.xml users plugins secrets userContent /etc/sudoers /shell ${BACKUP_DIR}

for i in `ls jobs/*/*.xml`;do
	job_name=`echo $i | awk -F'config.xml' '{print $1}'`
	mkdir -p ${BACKUP_DIR}/$job_name
	\cp -a $i ${BACKUP_DIR}/$job_name
done

# compile env output
ls -l /usr/local/ | grep -E 'maven|node ' > ${COMPILE_ENV}  
\cp -a /usr/local/maven/conf/settings.xml ${COMPILE_TOOLS}/maven-settings.xml
\cp -a /root/.npmrc ${COMPILE_TOOLS}/node-.npmrc
```



#### 2. 恢复到新的jenkins

```bash
root@jenkins:~# systemctl stop jenkins
root@jenkins:~# \cp -a /var/lib/jenkins /tmp/
root@jenkins:~# rm -rf /var/lib/jenkins/*
root@jenkins:~# \cp -a /winbackup/192.168.13.214/* /var/lib/jenkins/
root@jenkins:~# ls /var/lib/jenkins/
.....省略

root@jenkins:/var/lib/jenkins# chown -R root.jenkins /var/lib/jenkins/ && chmod -R 2774 /var/lib/jenkins/
root@jenkins:~# systemctl start jenkins
```



#### 3. 还原jenkins流水线执行脚本

```bash
root@jenkins:/var/lib/jenkins# \cp -ap /winbackup/192.168.13.214/shell/ /
root@jenkins:/var/lib/jenkins# chown -R root.jenkins /shell && chmod -R 770 /shell

# 替换 /bin/sh 为 /bin/bash，centos使用的是/bin/bash
root@jenkins:/var/lib/jenkins# sed -i 's|/bin/sh|/bin/bash|g' /shell/*

# 批量更改脚本执行shell环境
jenkins@jenkins:~$ rm /bin/sh
root@jenkins:~# ln -sv /bin/bash /bin/sh
root@jenkins:~# ls -l /bin/*sh
-rwxr-xr-x 1 root root 1113504 Jun  7  2019 /bin/bash
-rwxr-xr-x 1 root root  121432 Jan 25  2018 /bin/dash
lrwxrwxrwx 1 root root       4 Mar 31  2022 /bin/rbash -> bash
lrwxrwxrwx 1 root root       9 Nov 21 15:54 /bin/sh -> /bin/bash
lrwxrwxrwx 1 root root       7 Mar  7  2019 /bin/static-sh -> busybox
```



#### 4. 安装跟老jenkins上一样的编译环境

```bash
# git安装
root@jenkins:/var/lib/jenkins# git version
git version 2.17.1

# 安装maven和node.js
root@jenkins:/download# tar xf apache-maven-3.3.9-bin.tar.gz -C /usr/local/
root@jenkins:/download# tar xf node-v16.20.2-linux-x64.tar.gz -C /usr/local/
root@jenkins:/download# ln -sv /usr/local/apache-maven-3.3.9/ /usr/local/maven
'/usr/local/maven' -> '/usr/local/apache-maven-3.3.9/'
root@jenkins:/download# ln -sv /usr/local/node-v16.20.2-linux-x64/ /usr/local/node
'/usr/local/node' -> '/usr/local/node-v16.20.2-linux-x64/'
root@jenkins:/download# cat /etc/profile.d/node.sh /etc/profile.d/maven.sh
export PATH=$PATH:/usr/local/node/bin
export PATH=$PATH:/usr/local/maven/bin/
root@jenkins:/download# source /etc/profile
root@jenkins:/download# mvn --version
Apache Maven 3.3.9 (bb52d8502b132ec0a5a3f4c09453c07478323dc5; 2015-11-11T00:41:47+08:00)
Maven home: /usr/local/maven
Java version: 1.8.0_201, vendor: Oracle Corporation
Java home: /usr/local/jdk1.8.0_201/jre
Default locale: en_US, platform encoding: ISO-8859-1
OS name: "linux", version: "4.15.0-112-generic", arch: "amd64", family: "unix"
root@jenkins:/download# node --version
v16.20.2

## 配置maven
root@jenkins:/usr/local/maven# cp /winbackup/192.168.13.214/tools/settings.xml ./conf/
root@jenkins:/usr/local/maven# cat conf/settings.xml
    <mirror>
      <id>mirrorHomsom</id>
      <mirrorOf>*</mirrorOf>
      <name>NexusHomsom</name>
      <url>http://nexus.hs.com/repository/maven-public/</url>
    </mirror>
  </mirrors>

    <profile>
      <id>mirrorHomsom</id>
      <repositories>
        <repository>
                <id>mirrorHomsom</id>
                <name>mirrorHomsom</name>
                <url>http://nexus.hs.com/repository/maven-public/</url>
                <releases>
                        <enabled>true</enabled>
                </releases>
                <snapshots>
                        <enabled>true</enabled>
                </snapshots>
                <layout>default</layout>
                <snapshotPolicy>always</snapshotPolicy>
        </repository>
      </repositories>

        <pluginRepositories>
                <pluginRepository>
                <id>mirrorHomsom</id>
                <name>mirrorHomsom</name>
                <url>http://nexus.hs.com/repository/maven-public/</url>
                <releases>
                        <enabled>true</enabled>
                </releases>
                <snapshots>
                        <enabled>true</enabled>
                </snapshots>
                </pluginRepository>
        </pluginRepositories>
    </profile>
---
root@jenkins:/usr/local/maven# mkdir -p /data/mavenrepo
## 下载缓存包，可忽略
root@jenkins:/usr/local/maven# mvn help:system

## 配置node.js
root@jenkins:/usr/local/maven# mkdir -p /home/jenkins && chown -R jenkins.jenkins /home/jenkins/
root@jenkins:/usr/local/maven# cp /winbackup/192.168.13.214/tools/.npmrc /home/jenkins/
root@jenkins:/usr/local/maven# cat /home/jenkins/.npmrc
registry=http://nugetv3.hs.com/repository/npm-proxy/


# 配置sudo
root@jenkins:/usr/local/maven# cat /etc/sudoers
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/local/jdk/bin:/usr/local/maven/bin/:/usr/local/node/bin"
jenkins ALL=(ALL:ALL) NOPASSWD: ALL


# 安装docker
root@jenkins:/etc/apt/sources.list.d# sed -i 's|http://mirrors.aliyun.com/ubuntu/|http://repo.hs.com/repository/ubuntu-bionic/|g' /etc/apt/sources.list
root@jenkins:/etc/apt/sources.list.d# cat /etc/apt/sources.list
deb http://repo.hs.com/repository/ubuntu-bionic/ bionic main restricted universe multiverse
deb-src http://repo.hs.com/repository/ubuntu-bionic/ bionic main restricted universe multiverse

deb http://repo.hs.com/repository/ubuntu-bionic/ bionic-security main restricted universe multiverse
deb-src http://repo.hs.com/repository/ubuntu-bionic/ bionic-security main restricted universe multiverse

deb http://repo.hs.com/repository/ubuntu-bionic/ bionic-updates main restricted universe multiverse
deb-src http://repo.hs.com/repository/ubuntu-bionic/ bionic-updates main restricted universe multiverse

deb http://repo.hs.com/repository/ubuntu-bionic/ bionic-proposed main restricted universe multiverse
deb-src http://repo.hs.com/repository/ubuntu-bionic/ bionic-proposed main restricted universe multiverse

deb http://repo.hs.com/repository/ubuntu-bionic/ bionic-backports main restricted universe multiverse
deb-src http://repo.hs.com/repository/ubuntu-bionic/ bionic-backports main restricted universe multiverse
---
## 安装依赖包和添加docker软件源
root@jenkins:~# apt update -y
root@jenkins:~# apt-get -y install apt-transport-https ca-certificates curl software-properties-common gpg-agent
root@jenkins:/etc/apt/sources.list.d# curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -
root@jenkins:/etc/apt# add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
root@jenkins:/etc/apt# sed -i 's|https://mirrors.aliyun.com/docker-ce|http://repo.hs.com/repository/ubuntu-bionic-docker/|g' /etc/apt/sources.list
root@jenkins:/etc/apt# cat /etc/apt/sources.list
deb http://repo.hs.com/repository/ubuntu-bionic/ bionic main restricted universe multiverse
deb-src http://repo.hs.com/repository/ubuntu-bionic/ bionic main restricted universe multiverse

deb http://repo.hs.com/repository/ubuntu-bionic/ bionic-security main restricted universe multiverse
deb-src http://repo.hs.com/repository/ubuntu-bionic/ bionic-security main restricted universe multiverse

deb http://repo.hs.com/repository/ubuntu-bionic/ bionic-updates main restricted universe multiverse
deb-src http://repo.hs.com/repository/ubuntu-bionic/ bionic-updates main restricted universe multiverse

deb http://repo.hs.com/repository/ubuntu-bionic/ bionic-proposed main restricted universe multiverse
deb-src http://repo.hs.com/repository/ubuntu-bionic/ bionic-proposed main restricted universe multiverse

deb http://repo.hs.com/repository/ubuntu-bionic/ bionic-backports main restricted universe multiverse
deb-src http://repo.hs.com/repository/ubuntu-bionic/ bionic-backports main restricted universe multiverse

deb [arch=amd64] http://repo.hs.com/repository/ubuntu-bionic-docker/ bionic stable
# deb-src [arch=amd64] http://repo.hs.com/repository/ubuntu-bionic-docker/ bionic stable
---
## 安装docker-ce-19.03.15
root@jenkins:/etc/apt# apt-get -y update && apt-get -y install docker-ce=5:19.03.15~3-0~ubuntu-bionic
root@jenkins:/etc/apt# mkdir -pv /etc/docker
root@jenkins:/etc/apt# cat /etc/docker/daemon.json
{
        "registry-mirrors": ["http://hub-mirror.c.163.com","https://docker.mirrors.ustc.edu.cn","https://registry.docker-cn.com"],
        "insecure-registries": ["http://192.168.13.235:8000","http://192.168.13.197:8000","harbor.hs.com","harborrepo.hs.com"],
        "log-driver":"json-file",
        "log-opts": {"max-size":"500m", "max-file":"3"}
}
root@jenkins:/etc/apt# systemctl daemon-reload && systemctl enable docker && systemctl restart docker
```



#### 5. 配置git免密认证

```bash
## 因为使用gitops，所以需要配置jenkins服务器使用git免密认证克隆仓库
## 如果jenkins构建脚本使用的是sudo权限，则需要生成/roo/.ssh/id_rsa的非对称密钥

root@jenkins:/git# ssh-keygen -t rsa -f /home/jenkins/.ssh/id_rsa
root@jenkins:/git# cat /home/jenkins/.ssh/id_rsa.pub	# 配置到gitlab上，使本用户具有git修改权限
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDae3FJMehi+H881gENb58F+7FAQUorIThdujeXvvqK75gKMM2qQU0ieukNf73qwVYdHISIQWruXBHRgdNuz9VKJOTQesSVTYuWvP/uDwoyv27yJsHhA+BLeEhBSFhIA3BUPaXON8ROoQNfwcslixnVOAmUFb5QLCt5hfg1McvskMH/2mPhyGzzRPvlZJYgzbCdv89ucfbpiEy8Ey3TEycqB5LCFcvAayBXucQQVLbPi/G3yRMrTedui1BJervRtmjvkfgKzTHZJGCgs8lnsi+ojOog0iiDlD3g1mUk/ozIx5AGEX4xhKNODdyZSWRxab3WC+VX/NebxiYtsc6lcCsJ root@jenkins
root@jenkins:/git# chown -R root.jenkins /git/ && chmod -R 2775 /git/ # 此目录gitops需要存储克隆仓库

```



#### 6. 批量更改jenkins参数化过程参数

`原因：经过测试，迁移过来的所有job流水线在构建时无法读取Jenkins的变量'Language'，系统最初为CentOS7，目前为Ubuntu18.04`
`解决：经过测试将其改为变量'tech'可以读取，于是以下为批量更改参数`

```bash
# 将变量名Language替换为变量名tech
root@jenkins:/var/lib/jenkins# grep Language jobs/testd.k8s.hs.com/config.xml
          <name>Language</name>
root@jenkins:/var/lib/jenkins# sed -i 's/Language/tech/g' jobs/testd.k8s.hs.com/config.xml
root@jenkins:/var/lib/jenkins# grep Language jobs/testd.k8s.hs.com/config.xml
root@jenkins:/var/lib/jenkins# grep tech jobs/testd.k8s.hs.com/config.xml
          <name>tech</name>

root@jenkins:/var/lib/jenkins# systemctl restart jenkins.service

# 脚本
cd /var/lib/jenkins && for i in `ls jobs`;do sed -i 's/Language/tech/g' jobs/$i/config.xml;done
root@jenkins:/var/lib/jenkins# systemctl restart jenkins.service
```



## 插件方式备份和恢复

```bash
#jeinkins
#20210623

#jeknins备份还原时，源服务器版本和目标服务器版本号必须一样(子版本号和大版本号一样)
例如：
源服务器： jenkins-2.222.3
目标服务器：jenkins-2.222.3
如果源服务器和目标服务器子版本号不一样也会还原失败，因为有些插件还原时低版本不兼容，所以必须保持一致

源服务器和目标服务器都要安装ThinBackup插件，安装好后重启服务器并应用使之生效。
源服务器：在系统管理--ThinBackup中进行设置，设置备份目录（也是还原目录），其它可选
备份源服务器：点击Backup Now进行立即备份，

目标服务器：先安装ThinBackup插件，安装好后重启服务器并应用使之生效。
目标服务器：在系统管理--ThinBackup中进行设置，设置备份目录（也是还原目录），其它可选
还原目标服务器： 点击Restore进行还原，此操作会等待一会，可观察jenkins家目录，例如：/var/lib/jenkins/下的文件是否有变化，可用命令：
[root@LocalServer /var/lib/jenkins]# watch -n 1 'tree | wc -l'
注：以上命令可查看jenkins家目录下文件是否有变化 ，等待无变化时可到jenkinsUI界面查看是否已经完成备份，完成备份后可重启jenkins服务，方式有两种：

1. 在插件管理中重启服务
2. 在服务器上重启服务：systemctl restart jenkins

#jenkins升级：
原版本：jenkins-2.222
新版本：jenkins-2.222-3

1. 先停止jenkins服务
2. 进行备份
   [root@LocalServer /shell]# mv /usr/lib/jenkins/jenkins.war{,_2.222}
3. 下载新版本War文件予以替换
   curl -OL http://unzip.top:8088/software/jenkins.war
   cp jenkins.war /usr/lib/jenkins
4. 重启jenkins服务即可
   systemctl restart jenkins 

#jenkins升级遗留问题

1. 有些插件未成功安装，提示需要升级到enkins-2.222-4及以上版本
2. 因为插件原因而不能正常发布的问题等
   #解决升级遗留问题
3. 升级jenkins,因为之前备份还原已经成功，此时再升级解决插件等问题。
4. 因为需要升级到enkins-2.222-4及以上版本，所以在系统管理界面上有提示新的版本可用，我就选择了提示的版本进行下载：jenkins-2.289-1
5. 跟上面方法一样，将war包下载并替换/usr/lib/jenkins/jenkins.war包，并重启jenkins服务即可。
6. 此时在UI打开jenkins服务，跟上一步升级不同，因为这个升级是跨大版本升级，所以这里会跟新配置jenkins服务器一样需要让你选择，不过没有解锁步骤，你选择相应插件安装即可。成功后会提醒你重启jenkins服务。最后重启即可升级完成。

#注：备份还原，其实只要目标服务器版本比源服务器版本新就可以了
```



## jenkins插件下载更改代理

**更改位置一：/data/jenkins/datadir/updates/default.json**
source：

1. https://updates.jenkins.io/download
2. https://www.google.com/

destination:

1. https://mirrors.tuna.tsinghua.edu.cn/jenkins
2. https://www.baidu.com/



**更改位置二：/data/jenkins/datadir/hudson.model.UpdateCenter.xml**
source: https://updates.jenkins.io/download/updates/update-center.json
destination：https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json

```bash
[root@jenkins /data/jenkins/datadir]# cat hudson.model.UpdateCenter.xml
<?xml version='1.1' encoding='UTF-8'?>
<sites>
  <site>
    <id>default</id>
    <url>https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json</url>
  </site>
</sites>
```

**以上多个位置更改后，需要重启Jenkins服务生效**

**在安装最新jenkins时生效，经过几年后再使用此方法时不生效**





# Jenkins for pipeline

`实现基于Jenkins的K8s发布功能`



## 安装


* 安装jenkins，并安装以下插件
```
Git
Git Parameter
Git Pipeline for Blue Ocean
GitLab
Credentials
Credentials Binding
Blue Ocean
Blue Ocean Pipeline Editor
Blue Ocean Core JS
Pipeline SCM API for Blue Ocean
Dashboard for Blue Ocean
Build With Parameters
Dynamic Extended Choice Parameter Plug-In
Dynamic Parameter Plug-in
Extended Choice Parameter
List Git Branches Parameter
Pipeline
Pipeline: Declarative
Kubernetes
Kubernetes CLI
Kubernetes Credentials
Image Tag Parameter
Active Choices
Generic Webhook Trigger
```
* 安装gitlab
* 安装harbor
* 部署Kubernetes
* [Pipeline常用变量](http://Jenkins_URL/pipeline-syntax/globals)



## 配置Jenkins


**配置gitlab访问凭证**

1. 在jenkins服务器生成ssh-key密钥对，将公钥放到gitlab中有权限用户的SSH密钥中，免密访问gitlab
2. 将ssh-key密钥对的私钥复制到jenkins全局凭证中，名称为gitlab，类型为`SSH Username with private key`

**配置harbor访问凭证**
1. 在harbor中创建对应仓库用户和密码
2. 将用户和密码放到jenkins全局凭证中，ID为harbor，类型为`Username with password`

**配置k8s访问凭证**

1. 制作有权限部署到k8s的kubeconfig
2. 复制kubeconfig内容到新文件中，将将新文件上传到jenkins全局凭证中，ID为kubernetes，类型为`Secret file`



## 创建项目hotelbusiness.service

![](./images/jenkins/jenkins-job01.png)
![](./images/jenkins/jenkins-job02.png)



## 编写Jenkinsfile

```bash
pipeline {
  agent {
    kubernetes {
      cloud 'test-kubernetes'
      slaveConnectTimeout 1200
      workspaceVolume hostPathWorkspaceVolume(hostPath: "/opt/workspace", readOnly: false)
      yaml '''
kind: Pod
spec:
  nodeSelector:
    build: "true"
  restartPolicy: "Never"
  securityContext: {}
  containers:
    - args: [\'$(JENKINS_SECRET)\', \'$(JENKINS_NAME)\']
      #image: 'registry.cn-beijing.aliyuncs.com/citools/jnlp:alpine'
      image: 'harborrepo.hs.com/k8s/jenkins-jnlp-slave:4.13-jdk11'
      name: "jnlp"
      imagePullPolicy: IfNotPresent
      volumeMounts:
      - mountPath: "/etc/localtime"
        name: "localtime"
        readOnly: false
    - command:
      - "cat"
      env:
      - name: "LANGUAGE"
        value: "en_US:en"
      - name: "LC_ALL"
        value: "en_US.UTF-8"
      - name: "LANG"
        value: "en_US.UTF-8"
      image: "registry.cn-beijing.aliyuncs.com/citools/maven:3.5.3"
      imagePullPolicy: "IfNotPresent"
      name: "build"
      tty: true
      volumeMounts:
      - mountPath: "/etc/localtime"
        name: "localtime"
      - mountPath: "/root/.m2/"
        name: "cachedir"
        readOnly: false
    - command:
      - "cat"
      env:
      - name: "LANGUAGE"
        value: "en_US:en"
      - name: "LC_ALL"
        value: "en_US.UTF-8"
      - name: "LANG"
        value: "en_US.UTF-8"
      image: "registry.cn-beijing.aliyuncs.com/citools/kubectl:self-1.17"
      imagePullPolicy: "IfNotPresent"
      name: "kubectl"
      tty: true
      volumeMounts:
      - mountPath: "/etc/localtime"
        name: "localtime"
        readOnly: false
    - command:
      - "cat"
      env:
      - name: "LANGUAGE"
        value: "en_US:en"
      - name: "LC_ALL"
        value: "en_US.UTF-8"
      - name: "LANG"
        value: "en_US.UTF-8"
      image: "registry.cn-beijing.aliyuncs.com/citools/docker:19.03.9-git"
      imagePullPolicy: "IfNotPresent"
      name: "docker"
      tty: true
      volumeMounts:
      - mountPath: "/etc/localtime"
        name: "localtime"
        readOnly: false
      - mountPath: "/var/run/docker.sock"
        name: "dockersock"
        readOnly: false
  volumes:
  - hostPath:
      path: "/var/run/docker.sock"
    name: "dockersock"
  - hostPath:
      path: "/usr/share/zoneinfo/Asia/Shanghai"
    name: "localtime"
  - hostPath:
      path: "/opt/m2"
    name: "cachedir"
      '''
    }
  }

  options {
    //buildDiscarder(logRotator(numToKeepStr: '2'))
    //quietPeriod(5)
    //retry(1)
    //timeout(time: 1, unit: 'HOURS')
    timestamps()
  }
  
  triggers {
    cron('H */12 * * 6-7 ')
    //pollSCM('H */12 * * 6-7 ')
    //upstream(upstreamProjects: 'job1,job2', threshold: hudson.model.Result.SUCCESS)
  }
  
  //stages {
  //  stage('Example') {
  //    input {
  //      message "还继续么？"
  //      ok "继续"
  //      submitter "alice,admin"
  //      parameters {
  //        string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
  //      }
  //    }
  //  }
  //}
  
  stages {
    stage('Pulling Code') {
      parallel {
        stage('Pulling Code by Jenkins') {
          when {
            expression { 
              env.gitlabBranch == null 
            }
          }
          steps {
            git(changelog: true, poll: true, url: 'git@172.168.2.14:k8s/hotelbusiness.service.git', branch: "${BRANCH}", credentialsId: 'gitlab')
            script {
              COMMIT_ID = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
              DATE_TIME = sh(returnStdout: true, script: "date +'%Y%m%d%H%M%S'").trim()
              TAG = DATE_TIME + '-' + BUILD_NUMBER + '-' + COMMIT_ID
              println "Current branch is ${BRANCH}, Commit ID is ${COMMIT_ID}, Image TAG is ${TAG}"
            }
          }
        }

        stage('Pulling Code by trigger') {
          when {
            expression { 
              env.gitlabBranch != null 
            }	
          }
          steps {
            git(url: 'git@172.168.2.14:k8s/hotelbusiness.service.git', branch: env.gitlabBranch, changelog: true, poll: true, credentialsId: 'gitlab')
            script {
              COMMIT_ID = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
              DATE_TIME = sh(returnStdout: true, script: "date +'%Y%m%d%H%M%S'").trim()
              TAG = DATE_TIME + '-' + BUILD_NUMBER + '-' + COMMIT_ID
              println "Current branch is ${env.gitlabBranch}, Commit ID is ${COMMIT_ID}, Image TAG is ${TAG}"
            }
          }
        }
      }
    }

    stage('Building') { 
      steps {
        container(name: 'build') { 
          sh """
            mvn clean package -U -Dmaven.test.skip=true 
            ls target/*
          """
        }
      }
    }

    stage('Docker build for creating image') { 
      environment {
        HARBOR_USER = credentials('harbor')
      }	 
      steps {
        container(name: 'docker') { 
          sh """
            echo ${HARBOR_USER_USR} ${HARBOR_USER_PSW} ${TAG}
            docker build -t ${HARBOR_ADDRESS}/${REGISTRY_DIR}/${IMAGE_NAME}:${TAG} .
            docker login -u ${HARBOR_USER_USR} -p ${HARBOR_USER_PSW} ${HARBOR_ADDRESS}
            docker push ${HARBOR_ADDRESS}/${REGISTRY_DIR}/${IMAGE_NAME}:${TAG}
          """
        }
      }
    }

    stage('Deploying to K8s') { 
      environment {
        MY_KUBECONFIG = credentials('kubernetes')
      }
      steps {
        container(name: 'kubectl') { 
          sh"""
            /usr/local/bin/kubectl --kubeconfig $MY_KUBECONFIG set image deploy -l app=${IMAGE_NAME}-selector ${CONTAINER_NAME}=${HARBOR_ADDRESS}/${REGISTRY_DIR}/${IMAGE_NAME}:${TAG} -n $NAMESPACE
          """
        }
      }
    }
  }
  
  environment {
    COMMIT_ID = ""
    HARBOR_ADDRESS = "harborrepo.hs.com"
    REGISTRY_DIR = "test"
    IMAGE_NAME = "java-hotelbusiness-service-hs-com"
    NAMESPACE = "kubernetes"
    CONTAINER_NAME = "homsom-container"
    TAG = ""
  }
  parameters {
    gitParameter(branch: '', branchFilter: 'origin/(.*)', defaultValue: '', description: 'Branch for build and deploy', name: 'BRANCH', quickFilterEnabled: false, selectedValue: 'NONE', sortMode: 'NONE', tagFilter: '*', type: 'PT_BRANCH')
  }
  
  post {
    always {
      echo "Hello World!"
      echo "to do END"
    }
  }
}
```



## Dockerfile

```bash
# 项目结构
[root@BuildImage /tmp/hotelbusiness.service]# ll
total 28
-rw-r--r-- 1 root root  289 Jan 17 15:03 Dockerfile
-rw-r--r-- 1 root root  786 Jan 17 15:03 entrypoint.sh
-rw-r--r-- 1 root root 2116 Jan 17 15:06 hotelbusiness-service.yaml
-rw-r--r-- 1 root root 6357 Jan 17 17:13 Jenkinsfile
-rw-r--r-- 1 root root 4363 Jan 17 15:03 pom.xml
-rw-r--r-- 1 root root    0 Jan 17 15:03 README.md
drwxr-xr-x 4 root root   28 Jan 17 15:03 src
```

```bash
[root@BuildImage /tmp/hotelbusiness.service]# cat Dockerfile 
FROM harborrepo.hs.com/base/java/ops_java:8
EXPOSE 80

ENV TZ=Asia/Shanghai 
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR / 
ADD target/*.jar app.jar
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

[root@BuildImage /tmp/hotelbusiness.service]# cat entrypoint.sh 
#!/bin/bash

JAVA_ARGS='java -Xmx200m -Xss256k -XX:+UseParallelGC -XX:+UseParallelOldGC'

if [[ "${JAVA_ENVIRONMENT}" == 'pro' ]];then
	exec ${JAVA_ARGS} -javaagent:/jar/agent/skywalking-agent.jar -Dskywalking.agent.service_name=Hotel.operation.service.hs.com -Dskywalking.collector.backend_service=trace-skywalking.hs.com:11800 -jar app.jar --spring.profiles.active=${JAVA_ENVIRONMENT}
elif [[ "${JAVA_ENVIRONMENT}" == 'uat' ]];then
	exec ${JAVA_ARGS} -jar app.jar --spring.profiles.active=${JAVA_ENVIRONMENT}
elif [[ "${JAVA_ENVIRONMENT}" == 'fat' ]];then
	exec ${JAVA_ARGS} -jar -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=13372 app.jar --spring.profiles.active=${JAVA_ENVIRONMENT}
else
	echo "[ERROR]: JAVA_ENVIRONMENT variable not is pro | uat | fat"
	exit 10
fi
```





## 初始化K8s项目

```bash
# yaml文件
[root@BuildImage /tmp/hotelbusiness.service]# cat hotelbusiness-service.yaml 
apiVersion: v1
kind: Service
metadata:
  name: java-hotelbusiness-service-hs-com-service
spec:
  ports:
  - name: http
    nodePort: 43890
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: java-hotelbusiness-service-hs-com-selector
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    link.argocd.argoproj.io/external-link: http://172.168.2.30:8080/job/anvil.service.hs.com/
  name: java-hotelbusiness-service-hs-com-deployment
  labels:
    app: java-hotelbusiness-service-hs-com-selector
spec:
  replicas: 1
  revisionHistoryLimit: 5
  selector:
    matchLabels:
      app: java-hotelbusiness-service-hs-com-selector
  template:
    metadata:
      labels:
        app: java-hotelbusiness-service-hs-com-selector
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: java-hotelbusiness-service-hs-com-selector
              topologyKey: kubernetes.io/hostname
            weight: 50
      imagePullSecrets:
      - name: harborkey
      containers:
      - env:
        - name: JAVA_ENVIRONMENT
          value: fat
        image: harborrepo.hs.com/fat/anvil.service.hs.com:v20231228194247
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /actuator/health
            port: 80
          initialDelaySeconds: 120
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        name: homsom-container
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /actuator/health
            port: 80
          initialDelaySeconds: 120
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        resources:
          limits:
            cpu: 4
            memory: 1.5Gi
          requests:
            cpu: 10m
            memory: 50Mi
```



## 构建项目



### 手动构建项目

**注：创建完项目后，手动构建项目第一次会失败，第二次及以后将正常**

![手动构建项目](./images/jenkins/pipeline-manual.png)



### trigger构建项目

![配置触发器构建项目](./images/jenkins/pipeline-trigger-config01.png)
![配置触发器构建项目](./images/jenkins/pipeline-trigger-config02.png)



```bash
http://172.168.2.30:8080/project/hotelbusiness.service
a5ba9825e249291f768458c0e5429dfc
```

![触发器构建项目](./images/jenkins/gitlab-webhook.png)



![触发器构建项目](./images/jenkins/pipeline-trigger01.png)
![触发器构建项目](./images/jenkins/pipeline-trigger02.png)



### 查看k8s部署效果

![k8s部署项目](./images/jenkins/k8s-deploy01.png)
