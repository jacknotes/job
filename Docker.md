#Docker
<pre>
#Makedown激活
Email：Soar360@live.com
Key:GBPduHjWfJU1mZqcPM3BikjYKF6xKhlKIys3i1MU2eJHqWGImDHzWdD6xhMNLGVpbP2M5SN6bnxn2kSE8qHqNY5QaaRxmO3YSMHxlv2EYpjdwLcPwfeTG7kUdnhKE0vVy4RidP6Y2wZ0q74f47fzsZo45JE2hfQBFi2O9Jldjp1mW8HUpTtLA2a5/sQytXJUQl/QKO0jUQY4pa5CCx20sV1ClOTZtAGngSOJtIOFXK599sBr5aIEFyH0K7H4BoNMiiDMnxt1rD8Vb/ikJdhGMMQr0R4B+L3nWU97eaVPTRKfWGDE8/eAgKzpGwrQQoDh+nzX1xoVQ8NAuH+s4UcSeQ==
</pre>
<pre>
docker:redhat6.5下下载Centos源后，用sed -i 's/$releasever/7/g' /etc/yum.repos.d/Centos-7.repo  把releasever改成6的
[root@710c7a2a06aa application]# /usr/sbin/sshd 
Could not load host key: /etc/ssh/ssh_host_ed25519_key
[root@710c7a2a06aa application]# ssh-keygen -t rsa -f  /etc/ssh/ssh_host_ed25519_key  #可解决上面报错的问题
</pre>

![docker](https://github.com/jackli5689/job/blob/master/docker.png)
<pre>
三大理念：构建，运输，运行。
Docker组成：Docker Client,Docker Server
Docker组件：镜像（Image）,容器（Container）,仓库（Repository）
注意：当Docker服务端一挂，那么运行在Docker服务上面的镜像都挂了
镜像：应用镜像，MB级别
容器：从镜像创建的一个实例（类似kvm从系统镜像创建的虚拟机），容器是隔离的，但隔离得不彻底。
仓库：把镜像做完了放到仓库里面。
Docker的分层

docker:
部署难度：非常简单，启动速度：秒级，执行性能：和特别系统几乎一致，镜像体积：MB级别，管理效率：管理简单，隔离性：隔离性高，可管理性：单进程（不建议启动SSH），网络连接：比较弱

Docker快速入门：
[root@Linux-node1-salt ~]# yum install -y docker #安装docker
[root@Linux-node1-salt ~]# docker -v  #docker版本
Docker version 1.13.1, build 07f3374/1.13.1
[root@Linux-node1-salt ~]# systemctl start docker #启动docker
[root@Linux-node1-salt ~]# ifconfig  
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500  #docker自动创建的虚拟网卡
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 0.0.0.0
        ether 02:42:ee:37:11:b9  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
[root@Linux-node1-salt ~]# docker images #查看安装的镜像
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
[root@Linux-node1-salt ~]# docker search centos #docker镜像搜索
INDEX       NAME                                         DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
docker.io   docker.io/centos                             The official build of CentOS.                   5240      [OK]     
[root@Linux-node1-salt ~]# docker pull centos  #把查找到的镜像pull下来
Using default tag: latest
Trying to pull repository docker.io/library/centos ... 
latest: Pulling from docker.io/library/centos
a02a4930cb5d: Pull complete 
Digest: sha256:184e5f35598e333bfa7de10d8fb1cebb5ee4df5bc0f970bf2b1e7c7345136426
Status: Downloaded newer image for docker.io/centos:latest
[root@Linux-node1-salt ~]# docker images #查看同步过来的镜像
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
docker.io/centos    latest              1e1148e4cc2c        3 months ago        202 MB
[root@Linux-node1-salt ~]# docker save -o centos.tar centos #导出centos镜像到centos.tar
[root@Linux-node1-salt ~]# docker load --import centos.tar #导入安装centos
[root@Linux-node1-salt ~]# docker load < centos.tar #导入安装centos
[root@Linux-node1-salt ~]# docker rmi image_id  #删除镜像
[root@Linux-node1-salt ~]# docker run centos echo 'hello world' #运行centos并执行命令。镜像的名称必须在所有选项的后面，执行的命令可以有也可以没有。
[root@Linux-node1-salt ~]# docker ps -a #查看所有的容器状态
CONTAINER ID        IMAGE               COMMAND                CREATED             STATUS                     PORTS               NAMES
2e64ed511299        centos              "echo 'hello world'"   2 minutes ago       Exited (0) 2 minutes ago                       boring_dubinsky
[root@Linux-node1-salt ~]# docker run --name my-docker -t -i centos /bin/bash #运行cnetos容器，并设置容器名称，打开伪终端，打开输入，最后执行命令
[root@Linux-node1-salt ~]# docker ps -a
CONTAINER ID        IMAGE               COMMAND                CREATED                                                                                                     STATUS                      PORTS               NAMES
e3a540a4b30b        centos              "/bin/bash"            5 minutes ago                                                                                               Exited (0) 5 seconds ago                        my-docker
cc9b6726f55f        centos              "/bin/bash"            6 minutes ago                                                                                               Exited (0) 6 minutes ago                        mydocker
2e64ed511299        centos              "echo 'hello world'"   10 minutes ago                                                                                              Exited (0) 10 minutes ago                       boring_dubinsky
[root@Linux-node1-salt ~]# docker start my-docker #开启叫my-docker的容器
my-docker
[root@Linux-node1-salt ~]# docker ps -a
CONTAINER ID        IMAGE               COMMAND                CREATED                                                                                                     STATUS                      PORTS               NAMES
e3a540a4b30b        centos              "/bin/bash"            6 minutes ago                                                                                               Up 4 seconds  #已经开启了                                  my-docker
cc9b6726f55f        centos              "/bin/bash"            8 minutes ago                                                                                               Exited (0) 8 minutes ago                        mydocker
2e64ed511299        centos              "echo 'hello world'"   12 minutes ago                                                                                              Exited (0) 12 minutes ago                       boring_dubinsky
[root@Linux-node1-salt ~]# docker attach my-docker #进入容器，退出就退出了，不可靠。
[root@Linux-node1-salt ~]# nsenter #这个工具要安装，yum install -y util-linux可以安装，默认linux已经安装了，nsenter意为进入命名空间（name space enter）.
[root@Linux-node1-salt ~]# docker inspect -f "{{ .State.Pid }}" my-docker #查看容器叫my-docker的pid。如果pid为0则表示这个容器没有启动
14261
[root@Linux-node1-salt ~]# nsenter -t 14261 -m -u -i -n -p #进入容器
[root@e3a540a4b30b /]# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 13:41 ?        00:00:00 /bin/bash
root        16     0  0 13:43 ?        00:00:00 -bash  #通过nsenter新加的一个bash,退出时，pid为1的主bash还在运行着，所以这个是可靠的
root        38    16  0 13:44 ?        00:00:00 ps -ef
[root@e3a540a4b30b /]# exit
logout
[root@Linux-node1-salt ~]# docker ps #查看正在运行的docker窗口
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
e3a540a4b30b        centos              "/bin/bash"         45 minutes          Up 5 minutes                            my-docker
[root@Linux-node1-salt ~]# cat docker_in.sh  #进入docker的脚本
---------------
#!/bin/bash

#Use nsenter to access docker

docker_in(){
        NAME_ID=$1
        PID=$(docker inspect -f '{{ .State.Pid }}' $NAME_ID)
        nsenter -t $PID -m -u -i -n -p
}

docker_in $1
---------------
[root@Linux-node1-salt ~]# docker exec my-docker whoami  #只执行一次不登录容器时使用
root
[root@Linux-node1-salt ~]# docker exec -it my-docker /bin/bash #通过这种方式也可以进入容器，退出容器时也不影响容器工作
[root@e3a540a4b30b /]# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0  11820  1696 ?        Ss+  13:41   0:00 /bin/bash
root        77  0.6  0.0  11820  1860 ?        Ss   13:59   0:00 /bin/bash #新开bash
root        92  0.0  0.0  51740  1736 ?        R+   13:59   0:00 ps aux
[root@Linux-node1-salt ~]# docker rm  my-docker #删除停止的容器
[root@Linux-node1-salt ~]# docker rm  -f my-docker  #删除正在运行的容器
[root@Linux-node1-salt ~]# docker run --rm centos echo "hehe" #运行新容器并执行echo后删除这个新容器
[root@Linux-node1-salt ~]# docker run -d nginx  #运行nginx在后台并输出容器ID
1e4d6d3d5d73ec3876d9267dbbbd55060c978522cebdb8354b0c0f94ffbb6b68
[root@Linux-node1-salt ~]# docker logs boring_lumiere  #查看容器的日志

#Docker能干什么
简化配置，代码流水线，提高开发效率，隔离应用，整合服务器，调度能力，多租户环境，快速部署。
面向产品：产品交付
面向开发：简化环境配置
面向测试：多版本测试
面向运维：环境一致性
面向架构：自动化扩容（微服务）

#Docker的网络访问
Docker自带的桥接网卡：
#随机映射网络端口：
[root@Linux-node1-salt ~]# docker run -d -P nginx #后台运行nginx,并随机启动一个端口
[root@Linux-node1-salt ~]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                  NAMES
f621587121be        nginx               "nginx -g 'daemon ..."   About a minute ago   Up About a minute   0.0.0.0:1000->80/tcp   stoic_brahmagupta  #随机启动了1000端口
[root@Linux-node1-salt ~]# iptables -t nat -vnL #利用防火墙查看docker的网络映射情况
Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination 
    0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0  
    0     0 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:1001 to:172.17.0.2:80  #1001映射80端口
[root@Linux-node1-salt ~]# docker logs ae17dcdf1279  #查看nginx的访问日志
192.168.1.5 - - [16/Mar/2019:10:23:51 +0000] "GET / HTTP/1.1" 200 612 "-" "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:65.0) Gecko/20100101 Firefox/65.0" "-"
192.168.1.5 - - [16/Mar/2019:10:23:51 +0000] "GET /favicon.ico HTTP/1.1" 404 153 "-" "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:65.0) Gecko/20100101 Firefox/65.0" "-"
2019/03/16 10:23:51 [error] 7#7: *1 open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 192.168.1.5, server: localhost, request: "GET /favicon.ico HTTP/1.1", host: "192.168.1.233:1001"
#指定映射端口
-p 81:80:udp  #还可以指定本地的81端口映射容器的udp80端口，可以指定四层协议
[root@Linux-node1-salt ~]# docker run -d -p 81:80 --name mynginx nginx  #-小p为指定端口映射docker端口
fa69af65a6ca1e01363ed8ded684370fe384e35172638138792197daf9d53d59
[root@Linux-node1-salt ~]# docker run -d -p 192.168.1.233:88:80 --name mynginx2 nginx #-小p为指定端口映射，并且还指定ip
b684479c8a256458e5d9f928dc64d73380dc8c5b03016d790e2cba5cf134c26f
[root@Linux-node1-salt ~]# docker ps  -l 
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                NAMES
fa69af65a6ca        nginx               "nginx -g 'daemon ..."   20 seconds ago       Up 19 seconds       0.0.0.0:81->80/tcp   mynginx  #已经手动映射
[root@Linux-node1-salt ~]# docker port fa69af65a6ca #查看容器映射的端口
80/tcp -> 0.0.0.0:81 
[root@Linux-node1-salt ~]# docker run -d -p 90:80 -p 443:443 --name mynginx3 nginx #可以指定多个端口映射
291cf9fa5b915d5b09d1070c3916d022e0004ca46ed5853b559f9eab01bdbc19
[root@Linux-node1-salt ~]# docker port 291cf9fa5b915d5b09d1070c3916d022e0004ca46ed5853b559f9eab01bdbc19
443/tcp -> 0.0.0.0:443
80/tcp -> 0.0.0.0:90

#Docker的数据管理
#数据卷：
[root@Linux-node1-salt ~]# docker run -d --name nginx-test1 -v /data nginx #运行nginx镜像并挂载/data目录（不知道物理机挂载的是哪个目录）
61950aef5ca0e54071d8274c11329a07bf06c16f17b93159798d0fa4840e9c11
[root@Linux-node1-salt ~]# docker inspect -f '{{.Mounts}}' nginx-test1 #可查看/data目录挂载在物理机哪个目录下
[{volume dc8d2b64fe09c439b67cee4615b46d6a1c5aff355b193a64cb18cdc0de627635 /var/lib/docker/volumes/dc8d2b64fe09c439b67cee4615b46d6a1c5aff355b193a64cb18cdc0de627635/_data /data local  true }]  #/var/lib/docker/volumes/dc8d2b64fe09c439b67cee4615b46d6a1c5aff355b193a64cb18cdc0de627635/_data为物理机挂载的目录
[root@Linux-node1-salt ~]# mkdir -p /data/nginx-volume-test2 
[root@Linux-node1-salt ~]# docker run -d --name nginx-test2 -v /data/nginx-volume-test2:/data nginx  #手动指定挂载目录/data/nginx-volume-test2挂载到/data
82ef4e0c28086c295a8a23469cb87c102f3186febc4e2a40f29a0ace9a312e6b
[root@Linux-node1-salt ~]# docker run -d --name nginx-test2 -v /data/nginx-volume-test2:/data:ro nginx #以只读的方式挂载，不仅可以挂载目录也可以挂载文件
#数据卷容器：（数据在多个容器之间共享，无论容器是开启或关闭都可以共享）
[root@Linux-node1-salt ~]# docker run -it --name nginx-test3 --volumes-from nginx-test2 centos /bin/bash  #从其他数据卷容器中挂载到这个新容器中，其他数据卷容器是之前挂载的/data目录。当其他数据卷容器停止的时候，这个挂载的目录还是可用的，不受影响 
可以用--volumes-from来实现容器之间的共享，类似于NFS，可以启动一个容器来挂载目录，然后其他容器--volumes-from这个容器就可以了


##Docker镜像构建
1. 手动构建
2. Dockerfile构建
[root@Linux-node1-salt nginx-volume-test2]# docker kill `docker ps -a -q` #删除多个正在运行的容器
[root@Linux-node1-salt nginx-volume-test2]# docker rm `docker ps -a -q`  #删除所有容器
#手动构建镜像
制件nginx容器
[root@Linux-node1-salt ~]# docker run -it --name mynginx centos  #运行一个centos容器
[root@7f639bc6646b /]# rpm -ivh https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm #安装epel源
[root@7f639bc6646b /]# yum clean all  #清理yum缓存减小镜像大小
[root@7f639bc6646b /]# yum install nginx -y  #yum安装nginx，生产环境是中源码安装的
[root@7f639bc6646b /]# vi /etc/nginx/nginx.conf #修改nginx配置文件，使nginx运行在前台，因为docker容器必须运行在前台，在后台不能运行
daemon off;  #最前面添加一行
[root@Linux-node1-salt ~]# docker commit -m "My Nginx" 7f639bc6646b jackli/nginx:v1 #生成镜像，设置仓库名称和软件名称，版本号，是基于容器在运行时做的镜像
sha256:b7783e2ee4bfc033963ffca858e777005141216970e8f3b5eb206eedb4408d8c
[root@Linux-node1-salt ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SI ZE
jackli/nginx        v1                  b7783e2ee4bf        48 seconds ago      28 1 MB  #为自己添加的镜像，Docker镜像是存储在本地的，版本为v1
docker.io/nginx     latest              881bd08c0b08        11 days ago         10 9 MB
docker.io/centos    latest              1e1148e4cc2c        3 months ago        20 2 MB
[root@Linux-node1-salt ~]# docker run -d -p 81:80 --name mynginxv1 jackli/nginx:v1 nginx  #启动自己制作的镜像，选择仓库名称和版本号。和要启动的服务名称。
1cb0223907745803666aba909f190401b19d1d69497deb4817846e534d6c7e3a
[root@Linux-node1-salt ~]# docker ps 
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                NAMES
1cb022390774        jackli/nginx:v1     "nginx"             49 seconds ago      Up 49 seconds       0.0.0.0:81->80/tcp   mynginxv1
[root@Linux-node1-salt ~]# ./docker_in.sh mynginxv1
[root@1cb022390774 /]# cat /var/log/nginx/access.log  #查看访问的日志说明成功启动了
192.168.1.5 - - [17/Mar/2019:04:22:44 +0000] "GET / HTTP/1.1" 200 3700 "-" "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:65.0) Gecko/20100101 Firefox/65.0" "-"
192.168.1.5 - - [17/Mar/2019:04:22:44 +0000] "GET /favicon.ico HTTP/1.1" 404 3650 "-" "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:65.0) Gecko/20100101 Firefox/65.0" "-"

#Dockerfile构建镜像
自动化构建docker镜像的时候默认从当前目录去找一个叫Dockerfile的文件去创建镜像
[root@Linux-node1-salt nginx]# vim Dockerfile #名称必须为Dockerfile
----------------
#This a Dockerfile

#Base images
FROM centos  #从哪个基础镜像运行

#Maintainer
MAINTAINER Jack.Li jackli5689@gmail.com  #作者

#Commands
RUN rpm -ivh https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y nginx && yum clean all
RUN echo "daemon off;" >> /etc/nginx/nginx.conf  #生产环境是直接复制配置文件到镜像当中。
ADD index.html /usr/share/nginx/html/index.html  #增加index文件到index中。
EXPOSE 80  #对外的端口为80
CMD ["nginx"]  #运行nginx命令
----------------
FROM 指定基础镜像  #Dockerfile第一条必须是FROM，如果指定的镜像本地没有，会从远程仓库中pull下来
MAINTAINER 谁是维护者
RUN 运行什么（在命令前面使用），运行命令过长可以使用\来换行，与可以使用数组来使用，推荐使用数组，RUN["executable","param1","param2"]
ADD 复制文件（如果是识别的压缩文件格式，会自动解压，例如zip）
VOLUME 设置卷的挂载
EXPOSE 指定对外的端口，这样在运行docker run时用-p或-P时可以映射的容器端口
CMD 镜像启动后要执行的命令，Dockerfile只能有一条CMD,如果有多条，会以最后一条为准
ENTRYPOINT 和CMD类似，在运行docker run时使用的命令不会覆盖ENTRYPOINT的命令，但CMD的命令可以覆盖，这个就是两者的区别
USER 指定的用户和UID访问
ENV 常在RUN前面写，这样RUN时可以调用环境变量，启动容器也会调用环境变量
VOLUME 挂载目录到容器中，VOLUME["/data"]
WORKDIR 类似cd到某某目录
----------------
[root@Linux-node1-salt nginx]# echo "nginx hehe " > index.html #创建index.html文件
[root@Linux-node1-salt nginx]# ls #因为Dockerfile文件中有index.html文件要添加，所以这里要创建一个文件 
Dockerfile  index.html
[root@Linux-node1-salt nginx]# docker build -t mynginx:v2 . #docker构建镜像，-t为目标是当前目录的Dockerfile，名称为mynginx v2版本。
[root@Linux-node1-salt nginx]# docker images  
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
mynginx             v2                  abbf90b85e60        26 seconds ago      305 MB  #这个就是Dockerfile创建的镜像
jackli/nginx        v1                  b7783e2ee4bf        37 minutes ago      281 MB
docker.io/nginx     latest              881bd08c0b08        12 days ago         109 MB
docker.io/centos    latest              1e1148e4cc2c        3 months ago        202 MB
[root@Linux-node1-salt nginx]# docker run --name mynginxv2 -d -p 82:80 mynginx:v2  #运行Dockerfile创建的镜像，这里名称和版本号后面没有加命令，因为Dockerfile里面已经写了
e67abd2864ea0443a26699be8a03dd3b8c75d9edc960b7402ad4eaf4e7ec817a
#生产环境到底怎么来构建镜像
Docker架构层次：1.系统层（低层系统）  2.运行环境层（php环境，python环境，java环境）  3.应用服务层（放置配置和应用服务）
 [root@Linux-node1-salt docker]# tree
.
├── app
│   ├── xxx-admin
│   └── xxx-api
├── runtime
│   ├── java
│   ├── php
│   └── python
└── system
    ├── centos
    ├── centos-ssh
    └── ubuntu
#构建centos系统镜像
[root@Linux-node1-salt centos]# pwd
/root/docker/system/centos
[root@Linux-node1-salt centos]# wget http://mirrors.aliyun.com/repo/epel-7.repo
[root@Linux-node1-salt centos]# cat Dockerfile  
--------------
#Dcoker for CentOS

#Base image
FROM centos

#Maintainer
MAINTAINER Jack.Li jackli5689@gmail.com

#EPEL
ADD epel-7.repo /etc/yum.repos.d/

#Base pkg
RUN yum install -y wget mysql-devel supervisor git redis tree net-tools sudo psmisc && yum clean all
--------------
[root@Linux-node1-salt centos]# ls
Dockerfile  epel-7.repo
[root@Linux-node1-salt centos]# docker build -t jack/centos:base . #构建centos镜像
[root@Linux-node1-salt centos]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
jack/centos         base                8f22aa3610cd        2 minutes ago       299 MB  #这是新建立的centos镜像
mynginx             v2                  abbf90b85e60        About an hour ago   305 MB
jackli/nginx        v1                  b7783e2ee4bf        About an hour ago   281 MB
docker.io/nginx     latest              881bd08c0b08        12 days ago         109 MB
docker.io/centos    latest              1e1148e4cc2c        3 months ago        202 MB
#构建Python镜像
[root@Linux-node1-salt python]# pwd
/root/docker/runtime/python
[root@Linux-node1-salt python]# cat Dockerfile
----------
#This Python Dcokerfile

#Base Images
FROM jack/centos:base

#Maintainer
MAINTAINER Jack.Li@gmail.com

#Python ENV
RUN yum install -y python-devel python-pip supervisor

#Upgrade pip
RUN pip install --upgrade pip
----------
注意supervisor：Supervisor (http://supervisord.org) 是一个用 Python 写的进程管理工具，可以很方便的用来启动、重启、关闭进程（不仅仅是 Python 进程）。除了对单个进程的控制，还可以同时启动、关闭多个进程，比如很不幸的服务器出问题导致所有应用程序都被杀死，此时可以用 supervisor 同时启动所有应用程序而不是一个一个地敲命令启动。
[root@Linux-node1-salt python]# docker build -t jack/python .
[root@Linux-node1-salt python]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
jack/python         latest              749c95d4c731        2 minutes ago       433 MB  #新加的镜像
#构建centos-ssh镜像
[root@Linux-node1-salt centos-ssh]# ls
Dockerfile  epel-7.repo
[root@Linux-node1-salt centos-ssh]# cat Dockerfile
---------------
#Dcoker for CentOS

#Base image
FROM centos

#Maintainer
MAINTAINER Jack.Li jackli5689@gmail.com

#EPEL
ADD epel-7.repo /etc/yum.repos.d/

#Base pkg
RUN yum install -y openssh-clients openssh-server openssl-devel wget mysql-devel supervisor git redis tree net-tools sudo psmisc && yum clean all

#For SSHD
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key #生成rsa key清理旧的rsa key
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key #生成ecdsa key清理旧的ecdsa key
RUN echo "root:jack" | chpasswd  #更改root的密码
---------------
[root@Linux-node1-salt centos-ssh]# docker build -t jack/centos-ssh . #执行Dockerfile
[root@Linux-node1-salt centos-ssh]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED              SIZE
jack/centos-ssh     latest              256ccbacf7b6        About a minute ago   300 MB   #新加的镜像
#构建python-ssh镜像
[root@Linux-node1-salt python-ssh]# pwd
/root/docker/runtime/python-ssh
[root@Linux-node1-salt python-ssh]# cat Dockerfile
----------
#This Python Dcokerfile

#Base Images
FROM jack/centos:base

#Maintainer
MAINTAINER Jack.Li@gmail.com

#Python ENV
RUN yum install -y python-devel python-pip supervisor

#Upgrade pip
RUN pip install --upgrade pip
----------
[root@Linux-node1-salt python-ssh]# docker build -t jack/python-ssh .
[root@Linux-node1-salt python-ssh]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZ E
jack/python-ssh     latest              8421ab2148db        10 seconds ago      434  MB
注：后面实践是基于centos-ssh和python-ssh来做
#测试python小程序
[root@Linux-node1-salt shop-api]# pwd
/root/docker/app/shop-api
[root@Linux-node1-salt shop-api]# cat app.py
---------------
from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello():
        return 'Hello World!'
if __name__ == "__main__":
        app.run(host="0.0.0.0",debug=True)
---------------
[root@Linux-node1-salt shop-api]# pip install flask #先测试是否安装flask python框架
-bash: pip: command not found
[root@Linux-node1-salt shop-api]# yum install -y python-pip
[root@Linux-node1-salt shop-api]# pip install flask
[root@Linux-node1-salt shop-api]# python app.py
打开测试http://192.168.1.233:5000/是正常运行的
生产环境下python有一个依赖的文件，里面写了python的依赖文件

#生产环境docker的用法
[root@Linux-node1-salt shop-api]# pwd
/root/docker/app/shop-api
[root@Linux-node1-salt shop-api]# tree
.
├── app.py #项目
├── app-supervisor.ini  #supervisor启动的服务
├── Dockerfile  #docker file
├── requirements.txt #python依赖文件
└── supervisord.conf  #supervisor配置文件
-----------------
[root@Linux-node1-salt shop-api]# cat app.py
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
        return 'Hello World!'

if __name__ == "__main__":
        app.run(host="0.0.0.0",debug=True)
-----------------
[root@Linux-node1-salt shop-api]# cat app-supervisor.ini
[program:shop-api]
command=/usr/bin/python2.7 /opt/app.py #运行python项目
process_name=%(program_name)s
autostart=true
user=www
stdout_logfile=/tmp/app.log
stderr_logfile=/tmp/app.error

[program:sshd]
command=/usr/sbin/sshd -D #运行sshd服务，不会成为守护进程从而在前台运行
process_name=%(program_name)s
autostart=true #随着supervisor的开启而开启
-----------------
[root@Linux-node1-salt shop-api]# cat requirements.txt
flask
-----------------
[root@Linux-node1-salt shop-api]# cat supervisord.conf | grep nodaemon
nodaemon=true              ; (start in foreground if true;default false) #只需把false改为true即可，意思是让容器运行的时候执行supervison在前台运行，其他默认配置
-----------------
[root@Linux-node1-salt shop-api]# cat Dockerfile
#This Python Dcokerfile

#Base Images
FROM jack/python-ssh #从jack/python-ssh镜像创建镜像

#Maintainer
MAINTAINER Jack.Li@gmail.com

#Python ENV
RUN useradd -s /sbin/nologin -M www #新建用户www

#ADD file
ADD app.py /opt/app.py
ADD requirements.txt /opt/requirements.txt
ADD supervisord.conf /etc/supervisord.conf
ADD app-supervisor.ini /etc/supervisord.d/app-supervisor.ini

#pip install
RUN /usr/bin/pip2.7 install -r /opt/requirements.txt #安装python依赖的文件

#Port
EXPOSE 22 5000 #容器开启22和5000端口

#CMD
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"] #容器运行的默认命令
-----------------
[root@Linux-node1-salt shop-api]# docker build -t jack/shop-api . #创建镜像jack/shop-api
[root@Linux-node1-salt shop-api]# docker run -d --name shop-api -p 8088:5000 8022:22 jack/shop-api #运行容器shop-api

#构建Docker私有仓库（vic也可以）
#Docker Regestry Nginx+认证的方式 
1.申请免费ssl证书（沃通）
2.部署ssl证书
3.设置身份验证
4.proxy_pass 5000
5.启动regestry容器并映射端口：docker run -d -p 5000:5000 --name registry registry:2 



#HARBOR--企业级的分布式docker regestry，vmware写的（生产用这个）
https://github.com/goharbor/harbor
https://goharbor.io/docs/
#安装Harbor:
主机：192.168.13.197
[root@es01 ]# curl -sSfLo /download/harbor-offline-installer-v1.8.6.tgz https://github.com/goharbor/harbor/releases/download/v1.8.6/harbor-offline-installer-v1.8.6.tgz
[root@es01 ]# grep -Ev '#|^$' /usr/local/harbor/harbor.yml 
hostname: 192.168.13.197
http:
  port: 8000							--启用http并设置端口
harbor_admin_password: Harbor123456		--设置harbor admin密码
database:
  password: root123
data_volume: /data/harbor				--设置harbor数据存储目录
clair: 
  updaters_interval: 12
  http_proxy:
  https_proxy:
  no_proxy: 127.0.0.1,localhost,core,registry
jobservice:
  max_job_workers: 10
chart:
  absolute_url: disabled
log:
  level: info
  rotate_count: 50
  rotate_size: 200M
  location: /var/log/harbor
_version: 1.8.0
[root@es01 ]# ./install.sh --with-clair
#--重新配置harborhttp、https、harbor存储目录
[root@es01 ]# /usr/local/bin/docker-compose -f /usr/local/harbor/docker-compose.yml down
[root@es01 ]# vim harbor.yml
[root@es01 ]# ./prepare		--如果前面未开启镜像扫描，这里可开启: ./prepare	 --with-clair
[root@es01 ]# /usr/local/bin/docker-compose -f /usr/local/harbor/docker-compose.yml up -d
#--harbor1.8.6 admin密码重置,修改为初始化密码Harbor12345
[root@es01 /usr/local/harbor]# docker exec -it harbor-db /bin/sh
psql -h postgresql -d postgres -U postgres #这要输入默认密码：root123
psql -U postgres -d postgres -h 127.0.0.1 -p 5432 #或者用这个可以不输入密码
\c registry
select * from harbor_user;
update harbor_user set password='a71a7d0df981a61cbb53a97ed8d78f3e', salt='ah3fdh5b7yxepalg9z45bu8zb36sszmr' where username='admin';
update harbor_user set email='jack.li@homsom.com' where username='admin';	--设置admin邮箱为自己的邮箱，在配置邮件服务器后可通过电子邮件重置密码
--harbor2.0.2 admin密码重置,修改为初始化密码Harbor12345
update harbor_user set password='c999cbeae74a90282c8fa7c48894fb00', salt='nmgxu7a5ozddr0z6ov4k4f7dgnpbvqky'  where username='admin';
#harbor高可用
1. 安装两个harbor服务器，内网使用部署http模式即可。
2. 访问harbor WEB进行配置，在"同步管理"中添加进行配置，同步模式为"Push-based"，触发模式为"事件驱动"，并允许覆盖
3. 配置HA，可使用LVS或者HAproxy，例如HAproxy，配置一个服务组，并且基于源IP进行调度，并且对服务进行健康检查，如下：
listen haproxy
	mode tcp
	bind 0.0.0.0:8888
	balance source
	server harbor01 192.168.13.235:8000 check inter 2000 rise 2 fall 3
	server harbor02 192.168.13.197:8000 check inter 2000 rise 2 fall 3
4. 两个habor之间必须是万兆网络才能更稳定的实现高可用



#Docker hub仓库管理
[root@Linux-node1-salt ~]# docker run -d --name shop-api jack/shop-api supervisord -c /etc/supervisord.conf
[root@Linux-node1-salt ~]# docker commit abe2940bee46 jackli5689/jack
[root@Linux-node1-salt ~]# docker login 
[root@Linux-node1-salt ~]# docker push jackli5689/jack:python-ssh-v1

</pre>

#docker网络
默认分为三种：
1. bridge(容器通过docker0虚拟网口连接，然后docker0通过iptables规则做nat转换成宿主机ip)
2. host(共享宿主机ip和端口)
3. none（不使用网络）
#新建网络：
docker network create --driver bridge new_bridge
#在创建容器的时候可以也可以指定新容器连接的网络是什么，也可以共享运行的容器网络
docker run -d --rm --net=container:CONTAINER_NAME|_ID busybox /bin/sh
#指定使用共享主机网络模式：
docker run -d --rm --net=host busybox /bin/sh
#自定义网络：
macvlan：每个容器都有自己的mac地址，类似容器像宿主机一样连接在交换机当中，都有一个物理ip，不用在docker0和iptables之间做转换
#创建macvlan网络，跟宿主机在同一个vlan
docker network create -d macvlan \
    --subnet=172.16.86.0/24 \
    --gateway=172.16.86.1  \
    -o parent=eth0 pub_net  
#注：parent选项=宿主机网络接口名称，当不使用子接口时，则表示跟宿主机属于当一个vlan,如果使用子接口则表示属于特定vlan,例如eth0.10则表示属于vlan10
#创建macvlan网络，属于vlan10
docker network create \
  --driver macvlan \
  --subnet=10.10.0.0/24 \
  --gateway=10.10.0.253 \
  -o parent=eth0.10 macvlan10
#创建macvlan网络，属于vlan20
docker network create \
  --driver macvlan \
  --subnet=192.10.0.0/24 \
  --gateway=192.10.0.253 \
  -o parent=eth0.20 \
  -o macvlan_mode=bridge macvlan20
#注：macvlan_mode默认是macvlan_mode=bridge，要创建属于特定vlan模式，则宿主机连接的交换机端口必须是trunk模式或者Hybrid模式，不能是access模式


#Docker二进制安装
[root@centos7-node03 /download]# curl -sSfLO https://mirror.tuna.tsinghua.edu.cn/docker-ce/linux/static/stable/x86_64/docker-19.03.15.tgz
[root@centos7-node03 /download]# ll
total 153120
-rw-r--r-- 1 root root      647 Apr 11  2021 containerd.service
-rw-r--r-- 1 root root 62436240 Feb  5  2021 docker-19.03.15.tgz
-rwxr-xr-x 1 root root 16168192 Jun 24  2019 docker-compose-Linux-x86_64_1.24.1
-rwxr-xr-x 1 root root     2708 Apr 11  2021 docker-install.sh
-rw-r--r-- 1 root root     1683 Apr 11  2021 docker.service
-rw-r--r-- 1 root root      197 Apr 11  2021 docker.socket
-rw-r--r-- 1 root root      454 Apr 11  2021 limits.conf
-rw-r--r-- 1 root root      257 Apr 11  2021 sysctl.conf
[root@centos7-node03 /download]# ./docker-install.sh









## docker配置代理


**通过两种方式配置这些设置：**
* 通过配置文件或 CLI 标志配置守护进程
* 在系统上设置 环境变量
> 直接配置守护进程优先于环境变量


**守护进程配置**
```bash
root@k8s02-master01:~# cat /etc/docker/daemon.json
{
  "proxies": {
    "http-proxy": "http://172.168.2.219:10809",
    "https-proxy": "https://172.168.2.219:10809",
    "no-proxy": "localhost,127.0.0.0/8,192.168.0.0/8,172.168.0.0/8"
  }
}
```
> 有些服务器使用`守护进程配置`会导致docker无法启动，请移除proxies的所有配置，使用`环境变量配置`，不建议使用此方式



**环境变量配置**
```bash
root@k8s02-master01:~# cat /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://172.168.2.219:10809"
Environment="HTTPS_PROXY=http://172.168.2.219:10809"
Environment="NO_PROXY=localhost,127.0.0.1"
root@k8s02-master01:~# systemctl daemon-reload
root@k8s02-master01:~# systemctl restart docker
root@k8s02-master01:~# docker info | grep -i 'proxy'
WARNING: No swap limit support
 HTTP Proxy: http://172.168.2.219:10809
 HTTPS Proxy: http://172.168.2.219:10809
 No Proxy: localhost,127.0.0.1
  https://dockerproxy.com/
```


## docker健康检查
```bash
$ sudo docker run -d --name alipro_hotelryinglv_test -e JAVA_ENVIRONMENT=pro -p 12941:80 -m 2147483648 --health-cmd "curl -sf http://localhost/doc.html || exit 1" --health-start-period=2m --health-interval=30s --health-timeout=1s --health-retries=3 --restart always registry.cn-shanghai.aliyuncs.com/aliyun/hotelryinglv.service.hs.com:v20250117144201 

$ sudo docker inspect alipro_hotelryinglv_test
		"Health": {
                "Status": "healthy",
                "FailingStreak": 0,
                "Log": [
                    {
                        "Start": "2025-02-14T09:37:27.744022868+08:00",
                        "End": "2025-02-14T09:37:27.81685433+08:00",
                        "ExitCode": 1,
                        "Output": ""
                    },
                    {
                        "Start": "2025-02-14T09:37:57.822215241+08:00",
                        "End": "2025-02-14T09:37:58.024398105+08:00",
                        "ExitCode": 0,
                        "Output": "<!DOCTYPE html><html lang=en><head><meta charset=utf-8><meta http-equiv=X-UA-Compatible content=\"IE=edge\"><meta name=viewport content=\"width=device-width,initial-scale=1\"><link rel=icon href=favicon.ico><title></title><link href=webjars/css/chunk-51277dbe.57225f85.css rel=prefetch><link href=webjars/js/chunk-069eb437.a0c9f0ca.js rel=prefetch><link href=webjars/js/chunk-0fd67716.d57e2c41.js rel=prefetch><link href=webjars/js/chunk-2d0af44e.c09671a4.js rel=prefetch><link href=webjars/js/chunk-2d0bd799.5bb1a14e.js rel=prefetch><link href=webjars/js/chunk-2d0d0b98.4693c46e.js rel=prefetch><link href=webjars/js/chunk-2d0da532.a47fb5c8.js rel=prefetch><link href=webjars/js/chunk-2d22269d.fc57b306.js rel=prefetch><link href=webjars/js/chunk-3b888a65.8737ce4f.js rel=prefetch><link href=webjars/js/chunk-3ec4aaa8.a79d19f8.js rel=prefetch><link href=webjars/js/chunk-51277dbe.6f598840.js rel=prefetch><link href=webjars/js/chunk-589faee0.5b861f49.js rel=prefetch><link href=webjars/js/chunk-735c675c.be4e3cfe.js rel=prefetch><link href=webjars/js/chunk-adb9e944.fff7fcef.js rel=prefetch><link href=webjars/css/app.f802fc13.css rel=preload as=style><link href=webjars/css/chunk-vendors.2997cc1a.css rel=preload as=style><link href=webjars/js/app.23f8b31d.js rel=preload as=script><link href=webjars/js/chunk-vendors.90e8ba20.js rel=preload as=script><link href=webjars/css/chunk-vendors.2997cc1a.css rel=stylesheet><link href=webjars/css/app.f802fc13.css rel=stylesheet></head><body><noscript><strong>We're sorry but knife4j-vue doesn't work properly without JavaScript enabled. Please enable it to continue.</strong></noscript><div id=app></div><script src=webjars/js/chunk-vendors.90e8ba20.js></script><script src=webjars/js/app.23f8b31d.js></script></body></html>"
                    }
                ]
            }
        },
```



# docker容器迁移

```bash
# 源机器操作
# 需要迁移的镜像
[root@hw-blog ~]# docker ps -a | grep 5230 
0b6ef6a85cb6   neosmemo/memos:stable             "./memos"                5 months ago    Up 2 days             0.0.0.0:5230->5230/tcp, :::5230->5230/tcp       memos
# 查看数据挂载
[root@hw-blog ~]# docker inspect memos | grep -A 10 -i mounts
        "Mounts": [
            {
                "Type": "bind",
                "Source": "/root/memos",
                "Destination": "/var/opt/memos",
                "Mode": "",
                "RW": true,
                "Propagation": "rprivate"
            }
        ],
        "Config": {
# 查看运行容器的命令
[root@hw-blog tmp]# pip3 install runlike
[root@hw-blog tmp]# runlike memos | tee /tmp/docker_run_memos.sh
docker run --name=memos --hostname=0b6ef6a85cb6 --mac-address=02:42:ac:11:00:04 --volume /root/memos:/var/opt/memos --network=bridge --workdir=/usr/local/memos -p 5230:5230 --runtime=runc --detach=true neosmemo/memos:stable



# 目标机器操作
# 保存容器镜像为 tar 包
[root@hw-blog ~]# docker commit memos memos-image
sha256:e7fca771728de08275e264d6186864847dc036a4a633ac141157450d750e7f8f
[root@hw-blog ~]# docker save -o /tmp/memos-image.tar memos-image
# 复制数据到目标服务器
[root@hw-blog tmp]# tar -czvf data_and_image.tar.gz /root/memos /tmp/docker_run_memos.sh memos-image.tar 
[root@hw-blog tmp]# scp -P 8022 data_and_image.tar.gz root@hw3.test.cn:/tmp/

# 目标机器还原
## 还原数据
[root@hw3 /tmp]# tar xf data_and_image.tar.gz 
[root@hw3 /tmp]# mv -f root/memos/* /root/memos/
## 还原镜像
[root@hw3 /tmp]# docker load -i memos-image.tar 
# 运行容器
[root@hw3 /tmp]# cat /tmp/docker_run_memos.sh 
docker run --name=memos --hostname=0b6ef6a85cb6 --mac-address=02:42:ac:11:00:04 --volume /root/memos:/var/opt/memos --network=bridge --workdir=/usr/local/memos -p 5230:5230 --runtime=runc --detach=true neosmemo/memos:stable
[root@hw3 /tmp]# docker run --name=memos --volume /root/memos:/var/opt/memos  -p 5230:5230 --detach=true memos-image:latest
ae58591f58d30be0593a445da5947c8ad6cb9ca9b15100e404c2a52ff94c6a47

# 查看容器运行状态及检查服务
[root@hw3 /tmp]# docker ps -a 
CONTAINER ID   IMAGE                COMMAND     CREATED          STATUS          PORTS                                       NAMES
ae58591f58d3   memos-image:latest   "./memos"   16 seconds ago   Up 15 seconds   0.0.0.0:5230->5230/tcp, :::5230->5230/tcp   memos



```