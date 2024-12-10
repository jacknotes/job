# ELKStack
官网：https://www.elastic.co
插件文档：https://www.elastic.co/guide/en/logstash-versioned-plugins/current/index.html
ELKStack简介:
对于日志来说，最常见的需求就是收集、存储、查询、展示，开源社区正好有相对应的开源项目：logstash（收集）、elasticsearch（存储+搜索）、kibana（展示），我们将这三个组合起来的技术称之为ELKStack，所以说ELKStack指的是Elasticsearch、Logstash、Kibana技术栈的结合
Elasticsearch天生是分布式的，有两种方式进行通信：1.组播（加到组中，在组中的主机互相通信） 2.单播(指定主机)

```
### 安装JDK
[root@clusterFS-node4-salt ~]# yum install -y java-1.8.0
[root@clusterFS-node4-salt ~]# java -version
openjdk version "1.8.0_191"
OpenJDK Runtime Environment (build 1.8.0_191-b12)
OpenJDK 64-Bit Server VM (build 25.191-b12, mixed mode)

### Elasticsearch部署
Elasticsearch首先需要Java环境，所以需要提前安装好JDK，可以直接使用yum安装。也可以从Oracle官网下载JDK进行安装。开始之前要确保JDK正常安装并且环境变量也配置正确：
YUM安装ElasticSearch
1.下载并安装GPG key:
[root@clusterFS-node4-salt ~]# rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
2.添加yum仓库:
[root@clusterFS-node4-salt ~]# vim /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-2.x]
name=Elasticsearch repository for 2.x packages
baseurl=http://packages.elastic.co/elasticsearch/2.x/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
3.安装elasticsearch:
[root@clusterFS-node4-salt ~]#  yum install -y elasticsearch
4.更改elasticsearch.yml配置文件：
[root@clusterFS-node4-salt elasticsearch]# vim elasticsearch.yml
[root@clusterFS-node4-salt elasticsearch]# grep '^[a-Z]' elasticsearch.yml
cluster.name: myes
node.name: elk-node1
path.data: /data/es-data
path.logs: /var/log/elasticsearch
bootstrap.memory_lock: true  #锁住物理内存不适用虚拟内存
network.host: 192.168.1.31
http.port: 9200
5.配置/data目录给elasticsearch权限：
[root@clusterFS-node4-salt ~]# chown -R elasticsearch:elasticsearch /data
6.启动elasticsearch:
[root@clusterFS-node4-salt elasticsearch]# systemctl start elasticsearch.service
7.测试elasticsearch服务是否正常：
[root@clusterFS-node4-salt ~]# curl -i -XGET "http://192.168.1.31:9200/_count"
HTTP/1.1 200 OK
Content-Type: application/json; charset=UTF-8
Content-Length: 59

{"count":0,"_shards":{"total":0,"successful":0,"failed":0}}
注：java使用得是lucene，lucene是搜索巨头，大部分搜索基本都是lucene，lucene本身没有集群，高可用，分片。而elasticsearch具备集群，高可用和分片，elasticsearch底层是lucene。elasticsearch跟glusterFS一样，分布式是无中心的。
8.装插件，用插件联系elasticsearch[也可以用api]:
[root@clusterFS-node4-salt ~]# /usr/share/elasticsearch/bin/plugin install mobz/elasticsearch-head  #直接从github上去抓取安装
[root@clusterFS-node4-salt ~]# /usr/share/elasticsearch/bin/plugin install lmenezes/elasticsearch-kopf  #直接从github上去抓取安装
lukas-vlcek/bigdesk#bigdesk插件直接从github上抓取，但是版本不支持
[root@clusterFS-node4-salt ~]# /usr/share/elasticsearch/bin/plugin install marvel-agent  #从官网上去抓取
9.测试插件kopf:
http://192.168.1.31:9200/_plugin/kopf/ 
10.访问插件head[用于集群管理]:
http://192.168.1.31:9200/_plugin/head/
10.1：
点击复合查询-输入/index-demo/test-选择POST-输入json信息并提交请求
json信息：
{
  "user": "oldboy",
  "mesg": "hello world"
}
输出：
{

    "_index": "index-demo",
    "_type": "test",
    "_id": "AWkvYTZQKeOJs7st2toX",
    "_version": 1,
    "_shards": {
        "total": 2,
        "successful": 1,
        "failed": 0
    },
    "created": true

}
10.2:
点击概览-可查看到0 1 2 3 4 这些分片-深黑色是主分片浅灰色是副本分片-主分片和负分片要部署在不同的机器上-点击连接-集群健康值为黄色为良好，为红色是主负本分片都丢失了
注意：在生产环境中，http://192.168.1.31:9200/_plugin/head/打开要5分钟，因为elasticsearch要去收集日志并整理，要花时间所致。
11.访问插件kopf:
http://192.168.1.31:9200/_plugin/kopf/
12.另外一个节点也要安装elasticsearch,集群名要一样，节点不一样，此时有两个es了，两个节点根据组播查找到另外节点【也可以用单播查找到另外节点】。两个节点互相查找到以后会进行选举，产生主节点和备节点，主节点和备节点对用户来说不重要，随便哪一个节点都可以转发信息。分片来说，只能是主分片等划分，副本分片不行。
13.由于elasticsearch组播无法查询到另外节点，此时用单播方式，[root@clusterFS-node3-salt ~]# vim /etc/elasticsearch/elasticsearch.yml
discovery.zen.ping.unicast.hosts: ["192.168.1.31", "192.168.1.37"]    #ip地址可以加端口。默认是9200
14.[root@clusterFS-node3-salt ~]# systemctl restart elasticsearch.service
15.网页查看http://192.168.1.31:9200/_plugin/head/，此时有两个节点，带"五角星"的为主节点。健康值也为绿色。
16.可以用curl来查看集群的健康状态：curl -XGET http://192.168.1.31:9200/_cluster/health?pretty=true
[root@clusterFS-node3-salt .ssh]# curl -XGET http://192.168.1.31:9200/_cluster/health?pretty=true  #?pretty=true是要漂亮的输出
{
  "cluster_name" : "myes",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 2,
  "number_of_data_nodes" : 2,
  "active_primary_shards" : 5,
  "active_shards" : 10,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
17._cat来查看：
[root@clusterFS-node3-salt .ssh]# curl -XGET http://192.168.1.31:9200/_cat
=^.^=
/_cat/allocation
/_cat/shards
/_cat/shards/{index}
/_cat/master
/_cat/nodes
/_cat/indices
/_cat/indices/{index}
/_cat/segments
/_cat/segments/{index}
/_cat/count
/_cat/count/{index}
/_cat/recovery
/_cat/recovery/{index}
/_cat/health
/_cat/pending_tasks
/_cat/aliases
/_cat/aliases/{alias}
/_cat/thread_pool
/_cat/plugins
/_cat/fielddata
/_cat/fielddata/{fields}
/_cat/nodeattrs
/_cat/repositories
/_cat/snapshots/{repository}
18.[root@clusterFS-node3-salt .ssh]# curl -XGET http://192.168.1.31:9200/_cat/nodes
192.168.1.31 192.168.1.31 7 97 0.14 d * els-node1
192.168.1.37 192.168.1.37 7 96 0.00 d m els-node2
19.生产部署硬件：一般内存64G，JVM不要超过32G，SSD硬盘最好。不要调度。CPU越多越好，网卡越块越好。JVM版本越高越好。
20.[root@clusterFS-node3-salt .ssh]# cat /proc/sys/vm/max_map_count
65530
21.上elasticsearch第一件事情就是改openfile:sysctl -w vm.max_map_count=262144

### logstash部署：
YUM部署LogStash:
1.下载并安装GPG key:
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
2.添加yum仓库:
vim /etc/yum.repos.d/logstash.repo
[logstash-2.3]
name=Logstash repository for 2.3.x packages
baseurl=https://packages.elastic.co/logstash/2.3/centos
gpgcheck=1
gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
3.安装logstash:
yum install -y logstash
4.启动logstash:
systemctl start logstash

测试使用：
1.[root@clusterFS-node3-salt ~]# curl -i -XGET http://192.168.1.31:9200/_cluster/health?pretty=true
HTTP/1.1 200 OK
Content-Type: application/json; charset=UTF-8
Content-Length: 458

{
  "cluster_name" : "myes",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 2,
  "number_of_data_nodes" : 2,
  "active_primary_shards" : 5,
  "active_shards" : 10,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
2.[root@clusterFS-node3-salt ~]# /opt/logstash/bin/logstash -e 'input { stdin {} } output { stdout {} }' #从标准输入到标准输出,所以下面直接输出在屏幕上
Settings: Default pipeline workers: 2
Pipeline main started
hello
2019-03-01T08:06:19.817Z clusterFS-node3-salt hello
3.[root@clusterFS-node3-salt ~]# /opt/logstash/bin/logstash -e 'input { stdin {} } output { stdout { codec => rubydebug } }' #使用codec=>rubydebug使输出更美观
Settings: Default pipeline workers: 2
Pipeline main started
aa
{
       "message" => "aa",
      "@version" => "1",
    "@timestamp" => "2019-03-01T08:09:33.108Z",
          "host" => "clusterFS-node3-salt"
}
4.[root@clusterFS-node3-salt ~]# /opt/logstash/bin/logstash -e 'input { stdin {} } output { elasticsearch { hosts=>[ "192.168.1.31:9200" ] index=>"logstash-%{+YYYY.MM.dd}" } }'   #输出到elasticsearch
5.[root@clusterFS-node3-salt ~]# /opt/logstash/bin/logstash -e 'input { stdin {} } output { stdout { codec => rubydebug }  elasticsearch { hosts=>[ "192.168.1.31:9200" ] index=>"logstash-%{+YYYY.MM.dd}" } }'  #输出到elasticsearch中和标准输出
6.logstash脚本放置在/etc/logstash/conf.d/下，因为/etc/init.d/logstash里面LS_CONF_DIR=/etc/logstash/conf.d配置了从这里读。
7.cd /etc/logstash/conf.d && vim demo.conf
input{
    stdin{}
}

filter{
}

output{
##号代表注释
    elasticsearch {
        hosts => ["192.168.1.31:9200"]
        index => "logstash-%{+YYYY.MM.dd}"
    }
    stdout{
        codec => rubydebug
    }
}
8.[root@clusterFS-node3-salt conf.d]# /opt/logstash/bin/logstash -f /etc/logstash/conf.d/demo.conf  #命令运行这个配置文件就可以输出到elasticsearch和logstash中了
9.logstash语法：
1.行 = 事件	2.input  output		3.事件 ->  input -> codec -> filter -> codec -> output(编解码的动作)
10.input模块：
file插件收集系统日志：
input{
    file {
        path => ["/var/log/messages", "/var/log/secure"]
        type => "system-log"
        start_position => "beginning"
    }
}

filter{
}

output{
    elasticsearch {
        hosts => ["192.168.1.31:9200"]
        index => "system-log-%{+YYYY.MM}"
    }
}

### kabana部署:
kabana跟logstash没有一点关系，kabana只是为elasticsearch设置的一个设置界面
Yum安装Kibana
1.下载并安装GPG key
[root@clusterFS-node4-salt log]#  rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
2.添加yum仓库
[root@clusterFS-node4-salt log]# cat /etc/yum.repos.d/kibana.repo
[kibana-4.5]
name=Kibana repository for 4.5.x packages
baseurl=http://packages.elastic.co/kibana/4.5/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
3.安装kibana
[root@clusterFS-node4-salt log]# yum install -y kibana 
4.编辑kibana配置文件
[root@clusterFS-node4-salt log]# vim /opt/kibana/config/kibana.yml
[root@clusterFS-node4-salt log]# grep '^[a-Z]' /opt/kibana/config/kibana.yml
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.url: "http://192.168.1.31:9200"
kibana.index: ".kibana"
5.http://192.168.1.31:5601打开kibana,进入setting菜单添加index索引，勾上{Use event times to create index names [DEPRECATED] }选项，进入Index name or pattern选项，设置index索引匹配名称[logstash-]YYYY.MM.DD
6.进入discovery菜单进行日志的查看及管理

7.测试java日志提交es-log到新的索引
vim /etc/logstash/conf.d/file.conf
编写配置格式：每行4个空格
input{
    file {
        path => "/var/log/elasticsearch/myes.log"
        type => "es-log"
        start_position => "beginning"
    }
    file {
        path => ["/var/log/secure", "/var/log/messages"]
        type => "system-log"
        start_position => "beginning"
    }
}

filter{
}

output{
    if [type] == "es-log" {    #使用if来判断type
        elasticsearch {
            hosts => ["192.168.1.31:9200"]
            index => "es-log-%{+YYYY.MM}"
        }
    }
    if [type] == "system-log" {
        elasticsearch {
            hosts => ["192.168.1.31:9200"]
            index => "system-log-%{+YYYY.MM}"
        }
    }
}

需求：由于java日志报错exception时有多行是一个事件，而logstash却认为是多行而不是一行，所以要用multiline插件来更改使logstash认为这是一个事件输出为一行
8.测试配置文件：
[root@clusterFS-node4-salt conf.d]# cat codec.conf
input{
    stdin {
        codec => multiline{
            pattern => "^\["
            negate => true
            what => "previous"
        }
    }
}

filter{
}

output{
    stdout {
        codec => rubydebug
    }
}

9.加入正式配置文件：
[root@clusterFS-node4-salt conf.d]# cat file.conf
input{
    file {
        path => "/var/log/elasticsearch/myes.log"
        type => "es-log"
        start_position => "beginning"
        codec => multiline{
            pattern => "^\["      #匹配到[开头的
            negate => true        #如果没有匹配的话，是否否定正则表达式
            what => "previous"    #之前的合并
        }

    }
    file {
        path => ["/var/log/secure", "/var/log/messages"]
        type => "system-log"
        start_position => "beginning"
    }
}

filter{
}

output{
    if [type] == "es-log" {
        elasticsearch {
            hosts => ["192.168.1.31:9200"]
            index => "es-log-%{+YYYY.MM}"
        }
    }
    if [type] == "system-log" {
        elasticsearch {
            hosts => ["192.168.1.31:9200"]
            index => "system-log-%{+YYYY.MM}"
        }
    }
}

10.删除~目录下.sincedb开头的隐藏文件（用户记录index索引收集到哪一行的数据），重新收集日志
11.运行/opt/logstash/bin/logstash -f /etc/logstash/conf.d/file.conf重新创建index，并且使java报的Exception都在一行显示，不会错误的显示多行
注意：建立索引必需使用/opt/logstash/bin/logstash -f /etc/logstash/conf.d/file.conf来建立，重启服务并不会建立索引。(由于启动/etc/init.d/logstash restart 而有些日志没有写到输出的地方，原因是有些日志文件logstash这个用户没有权限读取。)

12.收集nginx日志：
logstash使用json插件来收集nginx日志，排版nginx日志取得需要的字段信息。因为nginx日志默认并不是json格式，好在nginx支持日志改成json格式。
例如：
 ab -n 1000 -c 1 http://192.168.1.31/  #-n为请求数据，-c为并发数（concurrency）
less /var/log/nginx/access.log  #查看nginx访问日志，日志格式在/etc/nginx/nginx.conf配置文件里面log_format参数下
 log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent" "$http_x_forwarded_for"';   #前面是系统自带日志参数
实现json格式两种方法：
第一种方式：nginx日志改成json格式:
log_format  access_log_json 	'{"user_ip":"$http_x_real_ip","lan_ip":"$remote_addr","log_time    	":"$time_iso8601","user_req":"$request","http_code":"$status","body_bytes_sent":"	$body_bytes_se    nt","req_time":"$request_time","user_ua":"$http_user_agent"} ';
#access_log_json为自己加进去的json格式
 access_log  /var/log/nginx/access_log_json.log  access_log_json;  #调用access_log_json日志格式 
第二种方式：
文件通过Redis直接收取，然后Python脚本读取Redis,写成Json,写入elasticsearch。
测试json日志格式：
input {
    file {
        path => "/var/log/nginx/access_log_json.log"
        codec => "json"
    }
}

filter {}

output{
    stdout {
        codec => rubydebug
    }
}

加入nginx.conf到/etc/logstash/conf.d/下：
[root@clusterFS-node4-salt conf.d]# cat nginx.conf
input {
    file {
        path => "/var/log/nginx/access_log_json.log"
        codec => "json"
        type => "nginx-access-log"
    }
}

filter {}

output{
    elasticsearch {
        hosts => ["192.168.1.31:9200"]
        index => "nginx-access-log-%{+YYYY.MM.dd}"
    }
}

13./opt/logstash/bin/logstash -f /etc/logstash/conf.d/nginx.conf #加-t是测试配置文件
注：ls -a /var/lib/logstash/  #logstash的sincedb默认在这个路径下
14.kibana中加nginx-access-log的index,之后可以在discovery下使用自己定义的json字段进行排序了。

14.在kibana中添加dashboard仪表盘，有makedown语法的（常用作紧急联系人）、计算器总计、饼图、柱状图、搜索结果等添加到仪表盘中。设置参数时Aggregation选项添加terms、Field 再可以添加自己配置的json键名。
注：当设置图表参数时显示?时，是index添加有问题，删除重新添加即可
生产环境的部署情况：
1.每个ES上面都启动一个Kibana
2.Kibana都连自己的ES
3.前端Nginx做负载均衡（kibana性能到20多个人时就极限）、ip_hash、身份验证（限制访问）、ACL。
```

```
### Rsyslog日志(Redhat6之后不叫syslog了)
syslog插件：logstash开启514端口，其他节点就可以把所有系统日志传到这台主机的514端口了。
#### syslog插件 （logstash自带所有插件，免安装）

1.vim /etc/logstash/conf.d/syslog.conf
input {
    syslog{   #意思是开启收集系统日志的端口，用于收取其他节点的系统日志
        type => "system-syslog"
        port => 514
    }

}

output {
    stdout {
        codec => rubydebug
    }
}

2.在需要传送系统日志的机器/etc/rsyslog.conf下添加这行配置
*.* @@192.168.1.31:514  
3.重启rsyslog服务：
systemctl restart rsyslog.service

4.写入到正式配置文件：
[root@clusterFS-node4-salt conf.d]# cat syslog.conf
input {
    syslog{
        type => "system-syslog"
        port => 514
    }

}

output {
    elasticsearch {
        hosts => ["192.168.1.31:9200"]
        index => "system-syslog-%{+YYYY.MM}"   #YYYY.MM前有个+号
    }
    stdout {
        codec => rubydebug
    }
}

#TCP日志（使用tcp插件）
当logstash收集日志时少收了一些日志，要补日志到kibana上，有两种方法：
1. 把缺少日志写到文件，再通过logstash把文件传到kibana
2. 用tcp来传少的日志到kibana(这种方式较灵活)
tcp插件：
1. [root@clusterFS-node4-salt conf.d]# cat tcp.conf
input {
    tcp {   #开启tcp端口收集日志
        type => "tcp"
        port => 6666
        mode => "server"
    }
}

output {
    stdout{
        codec => rubydebug
    }
}
2. /opg/logstash/bin/logstash -f tcp.conf
3. 通过任意一种方式连接端口传送日志到logstash
echo "hehe" | nc 192.168.1.31 6666
nc 192.168.1.31 6666 < /etc/resolv.conf
echo "hello" > /dev/tcp/192.168.1.31/6666
 
## filter模块：
#grok插件：
1. grok系统自带正则表达式目录（自带大部分应用正则表达式）：
[root@clusterFS-node4-salt conf.d]# cd /opt/logstash/vendor/bundle/jruby/1.9/gems/logstash-patterns-core-2.0.5/patterns/
2. [root@clusterFS-node4-salt conf.d]# cat grok.conf
input {
        stdin {}
}

filter {
        grok {
                match => { "message" => "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration}" }
        }
}

output {
        stdout {
                codec => rubydebug
        }
}
3. /opt/logstash/bin/logstash -f /etc/logstash/conf.d/grok.conf
4. 输入55.3.244.1 GET /index.html 15824 0.043进行测试正则表达式测试的结果。
5. 使用grok自带的正没表达式变量来过滤日志
[root@clusterFS-node4-salt conf.d]# cat apache-grok.conf
input {
        file{
                path => "/var/log/httpd/access_log"
                start_position => "beginning"
                type => "apache-accesslog"
        }
}

filter {
        grok{
                match => { "message" => "%{COMBINEDAPACHELOG}" }  #COMBINEDAPACHELOG为grok自带的正则表达式变量，变量在/opt/logstash/vendor/bundle/jruby/1.9/gems/logstash-patterns-core-2.0.5/patterns/grok-patterns文件中
        }
}

output{
        elasticsearch{
                hosts => "192.168.1.31:9200"
                index => "apache-accesslog-%{+YYYY.MM}"
        }
}

/opt/logstash/bin/logstash -f /etc/logstash/conf.d/apache-grok.conf

不用grok原因:
1.grok是非常影响性能的  2.不灵活。除非你懂ruby。 3.生产环境用的流程是：logstash->redis<-python->ES (logstash收集到redis,python读取redis并处理数据后写入到ES)
为什么用python脚本来处理，而不用grok处理，因为grok正则处理大量数据时很麻烦，而python处理大量数据时灵活。

#消息队列：rabbitMQ  kafka   redis    
1.用redis来做消息队列，安装redis:
yum install -y redis
2.vim /etc/redis.conf
-------------------------------------
[root@clusterFS-node4-salt conf.d]# grep '^[a-Z]' /etc/redis.conf
bind 192.168.1.31  #改ip，其他默认
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize yes   #改成后台运行，其他默认
supervised no
pidfile /var/run/redis_6379.pid
loglevel notice
logfile /var/log/redis/redis.log
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
-------------------------------------
3.启动redis：
systemctl start redis  
4.在logstash中配置redis.conf
[root@clusterFS-node4-salt conf.d]# cat redis.conf
input{
        stdin{}
}

output{
        redis {
                host => "192.168.1.31"
                port => "6379"
                db => "6"
                data_type => "list"
                key => "demo"
        }
}
5.连接操作redis:
[root@clusterFS-node4-salt conf.d]# redis-cli -h 192.168.1.31 -p 6379
---------------
192.168.1.31:6379> info  #查看redis信息
# Keyspace   #没有显示key信息，所以还没有key
192.168.1.31:6379> set name ljdfldjsflsd  #设置一个key
192.168.1.31:6379> info  #再次查看redis信息
# Keyspace
db0:keys=1,expires=0,avg_ttl=0  #显示有key了
192.168.1.31:6379> get name   #获得key名字
"ljdfldjsflsd"
192.168.1.31:6379[6]> keys *   #在db0中获取所有key
1) "demo"

[root@clusterFS-node4-salt conf.d]# /opt/logstash/bin/logstash -f redis.conf  #logstash执行redis.conf，标准输入会输出到redis中，key为demo,demo的类型为list
Settings: Default pipeline workers: 2
Pipeline main started
fdsjfdsljlf
flsdjfldsjfkds
jldsfjlsdflsd
afdsafdsfsafsd


192.168.1.31:6379> info   #redis再次查看所有信息
# Keyspace
db0:keys=1,expires=0,avg_ttl=0
db6:keys=1,expires=0,avg_ttl=0   #增加了db6，并且多了一个key
192.168.1.31:6379> SELECT 6  #进入db6
OK
192.168.1.31:6379[6]> keys *   #查看db6的所有key
1) "demo"
192.168.1.31:6379[6]> type demo  #查看key的类型
list
192.168.1.31:6379[6]> llen demo  #list length 列出key的长度
(integer) 4
192.168.1.31:6379[6]> LINDEX demo -1  #列出key为demo的-1号索引
"{\"message\":\"afdsafdsfsafsd\",\"@version\":\"1\",\"@timestamp\":\"2019-03-03T14:38:25.448Z\",\"host\":\"clusterFS-node4-salt\"}"
--------------
6.将apache的访问日志写入到redis,编写apache.conf：

7.运行apache.conf文件
[root@clusterFS-node4-salt conf.d]# /opt/logstash/bin/logstash -f apache.conf
Settings: Default pipeline workers: 2
Pipeline main started

8.访问http://192.168.1.31:81/触发apache的access-log日志
9.在redis中查看并管理db6的key:
192.168.1.31:6379[6]> keys *
1) "demo" 
2) "apache-accesslog"    #由于触发了access-log日志，所以将日志写到redis中而产生了一个key
192.168.1.31:6379[6]> llen apache-accesslog
(integer) 2
192.168.1.31:6379[6]> lindex apache-accesslog -1    #查看访问apache的用户信息
"{\"message\":\"192.168.1.5 - - [03/Mar/2019:22:57:14 +0800] \\\"GET /favicon.ico HTTP/1.1\\\" 404 209 \\\"-\\\" \\\"Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:65.0) Gecko/20100101 Firefox/65.0\\\"\",\"@version\":\"1\",\"@timestamp\":\"2019-03-03T14:57:14.465Z\",\"path\":\"/var/log/httpd/access_log\",\"host\":\"clusterFS-node4-salt\",\"type\":\"apache-access-log\"}"


10.在另外一个节点启动一个logstash，读取redis，详细看流程：
流程：   192.168.1.31  写=>   192.168.1.31的redis    <= 读     192.168.1.37
注意：读看官方文档input插件，写看官方文档output插件
11.在192.168.1.37中编写indexer.conf:
[root@clusterFS-node3-salt conf.d]# vim indexer.conf
input {
         redis {
                host => "192.168.1.31"
                port => "6379"
                db => "6"
                data_type => "list"
                key => "apache-accesslog"
        }
}

output{
        stdout{
                codec => rubydebug
        }
}
12.运行indexer.conf：
[root@clusterFS-node3-salt conf.d]# /opt/logstash/bin/logstash -f indexer.conf #此时会从redis读取并标准输出
Settings: Default pipeline workers: 2
Pipeline main started
{
       "message" => "192.168.1.5 - - [03/Mar/2019:                                   .1\" 200 54 \"-\" \"Mozilla/5.0 (Windows NT 6.1; W                                   0101 Firefox/65.0\"",
      "@version" => "1",
    "@timestamp" => "2019-03-03T14:57:14.464Z",
          "path" => "/var/log/httpd/access_log",
          "host" => "clusterFS-node4-salt",
          "type" => "apache-access-log"
}
{
       "message" => "192.168.1.5 - - [03/Mar/2019:                                   .ico HTTP/1.1\" 404 209 \"-\" \"Mozilla/5.0 (Windo                                   ) Gecko/20100101 Firefox/65.0\"",
      "@version" => "1",
    "@timestamp" => "2019-03-03T14:57:14.465Z",
          "path" => "/var/log/httpd/access_log",
          "host" => "clusterFS-node4-salt",
          "type" => "apache-access-log"
}
13.查看redis读取情况：
192.168.1.31:6379[6]> llen apache-accesslog
(integer) 0   #redis数据全部被读取完了，所以为0
14.再对indexer.conf进行过滤，使从redis读取的数据变成json格式易于管理：
[root@clusterFS-node3-salt conf.d]# vim indexer.conf
input {
         redis {
                host => "192.168.1.31"
                port => "6379"
                db => "6"
                data_type => "list"
                key => "apache-accesslog"
        }
}

filter {
        grok{
                match => { "message" => "%{COMBINEDAPACHELOG}" } #增加gork自带的正则表达式变量进行过滤
        }
}

output{
        stdout{
                codec => rubydebug
        }
}

15.192.168.1.31运行apache.conf，先让apache访问日志写入到redis
/opt/logstash/bin/logstash -f apache.conf
16.192.168.1.37上运行indexer.conf，再让logstash读取redis上的日志并进行过虑标准输出。
/opt/logstash/bin/logstash -f indexer.conf
17.设置logstash读取redis日志到elasticsearch中：
[root@clusterFS-node3-salt ~]# cat /etc/logstash/conf.d/indexer.conf 
input {
         redis {
                host => "192.168.1.31"
                port => "6379"
                db => "6"
                data_type => "list"
                key => "apache-accesslog"
        }
}

filter {
        grok{
                match => { "message" => "%{COMBINEDAPACHELOG}" }
        }
}


output{
        elasticsearch {
            hosts => ["192.168.1.31:9200"]
            index => "apache-accesslog-%{+YYYY.MM}"
        }
}
18.[root@clusterFS-node3-salt conf.d]# /opt/logstash/bin/logstash -f indexer.conf 
19.然后测试ab -n 1000 -c 1 http://192.168.1.31:81/ 
20.在kibana中设置时间显示的时候点开设置时间时左边有个自动刷新功能，一般设成1分钟。
```


## ELKStack生产环境实战
```
需求分析：
访问日志：apache访问日志、nginx访问日志、tomcat访问日志    
错误日志：error日志、java日志(需要使用多行插件并配合正则表达式来处理)
系统日志：/var/log/*   syslog   
运行日志：程序写的。
网络日志：防火墙、交换机、路由器的日志。

学习的插件：file（codec => "json"）、syslog、tcp、grok、redis  

1. 标准化：日志放哪里（/data/logs/），格式是什么(要求JSON)，命名规则（access-log、error_log、runtime_log三个目录），日志怎么切割（按天、按小时。access_log和error_log用crontab进行切分，runtime_log由程序直接行写的）
#所有原始的文本----rsync到NAS后，删除最近三天前的。（不建议复制到NAS和NFS，建议复制到本地，access-log每小时进行切片，error-log进行每天切片。）
2. 工具化：如何使用logstash进行收集方案

注意：1.systemctl restart logstash #由于启动logstash而有些日志没有写到输出的地方，原因是有些日志文件logstash这个用户没有权限读取。2.type是关键字，开发不能用，否则会覆盖你的type类型而无法判断。3.写入redis的时候所有的访问日志设为db6，错误日志写成db7，给它分开。

流程图：
源日志==>logstash收集==>写入redis存储<==logstash读取redis写到es==>kibana展示

###实战：
-----------------------------
#192.168.1.31上：
1. [root@clusterFS-node4-salt conf.d]# cat shipper.conf 
input {
        file{
                path => "/var/log/httpd/access_log"
                start_position => "beginning"
                type => "apache-accesslog"
        }
        file {
                path => "/var/log/elasticsearch/myes.log"
                type => "es-log"
                start_position => "beginning"
                codec => multiline{
                        pattern => "^\["
                        negate => true
                        what => "previous"
        }
    }
}

output{
        if [type] == "apache-accesslog" {
                redis {
                        host => "192.168.1.31"
                        port => "6379"
                        db => "6"
                        data_type => "list"
                        key => "apache-accesslog"
                }
        }
        if [type] == "es-log" {
                redis {
                        host => "192.168.1.31"
                        port => "6379"
                        db => "6"
                        data_type => "list"
                        key => "es-log"
                }
        }
}
2. [root@clusterFS-node4-salt logstash]# vim /etc/init.d/logstash 
LS_USER=root   #将logstash改成root(如果不启端口用root，启用端口用logstash用户)
LS_GROUP=root
3. [root@clusterFS-node4-salt conf.d]# systemctl restart logstash.service 
4. 设置系统日志传送到192.168.1.37：
[root@clusterFS-node4-salt conf.d]# vim /etc/rsyslog.conf 
*.* @@192.168.1.37:514  #配置最后面设置
5. [root@clusterFS-node4-salt conf.d]# systemctl restart rsyslog.service 
-----------------------------
#192.168.1.37上：
1. [root@clusterFS-node3-salt conf.d]# cat indexer.conf 
input {
        syslog{
                type => "system-syslog"
                port => 514
        }
        redis {
                type => "apache-accesslog"
                host => "192.168.1.31"
                port => "6379"
                db => "6"
                data_type => "list"
                key => "apache-accesslog"
        }
        redis {
                type => "es-log"
                host => "192.168.1.31"
                port => "6379"
                db => "6"
                data_type => "list"
                key => "es-log"
        }
}

filter {
        if [type] == "apache-accesslog"{
                grok{
                        match => { "message" => "%{COMBINEDAPACHELOG}" }
                }
        }
}


output{
        if [type] == "apache-accesslog"{
                elasticsearch {
                        hosts => ["192.168.1.31:9200"]
                        index => "apa-accesslog-%{+YYYY.MM}"
                }
        }
        if [type] == "system-syslog"{
                elasticsearch {
                        hosts => ["192.168.1.31:9200"]
                        index => "syslog-%{+YYYY.MM}"
                }
        }
        if [type] == "es-log"{
                elasticsearch {
                        hosts => ["192.168.1.31:9200"]
                        index => "myes-log-%{+YYYY.MM}"
                }
        }
}
2. [root@clusterFS-node3-salt logstash]# vim /etc/init.d/logstash 
LS_USER=root   #将logstash改成root(如果不启端口用root，启用端口用logstash用户)
LS_GROUP=root
3. [root@clusterFS-node3-salt logstash]# systemctl restart logstash.service 
-----------------------------
结论：如果redis list 作为ELKStack消息队列，那么请对所有list key的长度进行监控
llen key_name
根据实际情况，例如超过10万就报警。如果不做redis满了的话就会删除老的数据从而丢失数据。

作业：
消息队列换成kafka
深入学习：在infoQ上搜索kafka
实践==>深度实践：数据写入hadop(web-hdfs写入到hadop)

带着目标学Python:
目标一：
1. 把我们资产的Excel导出来，存放到redis里面。使用hash类型。
2. 使用Python脚本，遍历所有主机，通过zabbix api判断是否增加监控。

目标二：
1. 给所有资产的Excel。增加一个字段，叫做角色。例如nginx、haproxy、php
2. 同目标一一对应。然后编写python脚本，调用saltstack api。对该角色执行对应的状态。

目标三：
尝试把现在的Excel。写入到mysql数据库。通过Python导入。
把之前读取redis的操作，改成mysql。

Head First Python  #这本python书要看一下

```

### 源码安装ELKstack
```
备注:环境为centos7.6 ，请按实际需求更改
[root@elk down]# wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.3.0.tar.gz #下载elasticsearch
[root@elk down]# wget https://artifacts.elastic.co/downloads/kibana/kibana-6.3.0-linux-x86_64.tar.gz  #下载kibana
[root@elk down]# wget https://artifacts.elastic.co/downloads/logstash/logstash-6.3.0.tar.gz #下载logstash
[root@elk down]# wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.3.0-linux-x86_64.tar.gz #下载filebeat
[root@elk down]# ls
elasticsearch-6.3.0.tar.gz          kibana-6.3.0-linux-x86_64.tar.gz
filebeat-6.3.0-linux-x86_64.tar.gz  logstash-6.3.0.tar.gz
[root@elk down]# tar xf elasticsearch-6.3.0.tar.gz 
[root@elk down]# tar xf kibana-6.3.0-linux-x86_64.tar.gz 
[root@elk down]# tar xf filebeat-6.3.0-linux-x86_64.tar.gz 
[root@elk down]# tar xf logstash-6.3.0.tar.gz 
[root@elk down]# java -version #安装java1.8
java version "1.8.0"
Java(TM) SE Runtime Environment (build 1.8.0-b132)
Java HotSpot(TM) 64-Bit Server VM (build 25.0-b70, mixed mode)

# 安装elasticsearch
[root@elk down]# mv elasticsearch-6.3.0 /usr/local/
[root@elk down]# cd /usr/local/elasticsearch-6.3.0/
[root@elk elasticsearch-6.3.0]# grep '^[a-Z]' config/elasticsearch.yml  #编辑elasticsearch配置文件
cluster.name: elkserver
node.name: node-1
path.data: /data
path.logs: /var/log/elasticsearch
network.host: 192.168.1.237
http.port: 9200
bootstrap.memory_lock: true
[root@elk elasticsearch-6.3.0]# mkdir /var/log/elasticsearch -p
[root@elk elasticsearch-6.3.0]# mkdir /data -p
[root@elk elasticsearch-6.3.0]# chown -R elasticsearch.elasticsearch  /var/log/elasticsearch 
[root@elk elasticsearch-6.3.0]# chown -R elasticsearch.elasticsearch  /data 
[root@elk elasticsearch-6.3.0]# groupadd elasticsearch  # 新建elasticsearch用户，因为启动elasticsearch不允许root用户启动
[root@elk elasticsearch-6.3.0]# useradd elasticsearch -g elasticsearch -p elasticsearch
[root@elk elasticsearch-6.3.0]#  chown -R elasticsearch.elasticsearch /usr/local/elasticsearch-6.3.0/
[root@elk elasticsearch-6.3.0]# vim /etc/security/limits.conf #更改配置使elasticsearch能运行
elasticsearch soft memlock unlimited  #设置elasticsearch用户软链接，内存锁定大小无限制
elasticsearch hard memlock unlimited
elasticsearch soft nofile 65536  #设置elasticsearch用户软链接，打开文件最大65536个
elasticsearch hard nofile 65536
elasticsearch soft nproc 4096  #设置elasticsearch用户软链接，打开线程最大4096个
elasticsearch hard nproc 4096
备注： elsearch为用户名 可以是使用*进行通配  
nofile 最大打开文件数目
nproc 最大打开进程数目
[root@elk elasticsearch-6.3.0]# vim /etc/sysctl.conf #设置最大的虚拟内存映射数
vm.max_map_count = 262144
[root@elk elasticsearch-6.3.0]# sysctl -p
vm.max_map_count = 262144
[elasticsearch@elk ~]$ /usr/local/elasticsearch-6.3.0/bin/elasticsearch -d
[elasticsearch@elk ~]$ netstat -tunlp | grep 9200
tcp6       0      0 192.168.1.237:9200      :::*                    LISTEN      7414/java 
[elasticsearch@elk elasticsearch-6.3.0]$ curl -i -XGET "http://192.168.1.237:9200/_count" #测试
HTTP/1.1 200 OK
content-type: application/json; charset=UTF-8
content-length: 71

{"count":0,"_shards":{"total":0,"successful":0,"skipped":0,"failed":0}}
###elasticsearch启动脚本
---------------------
[root@elk init.d]# cat elasticsearch 
#!/bin/bash
#
#init file for elasticsearch
#chkconfig: - 86 14
#description: elasticsearch shell
#
#processname: elasticsearch

. /etc/rc.d/init.d/functions

export JAVA_HOME=/usr/local/jdk
export JAVA_BIN=$JAVA_HOME/bin
export PATH=$PATH:$JAVA_BIN
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export JAVA_HOME JAVA_BIN PATH CLASSPATH

##Default variables
USER=elasticsearch
ELSHOME=/usr/local/elasticsearch

case "$1" in
start)
    su $USER<<!
    cd $ELSHOME
    ./bin/elasticsearch -d
!
    echo "elasticsearch startup"
    ;;  
stop)
    es_pid=`ps aux|grep elasticsearch | grep -v 'grep elasticsearch' | awk '{print $2}'`
    kill -9 $es_pid
    echo "elasticsearch stopped"
    ;;  
restart)
    es_pid=`ps aux|grep elasticsearch | grep -v 'grep elasticsearch' | awk '{print $2}'`
    kill -9 $es_pid
    echo "elasticsearch stopped"
    su $USER<<!
    cd $ELSHOME
    ./bin/elasticsearch -d
!
    echo "elasticsearch startup"
    ;;  
*)
    echo "start|stop|restart"
    ;;  
esac

exit $?
---------------------


# 安装kibana
[root@elk data]# cd /down/
[root@elk down]# mv kibana-6.3.0-linux-x86_64 /usr/local/
[root@elk down]# cd /usr/local/kibana-6.3.0-linux-x86_64/
[root@elk kibana-6.3.0-linux-x86_64]# vim config/kibana.yml 
[root@elk kibana-6.3.0-linux-x86_64]# grep '^[a-Z]' config/kibana.yml #编辑kibana配置文件
server.port: 5601
server.host: "192.168.1.237"
elasticsearch.url: "http://localhost:9200"
[root@elk kibana-6.3.0-linux-x86_64]# /usr/local/kibana-6.3.0-linux-x86_64/bin/kibana >& /dev/null & #启动kibana
[root@elk ~]# netstat -tunlp | grep 5601
tcp        0      0 192.168.1.237:5601      0.0.0.0:*               LISTEN      8050/node  
[root@elk translations]# wget https://raw.githubusercontent.com/anbai-inc/Kibana_Hanization/master/translations/zh-CN.json #下载汉化kibanajson文件
[root@elk translations]# mvzh-CN.json /usr/local/kibana-6.3.0-linux-x86_64/src/core_plugins/kibana/translations/zh-CN.json #移到此位置
[root@elk kibana]# vim /usr/local/kibana-6.3.0-linux-x86_64/config/kibana.yml 
i18n.defaultLocale: "zh-CN" #修改默认语言
[root@elk translations]# /usr/local/kibana-6.3.0-linux-x86_64/bin/kibana >& /dev/null & #重新启动kibana
#注：当kibana打开时禁止登录表示kibana未成功连接elasticsearch。kibana可以用root用户启动

####kibana启动脚本
----------------
[root@elk init.d]# cat kibana 
#!/bin/bash
#
#init file for kibana 
#chkconfig: - 87 13
#description: kibana shell
#

. /etc/rc.d/init.d/functions

export JAVA_HOME=/usr/local/jdk
export JAVA_BIN=$JAVA_HOME/bin
export PATH=$PATH:$JAVA_BIN
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export JAVA_HOME JAVA_BIN PATH CLASSPATH

##Default variables
ETVAL=0
prog="/usr/local/kibana-6.3.0-linux-x86_64/bin/kibana >& /dev/null &"
desc="kibana"
lockfile="/var/lock/subsys/kibana"

start(){
        echo -n $"Starting $desc:"
        daemon $prog 
        RETVAL=$?
        echo 
        [ $RETVAL -eq 0 ] && touch $lockfile
        return $RETVAL
}

stop(){
        kb_pid=`ps aux|grep '/usr/local/kibana-6.3.0-linux-x86_64/bin'| grep -v 'grep --color=auto /usr/local/kibana-6.3.0-linux-x86_64/bin' | awk '{print $2}'`
        kill -9 $kb_pid
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && rm -f $lockfile
        return $RETVAL
}

restart (){
        stop
        start
}

case "$1" in 
        start)
                start;;
        stop)
                stop;;
        restart)
                restart;;
        *)
                echo $"Usage: $0 {start|stop|restart}"
                RETVAL=1;;
esac
exit #RETVAL
----------------

#安装logstash
[root@elk down]# mv logstash-6.3.0 /usr/local/ 
[root@elk logstash-6.3.0]# vim /etc/profile.d/jdk.sh 
#!/bin/bash
#
export JAVA_HOME=/usr/local/jdk   #加一行JAVA_HOME的变量
export PATH=$PATH:/usr/local/jdk/bin
[root@elk logstash-6.3.0]# . /etc/profile.d/jdk.sh  #生效变量JAVA_HOME
[root@elk logstash-6.3.0]# vim config/damo.conf  #新建一个配置文件
input {
  file {
    path => ["/var/log/messages", "/var/log/sucure"]
    type => "system237-log"
    start_position => "beginning"
  }
  file {
    path => "/var/log/httpd/*log"
    type => "httpd-log"
    start_position => "beginning"
  }
}

filter {
}

output {
  if [type] == "system237-log" {
    elasticsearch {
      hosts => ["192.168.1.237:9200"]
      index => "system-log-%{+YYYY.MM.dd}"
    }
  }
  if [type] == "httpd-log" {
    elasticsearch {
      hosts => ["192.168.1.237:9200"]
      index => "httpd-log-%{+YYYY.MM.dd}"
    }
  }
}

添加索引httpd-log-*，下一步选择时间戳格式进行保存索引

###logstash设置启动脚本
[root@elk bin]# /usr/local/logstash/bin/system-install /usr/local/logstash/config/startup.options systemd
#利用logstash启动脚本安装功能进行注册生成启动脚本，systemd和sysv风格二选一


##ELK日志收集系统使用架构
前端：nginx反向代理+身份验证+ACL
node1: elasticsearch、kibana
node2: elasticsearch、kibana
被收集机器：logstash,收集日志文件发送到elasticsearch
#注：它们之间全靠elasticsearch存储，各elasticsearch节点之间同步数据达到集群的作用
```

### docker部署elk
```
[root@elk2 ~]# docker pull elasticsearch:2.4.6
[root@elk2 ~]# docker pull kibana:4.5 
[root@elk2 ~]# docker pull logstash:2.4.0 
## 部署elasticsearch
[root@elk2 elk]# tree elasticsearch/
elasticsearch/
├── config
│?? ├── elasticsearch.yml
│?? ├── logging.yml
│?? └── scripts
├── data
│?? └── elkserver
│??     └── nodes
│??         └── 0
│??             ├── node.lock
│??             └── _state
│??                 └── global-0.st
└── logs
[root@elk2 elk]# cat elasticsearch/config/elasticsearch.yml 
cluster.name: elkserver
node.name: node-1
path.data: /usr/share/elasticsearch/data
path.logs: /usr/share/elasticsearch/logs
network.host: 0.0.0.0
http.port: 9200
bootstrap.memory_lock: true

docker run --name els -p 9200:9200 -p 9300:9300 -v /docker/elk/elasticsearch/data:/usr/share/elasticsearch/data -v /docker/elk/elasticsearch/config:/usr/share/elasticsearch/config -v /docker/elk/elasticsearch/logs:/usr/share/elasticsearch/logs elasticsearch:2.4.6

## 部署kibana
[root@elk2 elk]# tree kibana/
kibana/
└── config
    └── kibana.yml
[root@elk2 config]# grep '^[a-Z]' kibana.yml 
server.port: 5601
server.host: '0.0.0.0'
elasticsearch.url: 'http://elasticsearch:9200'

[root@elk2 config]# docker run -d --name kb --link els:elasticsearch -v /docker/elk/kibana/config:/etc/kibana -p 5601:5601 kibana:4.5

## 部署logstash
[root@elk2 elk]# tree logstash/
logstash/
├── config
│?? └── logstash.conf
└── docker-entrypoint.sh
[root@elk2 logstash]# cat config/logstash.conf 
input {
        tcp {
                port => 5000
        }
}
output {
        elasticsearch {
                hosts => "elasticsearch:9200"
                index => "system-log-%{+YYYY.MM.dd}"
        }
}
[root@elk2 logstash]# cat docker-entrypoint.sh 
#!/bin/bash
/opt/logstash/bin/logstash -f /etc/logstash/conf.d

[root@elk2 elasticsearsh]# docker run --name lg -d -p 5000:5000 -v /docker/elk/logstash/config:/etc/logstash/conf.d -v /docker/elk/logstash/docker-entrypoint.sh:/docker-entrypoint.sh --link els:elasticsearch logstash:2.4.0 

#注：--link els:elasticsearch表示连接名称为els的容器，并取一个elasticsearch别名，使在新建的容器中可以解析els主机的ip
```


### ELK docker部署
```
#1.宿主机系统调优
变更 /etc/security/limits.conf 文件，为其追加以下内容：
* soft nofile 204800
* hard nofile 204800
* soft nproc 204800
* hard nproc 204800
* soft memlock unlimited
* hard memlock unlimited
跳转到 /etc/security/limits.d 目录下，修改相应的 conf 文件，为其追加以下内容：
* soft nproc unlimited
* hard nproc unlimited
除了上述操作以外，还需要变更内核参数，执行以下命令即可：
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p
注意：ERROR: [1] bootstrap checks failed #此错误是宿主机没有进行系统调优导致的

#2.节点部署，凡是集群，必须是3台及以上，这样方便少数服从多数选举
##node1##
[root@node1 elk]# cat docker-compose.yml
version: '3'
services:
  elasticsearch:                    # 服务名称
    image: elasticsearch:7.1.1      # 使用的镜像
    container_name: elasticsearch7.1.1   # 容器名称
    restart: always                 # 失败自动重启策略
    environment:                                    
      - node.name=node-201                   # 节点名称，集群模式下每个节点名称唯一
      - network.publish_host=192.168.43.201  # 用于集群内各机器间通信,其他机器访问本机器的es服务
      - network.host=0.0.0.0                # 设置绑定的ip地址，可以是ipv4或ipv6的，默认为0.0.0.0，
      - discovery.seed_hosts=192.168.43.204,192.168.43.201,192.168.43.202          # es7.x 之后新增的配置，写入候选主节点的设备地址，在开启服务后可以被选为主节点
      - cluster.initial_master_nodes=192.168.43.204,192.168.43.201,192.168.43.202 # es7.x 之后新增的配置，初始化一个新的集群时需要此配置来选举master
      - cluster.name=es-cluster     # 集群名称，相同名称为一个集群
      - bootstrap.memory_lock=true  # 内存交换的选项，官网建议为true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"    # 设置内存
    ulimits:             
      memlock:
        soft: -1      
        hard: -1
    volumes:
      - /data/elk/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml  # 将容器中es的配置文件映射到本地，设置跨域， 否则head插件无法连接该节点
      - esdata:/usr/share/elasticsearch/data  # 存放数据的文件， 注意：这里的esdata为 顶级volumes下的一项。
    ports:
      - 9200:9200    # http端口
      - 9300:9300    # es节点直接交互的端口，非http
  kibana:
    image: docker.elastic.co/kibana/kibana:7.1.1
    container_name: kibana7.1.1
    environment:
      - elasticsearch.hosts=http://elasticsearch:9200  #设置连接的es节点
    hostname: kibana
    depends_on:
      - elasticsearch   #依赖es服务，会先启动es容器在启动kibana
    restart: always
    volumes:
      - /data/elk/kibana.yml:/usr/share/kibana/config/kibana.yml
    ports:
      - 5601:5601 #对外访问端口
  logstash:
    image: docker.elastic.co/logstash/logstash:7.1.1
    container_name: logstash7.1.1
    hostname: logstash
    restart: always
    volumes:
      - /data/elk/test_port.conf:/usr/share/logstash/pipeline/test_port.conf
    depends_on:
      - elasticsearch
    ports:
      - 6666:6666        #这个端口是tcp测试端口
      - 9600:9600		 #这个端口是logstash API端口
      - 5044:5044        #从filebeat读取消息输出到logstash的端口
volumes:
  esdata:
    driver: local    # 会生成一个对应的目录和文件，用来持久化数据，第一次从容器保存到盘，第二次从盘读配置到容器。

[root@node1 elk]# cat elasticsearch.yml 
network.host: 0.0.0.0
http.cors.enabled: true      # 设置跨域，主要用于head插件访问es
http.cors.allow-origin: "*"  # 允许所有域名访问

[root@node1 elk]# cat /data/elk/kibana.yml 
#
# ** THIS IS AN AUTO-GENERATED FILE **
#

# Default Kibana configuration for docker target
server.name: kibana
server.host: "0"
elasticsearch.hosts: [ "http://elasticsearch:9200" ]
xpack.monitoring.ui.container.elasticsearch.enabled: true
i18n.locale: "zh-CN"

[root@node1 elk]# cat /data/elk/test_port.conf 
input {
  tcp {
    type => "tcp"
    port => 6666
    mode => "server"
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "system-test2-%{+YYYY.MM.dd}"
  }
  stdout {
    codec => rubydebug
  }
}

##node2##
[root@node2 elk]# cat docker-compose.yml
version: '3'
services:
  elasticsearch:                    # 服务名称
    image: elasticsearch:7.1.1      # 使用的镜像
    container_name: elasticsearch7.1.1   # 容器名称
    restart: always                 # 失败自动重启策略
    environment:                                    
      - node.name=node-202                   # 节点名称，集群模式下每个节点名称唯一
      - network.publish_host=192.168.43.202  # 用于集群内各机器间通信,其他机器访问本机器的es服务
      - network.host=0.0.0.0                # 设置绑定的ip地址，可以是ipv4或ipv6的，默认为0.0.0.0，
      - discovery.seed_hosts=192.168.43.204,192.168.43.202,192.168.43.201          # es7.x 之后新增的配置，写入候选主节点的设备地址，在开启服务后可以被选为主节点
      - cluster.initial_master_nodes=192.168.43.204,192.168.43.202,192.168.43.201 # es7.x 之后新增的配置，初始化一个新的集群时需要此配置来选举master
      - cluster.name=es-cluster     # 集群名称，相同名称为一个集群
      - bootstrap.memory_lock=true  # 内存交换的选项，官网建议为true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"    # 设置内存
    ulimits:             
      memlock:
        soft: -1      
        hard: -1
    volumes:
      - /data/elk/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml  # 将容器中es的配置文件映射到本地，设置跨域， 否则head插件无法连接该节点
      - esdata:/usr/share/elasticsearch/data  # 存放数据的文件， 注意：这里的esdata为 顶级volumes下的一项。
    ports:
      - 9200:9200    # http端口
      - 9300:9300    # es节点直接交互的端口，非http
  kibana:
    image: docker.elastic.co/kibana/kibana:7.1.1
    container_name: kibana7.1.1
    environment:
      - elasticsearch.hosts=http://elasticsearch:9200  #设置连接的es节点
    hostname: kibana
    depends_on:
      - elasticsearch   #依赖es服务，会先启动es容器在启动kibana
    restart: always
    volumes:
      - /data/elk/kibana.yml:/usr/share/kibana/config/kibana.yml
    ports:
      - 5601:5601 #对外访问端口
  logstash:
    image: docker.elastic.co/logstash/logstash:7.1.1
    container_name: logstash7.1.1
    hostname: logstash
    restart: always
    volumes:
      - /data/elk/test_port.conf:/usr/share/logstash/pipeline/test_port.conf
    depends_on:
      - elasticsearch
    ports:
      - 6666:6666        #这个端口是tcp测试端口
      - 9600:9600		 #这个端口是logstash API端口
      - 5044:5044        #从filebeat读取消息输出到logstash的端口
volumes:
  esdata:
    driver: local    # 会生成一个对应的目录和文件，如何查看，下面有说明。

[root@node2 elk]# cat elasticsearch.yml 
network.host: 0.0.0.0
http.cors.enabled: true      # 设置跨域，主要用于head插件访问es
http.cors.allow-origin: "*"  # 允许所有域名访问

[root@node2 elk]# cat /data/elk/kibana.yml 
#
# ** THIS IS AN AUTO-GENERATED FILE **
#

# Default Kibana configuration for docker target
server.name: kibana
server.host: "0"
elasticsearch.hosts: [ "http://elasticsearch:9200" ]
xpack.monitoring.ui.container.elasticsearch.enabled: true
i18n.locale: "zh-CN"

[root@node2 elk]# cat /data/elk/test_port.conf 
input {
  tcp {
    type => "tcp"
    port => 6666
    mode => "server"
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "system-test2-%{+YYYY.MM.dd}"
  }
  stdout {
    codec => rubydebug
  }
}

##node3##
[root@node3 elk]# cat docker-compose.yml
version: '3'
services:
  elasticsearch:                    # 服务名称
    image: elasticsearch:7.1.1      # 使用的镜像
    container_name: elasticsearch7.1.1   # 容器名称
    restart: always                 # 失败自动重启策略
    environment:                                    
      - node.name=node-203                   # 节点名称，集群模式下每个节点名称唯一
      - network.publish_host=192.168.43.204  # 用于集群内各机器间通信,其他机器访问本机器的es服务
      - network.host=0.0.0.0                # 设置绑定的ip地址，可以是ipv4或ipv6的，默认为0.0.0.0，
      - discovery.seed_hosts=192.168.43.204,192.168.43.202,192.168.43.201          # es7.x 之后新增的配置，写入候选主节点的设备地址，在开启服务后可以被选为主节点
      - cluster.initial_master_nodes=192.168.43.204,192.168.43.202,192.168.43.201 # es7.x 之后新增的配置，初始化一个新的集群时需要此配置来选举master
      - cluster.name=es-cluster     # 集群名称，相同名称为一个集群
      - bootstrap.memory_lock=true  # 内存交换的选项，官网建议为true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"    # 设置内存
    ulimits:             
      memlock:
        soft: -1      
        hard: -1
    volumes:
      - /data/elk/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml  # 将容器中es的配置文件映射到本地，设置跨域， 否则head插件无法连接该节点
      - esdata:/usr/share/elasticsearch/data  # 存放数据的文件， 注意：这里的esdata为 顶级volumes下的一项。
    ports:
      - 9200:9200    # http端口
      - 9300:9300    # es节点直接交互的端口，非http
volumes:
  esdata:
    driver: local    # 会生成一个对应的目录和文件，如何查看，下面有说明。

#3.运行docker:
[root@node1 elk]# docker-compose up -d 
[root@node2 elk]# docker-compose up -d 
[root@node3 elk]# docker-compose up -d 
注：进行docker配置的时候，复制配置文件后就要修改每个主机上的ip及名称，否则会导致集群失败

#4.安装elasticsearch插件HEAD,然后进行查看Elasticsearch状态，
[root@node1 elk]# docker run -d --name es_admin -p 9100:9100 --restart=always mobz/elasticsearch-head:5
#然后访问http://192.168.43.201:9100就可以连接elasticsearch查看状态了

#4.设置分片：
一般以（节点数*1.5或3倍）来计算，比如有4个节点，分片数量一般是6个到12个，每个分片一般分配一个副本
----新建或修改默认模版all_default_template: 新生成的索引都会自动匹配该模版，number_of_shards: 索引分片为5，副本默认也是5，order:优先级，数字越高等级越高
PUT /_template/all_default_template
{
  "index_patterns": ["*"],
  "order" : 100,
  "settings": {
    "number_of_shards": 5
  }
}
----取消副本分片
PUT /filebeat-7.6.2-2022.11.03-000001/_settings
{
    "index": {
        "number_of_replicas" : 0
    }
}

curl -XGET -s -u user:pass http://localhost:9200/_cat/shards | grep UNASSIGNED | awk {'print $1'} | xargs -i curl -X PUT -s -H 'Content-Type: application/json' -u user:pass "http://localhost:9200/{}/_settings" -d '
{
    "index": {
        "number_of_replicas" : 0
    }
}
' | jq . > /tmp/test.log



----预设置索引，设置分片和副本（用来提前设置索引并设置分片，以防未来会使用,已经存在的索引不能更改）
PUT /testindex
{
   "settings" : {
      "number_of_shards" : 6,
      "number_of_replicas" : 1
   }
}
注意：在/usr/share/elasticsearch/config/elasticsearch.yml配置文件中#action.destructive_requires_name : true #设置禁用_all和*通配符
PUT /_cluster/settings
{
    "persistent" : {
       "action.destructive_requires_name":true }
}
get /_cluster/settings
例：
1.设置默认索引
PUT /_template/all_default_template
{
  "index_patterns": "*",
  "order" : 100,
  "settings": {
    "number_of_shards": 6,
    "number_of_replicas": "1"
  }
}
GET /_template/all_default_template
2.查看创建的模板，索引模板查看分片是否设置成功
get /_template?pretty=true
3.创建一个索引查看索引主分片和副本分片
put /test
4.查看创建的索引test主分片及副本分片数设置
get /test/_settings?pretty=true
get /_settings?pretty=true    --查看所有索引设置
5.删除索引
delete /test
delete /test*
delete /_all   --删除所有索引，超级危险
6.常用API命令：
get /_cat/nodes
192.168.13.160 74 83 1 0.05 0.16 0.21 dilm - dlog-01
192.168.13.162 58 96 2 0.13 0.19 0.22 dilm * dlog-03
192.168.13.161 55 82 2 0.47 0.41 0.27 dilm - dlog-02
get /_cat/health
1606550453 08:00:53 dlog green 3 3 84 39 0 0 0 0 - 100.0%
/_cat/indices
green open .kibana_1                6w8WSB8VQwyz8SPCPf7r9Q 1 1     38    5 137.4kb  49.5kb


#5.用logstash测试端口 6666进行写入elasticsear测试:
[root@node2 elk]# echo 'hello_world' | ncat 192.168.43.201 6666 #发送消息到logstash端口，从而写入数据到elasticsearch
注意：logstash在命令行运行命令时，会很慢，需要等会(在logstash容器中测试时遇到此问题)
或
#6.用filebeat写入elasticsearch
--安装及配置
[root@node2 log]# sudo rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
[root@node2 elk]# vim /etc/yum.repos.d/filebeat.repo
[elastic-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
[root@node2 log]# sudo yum install filebeat
[root@node2 log]# sudo systemctl enable filebeat
[root@node2 log]# egrep -v '#|^$' /etc/filebeat/filebeat.yml 
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/messages
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: true
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:
output.elasticsearch:
  hosts: ["127.0.0.1:9200"]
#output.logstash:	#下面是写入logstash.然后由logstash写入到elasticsearch,疑问见后面其他问题
  #hosts: ["192.168.43.201:5044"]
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
[root@node2 elk]# filebeat -c /etc/filebeat/filebeat.yml #运行filebeat进行测试
[root@node2 elk]# systemctl start filebeat.service  #以守护进程运行filebeat
[root@node2 log]# logger testtt

----filebeat将日志为Json格式的日志解析成单个字段-----
[root@master /data/elasticsearch]# grep -Ev '#|^$' /etc/filebeat/filebeat.yml 
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/httpd/access_log
  tags: ["httpd"]
  json.keys_under_root: true
  json.overwrite_keys: true
- type: log
  enabled: false
  paths:
    - /var/lib/docker/containers/*/*.log
  tags: ["docker"]
  json.keys_under_root: true
  json.overwrite_keys: true
output.elasticsearch:
  hosts: ["192.168.15.199:7200"]
  indices:
    - index: "docker_%{+yyyy.MM.dd}"
      when.contains:
        tags: "docker"
    - index: "httpd_%{+yyyy.MM.dd}"
      when.contains:
        tags: "httpd"
  username: "jack"
  password: "123456"
-------------------------------------------------


#7.访问kibana,http://192.168.43.201:5601 || http://192.168.43.202:5601
在设置中建立索引模式 system-test* 。就可以在首页查看测试日志了

##其它问题：##
1.需要删除太久远的日志，用来腾出空间
curl -X DELETE http://192.168.43.201:9200/system-test-2020.01.01 #system-test-2020.01.01就是索引名称，system-test-2020*，也可以用通配符来删除
2.elasticsearch需要进行安全防护，不然任何人都可以进行增删查改elasticsearch,很危险
3.kibana索引模式创建好后保存在elasticsearch的数据存储目录中
4.kibana索引模式创建保存时最后一步完成后，在已保存的对象中看不到索引模式，这个问题应该是测试elk时没有对旧的elasticsearch的data数据完全清除导致的
5.当filebeat 的5044端口和logstash tcp6666端口两种方式写入同一个索引时，哪个先写入那么这个索引就只能先写入的用，另外一个则写入不了
6.一般是使用filebeat对系统日志进行收集，然后通过5044端口写入到logstash，然后由logstash的filter模块进行过虑，使系统日志JSON化，最后写入到elasticsearch
7.logstash写入数据时可以将一条日志写入整个es集群所有节点，在logstash配置文件是指定es地址是列表格式，写入数据后在kibana中查找日志时不会是多少日志，只是一条日志。
8.在kibana的配置文件中，可以连接多个es集群。指定es地址是列表格式
--当es7.1.1集群是两个节点的时候：其中一个节点挂了，你往另外一个节点写入json日志时，kibana和es无法读取索引，必须等待另一个节点起来后，两个节点都是正常状态才能写入，之前写入的json日志也不会丢失，还是会在es中，只是未写入排队状态。（两个节点可以保证数据的安全，但不能保证业务的可靠）
--当大于等于3个节点时：不会遇到这个问题。因为当其中一个节点挂掉时，其它任一个节点会选举为master,此时被写入索引不会被锁定，可以正常写入（三个及以上节点及可以保证数据安全也可以保证业务可靠）

######Elasticsearch日志备份：采用快照方式，官方建议
Elasticsearch 做备份有两种方式，一是将数据导出成文本文件，比如通过 elasticdump、esm 等工具将存储在 Elasticsearch 中的数据导出到文件中。二是以备份 elasticsearch data 目录中文件的形式来做快照，也就是 Elasticsearch 中 snapshot 接口实现的功能。第一种方式相对简单，在数据量小的时候比较实用，当应对大数据量场景效率就大打折扣。
###第一种方式备份：
6.4版本docker-compose.yml
-------------
version: '3'
services:
  elasticsearch:                    # 服务名称
    image: elasticsearch:6.4.0      # 使用的镜像
    container_name: elasticsearch6.4.0   # 容器名称
    restart: always                 # 失败自动重启策略
    environment:                                    
      - cluster.name=es-cluster     # 集群名称，相同名称为一个集群
      - bootstrap.memory_lock=true  # 内存交换的选项，官网建议为true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"    # 设置内存
    ulimits:             
      memlock:
        soft: -1      
        hard: -1
    volumes:
      - esdata2:/usr/share/elasticsearch/data  # 存放数据的文件， 注意：这里的esdata为 顶级volumes下的一项。
    ports:
      - 9200:9200    # http端口
      - 9300:9300    # es节点直接交互的端口，非http
  kibana:
    image: docker.elastic.co/kibana/kibana:6.4.0
    container_name: kibana6.4.0
    environment:
      - elasticsearch.hosts=http://elasticsearch:9200  #设置连接的es节点
    hostname: kibana
    depends_on:
      - elasticsearch   #依赖es服务，会先启动es容器在启动kibana
    restart: always
    ports:
      - 5601:5601 #对外访问端口
volumes:
  esdata2:
    driver: local  
-------------------
blog:
#通过指定索引，指定匹配模式，指定时间来查看数据，match_all可以换成match来匹配特定字符
GET /homsom_log/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "match_all": {}
        }
      ],
      "filter": {
        "range": {
          "TimeStamp": {
            "gte":"2020-04-27T00:00:00.000+0800",
            "lt":"2020-04-28T00:00:00.000+0800"
          }
        }
      }
    }
  },
  "sort": [ { "TimeStamp": { "order": "desc" }}],
  "size": 100
}
#通过指定索引，指定匹配模式，指定时间来删除数据
#默认情况下，_delete_by_query使用1000个滚动批次。你可以用scroll_size URL参数来改变批大小
POST /homsom_log/_delete_by_query?scroll_size=5000
{
  "query": {
    "bool": {
      "must": [
        {
          "match_all": {}
        }
      ],
      "filter": {
        "range": {
          "@timestamp": {
            "gte":"2020-04-28T00:00:00.000+0800",
            "lt":"2020-04-28T00:00:00.000+0800"
          }
        }
      }
    }
  }
}
或者
#通过时间查找
GET /homsom_log/_search
{
  "query": {
        "range": {
          "TimeStamp": {
            "time_zone": "+08:00",
            "gte":"2020-04-27T00:00:00.000+0800",
            "lt":"2020-04-28T00:00:00.000+0800"
        }
      }
  }
}
#通过时间来删除
#默认情况下，_delete_by_query使用1000个滚动批次。你可以用scroll_size URL参数来改变批大小
POST /homsom_log/_delete_by_query?scroll_size=5000
{
  "query": {
        "range": {
          "@timestamp": {
            "time_zone": "+08:00",
            "gte":"2020-04-28T00:00:00.000+0800",
            "lt":"2020-04-28T00:00:00.000+0800"
        }
      }
  }
}
例：备份blog20200427-20200428的日志
注：备份的es版本和恢复的es版本必须保持高度一致，否则恢复会失败，恢复时选项可填limit,searchBody等选项限制。具体使用见：https://github.com/taskrabbit/elasticsearch-dump
1.备份mapping
docker run --rm -it -v /dockerdata/elasticsearchdump:/tmp taskrabbit/elasticsearch-dump  --input=http://192.168.13.239:9200/homsom_log  --output=/tmp/homsom_log_mapping.json   --type=mapping
2.备份data
docker run --rm -it -v /dockerdata/elasticsearchdump:/tmp taskrabbit/elasticsearch-dump  --input=http://192.168.13.239:9200/homsom_log  --output=/tmp/homsom_log.json   --type=data --limit=1000 --searchBody='{"query":{"range":{"TimeStamp":{"gte":"2020-04-27T00:00:00.000+0800","lt":"2020-04-28T00:00:00.000+0800"}}}}'
3.恢复mapping
docker run --rm -it -v /dockerdata/elasticsearchdump:/tmp taskrabbit/elasticsearch-dump  --input=/tmp/homsom_log_mapping.json --output=http://172.168.2.222:9200/homsom_log --type=mapping
4.恢复data
docker run --rm -it -v /dockerdata/elasticsearchdump:/tmp taskrabbit/elasticsearch-dump  --input=/tmp/homsom_log.json --output=http://172.168.2.222:9200/homsom_log --type=data --limit=1000

备份hlog操作流程
1.备份mapping
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=http://192.168.13.237:9200/clog  --output=/tmp/clog--mapping.json   --type=mapping
2.备份data
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=http://192.168.13.237:9200/clog  --output=/tmp/clog-low20190115.json   --type=data --limit=1000 --searchBody='{"query":{"range":{"time":{"lt":"2019-01-15T00:00:00.000+0800"}}}}'
3. 恢复mapping
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=/tmp/clog--mapping.json --output=http://172.168.2.223:9200/backup-clog --type=mapping
4.恢复data
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=/tmp/clog-low20190115.json --output=http://172.168.2.223:9200/backup-clog --type=data --limit=10000

备份blog操作流程:
1.备份mapping
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=http://192.168.13.239:9200/homsom_log  --output=/tmp/homsom_log--mapping.json   --type=mapping
2.备份data
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=http://192.168.13.239:9200/homsom_log  --output=/tmp/homsom_log-low20200430.json   --type=data --limit=1000 --searchBody='{"query":{"range":{"TimeStamp":{"lt":"2020-04-30T00:00:00.000+0800"}}}}'
3. 恢复mapping
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=/tmp/homsom_log--mapping.json --output=http://172.168.2.223:9200/backup-homsom_log  --type=mapping
4.恢复data
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=/tmp/homsom_log-low20200430.json --output=http://172.168.2.223:9200/backup-homsom_log --type=data --limit=20000

备份hlog操作流程--20200507
GET /clog/_search
{
  "query": {
        "range": {
          "time": {
            "time_zone": "+08:00",
            "gte":"2019-01-15T00:00:00.000",
            "lt":"2019-01-21T00:00:00.000"
        }
      }
  },
  "sort": [ { "time": { "order": "desc" }}],
  "size": 100
}

----20190115-20190120总共218288条记录，备份耗时大概5分钟
备份data
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=http://192.168.13.237:9200/clog  --output=/tmp/clog-20190115-20190120.json   --type=data --limit=1000 --searchBody='{"query":{"range":{"time":{"time_zone":"+08:00","gte":"2019-01-15T00:00:00.000","lt":"2019-01-21T00:00:00.000"}}}}'
----20190115-20190120总共218288条记录，恢复耗时大概3分钟
恢复data
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=/tmp/clog-20190115-20190120.json --output=http://172.168.2.223:9200/backup-clog --type=data --limit=10000
----20190121-20190220总共684224条记录，备份耗时大概12分钟
备份data
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=http://192.168.13.237:9200/clog  --output=/tmp/clog-20190121-20190220.json   --type=data --limit=1000 --searchBody='{"query":{"range":{"time":{"time_zone":"+08:00","gte":"2019-01-21T00:00:00.000","lt":"2019-02-21T00:00:00.000"}}}}'

----20190115-20190120总共684224条记录，恢复大概6分钟
恢复data
docker run --rm -it -v /mnt:/tmp taskrabbit/elasticsearch-dump  --input=/tmp/clog-20190121-20190220.json --output=http://172.168.2.223:9200/backup-clog --type=data --limit=10000
----注：如果恢复数据时报错：blocked by: [FORBIDDEN/12/index read-only / allow delete (api)，则表示磁盘空间不够用，es当磁盘的使用率超过95%时，为了防止节点耗尽磁盘空间，自动将索引设置为只读模式，只需腾出空间，然后手动把节点只读模式设为null即可。--当你从查询删除时这个状态为只读时也是无法删除的
GET /backup-clog/_settings
PUT /backup-clog/_settings
{
  "index.blocks.read_only_allow_delete": null
}
POST /backup-clog/_delete_by_query?scroll_size=5000
{
  "query": {
        "range": {
          "time": {
            "time_zone": "+08:00",
            "lt":"2019-01-12T00:00:00.000"
        }
      }
  }
}


**多条件查询数据删除**

must: and
must_not: not
should: or
```bash
#!/bin/sh
LOG_FILE=/shell/shell.log
DATETIME='date +"%Y-%m-%d %H:%M:%S"'
ES_ADDRESS='http://127.0.0.1:9210/clog'

echo "`eval ${DATETIME}`: start clear ${ES_ADDRESS} data... " >> ${LOG_FILE}
curl -s -H'Content-Type:application/json' -d'{
  "query": {
    "bool": {
      "must": [
        {
          "match": {
            "appid": "1350"
          }
        },
        {
          "match": {
            "level": "info"
          }
        }
      ],
      "filter": {
        "range": {
          "time": {
            "time_zone": "+08:00",
            "gte":"2024-04-06",
            "lte":"2024-05-06"
          }
        }
      }
    }
  }
}
' -XPOST "${ES_ADDRESS}/_delete_by_query?scroll_size=3000"


echo "`eval ${DATETIME}`: clear http://127.0.0.1:9210/clog data finished... " >> ${LOG_FILE}
echo '' >> ${LOG_FILE}
```




**批量手动配置所有索引为读写**
```bash
for i in `curl -s -XGET "http://localhost:9200/_settings" | jq 'keys' | jq .[] | tr -d '"'`;do echo $i;curl -H 'Content-Type: application/json' -X PUT http://localhost:9200/$i/_settings -d '{"index.blocks.read_only_allow_delete": null}';done
```


删除hlog小于20200101的旧日志-----20200508操作，一个月一个月来
--查看指定时间日志大小
GET /clog/_search
{
  "query": {
        "range": {
          "time": {
            "time_zone": "+08:00",
            "lt":"2020-01-01T00:00:00.000"
        }
      }
  },
  "sort": [ { "time": { "order": "desc" }}],
  "size": 10
}
--删除指定时间日志
POST /clog/_delete_by_query?scroll_size=5000
{
  "query": {
        "range": {
          "time": {
            "time_zone": "+08:00",
            "lt":"2020-01-01T00:00:00.000"
        }
      }
  }
}
刷新索引---不是必须操作
http://192.168.13.237:9200/clog/_refresh
查看clog的segments---不是必须操作
http://192.168.13.237:9200/_cat/segments/clog
--合并段腾出空间
POST /clog/_forcemerge?only_expunge_deletes=true&max_num_segments=1

###第二种备份的方式，即 snapshot api 的使用
elk日志备份步骤：
yum install -y nfs-utils rpcbind
#vim /etc/exports
  /backup	*(rw,async)
mkdir -p /backup
chown -R 1000:1000 /backup  #elasticsearch UID
systemctl start rpcbind
systemctl start nfs
systemctl enable rcpbind
systemctl enable nfs
exportfs -arv
mount -t nfs 192.168.43.201:/backup /mnt
---共享文件系统存储库（"type": "fs"）使用共享文件系统存储快照。为了注册共享文件系统存储库，必须将相同的共享文件系统安装到所有主节点和数据节点上的相同位置。path.repo 必须在所有主节点和数据节点上的设置中注册。而且更改后必须要重启es服务才行,滚动重启es服务
path.repo: ["/mount/backups"]
path.repo: ["\\\\MY_SERVER\\Snapshots"]
path.repo: ["/mnt"]  --追加到elasticsearch.yml中，这个路径要挂载宿主机上的NFS，NFS权限必须是1000:1000,因为elasticsearch要写入
注：经过实践得出，备份后的快照都会在主节点上显示
1.建仓库
###
PUT /_snapshot/my_backup
{
  "type": "fs",
  "settings": {
    "location": "/mnt"
  }
}
---
{
  "acknowledged" : true
}
###
GET /_snapshot/my_backup
----
{
  "my_backup" : {
    "type" : "fs",
    "settings" : {
      "location" : "/mnt"
    }
  }
}
###备份索引1
PUT /_snapshot/my_backup/snapshot_1?wait_for_completion=true
{
  "indices": "test-2020.04.15",
  "ignore_unavailable": true,
  "include_global_state": false,
  "metadata": {
    "taken_by": "jack",
    "taken_because": "20200405 backup index 'test-2020.04.15' "
  }
}
---
{
  "snapshot" : {
    "snapshot" : "snapshot_1",
    "uuid" : "YP0HygikQdGhuh1zeuQcAA",
    "version_id" : 7010199,
    "version" : "7.1.1",
    "indices" : [
      "test-2020.04.15"
    ],
    "include_global_state" : false,
    "state" : "SUCCESS",
    "start_time" : "2020-04-15T07:42:01.036Z",
    "start_time_in_millis" : 1586936521036,
    "end_time" : "2020-04-15T07:42:01.171Z",
    "end_time_in_millis" : 1586936521171,
    "duration_in_millis" : 135,
    "failures" : [ ],
    "shards" : {
      "total" : 1,
      "failed" : 0,
      "successful" : 1
    }
  }
}
###
GET /_snapshot/my_backup/snapshot_1  --查看快照备份成功与否信息
---
{
  "snapshots" : [
    {
      "snapshot" : "snapshot_1",
      "uuid" : "YP0HygikQdGhuh1zeuQcAA",
      "version_id" : 7010199,
      "version" : "7.1.1",
      "indices" : [
        "test-2020.04.15"
      ],
      "include_global_state" : false,
      "state" : "SUCCESS",
      "start_time" : "2020-04-15T07:42:01.036Z",
      "start_time_in_millis" : 1586936521036,
      "end_time" : "2020-04-15T07:42:01.171Z",
      "end_time_in_millis" : 1586936521171,
      "duration_in_millis" : 135,
      "failures" : [ ],
      "shards" : {
        "total" : 1,
        "failed" : 0,
        "successful" : 1
      }
    }
  ]
}
###备份索引2
PUT /_snapshot/my_backup/snapshot_2?wait_for_completion=true
{
  "indices": "system*",
  "ignore_unavailable": false,
  "include_global_state": false,
  "metadata": {
    "taken_by": "jack",
    "taken_because": "20200405 backup index 'system-jack-2020.04.15' "
  }
}
---
{
  "snapshot" : {
    "snapshot" : "snapshot_2",
    "uuid" : "i3RclQ1NS8uhRh6usJyWnQ",
    "version_id" : 7010199,
    "version" : "7.1.1",
    "indices" : [
      "system-jack-2020.04.15"
    ],
    "include_global_state" : false,
    "state" : "SUCCESS",
    "start_time" : "2020-04-15T07:45:27.308Z",
    "start_time_in_millis" : 1586936727308,
    "end_time" : "2020-04-15T07:45:27.375Z",
    "end_time_in_millis" : 1586936727375,
    "duration_in_millis" : 67,
    "failures" : [ ],
    "shards" : {
      "total" : 1,
      "failed" : 0,
      "successful" : 1
    }
  }
}
###备份索引3
PUT /_snapshot/my_backup/snapshot_3
{
  "indices": "*",
  "ignore_unavailable": true,    #其设置为true将会导致快照创建期间不存在的索引被忽略
  "include_global_state": false,
  "metadata": {
    "taken_by": "jack",
    "taken_because": "20200405 backup index all "
  }
}
---
{
  "accepted" : true
}
###删除一个索引
DELETE /test-2020.04.15
{
  "acknowledged" : true
}
###恢复一个快照
POST /_snapshot/my_backup/snapshot_1/_restore
---
{
  "acknowledged" : true
}
注：当你的快照复制到别的地方时，在恢复的时候需要先建一个仓库，仓库名随便。快照名从你建的快照文件中获取（index-*开头的文件，包括的索引名称也在里面）
###恢复一个快照中指定的索引
POST /_snapshot/my_backup/snapshot_3/_restore
{
  "indices": "system*",    #普通匹配索引
  "ignore_unavailable": false,
  "include_global_state": false,
  "rename_pattern": "index_(.+)",   #正则匹配索引，
  "rename_replacement": "restored_index_$1"  #匹配到的索引重命名
}
---
{
  "accepted" : true
}
###恢复指定索引并重命名
POST /_snapshot/my_backup/snapshot_3/_restore
{
  "indices": "system*",   #这个值不能为空，与下面匹配索引保持一致即可
  "ignore_unavailable": true,
  "include_global_state": false,
  "rename_pattern": "system(.+)",
  "rename_replacement": "restored_index_$1"
}
注：默认情况下，如果一个或多个参与该操作的索引没有所有可用分片的快照，则整个还原操作将失败。例如，如果某些分片无法快照，则会发生这种情况。但仍可以通过设置partial=true来恢复这些指数。请注意，在这种情况下，只有成功快照的分片将被还原，所有丢失的分片将被重新创建为空。
---
{
  "accepted" : true
}
###
POST /_snapshot/my_backup/snapshot_3/_restore?wait_for_completion=true
{
  "indices": "system*",
  "ignore_unavailable": true,
  "include_global_state": false,
  "rename_pattern": "system(.+)",
  "rename_replacement": "restored_system_$1"
}
---
{
  "snapshot" : {
    "snapshot" : "snapshot_3",
    "indices" : [
      "restored_system_-jack-2020.04.15"
    ],
    "shards" : {
      "total" : 1,
      "failed" : 0,
      "successful" : 1
    }
  }
}
###在还原过程中更改索引设置，可以覆盖大多数索引设置。 -----操作都支持等待完成响应再退出参数wait_for_completion=true
POST /_snapshot/my_backup/snapshot_3/_restore
{
  "indices": "test-2020.04.15",
  "ignore_unavailable": true,
  "index_settings": {
    "index.number_of_replicas": 0   ###表示恢复时不创建副本，不设置此选项默认是按集群节点数创建副本
  },
  "ignore_index_settings": [
    "index.refresh_interval"
  ]
}
---
{
  "accepted" : true
}
###获取当前正在运行的快照及其详细状态信息的列表
GET /_snapshot/_status
###返回给定快照的详细状态信息，即使当前未运行该快照
GET /_snapshot/my_backup/snapshot_1,snapshot_2/_status
###监视快照的还原进度
GET /_snapshot/my_backup/snapshot_1
GET /_snapshot/my_backup/snapshot_1/_status
###停止快照和恢复操作
DELETE /_snapshot/my_backup/snapshot_1

#复制索引并重命名
POST /_reindex
{
  "source": {
    "index": "newdon_2020.11.26"
  },
  "dest": {
    "index": "newdon_jack"
  }
}

#_reindex也支持从一个远处的Elasticsearch的服务器进行reindex，它的语法为：
POST _reindex
{
  "source": {
    "remote": {
      "host": "http://otherhost:9200",
      "username": "user",
      "password": "pass"
    },
    "index": "my-index-000001",
    "query": {
      "match": {
        "test": "data"
      }
    }
  },
  "dest": {
    "index": "my-new-index-000001"
  }
}
#注：elasticsearch7默认是true，表示允许自动创建索引
[root@prometheus prometheus]# curl -s "http://192.168.13.50:9401/_cluster/settings?pretty&include_defaults=true" -H "Content-Type: application/json" | grep auto_create_index
      "auto_create_index" : "true",
#注：阿里云action.auto_create_index默认不允许新建索引,如下所示，表示允许自动创建‘.’开头的索引，不允许自动创建除‘.’开头的所有索引
[ops0799@jumpserver ~]$ curl -su ops0799 "http://es-cn-6ja23a4j8004kwmyl.elasticsearch.aliyuncs.com:9200/_cluster/settings?pretty&include_defaults=true" -H "Content-Type: application/json" | grep auto_create_index
Enter host password for user 'ops0799':
      "auto_create_index" : "+.*,-*",
#更改自动创建索引配置
[ops0799@jumpserver ~]$ curl -XPUT -u ops0799 "http://es-cn-6ja23a4j8004kwmyl.elasticsearch.aliyuncs.com:9200/_cluster/settings?pretty" -H "Content-Type: application/json" -d'
{
    "persistent": {
        "action.auto_create_index": "+.*,+*_ali,-*" 
    }
}'
Enter host password for user 'ops0799':
{
  "acknowledged" : true,
  "persistent" : {
    "action" : {
      "auto_create_index" : "+.*,+*_ali,-*"
    }
  },
  "transient" : { }
}
#查看更改后的配置
[ops0799@jumpserver ~]$ curl -su ops0799 "http://es-cn-6ja23a4j8004kwmyl.elasticsearch.aliyuncs.com:9200/_cluster/settings?pretty&include_defaults=true" -H "Content-Type: application/json" | grep auto_create_index
Enter host password for user 'ops0799':
      "auto_create_index" : "+.*,+*_ali,-*"

```


### 基于sebp/elk镜像部署elk
```
--------部署环境---------
node1: 192.168.13.160
node2: 192.168.13.161
node3: 192.168.13.162
------------------------
-------
node1: 192.168.13.160
-------
[root@localhost elasticsearch]# cat /home/dockerdata/elasticsearch/elasticsearch.yml
############cluster#########
node.name: dlog-01 
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
path.repo: /var/backups
cluster.name: dlog
network.publish_host: 192.168.13.160
discovery.seed_hosts: ["192.168.13.160:9300","192.168.13.161:9300","192.168.13.162:9300"]
cluster.initial_master_nodes: ["192.168.13.161"]
node.master: true
node.data: true
discovery.zen.minimum_master_nodes: 2
discovery.zen.fd.ping_timeout: 1m
discovery.zen.fd.ping_retries: 5
http.cors.enabled: true    
http.cors.allow-origin: "*" 
############################
-------
[root@localhost elasticsearch]# cat /home/dockerdata/elasticsearch/kibana.yml 
server.name: train_kbn01
server.host: "0.0.0.0"
i18n.locale: "zh-CN"
-------
docker run -d --restart=always --name=dlog01 \
-p 9200:9200 \
-p 9300:9300 \
-p 5601:5601 \
-e ES_CONNECT_RETRY=60 \
-e KIBANA_CONNECT_RETRY=60 \
-e LOGSTASH_START=0 \
-e ELASTICSEARCH_START=1 \
-e KIBANA_START=1 \
-e ES_HEAP_SIZE="2g" \
-e TZ="Asia/Shanghai" \
-v /home/dockerdata/elasticsearch/elasticsearch.yml:/etc/elasticsearch/elasticsearch.yml \
-v /home/dockerdata/elasticsearch/kibana.yml:/opt/kibana/config/kibana.yml \
-v /home/dockerdata/elasticsearch/es_data:/var/lib/elasticsearch \
sebp/elk:761 

-------
node2: 192.168.13.161
-------
[root@redis-slave1 /home/dockerdata/elasticsearch]# cat /home/dockerdata/elasticsearch/elasticsearch.yml
##########cluster#########
node.name: dlog-02 
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
path.repo: /var/backups
cluster.name: dlog
network.publish_host: 192.168.13.161
discovery.seed_hosts: ["192.168.13.160:9300","192.168.13.161:9300","192.168.13.162:9300"]
cluster.initial_master_nodes: ["192.168.13.160"]
node.master: true
node.data: true
discovery.zen.minimum_master_nodes: 1
discovery.zen.fd.ping_timeout: 1m
discovery.zen.fd.ping_retries: 5
http.cors.enabled: true    
http.cors.allow-origin: "*" 
##########################
-------
[root@redis-slave1 /home/dockerdata/elasticsearch]# cat /home/dockerdata/elasticsearch/kibana.yml 
server.name: train_kbn01
server.host: "0.0.0.0"
i18n.locale: "zh-CN"
-------
docker run -d --restart=always --name=dlog02 \
-p 9200:9200 \
-p 9300:9300 \
-p 5601:5601 \
-e ES_CONNECT_RETRY=60 \
-e KIBANA_CONNECT_RETRY=60 \
-e LOGSTASH_START=0 \
-e ELASTICSEARCH_START=1 \
-e KIBANA_START=1 \
-e ES_HEAP_SIZE="2g" \
-e TZ="Asia/Shanghai" \
-v /home/dockerdata/elasticsearch/elasticsearch.yml:/etc/elasticsearch/elasticsearch.yml \
-v /home/dockerdata/elasticsearch/kibana.yml:/opt/kibana/config/kibana.yml \
-v /home/dockerdata/elasticsearch/es_data:/var/lib/elasticsearch \
sebp/elk:761 

-------
node3: 192.168.13.162
-------
[root@redis1_s2 elasticsearch]# cat /home/dockerdata/elasticsearch/elasticsearch.yml
###########cluster#########
node.name: dlog-03 
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
path.repo: /var/backups
cluster.name: dlog
network.publish_host: 192.168.13.162
discovery.seed_hosts: ["192.168.13.160:9300","192.168.13.161:9300","192.168.13.162:9300"]
cluster.initial_master_nodes: ["192.168.13.160"]
node.master: true
node.data: true
discovery.zen.minimum_master_nodes: 2
discovery.zen.fd.ping_timeout: 1m
discovery.zen.fd.ping_retries: 5
http.cors.enabled: true    
http.cors.allow-origin: "*" 
###########################
-------
[root@redis1_s2 elasticsearch]# cat /home/dockerdata/elasticsearch/kibana.yml 
server.name: train_kbn02
server.host: "0.0.0.0"
i18n.locale: "zh-CN"
-------
docker run -d --restart=always --name=dlog03 \
-p 9200:9200 \
-p 9300:9300 \
-p 5601:5601 \
-e ES_CONNECT_RETRY=60 \
-e KIBANA_CONNECT_RETRY=60 \
-e LOGSTASH_START=0 \
-e ELASTICSEARCH_START=1 \
-e KIBANA_START=1 \
-e ES_HEAP_SIZE="2g" \
-e TZ="Asia/Shanghai" \
-v /home/dockerdata/elasticsearch/elasticsearch.yml:/etc/elasticsearch/elasticsearch.yml \
-v /home/dockerdata/elasticsearch/kibana.yml:/opt/kibana/config/kibana.yml \
-v /home/dockerdata/elasticsearch/es_data:/var/lib/elasticsearch \
sebp/elk:761 
----------------
#注：elasticsearch.yml配置文件中
cluster.initial_master_nodes：表示节点启动时选择一个节点为master,当集群中的master转移为另一个节点时，则未启动的elasticsearch节点配置文件应将此配置项改为新的master节点地址，否则不会加入已经存在的集群，只会此节点成为一个孤立集群节点。
discovery.seed_hosts: 表示初始集群的各个候选节点地址，后面新加节点也可加入进来
discovery.zen.minimum_master_nodes: 表示最小两个候选节点投票才能选举出一个master，小于两个节点投票则不能选举master(elasticsearch集群将不能正常服务)，公式为(取整)：master数/2+1
----------------
[root@redis1_s2 elasticsearch]# curl -XGET http://192.168.13.161:9200/_cat/nodes?v
ip             heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
192.168.13.161           39          59   1    0.05    0.20     0.43 dilm      *      dlog-02
192.168.13.160           27          85   1    0.07    0.32     0.42 dilm      -      dlog-01
192.168.13.162           30          95   2    0.05    0.15     0.31 dilm      -      dlog-03
----------------
#注：上面master节点为dlog-02,表示后面初始master节点dlog-01转移为dlog-02了，后面的新加入节点cluster.initial_master_nodes应配置为dlog-02
----------------
-----single-----
---
[root@test /data/elk/elasticsearch]# cat elasticsearch.yml 
#elasticsearch user read this file. UID:991
node.name: elk
path.repo: /var/backups
network.host: 0.0.0.0
cluster.initial_master_nodes: ["elk"]
---
[root@test /data/elk]# cat /data/elk/kibana/kibana.yml 
server.name: syslog_kibana
server.host: "0.0.0.0"
i18n.locale: "zh-CN"
-----
docker run -d --restart=always --name=rsyslog  \
-p 9401:9200 \
-p 9402:5601 \
-e ES_CONNECT_RETRY=60 \
-e KIBANA_CONNECT_RETRY=60 \
-e LOGSTASH_START=0 \
-e ELASTICSEARCH_START=1 \
-e KIBANA_START=1 \
-e ES_HEAP_SIZE="2g" \
-e TZ="Asia/Shanghai" \
-v /data/elk/kibana/kibana.yml:/opt/kibana/config/kibana.yml \
-v /data/elk/elasticsearch/elasticsearch.yml:/etc/elasticsearch/elasticsearch.yml \
-v /data/elk/es_data:/var/lib/elasticsearch \
-v /data/elk/es_snapshot:/var/backups \
192.168.13.235:8000/ops/elk:761 
---
[root@test /data/elk]# chown -R 991:991 es_snapshot
----filebeat collect syslog-----
#vim /etc/rsyslog.conf   ----开启udp514端口，设置模板IpTemplate，所以主机日志命名及路径位置，下面引用这些模板，并且发送日志级别:*.*
---
$ModLoad imudp
$UDPServerRun 514
$template IpTemplate,"/var/log/hosts/%FROMHOST-IP%.log" 
*.*  ?IpTemplate 
#### GLOBAL DIRECTIVES ####   ----必须在GLOBAL DIRECTIVES前面开启或增加如上配置
---
[root@test /data/elk]# grep -Ev '#|^$' /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/hosts/192.168.3.1.log
  tags: ["newdon"]
- type: log
  enabled: true
  paths:
    - /usr/local/nginx/logs/access.log
  tags: ["nginx_access_log"]
  json.keys_under_root: true
  json.overwrite_keys: true
- type: log
  enabled: true
  paths:
    - /var/log/hosts/192.168.13.236.log
    - /var/log/hosts/127.0.0.1.log
  tags: ["linux_host"]
  exclude_lines: ["filebeat: 2"]
  output.elasticsearch:
  hosts: ["127.0.0.1:9401"]
  indices:
    - index: "newdon_%{+yyyy.MM.dd}"
      when.contains:
        tags: "newdon"
    - index: "linux_host_%{+yyyy.MM.dd}"
      when.contains:
        tags: "linux_host"
      #username: "jack"
      #password: "123456"
---
注：可用nginx进行htpasswd对es进行认证，反向代理es。在本机上配置iptables防火墙，只允许指定主机无密码访问es9200（一般指nginx反向代理），其它主机全部拒绝。如果是本机nginx代理本机docker，则无须进行只允许本机访问这条策略，因为防火墙只对外部有用，对同一个宿主机上的内部通信则不能控制。但是其它主机全部拒绝依旧配置。
---
[root@test /data/elk/nginx]# cat docker-compose-nginx.yml 
version: '3'
services:
  nginx:
    image: nginx:1.19.1
    container_name: nginx
    hostname: nginx
    restart: always
    #network_mode: host
    volumes:
      - /data/elk/nginx/.login.txt:/etc/nginx/.login.txt
      - /data/elk/nginx/default.conf:/etc/nginx/conf.d/default.conf
    ports:
      - 9200:9200
      - 5601:5601
    deploy:
     resources:
        limits:
           cpus: '2'
           memory: 500M
        reservations:
           cpus: '0.5'
           memory: 100M
---
[root@test /data/elk/nginx]# cat default.conf 
server {
    listen       0.0.0.0:5601;
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
	add_header backendIP $upstream_addr;
	proxy_redirect off;
	proxy_set_header Host $host;
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header X-Real-Port $remote_port;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	proxy_pass http://192.168.13.50:9402;
	auth_basic_user_file /etc/nginx/.login.txt;
	auth_basic	"htpasswd" ;
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
    }
}

server {
    listen       0.0.0.0:9200;
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
	add_header backendIP $upstream_addr;
	proxy_redirect off;
	proxy_set_header Host $host;
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header X-Real-Port $remote_port;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	proxy_pass http://192.168.13.50:9401;
	auth_basic_user_file /etc/nginx/.login.txt;
	auth_basic	"htpasswd" ;
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
    }
}
server_tokens off;
---
sudo /usr/local/bin/docker-compose -f docker-compose-nginx.yml up -d
[root@test /data/elk/elasticsearch]# cat ../nginx/docker_iptables.sh 
iptables -I FORWARD 1 -o docker0 -p tcp --dport 9200 -j DROP
iptables -I FORWARD 2 -o docker0 -p tcp --dport 5601 -j DROP
---
#其它主机配置/etc/rsyslog.conf,增加所有日志并且级别为info的发送到syslog服务器
*.info 	@192.168.13.50
--------------------------------
```


### Elasticsearch问题汇总
问题：
Validation Failed: 1: this action would add [8] total shards, but this cluster currently has [999]/[1000] maximum shards open
原因：
Elasticsearch默认分片数量1000
解决：
可以增加分片数量或者取消副本数，这里以设置为3000为例，此方法比写在配置文件还有效，表示持久化生效：
curl -X PUT localhost:9401/_cluster/settings -H "Content-Type: application/json" -d '{ "persistent": { "cluster.max_shards_per_node": "3000" } }'

```
### 分词器安装
DOWNLOAD URL: https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.6.1/elasticsearch-analysis-ik-7.6.1.zip
docker cp analysis elasticsearch:/opt/elasticsearch/plugins
docker exec -it elasticsearch /bin/sh
cd /opt/elasticsearch/plugins
chown -R elasticsearch:elasticsearch analysis
chmod -R 755 analysis

### 阿里云Elasticsearch和Kibana权限分配：
Aliyun Elasticsearch Product:	
Common User Add Privileges: kibana-system,kibana-admin,homsom_readuser	
Program User Add Privileges: kibana-system,kibana-admin,homsom_commonuser	
Admin User Add Privileges: superuser

Real Privileges Detail:	
homsom-readuser: read,view_index_metadata,monitor
homsom_commonuser: all	
superuser: System Built-in
Match Parttern Index:	*

#### 202104271058
--快照备份恢复
例如：在集群中每个节点挂载了NFS，并且创建了两个快照：
PUT /_snapshot/my_backup/snapshot_1?wait_for_completion=true
{
  "indices": "test01",
  "ignore_unavailable": true,
  "include_global_state": false,
  "metadata": {
    "taken_by": "jack",
    "taken_because": "snapshot on 202104271018' "
  }
}
PUT /_snapshot/my_backup/snapshot_2?wait_for_completion=true
{
  "indices": "test01",
  "ignore_unavailable": true,
  "include_global_state": false,
  "metadata": {
    "taken_by": "jack",
    "taken_because": "snapshot on 202104271019' "
  }
}
在恢复节点上挂载NFS，挂载目录必须对应elasticsearch的备份目录，这里为/var/backups
mkdir /tmpelkdata; chmod -R 777 /tmpelkdata
mount -t nfs 192.168.13.67:/elkdata /tmpelkdata
--新建一个仓库
put /_snapshot/test_backup
{ 
  "type": "fs",
  "settings": { 
    "location": "/var/backups"
  }
}
--恢复快照1，名称和原来一样
post /_snapshot/test_backup/snapshot_1/_restore
{
  "indices": "test*",   
  "ignore_unavailable": true,
  "include_global_state": false,
  "rename_pattern": "test(.+)",
  "rename_replacement": "test$1"
}
-- close index
post test01/_close
--恢复快照2
post /_snapshot/test_backup/snapshot_2/_restore
{
  "indices": "test*",   
  "ignore_unavailable": true,
  "include_global_state": false,
  "rename_pattern": "test(.+)",
  "rename_replacement": "test$1"
}
-- open index 
post test01/_open


#elasticsearch集群增加节点和删除节点
--删除节点
GET http://192.168.13.51:9200/_cat/nodes
192.168.13.52 24 97 2 0.31 0.13 0.09 dilm - testelk-02
192.168.13.51 30 96 8 1.00 1.03 0.89 dilm * testelk-01
192.168.13.53 26 97 6 0.49 0.55 0.53 dilm - testelk-03

1.1 移除指定节点
PUT _cluster/settings
{
  "transient" : {
    "cluster.routing.allocation.exclude._ip" : "192.168.13.52"
  }
}

1.2 检查集群健康状态，如果没有节点relocating，则节点已经被安全剔除，可以考虑关闭节点
GET http://192.168.13.51:9200/_cluster/health?pretty=true
{
  "cluster_name" : "testelk",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
  "active_primary_shards" : 23,
  "active_shards" : 51,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}

1.3 查看节点数据是否已迁移，都是 0 表示数据也已经迁移
GET http://192.168.13.53:9200/_nodes/testelk-02/stats/indices?pretty
      "indices" : {
        "docs" : { 
          "count" : 0,         --这里为0
          "deleted" : 0
        }

上述三步，能保证节点稳妥删除。以下可作辅助查看：
1.4 查看分布数量
GET http://192.168.13.51:9200/_cat/allocation?v
1.5 查看有没有任务挂起，若出现pening_tasks，当pending_tasks的等级>=HIGH时，存在集群无法新建索引的风险
GET http://192.168.13.51:9200/_cluster/pending_tasks?pretty
1.6 若集群中出现UNASSIGNED shards,检查原因，查看是否是分配策略导致无法迁移分片
GET http://192.168.13.51:9200/_cluster/allocation/explain?pretty
1.7 取消节点禁用策略，会使分片自动平均到各个节点
PUT _cluster/settings
{
  "transient": {
    "cluster.routing.allocation.exclude._ip": null
  }
}
--从集群中加入此节点的IP，会使除master leader节点外的节点分片到此ip地址，此参数可不用
PUT _cluster/settings
{
  "transient" : {
    "cluster.routing.allocation.include._ip" : "10.0.0.1"
  }
}
```


### 向现有集群增加节点，生产真实操作
```
[root@node01 ~/tmpelk]# cat elasticsearch.yml 
node.name: testelk-04
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
path.repo: /var/backups
cluster.name: testelk
network.publish_host: 192.168.13.56
discovery.seed_hosts: ["192.168.13.51:9300","192.168.13.52:9300","192.168.13.53:9300","192.168.13.56:9300"]
cluster.initial_master_nodes: ["192.168.13.51"]
node.master: true
node.data: true
discovery.zen.minimum_master_nodes: 2
discovery.zen.fd.ping_timeout: 1m
discovery.zen.fd.ping_retries: 5
http.cors.enabled: true
http.cors.allow-origin: "*"
注：指定的master必须是当前集群的master地址，成功加入集群后，可以更改最小节点数量为3，允许失败一个节点。
虽说不用更改配置文件，其它3个之前的节点discovery.seed_hosts中的主机配置没有配置新添加的节点，在整个集群重启过后
仍然可以成功建立集群，建立把配置文件补充完整，以后排错也方便。
[root@node01 ~/tmpelk]# cat kibana.yml 
server.name: testelk_kibana01
server.host: "0.0.0.0"
i18n.locale: "zh-CN"
[root@node01 ~/tmpelk]# cat docker_run.sh 
docker run -d --restart=always --name=testelk-node \
-p 9200:9200 \
-p 9300:9300 \
-p 5601:5601 \
-e ES_CONNECT_RETRY=60 \
-e KIBANA_CONNECT_RETRY=60 \
-e LOGSTASH_START=0 \
-e ELASTICSEARCH_START=1 \
-e KIBANA_START=1 \
-e ES_HEAP_SIZE="1g" \
-e TZ="Asia/Shanghai" \
-v /root/tmpelk/elasticsearch.yml:/etc/elasticsearch/elasticsearch.yml \
-v /root/tmpelk/kibana.yml:/opt/kibana/config/kibana.yml \
-v /root/tmpelk/es_data:/var/lib/elasticsearch \
-v /tmpelkdata:/var/backups \
192.168.13.235:8000/ops/elk:761
-- 设置最小master为3个--此参数应该写入到配置文件，否则不会持久生效。
curl -XPUT '192.168.13.56:9200/_cluster/settings' -d'
{
  "transient": {
    "discovery.zen.minimum_master_nodes": 3
  }
}


#向现有集群删除节点
--执行删除前
GET http://192.168.13.56:9200/_cluster/health?pretty=true
{
  "cluster_name" : "testelk",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 4,
  "number_of_data_nodes" : 4,
  "active_primary_shards" : 23,
  "active_shards" : 51,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}

GET http://192.168.13.56:9200/_cat/nodes
192.168.13.53 21 95 6 0.24 0.35 0.52 dilm - testelk-03
192.168.13.52 31 97 2 0.16 0.21 0.22 dilm - testelk-02
192.168.13.51 28 95 9 1.03 0.68 0.68 dilm - testelk-01
192.168.13.56 20 96 7 0.40 0.61 0.69 dilm * testelk-04

GET http://192.168.13.51:9200/_cat/allocation?v
shards disk.indices disk.used disk.avail disk.total disk.percent host          ip            node
    12       44.2kb     6.3gb     92.6gb     98.9gb            6 192.168.13.53 192.168.13.53 testelk-03
    13       48.4kb     6.6gb     92.3gb     98.9gb            6 192.168.13.51 192.168.13.51 testelk-01
    13         82kb     6.3gb     92.6gb     98.9gb            6 192.168.13.52 192.168.13.52 testelk-02
    13       86.5kb       7gb     91.8gb     98.9gb            7 192.168.13.56 192.168.13.56 testelk-04

GET http://192.168.13.51:9200/_cluster/pending_tasks?pretty
{
  "tasks" : [ ]
}


--执行删除后
PUT _cluster/settings
{
  "transient" : {
    "cluster.routing.allocation.exclude._ip" : "192.168.13.52"
  }
}
get /_cluster/settings
-------
{
  "persistent" : { },
  "transient" : {
    "cluster" : {
      "routing" : {
        "allocation" : {
          "exclude" : {
            "_ip" : "192.168.13.52"
          }
        }
      }
    }
  }
}
-------
GET http://192.168.13.56:9200/_cluster/health?pretty=true
{
  "cluster_name" : "testelk",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 4,
  "number_of_data_nodes" : 4,
  "active_primary_shards" : 23,
  "active_shards" : 51,
  "relocating_shards" : 0,    --这里为0就说明分片分离成功,等到为0才可进行下一步
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
GET http://192.168.13.56:9200/_cat/nodes
192.168.13.53 26 96  6 0.53 0.36 0.49 dilm - testelk-03
192.168.13.52 11 97  2 0.30 0.21 0.22 dilm - testelk-02
192.168.13.51 26 95 11 0.61 0.66 0.67 dilm - testelk-01
192.168.13.56 12 97  6 0.10 0.39 0.59 dilm * testelk-04
GET http://192.168.13.51:9200/_cat/allocation?v
shards disk.indices disk.used disk.avail disk.total disk.percent host          ip            node
    17       61.7kb     6.6gb     92.3gb     98.9gb            6 192.168.13.51 192.168.13.51 testelk-01
    17        103kb     6.3gb     92.6gb     98.9gb            6 192.168.13.53 192.168.13.53 testelk-03
    17        103kb       7gb     91.8gb     98.9gb            7 192.168.13.56 192.168.13.56 testelk-04
     0           0b     6.3gb     92.6gb     98.9gb            6 192.168.13.52 192.168.13.52 testelk-02
GET http://192.168.13.51:9200/_cluster/pending_tasks?pretty
{
  "tasks" : [ ]
}
GET http://192.168.13.51:9200/_nodes/testelk-02/stats/indices?pretty
--------
      "indices" : {
        "docs" : {
          "count" : 0,   --这里为0说明此节点数据已经分离到其它节点成功，此时可以关闭此节点的服务进行移除了
          "deleted" : 0
        }
--------
注：当节点成功添加和移除，记得要更新配置文件，为现有的节点，另外要仔细检查配置文件，防止最后配置更改错误导致集群起不来。

```


### 一次UNASSIGNED_FAILED事便原因解决：
```
#查看集群状态
GET http://192.168.13.160:9200/_cluster/health?pretty
{
  "cluster_name" : "dlog",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
  "active_primary_shards" : 255,
  "active_shards" : 485,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 31,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 93.9922480620155
}
#查看分片分配情况
http://192.168.13.197:9200/_cat/allocation?v
shards disk.indices disk.used disk.avail disk.total disk.percent host           ip             node
   241       67.4gb   129.5gb    258.6gb    388.1gb           33 192.168.13.160 192.168.13.160 dlog-01
    92       19.2gb    24.5gb    174.3gb    198.8gb           12 192.168.13.197 192.168.13.197 dlog-04
   152       64.8gb    80.1gb    318.6gb    398.8gb           20 192.168.13.161 192.168.13.161 dlog-02
    31                                                                                         UNASSIGNED
#查看unassigned失败原因
GET http://192.168.13.160:9200/_cat/shards?h=index,shard,prirep,state,unassigned.reason
#查看集群节点ID详细信息
GET http://192.168.13.160:9200/_nodes/process?pretty
-----------
{
  "_nodes" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "cluster_name" : "dlog",
  "nodes" : {
    "18E6bO7URyKQUekXZPi_OQ" : {
      "name" : "dlog-04",
      "transport_address" : "192.168.13.197:9300",
      "host" : "192.168.13.197",
      "ip" : "192.168.13.197",
      "version" : "7.6.1",
      "build_flavor" : "default",
      "build_type" : "tar",
      "build_hash" : "aa751e09be0a5072e8570670309b1f12348f023b",
      "roles" : [
        "master",
        "ingest",
        "data",
        "ml"
      ],
      "attributes" : {
        "ml.machine_memory" : "8200798208",
        "ml.max_open_jobs" : "20",
        "xpack.installed" : "true"
      },
      "process" : {
        "refresh_interval_in_millis" : 1000,
        "id" : 130,
        "mlockall" : false
      }
    },
    "w1f1PVrRRWWARu8M6HlPRA" : {
      "name" : "dlog-02",
      "transport_address" : "192.168.13.161:9300",
      "host" : "192.168.13.161",
      "ip" : "192.168.13.161",
      "version" : "7.6.1",
      "build_flavor" : "default",
      "build_type" : "tar",
      "build_hash" : "aa751e09be0a5072e8570670309b1f12348f023b",
      "roles" : [
        "master",
        "ingest",
        "data",
        "ml"
      ],
      "attributes" : {
        "ml.machine_memory" : "16651141120",
        "ml.max_open_jobs" : "20",
        "xpack.installed" : "true"
      },
      "process" : {
        "refresh_interval_in_millis" : 1000,
        "id" : 126,
        "mlockall" : false
      }
    },
    "FKJ5nYktROmj7aLiQ9i5Fw" : {
      "name" : "dlog-01",
      "transport_address" : "192.168.13.160:9300",
      "host" : "192.168.13.160",
      "ip" : "192.168.13.160",
      "version" : "7.6.1",
      "build_flavor" : "default",
      "build_type" : "tar",
      "build_hash" : "aa751e09be0a5072e8570670309b1f12348f023b",
      "roles" : [
        "master",
        "ingest",
        "data",
        "ml"
      ],
      "attributes" : {
        "ml.machine_memory" : "16277364736",
        "xpack.installed" : "true",
        "ml.max_open_jobs" : "20"
      },
      "process" : {
        "refresh_interval_in_millis" : 1000,
        "id" : 136,
        "mlockall" : false
      }
    }
  }
}
-----------

#查看分配详细信息，可以看到分配失败原因
GET http://192.168.13.197:9200/_cluster/allocation/explain?pretty
{
  "index" : "jinjianghotel_db_pro",
  "shard" : 2,
  "primary" : false,
  "current_state" : "unassigned",
  "unassigned_info" : {
    "reason" : "ALLOCATION_FAILED",
    "at" : "2021-04-28T05:39:05.809Z",
    "failed_allocation_attempts" : 5,
    "details" : "failed shard on node [18E6bO7URyKQUekXZPi_OQ]: failed to create index, failure IllegalArgumentException[Unknown analyzer type [ik_max_word] for [default]]",
    "last_allocation_status" : "no_attempt"
  },
  "can_allocate" : "no",
  "allocate_explanation" : "cannot allocate because allocation is not permitted to any of the nodes",
  "node_allocation_decisions" : [
    {
      "node_id" : "18E6bO7URyKQUekXZPi_OQ",
      "node_name" : "dlog-04",
      "transport_address" : "192.168.13.197:9300",
      "node_attributes" : {
        "ml.machine_memory" : "8200798208",
        "ml.max_open_jobs" : "20",
        "xpack.installed" : "true"
      },
      "node_decision" : "no",
      "deciders" : [
        {
          "decider" : "max_retry",
          "decision" : "NO",
          "explanation" : "shard has exceeded the maximum number of retries [5] on failed allocation attempts - manually call [/_cluster/reroute?retry_failed=true] to retry, [unassigned_info[[reason=ALLOCATION_FAILED], at[2021-04-28T05:39:05.809Z], failed_attempts[5], failed_nodes[[18E6bO7URyKQUekXZPi_OQ]], delayed=false, details[failed shard on node [18E6bO7URyKQUekXZPi_OQ]: failed to create index, failure IllegalArgumentException[Unknown analyzer type [ik_max_word] for [default]]], allocation_status[no_attempt]]]"
        }
      ]
    },
    {
      "node_id" : "FKJ5nYktROmj7aLiQ9i5Fw",
      "node_name" : "dlog-01",
      "transport_address" : "192.168.13.160:9300",
      "node_attributes" : {
        "ml.machine_memory" : "16277364736",
        "ml.max_open_jobs" : "20",
        "xpack.installed" : "true"
      },
      "node_decision" : "no",
      "deciders" : [
        {
          "decider" : "max_retry",
          "decision" : "NO",
          "explanation" : "shard has exceeded the maximum number of retries [5] on failed allocation attempts - manually call [/_cluster/reroute?retry_failed=true] to retry, [unassigned_info[[reason=ALLOCATION_FAILED], at[2021-04-28T05:39:05.809Z], failed_attempts[5], failed_nodes[[18E6bO7URyKQUekXZPi_OQ]], delayed=false, details[failed shard on node [18E6bO7URyKQUekXZPi_OQ]: failed to create index, failure IllegalArgumentException[Unknown analyzer type [ik_max_word] for [default]]], allocation_status[no_attempt]]]"
        },
        {
          "decider" : "same_shard",
          "decision" : "NO",
          "explanation" : "the shard cannot be allocated to the same node on which a copy of the shard already exists [[jinjianghotel_db_pro][2], node[FKJ5nYktROmj7aLiQ9i5Fw], [P], s[STARTED], a[id=zFx1U41-TGmF8l0wfH5I4g]]"
        }
      ]
    },
    {
      "node_id" : "w1f1PVrRRWWARu8M6HlPRA",
      "node_name" : "dlog-02",
      "transport_address" : "192.168.13.161:9300",
      "node_attributes" : {
        "ml.machine_memory" : "16651141120",
        "ml.max_open_jobs" : "20",
        "xpack.installed" : "true"
      },
      "node_decision" : "no",
      "deciders" : [
        {
          "decider" : "max_retry",
          "decision" : "NO",
          "explanation" : "shard has exceeded the maximum number of retries [5] on failed allocation attempts - manually call [/_cluster/reroute?retry_failed=true] to retry, [unassigned_info[[reason=ALLOCATION_FAILED], at[2021-04-28T05:39:05.809Z], failed_attempts[5], failed_nodes[[18E6bO7URyKQUekXZPi_OQ]], delayed=false, details[failed shard on node [18E6bO7URyKQUekXZPi_OQ]: failed to create index, failure IllegalArgumentException[Unknown analyzer type [ik_max_word] for [default]]], allocation_status[no_attempt]]]"
        }
      ]
    }
  ]
}
注：UNASSIGNED原因是新添加集群节点未安装analysis-ik分词器插件，所以导致未分配。
解决：
在新节点dlog04安装analysis-ik分词器，并重启节点，节点起来后，此错误仍在，是因为master重试分配分片次数达到5次。所以需要
执行命令来重新分配分片：
POST /_cluster/reroute?retry_failed=true 
注：集群会自动平均分布分片到节点，如果遇到某些节点分布数量多，而某个节点分片数量小，那么你就要看这一个节点是否有什么问题，我这里就是没有安装analysis-ik分词器，
所以导致分布不均。当我安装完analysis-ik分词器后集群自动平均分配分片。
```


### elk6.5.1部署
Author: https://github.com/spujadas/elk-docker
```
sebp/elk:651
[root@TestHotelES /data/hlogelk/elasticsearch]# cat elasticsearch.yml
node.name: hlogelk
cluster.name: hlogelk
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
network.publish_host: 192.168.13.196
path.repo: /var/backups

#run
[root@docker /data/hlogelk]# sysctl -a | grep vm.max_map_count
vm.max_map_count = 262144

docker run -d --restart=always --name=hlogelk  \
-p 9210:9200 \
-p 9310:9300 \
-p 80:5601 \
-e ES_CONNECT_RETRY=90 \
-e KIBANA_CONNECT_RETRY=90 \
-e LOGSTASH_START=0 \
-e ELASTICSEARCH_START=1 \
-e KIBANA_START=1 \
-e ES_HEAP_SIZE="2g" \
-e TZ="Asia/Shanghai" \
-v /data/hlogelk/kibana/kibana.yml:/opt/kibana/config/kibana.yml \
-v /data/hlogelk/elasticsearch/elasticsearch.yml:/etc/elasticsearch/elasticsearch.yml \
-v /data/hlogelk/es_data:/var/lib/elasticsearch \
-v /data/hlogelk/es_snapshot:/var/backups \
192.168.13.235:8000/ops/elk:651



#20210713
--------------------
[root@TestHotelES /data/elk/es_snapshot]# chmod -R 777 /data/elk/es_snapshot/
--创建快照仓库
PUT /_snapshot/my_repo
{
  "type": "fs",
  "settings": {
    "location": "/var/backups"
  }
}
--查看仓库
GET _snapshot
get _snapshot/_all

--查看全部备份快照
get _snapshot/my_repo/_all

--创建所有索引快照
PUT _snapshot/my_repo/testhoteles_20210713104400?wait_for_completion=true
--创建指定索引快照
PUT _snapshot/my_repo/testhoteles_20210713104400?wait_for_completion=true
{
    "indices": "jinjianghotel_db_en_test"
}
--查看指定快照详细信息
get _snapshot/my_repo/testhoteles_20210713104400/_status

--删除快照
DELETE _snapshot/my_backup/snapshot_3


恢复
--从快照恢复所有
POST _snapshot/my_backup/snapshot_1/_restore
POST _snapshot/my_backup/snapshot_1/_restore?wait_for_completion=true

--恢复所有索引（除.开头的系统索引）
POST _snapshot/my_backup/snapshot_1/_restore 
{"indices":"*,-.monitoring*,-.security*,-.kibana*","ignore_unavailable":"true"}

--将指定快照中备份的指定索引恢复到Elasticsearch集群中，并重命名。
如果您需要在不替换现有数据的前提下，恢复旧版本的数据来验证内容，或者进行其他处理，可恢复指定的索引，并重命名该索引。
POST /_snapshot/my_backup/snapshot_1/_restore
{
 "indices": "index_1", 
 "rename_pattern": "index_(.+)", 
 "rename_replacement": "restored_index_$1" 
}

----查看快照恢复信息
--查看快照中，指定索引的恢复状态
GET restored_index_3/_recovery

--查看集群中的所有索引的恢复信息（可能包含跟您的恢复进程无关的其他分片的恢复信息）
GET /_recovery/

----取消快照恢复
--通过DELETE命令删除正在恢复的索引，取消恢复操作。如果restored_index_3正在恢复中，以上删除命令会停止恢复，同时删除所有已经恢复到集群中的数据。
DELETE /restored_index_3
--------------------


#20210812
#复制es索引到本机
1. 列出索引名称
[ops0799@jumpserver ~]$ curl -su ops0799 "http://es-cn-6ja23a4j8004kwmyl.elasticsearch.aliyuncs.com:9200/_cat/indices" -H "Content-Type: application/json" | awk '{print $3}' | grep -Ev 'core|\..*' | tee /home/ops0799/indexNameList.txt
Enter host password for user 'ops0799':
youyouroom_en_db_pro
jinjianghotelroom_db_pro
elonghotelroom_db_pro
jinjianghotelroom_db_en_pro
huazhuroom_db_pro
tepaihotelprice_db_pro
huazhuhotel_db_pro
qianqianhotel_en_db_pro
---------------创建索引并从源索引复制mapping到新索引----------------------
[ops0799@jumpserver ~/es]$ cat es-configIndex.sh 
#!/bin/sh

LogFile='./es.log'
DateTime='date +"%Y-%m-%d %H:%M:%S"'
Suffix='_ali'
Username='test2021'
Password='test'
ESAddress='http://es-cn-6ja23a4j8004kwmyl.elasticsearch.aliyuncs.com:9200'
#IndexList='cat /home/ops0799/indexNameList.txt | head -n 2'
IndexList='cat /home/ops0799/es/indexNameList.txt | grep -E "^[a-z]|^[A-Z]|^[0-9]'

# create index 
for i in `eval ${IndexList}`;do
	echo "`eval ${DateTime}`: start create index ${i}${Suffix} ..." >> ${LogFile}
	curl -s -u ${Username}:${Password} -XPUT "${ESAddress}/${i}${Suffix}" -H 'Content-Type: application/json' -d'{	"settings": {		"number_of_shards": 6,		"number_of_replicas": 1,	 "analysis.analyzer.default.type": "ik_max_word"	}}' | grep 'acknowledged":true' &> /dev/null
	[ $? == 0 ] && echo "`eval ${DateTime}`: create index ${i}${Suffix} successful......."  >> ${LogFile} || echo "`eval ${DateTime}`: create index ${i}${Suffix} failure......."  >> ${LogFile}
done

echo '-------------------' >> ${LogFile}

# config mapping
for i in `eval ${IndexList}`;do
	echo "`eval ${DateTime}`: start config index mapping ${i}${Suffix} ..." >> ${LogFile}
	curl -s -X GET -u ${Username}:${Password} "${ESAddress}/${i}/_mapping" -H 'Content-Type: application/json' | jq '."'${i}'".mappings' | curl -s -u ${Username}:${Password} -XPUT "${ESAddress}/${i}${Suffix}/_mapping" -H 'Content-Type: application/json' -d @- | grep 'acknowledged":true' &> /dev/null
	[ $? == 0 ] && echo "`eval ${DateTime}`: config index mapping ${i}${Suffix} successful......."  >> ${LogFile} || echo "`eval ${DateTime}`: config index mapping ${i}${Suffix} failure......."  >> ${LogFile}
done

echo '-------------------' >> ${LogFile}

echo '' >> ${LogFile}
-----------------创建索引并从源索引复制mapping到新索引，最后复制数据到目标索引------------------------
[ops0799@jumpserver ~/es]$ cat es-moveIndex.sh
#!/bin/sh
#"size": 100,表示每批索引的文档数量，默认是100，可以调整大小
LogFile='./es.log'
DateTime='date +"%Y-%m-%d %H:%M:%S"'
Suffix='_ali'
Username='test2021'
Password='test'
ESAddress='http://es-cn-6ja23a4j8004kwmyl.elasticsearch.aliyuncs.com:9200'
#IndexList='cat /home/ops0799/indexNameList.txt | head -n 2'
IndexList='cat /home/ops0799/es/indexNameList.txt | grep -E "^[a-z]|^[A-Z]|^[0-9]'

# create index 
for i in `eval ${IndexList}`;do
	echo "`eval ${DateTime}`: start create index ${i}${Suffix} ..." >> ${LogFile}
	curl -s -u ${Username}:${Password} -XPUT "${ESAddress}/${i}${Suffix}" -H 'Content-Type: application/json' -d'{	"settings": {		"number_of_shards": 6,		"number_of_replicas": 1,	 "analysis.analyzer.default.type": "ik_max_word"	}}' | grep 'acknowledged":true' &> /dev/null
	[ $? == 0 ] && echo "`eval ${DateTime}`: create index ${i}${Suffix} successful......."  >> ${LogFile} || echo "`eval ${DateTime}`: create index ${i}${Suffix} failure......."  >> ${LogFile}
done

echo '-------------------' >> ${LogFile}

# config mapping
for i in `eval ${IndexList}`;do
	echo "`eval ${DateTime}`: start config index mapping ${i}${Suffix} ..." >> ${LogFile}
	curl -s -X GET -u ${Username}:${Password} "${ESAddress}/${i}/_mapping" -H 'Content-Type: application/json' | jq '."'${i}'".mappings' | curl -s -u ${Username}:${Password} -XPUT "${ESAddress}/${i}${Suffix}/_mapping" -H 'Content-Type: application/json' -d @- | grep 'acknowledged":true' &> /dev/null
	[ $? == 0 ] && echo "`eval ${DateTime}`: config index mapping ${i}${Suffix} successful......."  >> ${LogFile} || echo "`eval ${DateTime}`: config index mapping ${i}${Suffix} failure......."  >> ${LogFile}
done

echo '-------------------' >> ${LogFile}

#reindex 
for i in `eval ${IndexList}`;do
	echo "`eval ${DateTime}`: start rename index ${i} to ${i}${Suffix} ..." >> ${LogFile}
	curl -s -u ${Username}:${Password} -XPOST "${ESAddress}/_reindex" -H 'Content-Type: application/json' -d'{  "source": {    "index": "'${i}'", "size": 100  },  "dest": {    "index": "'${i}${Suffix}'"  }}' | grep '"status":' &> /dev/null
	[ $? != 0 ] && echo "`eval ${DateTime}`: rename index ${i}${Suffix} successful......."  >> ${LogFile} || echo "`eval ${DateTime}`: rename index ${i}${Suffix} failure......."  >> ${LogFile}
done

echo '-------------------' >> ${LogFile}

echo '' >> ${LogFile}
------------------------------------------------------

#创建索引
PUT /test01
{
	"settings": {
		"number_of_shards": 6,
		"number_of_replicas": 1
	}
}
#配置修改索引mapping
PUT /huazhuhotelpricebookinfo_db_pro-backup/_mapping
{
"properties": {
        "acceptedCreditCards": {
          "properties": {
            "cardName": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            },
            "cardType": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            }
          }
        },
        "updateTime": {
          "type": "date"
        }
    }
}
#创建索引并配置mapping
[jack@ubuntu:~]$ cat test01
{
	"settings": {
		"number_of_shards": 6,
		"number_of_replicas": 1
	},
	"mappings" : {
    "properties": {
        "acceptedCreditCards": {
          "properties": {
            "cardName": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            },
            "cardType": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            }
          }
        },
        "updateTime": {
          "type": "date"
        }
    }
	}
}
[jack@ubuntu:~]$ curl -XPUT "http://192.168.13.50:9401/huazhuhotelpricebookinfo_db_pro-backup" -H 'Content-Type: application/json' -d @test01 
{"acknowledged":true,"shards_acknowledged":true,"index":"huazhuhotelpricebookinfo_db_pro-backup"}
#获取mapping
[jack@ubuntu:~]$ curl -s -X GET "http://192.168.13.50:9401/huazhuhotelpricebookinfo_db_pro-backup/_mapping" | jq .
{
  "huazhuhotelpricebookinfo_db_pro-backup": {
    "mappings": {
      "properties": {
        "acceptedCreditCards": {
          "properties": {
            "cardName": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            },
            "cardType": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 256
                }
              }
            }
          }
        },
        "updateTime": {
          "type": "date"
        }
      }
    }
  }
}

#从原索引复制mapping并导入到新索引中
curl -s -X GET "http://192.168.13.50:9401/huazhuhotelpricebookinfo_db_pro-backup/_mapping" -H 'Content-Type: application/json' | jq '."huazhuhotelpricebookinfo_db_pro-backup".mappings' | curl -XPUT "http://192.168.13.50:9401/test-backup/_mapping" -H 'Content-Type: application/json' -d @-


#20210819
#查看索引设置和修改设置
get /skywalking_metrics-apdex-20210808/_settings?pretty=true&include_defaults=true
PUT /*/_settings
{
  "index" : {
    "number_of_replicas" : 0
  }
}
#查看模板和修改设置，order是优先级，数值越大优先级越大
GET /_template/all_default_template
PUT /_template/all_default_template
{
  "index_patterns": "*",
  "order" : 100,
  "settings": {
    "number_of_shards": "4",
    "number_of_replicas": "0"
  }
}

#查看和设置是否允许使用通配符，为true是禁用通配符，为false为启用通配符
get /_cluster/settings?include_defaults=true
PUT /_cluster/settings
{
    "persistent" : {
       "action.destructive_requires_name":true }
}

#关闭索引，设置索引，打开索引
POST /skywalking*/_close
PUT /skywalking*/_settings?preserve_existing=true
{  
"index.refresh_interval" : "60s",  
"index.number_of_shards" : "2",
"index.number_of_replicas" : "0",
"index.translog.durability" : "async",  
"index.translog.flush_threshold_size" : "512mb",  
"index.translog.sync_interval" : "30s"  
}
POST /skywalking*/_open


#20210913 
#阿里云备份到OSS中

GET _snapshot
get _snapshot/aliyun_auto_snapshot/_all

IN_PROGRESS	快照正在执行。
SUCCESS	快照执行结束，且所有shard中的数据都存储成功。
FAILED	快照执行结束，但部分索引中的数据存储不成功。
PARTIAL	部分数据存储成功，但至少有1个shard中的数据没有存储成功。
INCOMPATIBLE	快照与阿里云Elasticsearch实例的版本不兼容。


手动备份与恢复
--创建elasticsearch 访问的access_key_id和secret_access_key，开通OSS服务
--创建仓库
PUT _snapshot/my_backup/
{
    "type": "oss",
    "settings": {
        "endpoint": "http://oss-cn-shanghai-internal.aliyuncs.com",
        "access_key_id": "abc",
        "secret_access_key": "12345",
        "bucket": "dbs-backup-100000-cn-shanghai",
        "compress": true,
        "chunk_size": "500mb",
        "base_path": "snapshot/"
    }
}
GET _snapshot/my_backup
--备份所有索引 
PUT _snapshot/my_backup/snapshot_1?wait_for_completion=true
--备份指定索引
PUT _snapshot/my_backup/snapshot_202109131458?wait_for_completion=true
{
    "indices": "corehotel_db_pro_ali,corehotel_en_db_pro_ali,coreroom_db_pro_ali,coreroom_en_db_pro_ali"
}
--查看所有快照信息
GET _snapshot/my_backup/_all
--查看指定快照信息
GET _snapshot/my_backup/snapshot_3
GET _snapshot/my_backup/snapshot_3/_status
--删除指定的快照。如果该快照正在进行，执行以下命令，系统会中断快照进程并删除仓库中创建到一半的快照。
DELETE _snapshot/my_backup/snapshot_3


--从快照恢复
--将指定快照中备份的所有索引恢复到Elasticsearch集群中。
POST _snapshot/my_backup/snapshot_1/_restore?wait_for_completion=true
--恢复所有索引（除.开头的系统索引）
POST _snapshot/my_backup/snapshot_1/_restore 
{"indices":"*,-.monitoring*,-.security*,-.kibana*","ignore_unavailable":"true"}
--将指定快照中备份的指定索引恢复到Elasticsearch集群中，并重命名。
如果您需要在不替换现有数据的前提下，恢复旧版本的数据来验证内容，或者进行其他处理，可恢复指定的索引，并重命名该索引
POST /_snapshot/my_backup/snapshot_1/_restore
{
 "indices": "index_1", 
 "rename_pattern": "index_(.+)", 
 "rename_replacement": "restored_index_$1" 
}
--查看快照恢复信息
GET restored_index_3/_recovery
--查看集群中的所有索引的恢复信息（可能包含跟您的恢复进程无关的其他分片的恢复信息）。
GET /_recovery/

# 查看恢复状态
GET /_cat/recovery
GET /interdaolvv2_hotelstatic_db_ali_pro/_recovery


--取消快照恢复
DELETE /restored_index_3


##本地ES备份到阿里云OSS
1. 阿里云开通OSS，创建bukect，授权RAM子帐户权限
{
    "Version": "1",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "oss:*",
            "Resource": [
                "acs:oss:*:*:dbs-backup-20159124-cn-shanghai",
                "acs:oss:*:*:dbs-backup-20159124-cn-shanghai/*",
                "acs:oss:*:*:hs-travelreportes-data-backup",
                "acs:oss:*:*:hs-travelreportes-data-backup/*"
            ]
        }
    ]
}

2. 本地ES集群所有节点安装S3插件，并所有节点配置s3.client.default.access_key 和 s3.client.default.secret_key，最后所有节点更改/etc/elasticsearch/elasticsearch.keystore权限使elasticsearch用户有权限访问，否则无法成功创建阿里云OSS仓库，此步非常重要，之前就是卡在这步

`例子`
sh /opt/elasticsearch/bin/elasticsearch-plugin install --batch repository-s3  && 
sh -c /bin/echo -e "HDRZ3WYIX4BFUWZNHF45" | sh /opt/elasticsearch/bin/elasticsearch-keystore add s3.client.default.access_key && 
sh -c /bin/echo -e "SERuAXJdPRkXBXA4eQEC8wbIoULoR05fihVUvems" | sh /opt/elasticsearch/bin/elasticsearch-keystore add s3.client.default.secret_key && 
sh -c /bin/echo -e "https://s3-sh-prod.fin-shine.com/" | sh /opt/elasticsearch/bin/elasticsearch-keystore add s3.client.default.endpoint 


cd /opt/elasticsearch 
bin/elasticsearch-plugin install repository-s3
bin/elasticsearch-keystore add s3.client.default.access_key
bin/elasticsearch-keystore add s3.client.default.secret_key
bin/elasticsearch-keystore list
chown elasticsearch.elasticsearch /etc/elasticsearch/elasticsearch.keystore

3. 创建仓库
PUT _snapshot/backup/
{
    "type": "s3",
    "settings": {
        "endpoint": "https://oss-cn-shanghai.aliyuncs.com",
        "bucket": "hs-travelreportes-data-backup",
        "base_path": "snapshot/"
    }
}

4. 对所有索引进行快照
PUT _snapshot/backup/snapshot_202208161027?wait_for_completion=true

output:
--------
{
  "snapshots" : [
    {
      "snapshot" : "snapshot_202208161026",
      "uuid" : "N4ePUbH0RSetRBm6dDdzZA",
      "version_id" : 7060199,
      "version" : "7.6.1",
      "indices" : [
        "traindepartmentmonthsummary_db"
      ],
      "include_global_state" : true,
      "state" : "SUCCESS",
      "start_time" : "2022-08-16T02:26:19.733Z",
      "start_time_in_millis" : 1660616779733,
      "end_time" : "2022-08-16T02:26:20.933Z",
      "end_time_in_millis" : 1660616780933,
      "duration_in_millis" : 1200,
      "failures" : [ ],
      "shards" : {
        "total" : 5,
        "failed" : 0,
        "successful" : 5
      }
    },
    {
      "snapshot" : "snapshot_202208161027",
      "uuid" : "TRBccmNHRcukeTXv5Lnq9Q",
      "version_id" : 7060199,
      "version" : "7.6.1",
      "indices" : [
        "carorder_db",
        "flightbumonthsummary_db",
        "trainorder_db",
        "traincompanymonthsummary_db",
        "hoteldepartmentmonthsummary_db",
        "ibelog",
        "domesticflightrefund_db",
        "flightcompanymonthsummary_db",
        "flightdepartmentmonthsummary_db",
        "domesticflightticket_db",
        "trainbumonthsummary_db",
        "internationalflightorder_db",
        "hotelcostcentermonthsummary_db",
        ".reporting-2021.04.25",
        "internationalflightrefund_db",
        "intlflightsegment_db",
        "domesticflightsegment_db",
        "internationalflightticket_db",
        "hotelsalesorder_db",
        "carcostcentermonthsummary_db",
        "travellocation_db",
        "hotelcompanymonthsummary_db",
        ".reporting-2021.03.21",
        "cardepartmentmonthsummary_db",
        "hotelbusinesstravelgeneralintroduction_db",
        "carbumonthsummary_db",
        "domesticflightorder_db",
        "traincostcentermonthsummary_db",
        "traindepartmentmonthsummary_db",
        "hotelbumonthsummary_db",
        ".apm-agent-configuration",
        "businesstravelgeneralintroduction_db",
        ".kibana_task_manager_1",
        ".reporting-2021.04.18",
        "flightcostcentermonthsummary_db",
        "carcompanymonthsummary_db",
        ".kibana_1"
      ],
      "include_global_state" : true,
      "state" : "IN_PROGRESS",								###此行表示快照还在进行中，等状态为success后则快照创建完成
      "start_time" : "2022-08-16T02:27:02.153Z",
      "start_time_in_millis" : 1660616822153,
      "end_time" : "1970-01-01T00:00:00.000Z",
      "end_time_in_millis" : 0,
      "duration_in_millis" : -1660616822153,
      "failures" : [ ],
      "shards" : {
        "total" : 0,
        "failed" : 0,
        "successful" : 0
      }
    }
  ]
}
```

```
----自动化备份脚本----
[root@prometheus shell]# cat es-travelreportes-backup.sh 
#!/bin/sh

ES_ADDRESS='http://192.168.13.160:9200'
ES_REPO_NAME='/_snapshot/backup'
ES_SNAPSHOT_NAME="snapshot_`date +'%Y%m%d%H%M%S'`"
DATETIME="date +'%Y-%m-%d_%H-%M-%S'"
LOG_FILE="./eslog.txt"


Log(){
	echo "`eval ${DATETIME}`: $1" >> ${LOG_FILE}
}

GetRepo(){
	esRepoType=`curl -s -X GET "${ES_ADDRESS}${ES_REPO_NAME}" | jq .backup.type`
	if [ -n "${esRepoType}" ];then
		echo 1
	else
		echo 0
	fi
}

Snapshot(){
	sum=0
	count=1800
	# snapshot
	Log "start snapshot ${ES_SNAPSHOT_NAME}..."
	curl -s -X PUT "${ES_ADDRESS}${ES_REPO_NAME}/${ES_SNAPSHOT_NAME}?wait_for_completion=true" >& /dev/null

	# get snapshot state
	while [ ${sum} -lt ${count} ];do
		snapshotState=`curl -s -XGET "${ES_ADDRESS}${ES_REPO_NAME}/${ES_SNAPSHOT_NAME}" | jq .snapshots[].state`
		if [ ${snapshotState} == '"SUCCESS"' ];then
			Log "snapshot ${ES_SNAPSHOT_NAME} success!"
			return 0
		fi
		let sum+=1
		sleep 1
	done
	
	if [ ${sum} -eq ${count} ];then
		Log "snapshot ${ES_SNAPSHOT_NAME} failure!"
		exit 10
	fi
}

DeleteSnapshot(){
	# reserve snapshot number
	reserveNumber=7
	snapshotNameList=(`curl -s -XGET "${ES_ADDRESS}${ES_REPO_NAME}/_all" | jq .snapshots[].snapshot | sort -n`)
	snapshotNumber=`echo ${#snapshotNameList[*]}`
	if [ ${snapshotNumber} -gt ${reserveNumber} ];then
		let i=${snapshotNumber}-${reserveNumber}-1
		for j in `seq 0 $i`;do
			formatSnapshotName=`echo ${snapshotNameList[$j]} | tr -dc 'a-zA-Z0-9_'`
			Log "start delete ${formatSnapshotName}..."
			curl -s -X DELETE "${ES_ADDRESS}${ES_REPO_NAME}/${formatSnapshotName}" >& /dev/null
			curl -s -XGET "${ES_ADDRESS}${ES_REPO_NAME}/_all" | jq .snapshots[].snapshot | grep ${formatSnapshotName} && Log "delete ${formatSnapshotName} failure" || Log "delete ${formatSnapshotName} success"
		done
	fi
}

echo ' ' >> ${LOG_FILE}
if [ `GetRepo` == 1 ];then
	Snapshot
	DeleteSnapshot
else
	Log "repo not exists, snapshot failure!"
	exit 10
fi
-----------------------
```


#问题汇总：
1. skywalking无法查看追踪信息，经过查看日志skywalking-oap-server.log得出原因，日志如下：
2022-03-10 20:31:22,979 - org.apache.skywalking.oap.server.library.client.elasticsearch.ElasticSearchClient - 575 [I/O dispatcher 6] WARN  [] - Bulk [684979] executed with failures:[failure 
[0]: index [skywalking_segment-20220310], type [_doc], id [5ebadf0d1695409f9c9bbac832ac5965.61.16469154792759280], message [ElasticsearchException[Elasticsearch exception [type=validation_exdation Failed: 1: this action would add [5] total shards, but this cluster currently has [998]/[1000] maximum shards open;]]]
注：经过日志得出skywalking写入ES数据分片达到最大数1000，无法再写入数据，需要手动调整分布设置即可，表示临时生效，操作如下：
curl -XPUT localhost:9200/_cluster/settings -H 'Content-type: application/json' --data-binary $'{"transient":{"cluster.max_shards_per_node":2000}}'	#临时的

2. 持久化配置
[root@docker03 /data/elasticsearch]# cat elasticsearch.yml 
node.name: skywalking
path.repo: /var/backups
network.host: 0.0.0.0
cluster.initial_master_nodes: ["skywalking"]
cluster.max_shards_per_node: 2000


3. kibana连接elasticsearch超时问题
[root@opsaudit elasticsearch]# cat ../kibana/kibana.yml
server.name: rsyslog_kibana
server.host: "0.0.0.0"
i18n.locale: "zh-CN"
elasticsearch.requestTimeout: 120000	#配置为120s超时



### elasticsearch 6.4.0 docker部署
```
[root@BuildImage /data/elk640]# cat es01/elasticsearch.yml es02/elasticsearch.yml es03/elasticsearch.yml 
cluster.name: blog
node.name: blog01
path.repo: /var/backups
network.host: 0.0.0.0
#network.publish_host: 192.168.13.214
http.port: 9200
transport.tcp.port: 9300
discovery.zen.ping.unicast.hosts: ["192.168.13.214:9321","192.168.13.214:9322","192.168.13.214:9323"]
node.master: true
node.data: true
----
cluster.name: blog
node.name: blog02
path.repo: /var/backups
network.host: 0.0.0.0
#network.publish_host: 192.168.13.214
http.port: 9200
transport.tcp.port: 9300
discovery.zen.ping.unicast.hosts: ["192.168.13.214:9321","192.168.13.214:9322","192.168.13.214:9323"]
node.master: true
node.data: true
----
cluster.name: blog
node.name: blog03
path.repo: /var/backups
network.host: 0.0.0.0
#network.publish_host: 192.168.13.214
http.port: 9200
transport.tcp.port: 9300
discovery.zen.ping.unicast.hosts: ["192.168.13.214:9321","192.168.13.214:9322","192.168.13.214:9323"]
node.master: true
node.data: true
----
[root@BuildImage /data/elk640]# cat docker01.sh docker02.sh docker03.sh 
docker run -d --restart=always --name=blog-test01  \
-p 9221:9200 \
-p 9321:9300 \
-p 5621:5601 \
-e ES_CONNECT_RETRY=300 \
-e KIBANA_CONNECT_RETRY=300 \
-e LOGSTASH_START=0 \
-e ELASTICSEARCH_START=1 \
-e KIBANA_START=1 \
-e ES_HEAP_SIZE="1g" \
-e TZ="Asia/Shanghai" \
-v /data/elk640/es01/elasticsearch.yml:/etc/elasticsearch/elasticsearch.yml \
-v /data/elk640/es01/es_data:/var/lib/elasticsearch \
harborrepo.hs.com/ops/elk:640
----
docker run -d --restart=always --name=blog-test02  \
-p 9222:9200 \
-p 9322:9300 \
-p 5622:5601 \
-e ES_CONNECT_RETRY=300 \
-e KIBANA_CONNECT_RETRY=300 \
-e LOGSTASH_START=0 \
-e ELASTICSEARCH_START=1 \
-e KIBANA_START=1 \
-e ES_HEAP_SIZE="1g" \
-e TZ="Asia/Shanghai" \
-v /data/elk640/es02/elasticsearch.yml:/etc/elasticsearch/elasticsearch.yml \
-v /data/elk640/es02/es_data:/var/lib/elasticsearch \
harborrepo.hs.com/ops/elk:640
----
docker run -d --restart=always --name=blog-test03  \
-p 9223:9200 \
-p 9323:9300 \
-p 5623:5601 \
-e ES_CONNECT_RETRY=300 \
-e KIBANA_CONNECT_RETRY=300 \
-e LOGSTASH_START=0 \
-e ELASTICSEARCH_START=1 \
-e KIBANA_START=1 \
-e ES_HEAP_SIZE="1g" \
-e TZ="Asia/Shanghai" \
-v /data/elk640/es03/elasticsearch.yml:/etc/elasticsearch/elasticsearch.yml \
-v /data/elk640/es03/es_data:/var/lib/elasticsearch \
harborrepo.hs.com/ops/elk:640
----
```





### 手动部署elsaticsearch 7.6.2，带x-pack认证

```
root@ansible:~# ansible '~172.168.2.1[789]' -m copy -a 'src=/download/elasticsearch-7.6.2-linux-x86_64.tar.gz dest=/download/'
root@ansible:~# ansible '~172.168.2.1[789]' -m copy -a 'src=/download/kibana-7.6.2-linux-x86_64.tar.gz dest=/download/'

##单节点es762 on x-pack
1. 安装es
[root@node01 local]# tar xf /download/elasticsearch-7.6.2-linux-x86_64.tar.gz -C /usr/local/
[root@node01 local]# ln -sv elasticsearch-7.6.2/ elasticsearch
[root@node01 local]# cd /usr/local/elasticsearch
[root@node01 elasticsearch]# ls
bin  config  jdk  lib  LICENSE.txt  logs  modules  NOTICE.txt  plugins  README.asciidoc
[root@node01 elasticsearch]# vim config/elasticsearch.yml
------------------
cluster.name: blog-search
node.name: blog-search-node01
path.data: /data/elasticsearch7/data
path.logs: /data/elasticsearch7/log
path.repo: /data/elasticsearch7/backups
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
xpack.security.enabled: true # 这条配置表示开启xpack认证机制
xpack.security.transport.ssl.enabled: true  #这条如果不配，es将起不来
cluster.initial_master_nodes: ["172.168.2.17"]
------------------
[root@node01 config]# mkdir -p /data/elasticsearch7/data /data/elasticsearch7/log /data/elasticsearch7/backups
[root@node01 elasticsearch]# groupadd -r elasticsearch && useradd -r -M -s /sbin/nologin -g elasticsearch elasticsearch
[root@node01 elasticsearch]# chown -R elasticsearch.elasticsearch /usr/local/elasticsearch-7.6.2/
[root@node01 elasticsearch]# chown -R elasticsearch.elasticsearch /data/elasticsearch7/
[root@node01 elasticsearch]# cat /etc/security/limits.d/99-ansible.conf
*             soft    core            unlimited
*             hard    core            unlimited
*             soft    nproc           1000000
*             hard    nproc           1000000
*             soft    nofile          1000000
*             hard    nofile          1000000
*             soft    memlock         unlimited
*             hard    memlock         unlimited
*             soft    msgqueue        8192000
*             hard    msgqueue        8192000
root          soft    nproc             unlimited
root          hard    nproc             unlimited
[root@node01 elasticsearch]# cat /etc/sysctl.d/99-sysctl.conf
net.ipv4.ip_local_port_range=10001 65000
net.ipv4.ip_forward=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_tw_recycle=0
net.ipv4.tcp_keepalive_time=1200
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets=5000
net.ipv6.conf.all.disable_ipv6=1
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
vm.max_map_count=262144
[root@node01 elasticsearch]# cat /usr/lib/systemd/system/elasticsearch.service
[Unit]
Description=https://elastic.co
After=network-online.target

[Service]
User=elasticsearch
Group=elasticsearch
Type=simple
ExecStart=/usr/local/elasticsearch/bin/elasticsearch
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
----------
[root@node01 elasticsearch]# systemctl start elasticsearch.service
[root@node01 elasticsearch]# chown elasticsearch:elasticsearch  config/elasticsearch.keystore
[root@node01 elasticsearch]# systemctl restart elasticsearch.service
[root@node01 elasticsearch]# systemctl status elasticsearch.service



2. 为内置账号添加密码
ES中内置了几个管理其他集成组件的账号即：apm_system, beats_system, elastic, kibana, logstash_system, remote_monitoring_user，使用之前，首先需要添加一下密码
[root@node01 elasticsearch]# /usr/local/elasticsearch/bin/elasticsearch-setup-passwords --help
auto - Uses randomly generated passwords
interactive - Uses passwords entered by a use

[root@node01 elasticsearch]# /usr/local/elasticsearch/bin/elasticsearch-setup-passwords interactive
Initiating the setup of passwords for reserved users elastic,apm_system,kibana,logstash_system,beats_system,remote_monitoring_user.
You will be prompted to enter passwords as the process progresses.
Please confirm that you would like to continue [y/N]y
Enter password for [elastic]:			#homsom
Reenter password for [elastic]:
Enter password for [apm_system]:
Reenter password for [apm_system]:
Enter password for [kibana]:
Reenter password for [kibana]:
Enter password for [logstash_system]:
Reenter password for [logstash_system]:
Enter password for [beats_system]:
Reenter password for [beats_system]:
Enter password for [remote_monitoring_user]:
Reenter password for [remote_monitoring_user]:
Changed password for user [apm_system]
Changed password for user [kibana]
Changed password for user [logstash_system]
Changed password for user [beats_system]
Changed password for user [remote_monitoring_user]
Changed password for user [elastic]		#只能此用户登录kibana，此用户是admin
---访问测试
[root@node01 elasticsearch]# curl 172.168.2.17:9200
{"error":{"root_cause":[{"type":"security_exception","reason":"missing authentication credentials for REST request [/]","header":{"WWW-Authenticate":"Basic realm=\"security\" charset=\"UTF-8\""}}],"type":"security_exception","reason":"missing authentication credentials for REST request [/]","header":{"WWW-Authenticate":"Basic realm=\"security\" charset=\"UTF-8\""}},"status":401}[root@node01 elasticsearch]# ^C
[root@node01 elasticsearch]# curl -u elastic 172.168.2.17:9200
Enter host password for user 'elastic':
{
  "name" : "blog-search-node01",
  "cluster_name" : "blog-search",
  "cluster_uuid" : "NiQXNxVBQBGaytaZJ5TRUg",
  "version" : {
    "number" : "7.6.2",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "ef48eb35cf30adf4db14086e8aabd07ef6fb113f",
    "build_date" : "2020-03-26T06:34:37.794943Z",
    "build_snapshot" : false,
    "lucene_version" : "8.4.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}

3. 配置kibana连接
[root@node01 local]# tar xf /download/kibana-7.6.2-linux-x86_64.tar.gz -C /usr/local/
[root@node01 local]# ln -sv /usr/local/kibana-7.6.2-linux-x86_64/ /usr/local/kibana
[root@node01 kibana]# chown -R elasticsearch.elasticsearch /usr/local/kibana-7.6.2-linux-x86_64/
---------开启了安全认证之后，kibana连接es以及访问es都需要认证。变更kibana的配置，一共有两种方法，一种明文的，一种密文的。
----明文配置
server.port: 5601
server.host: "0.0.0.0"
server.name: "blog-search-node01"
elasticsearch.hosts: ["http://172.168.2.17:9200"]
kibana.index: ".kibana"
i18n.locale: "zh-CN"
elasticsearch.username: "kibana"
elasticsearch.password: "homsom"
xpack.reporting.encryptionKey: "sSpUE8whw1eMnk2ISYjQeu4nKsXslDjz"		#如果不添加这条配置，将会报错
xpack.security.encryptionKey: "yZr7lNijpHFb310qaEY5cp7MjVoyXw0C"	#如果不配置这条，将会报错
[root@node01 kibana]# cat /usr/lib/systemd/system/kibana.service
[Unit]
Description=https://elastic.co
After=network-online.target

[Service]
User=elasticsearch
Group=elasticsearch
Type=simple
ExecStart=/usr/local/kibana/bin/kibana
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
---
[root@node01 kibana]# systemctl start kibana

----密文配置
[root@node01 kibana]# sudo -u elasticsearch /usr/local/kibana/bin/kibana-keystore --allow-root create
Created Kibana keystore in /usr/local/kibana-7.6.2-linux-x86_64/data/kibana.keystore
[root@node01 kibana]# sudo -u elasticsearch /usr/local/kibana/bin/kibana-keystore --allow-root add elasticsearch.username
Enter value for elasticsearch.username: ******		#kibana
[root@node01 kibana]# sudo -u elasticsearch /usr/local/kibana/bin/kibana-keystore --allow-root add elasticsearch.password
Enter value for elasticsearch.password: ******		#homsom
[root@node01 kibana]# cat config/kibana.yml
server.port: 5601
server.host: "0.0.0.0"
server.name: "blog-search-node01"
elasticsearch.hosts: ["http://172.168.2.17:9200"]
kibana.index: ".kibana"
i18n.locale: "zh-CN"
xpack.reporting.encryptionKey: "sSpUE8whw1eMnk2ISYjQeu4nKsXslDjz"               #如果不添加这条配置，将会报错
xpack.security.encryptionKey: "yZr7lNijpHFb310qaEY5cp7MjVoyXw0C"        #如果不配置这条，将会报错
[root@node01 kibana]# systemctl start kibana






########集群配置
注：前提其它节点跟node01一样安装好elasticsearch、kibana并创建好相关目录及权限 
[root@node02 config]# mkdir -p /data/elasticsearch7/data /data/elasticsearch7/log /data/elasticsearch7/backups
[root@node02 config]# chown -R elasticsearch.elasticsearch /data/elasticsearch7/
[root@node03 config]# mkdir -p /data/elasticsearch7/data /data/elasticsearch7/log /data/elasticsearch7/backups
[root@node03 config]# chown -R elasticsearch.elasticsearch /data/elasticsearch7/
[root@node01 config]# scp /usr/lib/systemd/system/elasticsearch.service /usr/lib/systemd/system/kibana.service root@172.168.2.18:/usr/lib/systemd/system/
[root@node01 config]# scp /usr/lib/systemd/system/elasticsearch.service /usr/lib/systemd/system/kibana.service root@172.168.2.19:/usr/lib/systemd/system/


1. 证书
----在其中一个node节点执行即可，生成完证书传到集群其他节点即可，两条命令均一路回车即可，不需要给秘钥再添加密码。
[root@node01 elasticsearch]# sudo -u elasticsearch /usr/local/elasticsearch/bin/elasticsearch-certutil ca
Please enter the desired output file [elastic-stack-ca.p12]:
Enter password for elastic-stack-ca.p12 :
[root@node01 elasticsearch]# sudo -u elasticsearch /usr/local/elasticsearch/bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12
Enter password for CA (elastic-stack-ca.p12) :
Please enter the desired output file [elastic-certificates.p12]:
Enter password for elastic-certificates.p12 :

[root@node01 elasticsearch]# ls
bin  config  elastic-certificates.p12  elastic-stack-ca.p12  jdk  lib  LICENSE.txt  logs  modules  NOTICE.txt  plugins  README.asciidoc
[root@node01 elasticsearch]# mv elastic* config
[root@node01 elasticsearch]# cd config
[root@node01 config]# scp elastic-* root@172.168.2.18:/usr/local/elasticsearch/config/	#复制这两个文件到其它的节点
root@172.168.2.18's password:   
[root@node01 config]# scp elastic-* root@172.168.2.19:/usr/local/elasticsearch/config/
root@172.168.2.19's password:
[root@node01 config]# chown -R elasticsearch.elasticsearch /usr/local/elasticsearch-7.6.2/
[root@node02 config]# chown -R elasticsearch.elasticsearch /usr/local/elasticsearch-7.6.2/
[root@node03 config]# chown -R elasticsearch.elasticsearch /usr/local/elasticsearch-7.6.2/

2. 配置
####node01
[root@node01 config]# ls
elastic-certificates.p12  elasticsearch.keystore  elasticsearch.yml  elasticsearch.yml.bak  elastic-stack-ca.p12  jvm.options  log4j2.properties  role_mapping.yml  roles.yml  users  users_roles
[root@node01 config]# cat elasticsearch.yml
cluster.name: blog-search
node.name: blog-search-node01
path.data: /data/elasticsearch7/data
path.logs: /data/elasticsearch7/log
path.repo: /data/elasticsearch7/backups
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
discovery.seed_hosts: ["172.168.2.17:9300","172.168.2.18:9300","172.168.2.19:9300"]
cluster.initial_master_nodes: ["172.168.2.17:9300","172.168.2.18:9300","172.168.2.19:9300"]
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /usr/local/elasticsearch/config/elastic-certificates.p12#只能在config目录下，否则会失败
xpack.security.transport.ssl.truststore.path: /usr/local/elasticsearch/config/elastic-certificates.p12
http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-headers: Authorization,X-Requested-With,Content-Type,Content-Length

####node02
[root@node02 config]# ls
elastic-certificates.p12  elasticsearch.keystore  elasticsearch.yml  elastic-stack-ca.p12  jvm.options  log4j2.properties  role_mapping.yml  roles.yml  users  users_roles
[root@node02 config]# cat elasticsearch.yml
cluster.name: blog-search
node.name: blog-search-node02
path.data: /data/elasticsearch7/data
path.logs: /data/elasticsearch7/log
path.repo: /data/elasticsearch7/backups
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
discovery.seed_hosts: ["172.168.2.17:9300","172.168.2.18:9300","172.168.2.19:9300"]
cluster.initial_master_nodes: ["172.168.2.17:9300","172.168.2.18:9300","172.168.2.19:9300"]
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /usr/local/elasticsearch/config/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /usr/local/elasticsearch/config/elastic-certificates.p12
http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-headers: Authorization,X-Requested-With,Content-Type,Content-Length

####node03
[root@node03 config]# ls
elastic-certificates.p12  elasticsearch.keystore  elasticsearch.yml  elastic-stack-ca.p12  jvm.options  log4j2.properties  role_mapping.yml  roles.yml  users  users_roles
[root@node03 config]# cat elasticsearch.yml
cluster.name: blog-search
node.name: blog-search-node03
path.data: /data/elasticsearch7/data
path.logs: /data/elasticsearch7/log
path.repo: /data/elasticsearch7/backups
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
discovery.seed_hosts: ["172.168.2.17:9300","172.168.2.18:9300","172.168.2.19:9300"]
cluster.initial_master_nodes: ["172.168.2.17:9300","172.168.2.18:9300","172.168.2.19:9300"]
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /usr/local/elasticsearch/config/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /usr/local/elasticsearch/config/elastic-certificates.p12
http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-headers: Authorization,X-Requested-With,Content-Type,Content-Length

###报错
ElasticsearchException[failed to initialize SSL TrustManager - access to read truststore file [/usr/local/elasticsearch/elastic-certificates.p12] is blocked; SSL resources should be placed in the [/usr/local/elasticsearch/config] directory]; nested: AccessControlException[access denied ("java.io.FilePermission" "/usr/local/elasticsearch/elastic-certificates.p12" "read")];
[root@node03 elasticsearch]# mv elastic-certificates.p12 elastic-stack-ca.p12 /usr/local/elasticsearch/config/


3. 为内置账号添加密码
[root@node03 config]# /usr/local/elasticsearch/bin/elasticsearch-setup-passwords interactive
Initiating the setup of passwords for reserved users elastic,apm_system,kibana,logstash_system,beats_system,remote_monitoring_user.
You will be prompted to enter passwords as the process progresses.
Please confirm that you would like to continue [y/N]y
Enter password for [elastic]:
Reenter password for [elastic]:
Enter password for [apm_system]:
Reenter password for [apm_system]:
Enter password for [kibana]:
Reenter password for [kibana]:
Enter password for [logstash_system]:
Reenter password for [logstash_system]:
Enter password for [beats_system]:
Reenter password for [beats_system]:
Enter password for [remote_monitoring_user]:
Reenter password for [remote_monitoring_user]:
Changed password for user [apm_system]
Changed password for user [kibana]
Changed password for user [logstash_system]
Changed password for user [beats_system]
Changed password for user [remote_monitoring_user]
Changed password for user [elastic]

[root@node03 config]# curl -u elastic:homsom 172.168.2.17:9200
{
  "name" : "blog-search-node01",
  "cluster_name" : "blog-search",
  "cluster_uuid" : "ejFR_3T_QjK4ADhDcscYaQ",
  "version" : {
    "number" : "7.6.2",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "ef48eb35cf30adf4db14086e8aabd07ef6fb113f",
    "build_date" : "2020-03-26T06:34:37.794943Z",
    "build_snapshot" : false,
    "lucene_version" : "8.4.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}

###通过elasticsearch-head查看es
http://192.168.13.50:9900/?auth_user=elastic&auth_password=homsom	#head地址
http://172.168.2.17:9200/		#es地址


4. 配置kibana连接所有es节点
[root@node01 kibana]# cat config/kibana.yml
server.port: 5601
server.host: "0.0.0.0"
server.name: "blog-search-node01"
elasticsearch.hosts: ["http://172.168.2.17:9200", "http://172.168.2.18:9200", "http://172.168.2.19:9200"]	#自动会健康检查es节点，但这些节点必须同属于一个集群
kibana.index: ".kibana"
i18n.locale: "zh-CN"
xpack.reporting.encryptionKey: "sSpUE8whw1eMnk2ISYjQeu4nKsXslDjz"               #如果不添加这条配置，将会报错
xpack.security.encryptionKey: "yZr7lNijpHFb310qaEY5cp7MjVoyXw0C"        #如果不配置这条，将会报错
[root@node01 kibana]# systemctl start kibana

[root@node02 config]# cat kibana.yml
server.port: 5601
server.host: "0.0.0.0"
server.name: "blog-search-node01"
elasticsearch.hosts: ["http://172.168.2.17:9200", "http://172.168.2.18:9200", "http://172.168.2.19:9200"]       #自动会健康检查es节点，但这些节点必须同属于一个集群
kibana.index: ".kibana"
i18n.locale: "zh-CN"
xpack.reporting.encryptionKey: "aapUE8whw1eMnk2ISYjQeu4nKsXslDjz"      #如果不添加这条配置，将会报错，32位字符，可以与上面kibana不一样，但尽量保持一样
xpack.security.encryptionKey: "aar7lNijpHFb310qaEY5cp7MjVoyXw0C"        #如果不配置这条，将会报错
[root@node01 kibana]# systemctl start kibana
```



### 收集k8s日志（filebeat -> kafka -> logstash -> elasticsearch -> kibana）

#### 安装zookeeper
```
[root@kafka download]# curl -OL https://dlcdn.apache.org/zookeeper/zookeeper-3.7.1/apache-zookeeper-3.7.1-bin.tar.gz
[root@kafka download]# tar xf apache-zookeeper-3.7.1-bin.tar.gz -C /usr/local/
[root@kafka download]# ln -sv /usr/local/apache-zookeeper-3.7.1-bin/ /usr/local/zookeeper
[root@kafka conf]# grep -Ev '#|^$' /usr/local/zookeeper/conf/zoo.cfg
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/usr/local/zookeeper/data/
clientPort=2181
---
[root@kafka zookeeper]# /usr/local/zookeeper/bin/zkServer.sh start
[root@kafka zookeeper]# /usr/local/zookeeper/bin/zkServer.sh status
/usr/bin/java
ZooKeeper JMX enabled by default
Using config: /usr/local/zookeeper/bin/../conf/zoo.cfg
Client port found: 2181. Client address: localhost. Client SSL: false.
Mode: standalone
[root@kafka zookeeper]# ss -tnl | grep 2181
LISTEN     0      50        [::]:2181                  [
```

#### 安装kafka
```
[root@kafka download]# curl -OL https://downloads.apache.org/kafka/2.2.2/kafka_2.12-2.2.2.tgz
[root@kafka download]# tar xf kafka_2.12-2.2.2.tgz -C /usr/local/
[root@kafka download]# ln -sv /usr/local/kafka_2.12-2.2.2/ /usr/local/kafka
[root@kafka config]# grep -Ev '#|^$' server.properties
broker.id=0
listeners=PLAINTEXT://:9092
num.network.threads=2
num.io.threads=4
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/usr/local/kafka/kafka-logs
num.partitions=2
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connect=localhost:2181
zookeeper.connection.timeout.ms=6000
group.initial.rebalance.delay.ms=0
[root@kafka kafka]# /usr/local/kafka/bin/kafka-server-start.sh -daemon /usr/local/kafka/config/server.properties

[root@kafka kafka]# ss -tnlp | grep 9092
LISTEN     0      50        [::]:9092                  [::]:*                   users:(("java",pid=4365,fd=106))

---测试kafka
[root@kafka kafka]# bin/kafka-topics.sh --list --bootstrap-server 127.0.0.1:9092
test1
[root@kafka kafka]# bin/kafka-console-producer.sh --broker-list 127.0.0.1:9092 --topic test1
>hello world!
[root@kafka kafka]# bin/kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --topic test1 --from-beginning
hello world!
```

#### logstash安装配置
```
1. 安装openjdk-11，并下载tar包解压到/usr/local即可
2. 配置logstash
[root@elk /usr/local/logstash]# grep -Ev '#|^$' config/logstash.yml
path.config: /usr/local/logstash/pipeline/*.conf
http.host: "0.0.0.0"
[root@elk /usr/local/logstash/pipeline]# cat logstash.conf
input {
    kafka {
    bootstrap_servers => "172.168.2.14:9092"
    topics => ["filebeat"]
    codec => "json"
    }
}
filter {
    date {
    match => [ "timestamp" , "dd/MMM/yyyy:HH:mm:ss Z" ]
    }
}
output {
    if [kubernetes][pod][name] {
    elasticsearch {
      hosts => ["127.0.0.1:9200"]
      user => "elastic"
      password => "homsom"
      index => "%{[kubernetes][pod][name]}-%{+YYYY.MM.dd}"
    }
    }
}
----
[root@elk /usr/local/logstash/pipeline]# /usr/local/logstash/bin/logstash -f logstash.conf
[root@elk /usr/local/logstash/pipeline]# systemctl cat logstash
# /usr/lib/systemd/system/logstash.service
[Unit]
Description=https://elastic.co
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/logstash/bin/logstash -f /usr/local/logstash/pipeline	#运行此目录下配置，更改后需要重启此服务再生效
Restart=on-failure

[Install]
WantedBy=multi-user.target
---
------注：此时如果新增一个配置文件，然后重启服务生效后，则会将符合if [kubernetes][pod][name]的消息也会再写一份到下面索引中，多个配置文件是合并的关系
[root@elk /usr/local/logstash/pipeline]# systemctl start logstash
input {
  tcp {
    type => "tcp"
    port => 6666
    mode => "server"
  }
}

output {
    elasticsearch {
      hosts => ["127.0.0.1:9200"]
      user => "elastic"
      password => "homsom"
      index => "test-%{+YYYY.MM.dd}"
    }
}
----
```

#### filebeat安装
```
--------------------
root@k8s-master01:~# cat filebeat.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: ns-elk
  labels:
    k8s-app: filebeat
data:
  filebeat.yml: |-
    filebeat.inputs:
    - type: container
      paths:
        - '/var/lib/docker/containers/*/*.log'
      processors:
        - add_kubernetes_metadata:
            host: ${NODE_NAME}
            matchers:
            - logs_path:
                logs_path: "/var/lib/docker/containers/"

    # To enable hints based autodiscover, remove `filebeat.inputs` configuration and uncomment this:
    #filebeat.autodiscover:
    #  providers:
    #    - type: kubernetes
    #      node: ${NODE_NAME}
    #      hints.enabled: true
    #      hints.default_config:
    #        type: container
    #        paths:
    #          - /var/log/containers/*${data.kubernetes.container.id}.log
    
    processors:
      - add_cloud_metadata:
      - add_host_metadata:
    
    #https://www.elastic.co/guide/en/beats/filebeat/current/kafka-output.html
    output:
      kafka:
        enabled: true
        hosts: ["172.168.2.14:9092"]
        topic: filebeat
        max_message_bytes: 5242880
        partition.round_robin:
          reachable_only: true
        keep-alive: 120
        #required_acks: 1
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: ns-elk
  labels:
    k8s-app: filebeat
spec:
  selector:
    matchLabels:
      k8s-app: filebeat
  template:
    metadata:
      labels:
        k8s-app: filebeat
    spec:
      serviceAccountName: filebeat
      terminationGracePeriodSeconds: 30
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      hostAliases:
      - ip: "172.168.2.14"
        hostnames:
        - "kafka"
      containers:
      - name: filebeat
        image: docker.elastic.co/beats/filebeat:7.6.2
        args: [
          "-c", "/etc/filebeat.yml",
          "-e",
        ]
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        securityContext:
          runAsUser: 0
          # If using Red Hat OpenShift uncomment this:
          #privileged: true
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: config
          mountPath: /etc/filebeat.yml
          readOnly: true
          subPath: filebeat.yml
        - name: data
          mountPath: /usr/share/filebeat/data
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: config
        configMap:
          defaultMode: 0640
          name: filebeat-config
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      # data folder stores a registry of read status for all files, so we don't send everything again on a Filebeat pod restart
      - name: data
        hostPath:
          # When filebeat runs as non-root user, this directory needs to be writable by group (g+w).
          path: /var/lib/filebeat-data
          type: DirectoryOrCreate
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: filebeat
subjects:
- kind: ServiceAccount
  name: filebeat
  namespace: ns-elk
  roleRef:
  kind: ClusterRole
  name: filebeat
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: filebeat
  namespace: ns-elk
subjects:
  - kind: ServiceAccount
    name: filebeat
    namespace: ns-elk
    roleRef:
    kind: Role
    name: filebeat
    apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: filebeat-kubeadm-config
  namespace: ns-elk
subjects:
  - kind: ServiceAccount
    name: filebeat
    namespace: ns-elk
    roleRef:
    kind: Role
    name: filebeat-kubeadm-config
    apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: filebeat
  labels:
    k8s-app: filebeat
rules:
- apiGroups: [""] # "" indicates the core API group
  resources:
  - namespaces
  - pods
  - nodes
  verbs:
  - get
  - watch
  - list
- apiGroups: ["apps"]
  resources:
    - replicasets
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: filebeat
  # should be the namespace where filebeat is running
  namespace: ns-elk
  labels:
    k8s-app: filebeat
rules:
  - apiGroups:
      - coordination.k8s.io
    resources:
      - leases
    verbs: ["get", "create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: filebeat-kubeadm-config
  namespace: ns-elk
  labels:
    k8s-app: filebeat
rules:
  - apiGroups: [""]
    resources:
      - configmaps
    resourceNames:
      - kubeadm-config
    verbs: ["get"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: filebeat
  namespace: ns-elk
  labels:
    k8s-app: filebeat

# kubectl -n ns-elk apply -f 08-filebeat.yaml
root@k8s-master01:~# vim filebeat.yaml
root@k8s-master01:~# cat filebeat.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: ns-elk
  labels:
    k8s-app: filebeat
data:
  filebeat.yml: |-
    filebeat.inputs:
    - type: container
      paths:
        - '/var/lib/docker/containers/*/*.log'
      processors:
        - add_kubernetes_metadata:
            host: ${NODE_NAME}
            matchers:
            - logs_path:
                logs_path: "/var/lib/docker/containers/"
    processors:
      - add_cloud_metadata:
      - add_host_metadata:

    # https://www.elastic.co/guide/en/beats/filebeat/current/kafka-output.html
    output:
      kafka:
        enabled: true
        hosts: ["172.168.2.14:9092"]
        topic: filebeat
        max_message_bytes: 5242880
        partition.round_robin:
          reachable_only: true
        keep-alive: 120
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: ns-elk
  labels:
    k8s-app: filebeat
spec:
  selector:
    matchLabels:
      k8s-app: filebeat
  template:
    metadata:
      labels:
        k8s-app: filebeat
    spec:
      serviceAccountName: filebeat
      terminationGracePeriodSeconds: 30
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      hostAliases:
      - ip: "172.168.2.14"
        hostnames:
        - "kafka"		#需要添加此主机名，否则filebeat无法解析kafka:9092的地址
      containers:
      - name: filebeat
        image: docker.elastic.co/beats/filebeat:7.6.2
        args: [
          "-c", "/etc/filebeat.yml",
          "-e",
        ]
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        securityContext:
          runAsUser: 0
          # If using Red Hat OpenShift uncomment this:
          #privileged: true
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: config
          mountPath: /etc/filebeat.yml
          readOnly: true
          subPath: filebeat.yml
        - name: data
          mountPath: /usr/share/filebeat/data
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: config
        configMap:
          defaultMode: 0640
          name: filebeat-config
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      # data folder stores a registry of read status for all files, so we don't send everything again on a Filebeat pod restart
      - name: data
        hostPath:
          # When filebeat runs as non-root user, this directory needs to be writable by group (g+w).
          path: /var/lib/filebeat-data
          type: DirectoryOrCreate
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: filebeat
subjects:
- kind: ServiceAccount
  name: filebeat
  namespace: ns-elk
  roleRef:
  kind: ClusterRole
  name: filebeat
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: filebeat
  namespace: ns-elk
subjects:
  - kind: ServiceAccount
    name: filebeat
    namespace: ns-elk
    roleRef:
    kind: Role
    name: filebeat
    apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: filebeat-kubeadm-config
  namespace: ns-elk
subjects:
  - kind: ServiceAccount
    name: filebeat
    namespace: ns-elk
    roleRef:
    kind: Role
    name: filebeat-kubeadm-config
    apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: filebeat
  labels:
    k8s-app: filebeat
rules:
- apiGroups: [""] # "" indicates the core API group
  resources:
  - namespaces
  - pods
  - nodes
  verbs:
  - get
  - watch
  - list
- apiGroups: ["apps"]
  resources:
    - replicasets
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: filebeat
  # should be the namespace where filebeat is running
  namespace: ns-elk
  labels:
    k8s-app: filebeat
rules:
  - apiGroups:
      - coordination.k8s.io
    resources:
      - leases
    verbs: ["get", "create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: filebeat-kubeadm-config
  namespace: ns-elk
  labels:
    k8s-app: filebeat
rules:
  - apiGroups: [""]
    resources:
      - configmaps
    resourceNames:
      - kubeadm-config
    verbs: ["get"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: filebeat
  namespace: ns-elk
  labels:
    k8s-app: filebeat
--------------------
kubectl -n ns-elk apply -f filebeat.yaml
```

### 常见问题汇总
```
-----------------
##创建索引生命周期策略
PUT _ilm/policy/auto_delete_index
{
  "policy": {
    "phases": {
      "delete": {
        "min_age": "1d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}

##配置logstash创建索引的默认分片及引用索引生命周期策略
PUT /_template/logstash
{
  "index_patterns" : [
      "*"
    ],
  "settings": {
    "index": {
        "number_of_shards" : "1",
        "number_of_replicas" : "0",
        "lifecycle.name": "auto_delete_index",
        "lifecycle.rollover_alias": "logstash"
    }
  }
}

##配置生命周期策略每10分钟执行一次
PUT _cluster/settings
{
  "transient": {
    "indices.lifecycle.poll_interval": "10m" 
  }
}

get _ilm/policy/auto_delete_index
get _ilm/status
POST _ilm/start
get /_template/logstash
get /_cluster/settings
-----------------
```




####k8s部署elasticsearch 6.4.0
部署：3节点es集群，经过测试，一主两备，当备节点down掉一个后，es集群不受影响，当主节点down掉后有1分钟左右的时间故障。








</pre>



## elasticsearch7 问题小记

问题：挂起任务"number_of_pending_tasks" : 2
```bash
curl -X GET http://192.168.13.99:9200/_cluster/health?pretty=true
{
  "cluster_name" : "dlog",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
  "active_primary_shards" : 243,
  "active_shards" : 486,
  "relocating_shards" : 2,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 2,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 61,
  "active_shards_percent_as_number" : 100.0
}

curl -X GET http://192.168.13.99:9200/_cat/pending_tasks
1877733 132ms HIGH shard-failed
1877734 131ms HIGH shard-failed
1877735  33ms HIGH shard-failed
1877736  32ms HIGH shard-failed

curl -X GET http://192.168.13.99:9200/_cluster/pending_tasks?pretty=true
{
  "tasks" : [
    {
      "insert_order" : 1872557,
      "priority" : "HIGH",
      "source" : "shard-failed",
      "executing" : true,
      "time_in_queue_millis" : 96,
      "time_in_queue" : "96ms"
    },
    {
      "insert_order" : 1872558,
      "priority" : "HIGH",
      "source" : "shard-failed",
      "executing" : false,
      "time_in_queue_millis" : 95,
      "time_in_queue" : "95ms"
    },
    {
      "insert_order" : 1872559,
      "priority" : "HIGH",
      "source" : "shard-failed",
      "executing" : false,
      "time_in_queue_millis" : 27,
      "time_in_queue" : "27ms"
    },
    {
      "insert_order" : 1872560,
      "priority" : "HIGH",
      "source" : "shard-failed",
      "executing" : false,
      "time_in_queue_millis" : 26,
      "time_in_queue" : "26ms"
    }
  ]
}
```
原因：有个索引ibelog副本分片无法建立
解决：我将该分片副本改为1后，pending任务就没有了


问题：Elasticsearch breakers tripped大于0，解决断路器
curl -X GET http://192.168.13.234:9200/_nodes/stats/breaker?pretty
```bash
        "parent" : {
          "limit_size_in_bytes" : 2958183628,
          "limit_size" : "2.7gb",
          "estimated_size_in_bytes" : 2661691104,
          "estimated_size" : "2.4gb",
          "overhead" : 1.0,
          "tripped" : 77448
        }
```
原因：Elasticsearche内存达到100%使用
解决：扩展内存可使用空间并重启服务






问题：报错如下，阿里云服务大量查询无法连接ES
```
System.Exception: ServerError: 429Type: search_phase_execution_exception Reason: "all shards failed" CausedBy: "Type: es_rejected_execution_exception Reason: "rejected execution of org.elasticsearch.common.util.concurrent.TimedRunnable@3f9a0659 on QueueResizingEsThreadPoolExecutor[name = hotel01/search, queue capacity = 1000, min queue capacity = 1000, max queue capacity = 1000, frame size = 2000, targeted response rate = 1s,task execution EWMA = 422.3micros, adjustment amount = 50, org.elasticsearch.common.util.concurrent.QueueResizingEsThreadPoolExecutor@1706f25f[Running, pool size = 13, active threads = 13, queued tasks = 1000, completed tasks = 1164701926]]" CausedBy: "Type: es_rejected_execution_exception Reason: "rejected execution of org.elasticsearch.common.util.concurrent.TimedRunnable@3f9a0659 on QueueResizingEsThreadPoolExecutor[name =hotel01/search, queue capacity = 1000, min queue capacity = 1000, max queue capacity = 1000, frame size = 2000, targeted response rate = 1s, task execution EWMA = 422.3micros, adjustment amount = 50, org.elasticsearch.common.util.concurrent.QueueResizingEsThreadPoolExecutor@1706f25f[Running, pool size = 13, active threads = 13, queued tasks = 1000, completed tasks = 1164701926]]"""
```

```
# 查看集群健康状态
GET /_cluster/health?pretty

# 查看节点线程池使用信息
GET /_nodes/stats/thread_pool?pretty

-- search线程有大量的rejected
        "search" : {
          "threads" : 13,
          "queue" : 0,
          "active" : 0,
          "rejected" : 16265042,
          "largest" : 13,
          "completed" : 1169058281
        },
-- write线程有很多的rejected	
		"write" : {
          "threads" : 8,
          "queue" : 0,
          "active" : 0,
          "rejected" : 4924,
          "largest" : 8,
          "completed" : 194180403
        }

# 调整search线程数
thread_pool.search.size: 20
thread_pool.search.queue_size: 2000
thread_pool.search.max_queue_size: 3000

# 重启节点服务，使配置生效
```



问题：集群索引量大会影响搜索性能
**在调整refresh_interval时，请注意以下几点：**
* 在进行大量数据导入时，将refresh_interval设置为-1可以加快数据导入速度。这是因为关闭索引刷新可以减少I/O操作和磁盘空间的使用量。一旦数据导入完成，你可以将refresh_interval重新设置为一个正数，以恢复正常的索引刷新操作。
* 调整refresh_interval时要权衡性能和实时性需求。较短的refresh_interval可以提高查询的响应速度，但会增加I/O负载和磁盘空间的使用量。相反，较长的refresh_interval可以减少I/O负载和磁盘空间的使用量，但可能会降低查询的响应速度。
* 在调整refresh_interval之前，建议先监控Elasticsearch集群的性能指标，如CPU使用率、内存使用率、磁盘I/O等。这将帮助你了解集群的负载情况，并更好地调整相关参数以优化性能。
* 除了refresh_interval外，还有其他一些参数可以影响Elasticsearch的性能和响应时间，如index.shard.recovery.concurrent_streams和indices.recovery.max_bytes_per_sec等。合理配置这些参数也可以帮助优化Elasticsearch的性能。
* 总之，了解refresh_interval的工作原理并根据实际需求进行合理设置是优化Elasticsearch性能的重要步骤之一。通过调整refresh_interval和其他相关参数，你可以在实时性和性能之间找到最佳平衡点，以满足你的应用场景需求。


```
# 配置索引模板
PUT _template/custom_index_refresh_interval_template
{
  "index_patterns": ["*"],  // 匹配所有索引
  "order" : 50,
  "settings": {
    "index.refresh_interval": "30s"  // 设置刷新间隔为60秒
  }
}


# 设置索引刷新间隔时间
PUT student/_settings
{
    "index" : {
        "refresh_interval" : "30s"
    }
}


# 清除索引刷新间隔设置
PUT student/_settings
{
    "index" : {
        "refresh_interval" : null
    }
}
```

## index.refresh_interval，默认是10s
```
# 查看所有索引配置
GET /_all/_settings?pretty

# API即时生效，仅针对单个索引
PUT /my_index/_settings
{
  "settings": {
    "index.refresh_interval": "15s"
  }
}

# API即时生效，批量更改所有索引 
PUT /_all/_settings
{
  "settings": {
    "index.refresh_interval": "30s"
  }
}
```

```yaml
# 全局生效，需要重启ES服务，仅针对新创建索引生效
index.refresh_interval: 15s
```


## index.memory.index_buffer_size，主要提高写入效率的问题，
默认是ES堆内存的10%，这里面ES堆内存为16G却1.6G，从 Elasticsearch 5.x 到 Elasticsearch 7.x，该设置已经被弃用并不再使用。替代方案见转录日志（translog）

```
# 查看全部索引配置
GET /_all/_settings?pretty

# API即时生效，仅针对单个索引
PUT /my_index/_settings
{
  "settings": {
    "index.memory.index_buffer_size": "20%"
  }
}

# API即时生效，批量更改所有索引 
PUT /_all/_settings
{
  "settings": {
    "index.memory.index_buffer_size": "20%"
  }
}
```

```yaml
# 全局生效，需要重启ES服务，仅针对新创建索引生效
index.memory.index_buffer_size: 15%
```




## index.memory.index_buffer_size替代方案，主要提高写入效率的问题
索引缓冲区的大小与刷新间隔（refresh_interval）以及转录日志（translog）设置有更直接的关联。

**关键设置：**
* index.translog.durability：控制转录日志的持久性。async 表示异步写入，request 表示每个写入操作都等待同步确认。
	* 对于批量写入：建议使用 async，这样可以提高写入吞吐量。
	* 对于更高的持久性：使用 request。

* index.translog.sync_interval：控制转录日志的刷写频率，默认为 5s。
	* 对于高写入负载，可以考虑将 sync_interval 设置为较短时间（如 1 秒），以更频繁地将数据持久化到磁盘。
	* 对于批量导入数据，可以增加同步间隔，减少磁盘 I/O。

* index.translog.flush_threshold_size：控制当转录日志大小达到一定阈值时，自动刷新到磁盘。
	* 可以根据集群内存和磁盘容量调整此阈值，以平衡性能和持久性。

```
# 高吞吐量的批量写入（如数据导入）：
PUT /my_index/_settings
{
  "settings": {
    "index.refresh_interval": "-1",  // 禁用刷新，直到数据导入完毕
    "index.translog.durability": "async",  // 异步写入提高吞吐量
    "index.translog.sync_interval": "30s",  // 延长同步间隔，减少磁盘 I/O
    "index.translog.flush_threshold_size": "512mb"  // 增加阈值，减少转录日志刷新频率
  }
}

# 需要快速查询的场景（低延迟）
PUT /my_index/_settings
{
  "settings": {
    "index.refresh_interval": "1s",  // 每秒刷新一次，确保快速数据可见
    "index.translog.durability": "request",  // 每次写入操作都同步到磁盘
    "index.translog.sync_interval": "5s",  // 每 5 秒同步一次转录日志
    "index.translog.flush_threshold_size": "256mb"  // 较低阈值，确保快速数据持久化
  }
}
```

## CPU和磁盘繁忙故障排错、原因查找 
```
# 查看繁忙的线程
GET /_nodes/hot_threads?interval=500ms&threads=20
# 查看指定索引慢日志的操作
GET /fuxunhotel_db_pro_ali/slowlog/_settings?pretty
# 查看节点CPU、内存、磁盘状态
GET /_nodes/stats/process?pretty
GET /_nodes/stats/jvm?pretty
GET /_nodes/stats/fs?pretty
# 查看集群健康状态
GET /_cluster/health?pretty
```





# 网络设备日志收集


## elasticsearch-7.17.23

```
[root@opsaudit /usr/local]# cat elasticsearch/config/elasticsearch.yml 
cluster.name: rsyslog
node.name: log01
path.data: /data/rsyslog/data
path.logs: /data/rsyslog/log
path.repo: /data/rsyslog/backups
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
xpack.security.enabled: true # 这条配置表示开启xpack认证机制
xpack.security.transport.ssl.enabled: true  #这条如果不配，es将起不来
cluster.initial_master_nodes: ["192.168.13.198"]
cluster.max_shards_per_node: 3000

[root@opsaudit /usr/local]# systemctl cat elasticsearch
# /usr/lib/systemd/system/elasticsearch.service
[Unit]
Description=https://elastic.co
After=network-online.target

[Service]
User=elasticsearch
Group=elasticsearch
Type=simple
ExecStart=/usr/local/elasticsearch/bin/elasticsearch
Restart=on-failure
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

```



## kibana-7.17.23

```
[root@opsaudit /usr/local]# cat kibana/config/kibana.yml 
server.port: 5601
server.host: "0.0.0.0"
server.name: "rsyslogui"
elasticsearch.hosts: ["http://127.0.0.1:9200"]
kibana.index: ".kibana"
i18n.locale: "zh-CN"
elasticsearch.username: "kibana"
elasticsearch.password: "VtMElqTDraGIuOlI"
xpack.reporting.encryptionKey: "x3oAYMnN43j0OapL5xXDAOxEKV"       # 如果不添加这条配置，将会报错
xpack.security.encryptionKey: "2xwVwyH2j25IVQEfpsvpCXsKwSce"        # 如果不配置这条，将会报错
server.publicBaseUrl: "http://127.0.0.1:5601"
elasticsearch.requestTimeout: 120000

[root@opsaudit /usr/local]# systemctl cat kibana
# /usr/lib/systemd/system/kibana.service
[Unit]
Description=https://elastic.co
After=network-online.target

[Service]
User=elasticsearch
Group=elasticsearch
Type=simple
ExecStart=/usr/local/kibana/bin/kibana
Restart=on-failure
LimitNOFILE=1000000
MemoryLimit=1G
MemoryAccounting=true

[Install]
WantedBy=multi-user.target


# 索引优化，配置副本分片为0
PUT /_template/indx_default_template
{
  "index_patterns": "*",
  "order" : 100,
  "settings": {
    "number_of_shards": 2,
    "number_of_replicas": "0"
  }
}


```




## rsyslog

```
[root@opsaudit /var/log]# grep -Ev '#|^$' /etc/rsyslog-remote.conf
$ModLoad imudp
$UDPServerRun 514
$ModLoad imtcp
$InputTCPServerRun 514
$template RemoteIp,"/var/log/rsyslog-remote/%FROMHOST-IP%.log"
*.*  ?RemoteIp
$WorkDirectory /var/lib/rsyslog-remote
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat


[root@opsaudit /var/log]# mkdir -p /var/lib/rsyslog-remote /var/log/rsyslog-remote
[root@opsaudit /var/log]# chmod 700 /var/lib/rsyslog-remote


[root@opsaudit /var/log]# cat /usr/lib/systemd/system/rsyslog-remote.service
[Unit]
ConditionPathExists=/etc/rsyslog-remote.conf
Description=Remote Syslog Service

[Service]
Type=simple
PIDFile=/var/run/rsyslogd-remote.pid
ExecStart=/usr/sbin/rsyslogd -n -f /etc/rsyslog-remote.conf -i /var/run/rsyslogd-remote.pid
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target

[root@opsaudit /var/log]# systemctl daemon-reload 
[root@opsaudit /var/log]# systemctl enable rsyslog-remote.service
[root@opsaudit /var/log]# systemctl start rsyslog-remote.service 
[root@opsaudit /var/log]# systemctl status rsyslog-remote.service 
● rsyslog-remote.service - Remote Syslog Service
   Loaded: loaded (/usr/lib/systemd/system/rsyslog-remote.service; disabled; vendor preset: disabled)
   Active: active (running) since 三 2024-10-30 14:54:37 CST; 915ms ago
 Main PID: 2640 (rsyslogd)
   CGroup: /system.slice/rsyslog-remote.service
           └─2640 /usr/sbin/rsyslogd -n -f /etc/rsyslog-remote.conf -i /var/run/rsyslogd-remote.pid
[root@opsaudit /var/log]# netstat -anulp | grep 514
udp        0      0 0.0.0.0:514             0.0.0.0:*                           2640/rsyslogd       
udp6       0      0 :::514                  :::*                                2640/rsyslogd    


# 配置日志轮替，需要配置postrotate使rsyslog-remote服务重新读取新文件
[root@opsaudit /var/log/rsyslog-remote]# cat /etc/logrotate.d/homsom_audit.conf
/var/log/rsyslog-remote/*.log{
	daily
	missingok
	rotate 10
	compress
	#delaycompress
	notifempty
	create 0644 root root
	su root root
	dateext
	dateformat -%Y%m%d%H.%s
	olddir /var/log/rsyslog-remote/backup_logs
    postrotate
      /usr/bin/systemctl reload rsyslog-remote > /dev/null 2>/dev/null || true
    endscript
}


# 立即执行轮替
logrotate -vf /etc/logrotate.d/homsom_audit.conf
[root@opsaudit /var/log/rsyslog-remote]# ls backup_logs/
172.168.2.31.log-20240815.gz  172.168.2.35.log-20240815.gz   192.168.102.15.log-20240815.gz  192.168.10.253.log-20240815.gz  192.168.16.251.log-20240815.gz
172.168.2.32.log-20240815.gz  172.168.2.36.log-20240815.gz   192.168.102.1.log-20240815.gz   192.168.102.7.log-20240815.gz   192.168.16.252.log-20240815.gz
172.168.2.33.log-20240815.gz  172.168.2.37.log-20240815.gz   192.168.102.2.log-20240815.gz   192.168.103.10.log-20240815.gz  192.168.16.253.log-20240815.gz
172.168.2.34.log-20240815.gz  192.168.101.1.log-20240815.gz  192.168.10.252.log-20240815.gz  192.168.103.9.log-20240815.gz   192.168.16.254.log-20240815.gz

# 或者编辑/var/lib/logrotate/logrotate.status文件，将需要轮替的文件时间往前调小，如果将要轮替的文件记录删除将不起作用。
# 执行命令即可
/etc/cron.daily/logrotate
```



## filebeat-7.17.23

```bash
#### centos6
#!/bin/bash
#
# filebeat    Start/Stop the filebeat service
#
# chkconfig: - 85 15
# description: Filebeat is a log shipper from Elastic
# processname: filebeat
# config: /usr/local/filebeat/filebeat.yml
# pidfile: /var/run/filebeat.pid

### BEGIN INIT INFO
# Provides:          filebeat
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts and stops the filebeat service
### END INIT INFO

PATH_HOME=/usr/local/filebeat
FILEBEAT_PATH=/usr/local/filebeat/filebeat
CONFIG_FILE=/usr/local/filebeat/filebeat.yml
PID_FILE=/var/run/filebeat.pid
LOG_FILE=/var/log/filebeat.log

start() {
    echo -n "Starting filebeat: "
    if [ -f $PID_FILE ]; then
        echo "filebeat is already running."
        return 1
    fi
    $FILEBEAT_PATH -c $CONFIG_FILE -path.home $PATH_HOME -path.config $PATH_HOME -path.data $PATH_HOME -path.logs $LOG_FILE &> $LOG_FILE &
    echo $! > $PID_FILE
    echo "done."
}

stop() {
    echo -n "Stopping filebeat: "
    if [ ! -f $PID_FILE ]; then
        echo "filebeat is not running."
        return 1
    fi
    kill `cat $PID_FILE`
    rm $PID_FILE
    echo "done."
}

restart() {
    stop
    start
}

status() {
    if [ -f $PID_FILE ]; then
        echo "filebeat is running, PID=`cat $PID_FILE`"
    else
        echo "filebeat is not running."
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
esac

exit 0
```

```bash
# syslog收集网络设备日志
[root@opsaudit /usr/local/filebeat]# grep -Ev '#|^$' filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*
  exclude_files: ['/var/log/rsyslog-remote/*']
  processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~ 
  - add_fields:
      target: host
      fields:
        tags: linux
- type: log
  enabled: true
  paths:
    - /var/log/rsyslog-remote/192.168.101.1.log
  tags: ["sangfor-af"]
  processors:
    - add_fields:
        fields:
          hostIP: 192.168.101.1
- type: log
  enabled: true
  paths:
    - /var/log/rsyslog-remote/192.168.102.15.log
  tags: ["sangfor-ac"]
  processors:
    - add_fields:
        fields:
          hostIP: 192.168.102.15
- type: log
  enabled: true
  paths:
    - /var/log/rsyslog-remote/192.168.102.1.log
  tags: ["sangfor-atrust"]
  processors:
    - add_fields:
        fields:
          hostIP: 192.168.102.1
- type: log
  enabled: true
  paths:
    - /var/log/rsyslog-remote/192.168.103.9.log
  tags: ["huawei-af"]
  processors:
    - add_fields:
        fields:
          hostIP: 192.168.102.9
- type: log
  enabled: true
  paths:
    - /var/log/rsyslog-remote/192.168.103.10.log
  tags: ["huawei-af"]
  processors:
    - add_fields:
        fields:
          hostIP: 192.168.102.10
- type: log
  enabled: true
  paths:
    - /var/log/rsyslog-remote/192.168.102.2.log
  tags: ["switch", "huawei-csw"]
- type: log
  enabled: true
  paths:
    - /var/log/rsyslog-remote/192.168.10.252.log
    - /var/log/rsyslog-remote/192.168.10.253.log
    - /var/log/rsyslog-remote/192.168.16.254.log
  tags: ["switch", "huawei-dsw"]
- type: log
  enabled: true
  paths:
    - /var/log/rsyslog-remote/192.168.16.251.log
    - /var/log/rsyslog-remote/192.168.16.252.log
    - /var/log/rsyslog-remote/192.168.16.253.log
  tags: ["switch", "huawei-asw"]
- type: log
  enabled: true
  paths:
    - /var/log/rsyslog-remote/172.168.2.31.log
    - /var/log/rsyslog-remote/172.168.2.32.log
    - /var/log/rsyslog-remote/172.168.2.33.log
    - /var/log/rsyslog-remote/172.168.2.34.log
    - /var/log/rsyslog-remote/172.168.2.35.log
    - /var/log/rsyslog-remote/172.168.2.36.log
    - /var/log/rsyslog-remote/172.168.2.37.log
  tags: ["switch", "huasan-asw"]
- type: log
  enabled: true
  paths:
    - /var/log/rsyslog-remote/192.168.102.7.log
  tags: ["switch", "cisco-msw"]
processors:
  - drop_fields:
      fields: ["ecs","input","agent"]
      ignore_missing: false
output.elasticsearch:
  hosts: ["172.168.2.199:9200"]
  username: "filebeat"
  password: "pass"
  template:
    name: "ops_template"
    pattern: "*"
  indices:
    - index: "sangfor-af_%{+yyyy.MM.dd}"
      when.contains:
        tags: "sangfor-af"
    - index: "sangfor-ac_%{+yyyy.MM.dd}"
      when.contains:
        tags: "sangfor-ac"
    - index: "sangfor-atrust_%{+yyyy.MM.dd}"
      when.contains:
        tags: "sangfor-atrust"
    - index: "huawei-af_%{+yyyy.MM.dd}"
      when.contains:
        tags: "huawei-af"
    - index: "switch_%{+yyyy.MM.dd}"
      when.contains:
        tags: "switch"
    - index: "hosts-linux_%{+yyyy.MM.dd}"
      when.contains:
        host.tags: "linux"
logging.level: error



[root@opsaudit /usr/local/filebeat]# chown -R root.filebeat /usr/local/filebeat-7.17.23-linux-x86_64/
[root@opsaudit /usr/local/filebeat]# chmod -R 754 /usr/local/filebeat-7.17.23-linux-x86_64/
[root@opsaudit /usr/local/filebeat]# cat /usr/lib/systemd/system/filebeat.service
[Unit]
Description=https://elastic.co
After=network-online.target

[Service]
User=root
Group=filebeat
Type=simple
ExecStart=/usr/local/filebeat/filebeat -c /usr/local/filebeat/filebeat.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target

[root@opsaudit /usr/local/filebeat]# systemctl daemon-reload 
[root@opsaudit /usr/local/filebeat]# systemctl restart filebeat
[root@opsaudit /usr/local/filebeat]# systemctl status filebeat

```



## 收集nginx日志

```
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*
  exclude_files: ['/var/log/rsyslog-remote/*']
  tags: ["linux"]
  processors:
    - add_host_metadata: ~
    - add_cloud_metadata: ~
    - drop_fields:
        fields: ["ecs","input","agent"]
        ignore_missing: false
- type: log
  enabled: true
  paths:
    - /usr/local/nginx/logs/access*log
    - /usr/local/nginx/logs/*/access*log
  json.keys_under_root: true
  processors:
    - rename:
        fields:
          - from: "time"
            to: "nginx_timestamp"
          - from: "remote_addr"
            to: "nginx-remote_addr"
          - from: "referer"
            to: "nginx-referer"
          - from: "host"
            to: "nginx-host"
          - from: "request"
            to: "nginx-request"
          - from: "status"
            to: "nginx-status"
          - from: "bytes"
            to: "nginx-bytes"
          - from: "agent"
            to: "nginx-agent"
          - from: "x_forwarded"
            to: "nginx-x_forwarded"
          - from: "up_addr"
            to: "nginx-up_addr"
          - from: "up_host"
            to: "nginx-up_host"
          - from: "up_resp_time"
            to: "nginx-up_resp_time"
          - from: "request_time"
            to: "nginx-request_time"
        ignore_missing: true
  tags: ["nginx-access"]
- type: log
  enabled: true
  paths:
    - /usr/local/nginx/logs/error*log
    - /usr/local/nginx/logs/*/error*log
  tags: ["nginx-error"]
output.elasticsearch:
  hosts: ["172.168.2.199:9200"]
  username: "filebeat"
  password: "pass"
  indices:
    - index: "hosts-linux_%{+yyyy.MM.dd}"
      when.contains:
        tags: "linux"
    - index: "nginx-access_%{+yyyy.MM.dd}"
      when.contains:
        tags: "nginx-access"
    - index: "nginx-error_%{+yyyy.MM.dd}"
      when.contains:
        tags: "nginx-error"
  template:
    name: "ops_template"
    pattern: "*"
logging.level: error
```



## filebeat收集centos7主机日志

```bash
# 配置索引模板
PUT _template/ops_template
{
  "index_patterns": ["hosts-*","sangfor-*","huawei-*","switch*","filebeat-*","winlogbeat-*","nginx*"],
  "settings": {
    "number_of_shards": 1,  
    "number_of_replicas": 0 
  }
}

# filebeat配置段
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*
  exclude_files: ['/var/log/rsyslog-remote/*']
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - drop_fields:
      fields: ["ecs","input","agent"]
      ignore_missing: false
output.elasticsearch:
  hosts: ["172.168.2.199:9200"]
  username: "filebeat"
  password: "pass"
  indices:
    - index: "hosts-linux_%{+yyyy.MM.dd}"
  template:
    name: "ops_template"
    pattern: "*"
logging.level: error
```



## filebeat收集ubuntu18主机日志

```bash
filebeat.config.modules.path: ${path.config}/modules.d/*.yml
filebeat.inputs:
  - type: journald
    id: everything
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - drop_fields:
      fields: ["ecs","input","agent"]
      ignore_missing: false
output.elasticsearch:
  hosts: ["172.168.2.199:9200"]
  username: "filebeat"
  password: "password"
  indices:
    - index: "hosts-linux_%{+yyyy.MM.dd}"
  template:
    name: "ops_template"
    pattern: "*"
logging.level: error
```

> type: journald是filebeat7.16及以后集成的，可直接使用解析journal的日志





## filebeat收集lvs日志

```bash
[root@lvs02 ~]# cat /usr/local/filebeat/filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*
  exclude_files: ['/var/log/rsyslog-remote/*']
  tags: ["linux"]
- type: log
  enabled: true
  paths:
    - /root/lvs.log
  multiline:
    pattern: '^"\d{4}-\d{2}-\d{2}-\d{2}:\d{2}:\d{2}":\s$'
    negate: true
    match: after
  multiline:
    pattern: '^"\d{4}-\d{2}-\d{2}-\d{2}:\d{2}:\d{2}":\s--------------------\sSTEP\sEND\s--------------------$'
    negate: true
    match: before
  tags: ["lvs"]
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - drop_fields:
      fields: ["ecs","input","agent"]
      ignore_missing: false
output.elasticsearch:
  hosts: ["172.168.2.199:9200"]
  username: "filebeat"
  password: "password"
  indices:
    - index: "hosts-linux_%{+yyyy.MM.dd}"
      when.contains:
        tags: "linux"
    - index: "lvs"
      when.contains:
        tags: "lvs"
  template:
    name: "ops_template"
    pattern: "*"
logging.level: error
```

> **pattern**: 使用正则表达式匹配以 `# Time:` 开头并遵循时间格式的行：
>
> ```
> ^# Time: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}\+\d{2}:\d{2}$
> ```
>
> 这会匹配所有以 `# Time: YYYY-MM-DDTHH:MM:SS.ssssss+ZZ:ZZ` 格式的时间戳开头的行。
>
> **negate: true**: 表示匹配的行不是多行事件的一部分，而是多行事件的开始。
>
> **match: after**: 表示匹配模式后面的行将被追加到前一行。也就是说，所有以时间戳开头的行将被视为新的日志事件的开始，并将它们后面的行与之合并。



## filebeat收集mysql日志

```bash
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*
  exclude_files: ['/var/log/rsyslog-remote/*']
  tags: ["linux"]
- type: log
  enabled: true
  paths:
    - /data/mysql/mysql.err
  tags: ["mysql"]
- type: log
  enabled: true
  paths:
    - /data/mysql/mysql-slow.log
  multiline:
    pattern: '^# Time: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}\+\d{2}:\d{2}$'
    negate: true
    match: after
  tags: ["mysql"]
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - drop_fields:
      fields: ["ecs","input","agent"]
      ignore_missing: false
output.elasticsearch:
  hosts: ["172.168.2.199:9200"]
  username: "filebeat"
  password: "password"
  indices:
   - index: "hosts-linux_%{+yyyy.MM.dd}"
     when.contains:
       tags: "linux"
   - index: "mysql"
     when.contains:
       tags: "mysql"
  template:
    name: "ops_template"
    pattern: "*"
logging.level: error
```



## 交换机配置日志收集命令

```
# 华为日志配置



# 用户模式下手动配置时间
clock timezone SH add 08:00:00
clock datetime 13:57:00 2024-08-15

# 配置模式下自动同步时间配置
clock timezone SH add 08:00:00
ntp-service unicast-server 203.107.6.88	# 执行2次
ntp-service unicast-server 203.107.6.88

# 查看时间
[ASW1]display clock
2024-08-15 15:55:21+08:00
Thursday
Time Zone(SH) : UTC+08:00

# 配置日志
info-center source default channel 2 log level debugging
info-center loghost source Vlanif60
info-center loghost 192.168.13.198 facility local7


# 查看日志配置
[ASW1]display current-configuration | include info-
info-center source default channel 2 log level debugging
info-center loghost source Vlanif60
info-center loghost 192.168.13.198 facility local7




-----------------------

# 华三日志配置

# 配置模式下自动同步时间配置
---- H3C S5048 配置ntp
clock timezone SH add 08:00:00
ntp-service enable  
ntp-service unicast-server 203.107.6.88  
clock protocol ntp
---- H3C S5120-52P-LI 配置ntp
ntp-service unicast-server 203.107.6.88 



# 查看时间
[UA-ASW07]display clock
16:15:28.618 SH Thu 08/15/2024
Time Zone : SH add 08:00:00

# 配置日志
---- H3C S5048 配置
info-center source default loghost level debugging
info-center loghost source Vlan-interface 20
info-center loghost 192.168.13.198 facility local7
-----H3C S5120-52P-LI 配置
info-center source default channel 2 log level debugging
info-center loghost source Vlan-interface 20
info-center loghost 192.168.13.198 facility local7

# 查看日志配置
[UA-ASW07]display current-configuration | include info-
 info-center loghost source Vlan-interface20
 info-center loghost 192.168.13.198
 info-center source default loghost level debugging




-----------------------

# 思科日志配置

# 配置时间同步
ntp source vlan 102
ntp server 203.107.6.88

# 查看时间
DSW4#show clock
15:36:23.909 GMT Thu Aug 15 2024


# 配置日志
logging on
logging console debugging
logging monitor debugging
logging buffered debugging
logging trap debugging
logging facility syslog
logging source-interface Vlan10
logging 192.168.13.198


# 查看日志配置
DSW3(config)#do show run | inclu logg
logging trap debugging
logging facility syslog
logging source-interface Vlan10
logging 192.168.13.198
```



## filebeat for windows安装
[filebeat-7.17.23-windows-x86_64.zip](https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.17.23-windows-x86_64.zip)

```powershell

# 将安装包解压放到以下目录，并使用管理员权限打开powershell
PS C:\Program Files\filebeat> dir


    目录: C:\Program Files\filebeat


Mode                LastWriteTime     Length Name
----                -------------     ------ ----
d----        2024/10/31     17:19            kibana
d----        2024/10/31     17:20            module
d----        2024/10/31     17:20            modules.d
-a---         2024/7/25     21:46         41 .build_hash.txt
-a---         2024/7/25     21:41    3782069 fields.yml
-a---         2024/7/25     21:44   83708928 filebeat.exe
-a---         2024/7/25     21:41     171147 filebeat.reference.yml
-a---         2024/7/25     21:41       8348 filebeat.yml
-a---         2024/7/25     21:46        883 install-service-filebeat.ps1
-a---         2024/7/25     21:41      13675 LICENSE.txt
-a---         2024/7/25     21:41    2262097 NOTICE.txt
-a---         2024/7/25     21:46        816 README.md
-a---         2024/7/25     21:46        250 uninstall-service-filebeat.ps1


# 执行命令安装
PS C:\Program Files\filebeat> .\install-service-filebeat.ps1

Status   Name               DisplayName
------   ----               -----------
Stopped  filebeat           filebeat

# 查看模块
PS C:\Program Files\filebeat> .\filebeat.exe modules list
Enabled:

Disabled:
activemq
apache
auditd
aws
awsfargate
azure
barracuda
bluecoat
cef
checkpoint
cisco
coredns
crowdstrike
cyberark
cyberarkpas
cylance
elasticsearch
envoyproxy
f5
fortinet
gcp
google_workspace
googlecloud
gsuite
haproxy
ibmmq
icinga
iis
imperva
infoblox
iptables
juniper
kafka
kibana
logstash
microsoft
misp
mongodb
mssql
mysql
mysqlenterprise
nats
netflow
netscout
nginx
o365
okta
oracle
osquery
panw
pensando
postgresql
proofpoint
rabbitmq
radware
redis
santa
snort
snyk
sonicwall
sophos
squid
suricata
system
threatintel
tomcat
traefik
zeek
zookeeper
zoom
zscaler

# filebeat配置文件
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - C:\Windows\System32\winevt\Logs\*
  exclude_files: ['C:\Windows\System32\winevt\Logs\rsyslog-remote\*']
        
filebeat.config.modules:
  # Glob pattern for configuration loading
  path: ${path.config}/modules.d/*.yml
  # Set to true to enable config reloading
  reload.enabled: false
  
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - drop_fields:
      fields: ["ecs","input","agent"]
      ignore_missing: false
output.elasticsearch:
  hosts: ["opsaudites.hs.com:9200"]
  username: "filebeat"
  password: "pass"
  indices:
    - index: "hosts-windows_%{+yyyy.MM.dd}"
  template:
    name: "ops_template"
    pattern: "*"
logging.level: error


PS C:\Program Files\filebeat> start-service filebeat
PS C:\Program Files\filebeat> get-service filebeat
PS C:\Program Files\filebeat> stop-service filebeat
```



## winlogbeat安装

[winlogbeat-7.17.23-windows-x86_64.zip](https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-7.17.23-windows-x86_64.zip)

```powershell

PS C:\Program Files\winlogbeat> dir


    目录: C:\Program Files\winlogbeat


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         2024/11/1     10:10                kibana
d-----         2024/11/1     10:10                module
-a----         2024/7/25     15:30             41 .build_hash.txt
-a----         2024/7/25     15:30         380360 fields.yml
-a----         2024/7/25     15:30            901 install-service-winlogbeat.ps1
-a----         2024/7/25     15:30          13675 LICENSE.txt
-a----         2024/7/25     15:30        2262097 NOTICE.txt
-a----         2024/7/25     15:30            839 README.md
-a----         2024/7/25     15:30            254 uninstall-service-winlogbeat.ps1
-a----         2024/7/25     15:30       69578888 winlogbeat.exe
-a----         2024/7/25     15:30          63590 winlogbeat.reference.yml
-a----         2024/11/1     11:04           2389 winlogbeat.yml


# winlogbeat配置
winlogbeat.event_logs:
  - name: Application
    ignore_older: 72h

  - name: System

  - name: Security
    processors:
      - script:
          lang: javascript
          id: security
          file: ${path.home}/module/security/config/winlogbeat-security.js

  - name: Microsoft-Windows-Sysmon/Operational
    processors:
      - script:
          lang: javascript
          id: sysmon
          file: ${path.home}/module/sysmon/config/winlogbeat-sysmon.js

  - name: Windows PowerShell
    event_id: 400, 403, 600, 800
    processors:
      - script:
          lang: javascript
          id: powershell
          file: ${path.home}/module/powershell/config/winlogbeat-powershell.js

  - name: Microsoft-Windows-PowerShell/Operational
    event_id: 4103, 4104, 4105, 4106
    processors:
      - script:
          lang: javascript
          id: powershell
          file: ${path.home}/module/powershell/config/winlogbeat-powershell.js

  - name: ForwardedEvents
    tags: [forwarded]
    processors:
      - script:
          when.equals.winlog.channel: Security
          lang: javascript
          id: security
          file: ${path.home}/module/security/config/winlogbeat-security.js
      - script:
          when.equals.winlog.channel: Microsoft-Windows-Sysmon/Operational
          lang: javascript
          id: sysmon
          file: ${path.home}/module/sysmon/config/winlogbeat-sysmon.js
      - script:
          when.equals.winlog.channel: Windows PowerShell
          lang: javascript
          id: powershell
          file: ${path.home}/module/powershell/config/winlogbeat-powershell.js
      - script:
          when.equals.winlog.channel: Microsoft-Windows-PowerShell/Operational
          lang: javascript
          id: powershell
          file: ${path.home}/module/powershell/config/winlogbeat-powershell.js

setup.template.settings:
  index.number_of_shards: 1

setup.kibana:
#  hosts: ["opsaudites.hs.com:9200"]
#  username: "filebeat"
#  password: "pass"

output.elasticsearch:
  hosts: ["opsaudites.hs.com:9200"]
  username: "filebeat"
  password: "pass"
  indices:
    - index: "hosts-windows_%{+yyyy.MM.dd}"
  template:
    name: "ops_template"
    pattern: "*"

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - drop_fields:
      fields: ["ecs","event","agent"]
      ignore_missing: false



PS C:\Program Files\winlogbeat> .\install-service-winlogbeat.ps1

Status   Name               DisplayName
------   ----               -----------
Stopped  winlogbeat         winlogbeat

PS C:\Program Files\winlogbeat> Start-Service winlogbeat
PS C:\Program Files\winlogbeat> Get-Service winlogbeat

Status   Name               DisplayName
------   ----               -----------
Running  winlogbeat         winlogbeat


PS C:\Program Files\winlogbeat> Get-Process *winlogbeat* | Stop-Process -Force

```



