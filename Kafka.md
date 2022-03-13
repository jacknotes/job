##Kafka与MQ的区别
作为消息队列来说，企业中选择mq的还是多数，因为像Rabbit，Rocket等mq中间件都属于很成熟的产品，性能一般但可靠性较强，
而kafka原本设计的初衷是日志统计分析，现在基于大数据的背景下也可以做运营数据的分析统计，而redis的主要场景是内存数据库，作为消息队列来说可靠性太差，而且速度太依赖网络IO，在服务器本机上的速度较快，且容易出现数据堆积的问题，在比较轻量的场合下能够适用。
RabbitMQ,遵循AMQP协议，由内在高并发的erlanng语言开发，用在实时的对可靠性要求比较高的消息传递上。
kafka是Linkedin于2010年12月份开源的消息发布订阅系统,它主要用于处理活跃的流式数据,大数据量的数据处理上。
1)在架构模型方面，
RabbitMQ遵循AMQP协议，RabbitMQ的broker由Exchange,Binding,queue组成，其中exchange和binding组成了消息的路由键；客户端Producer通过连接channel和server进行通信，Consumer从queue获取消息进行消费（长连接，queue有消息会推送到consumer端，consumer循环从输入流读取数据）。rabbitMQ以broker为中心；有消息的确认机制。
kafka遵从一般的MQ结构，producer，broker，consumer，以consumer为中心，消息的消费信息保存客户端consumer上，consumer根据消费的点，从broker上批量pull数据；无消息确认机制。
2)在吞吐量，
rabbitMQ在吞吐量方面稍逊于kafka，他们的出发点不一样，rabbitMQ支持对消息的可靠的传递，支持事务，不支持批量的操作；基于存储的可靠性的要求存储可以采用内存或者硬盘。
kafka具有高的吞吐量，内部采用消息的批量处理，zero-copy机制，数据的存储和获取是本地磁盘顺序批量操作，具有O(1)的复杂度，消息处理的效率很高。
3)在可用性方面，
rabbitMQ支持miror的queue，主queue失效，miror queue接管。
kafka的broker支持主备模式。
4)在集群负载均衡方面，
rabbitMQ的负载均衡需要单独的loadbalancer进行支持。
kafka采用zookeeper对集群中的broker、consumer进行管理，可以注册topic到zookeeper上；通过zookeeper的协调机制，producer保存对应topic的broker信息，可以随机或者轮询发送到broker上；并且producer可以基于语义指定分片，消息发送到broker的某分片上。


----消息队列
消息队列技术是分布式应用间交换信息的一种技术。常用的消息队列技术是 Message Queue。
分布式协调技术，所谓分布式协调技术主要是用来解决分布式环境当中多个进程之间的同步控制，让他们有序的去访问某种共享资源，防止造成资源竞争（脑裂）的后果。
----Message Queue 的通讯模式
点对点通讯：点对点方式是最为传统和常见的通讯方式，它支持一对一、一对多、多对多、多对一等多种配置方式，支持树状、网状等多种拓扑结构。

多点广播：MQ 适用于不同类型的应用。其中重要的，也是正在发展中的是"多点广播"应用，即能够将消息发送到多个目标站点 (Destination List)。可以使用一条 MQ 指令将单一消息发送到多个目标站点，并确保为每一站点可靠地提供信息。MQ 不仅提供了多点广播的功能，而且还拥有智能消息分发功能，在将一条消息发送到同一系统上的多个用户时，MQ 将消息的一个复制版本和该系统上接收者的名单发送到目标 MQ 系统。目标 MQ 系统在本地复制这些消息，并将它们发送到名单上的队列，从而尽可能减少网络的传输量。

发布/订阅 (Publish/Subscribe) 模式：发布/订阅功能使消息的分发可以突破目的队列地理指向的限制，使消息按照特定的主题甚至内容进行分发，用户或应用程序可以根据主题或内容接收到所需要的消息。发布/订阅功能使得发送者和接收者之间的耦合关系变得更为松散，发送者不必关心接收者的目的地址，而接收者也不必关心消息的发送地址，而只是根据消息的主题进行消息的收发。

群集 (Cluster)：为了简化点对点通讯模式中的系统配置，MQ 提供 Cluster(群集) 的解决方案。群集类似于一个域 (Domain)，群集内部的队列管理器之间通讯时，不需要两两之间建立消息通道，而是采用群集 (Cluster) 通道与其它成员通讯，从而大大简化了系统配置。此外，群集中的队列管理器之间能够自动进行负载均衡，当某一队列管理器出现故障时，其它队列管理器可以接管它的工作，从而大大提高系统的高可靠性。

----Kafka中有以下一些概念：
Broker：任何正在运行中的Kafka示例都称为Broker。
Topic：Topic其实就是一个传统意义上的消息队列。
Partition：即分区。一个Topic将由多个分区组成，每个分区将存在独立的持久化文件，任何一个Consumer在分区上的消费一定是顺序的；当一个Consumer同时在多个分区上消费时，Kafka不能保证总体上的强顺序性（对于强顺序性的一个实现是Exclusive Consumer，即独占消费，一个队列同时只能被一个Consumer消费，并且从该消费开始消费某个消息到其确认才算消费完成，在此期间任何Consumer不能再消费）。（通常有几个节点就初始化几个Partition，Partition指的是一个topic有几个，分布在四个节点，把四个节点的数据均分在不同的partition实现均衡）
Producer：消息的生产者。
Consumer：消息的消费者。
Consumer Group：即消费组。一个消费组是由一个或者多个Consumer组成的，对于同一个Topic，不同的消费组都将能消费到全量的消息，而同一个消费组中的Consumer将竞争每个消息（在多个Consumer消费同一个Topic时，Topic的任何一个分区将同时只能被一个Consumer消费）。

----Kafka的特性
高吞吐量、低延迟：kafka每秒可以处理几十万条消息，它的延迟最低只有几毫秒，每个topic可以分多个partition, consumer group 对partition进行consume操作；
可扩展性：kafka集群支持热扩展；
持久性、可靠性：消息被持久化到本地磁盘，并且支持数据备份防止数据丢失；
容错性：允许集群中节点失败（若副本数量为n,则允许n-1个节点失败）；
高并发：支持数千个客户端同时读写；
支持实时在线处理和离线处理：可以使用Storm这种实时流处理系统对消息进行实时进行处理，同时还可以使用Hadoop这种批处理系统进行离线处理；

----Kafka的Leader的选举机制
Kafka的Leader是什么
首先Kafka会将接收到的消息分区（partition），每个主题（topic）的消息有不同的分区。这样一方面消息的存储就不会受到单一服务器存储空间大小的限制，另一方面消息的处理也可以在多个服务器上并行。
其次为了保证高可用，每个分区都会有一定数量的副本（replica）。这样如果有部分服务器不可用，副本所在的服务器就会接替上来，保证应用的持续性。
但是，为了保证较高的处理效率，消息的读写都是在固定的一个副本上完成。这个副本就是所谓的Leader，而其他副本则是Follower。而Follower则会定期地到Leader上同步数据。
Leader选举
如果某个分区所在的服务器出了问题，不可用，kafka会从该分区的其他的副本中选择一个作为新的Leader。之后所有的读写就会转移到这个新的Leader上。现在的问题是应当选择哪个作为新的Leader。显然，只有那些跟Leader保持同步的Follower才应该被选作新的Leader。
Kafka会在Zookeeper上针对每个Topic维护一个称为ISR（in-sync replica，已同步的副本）的集合，该集合中是一些分区的副本。只有当这些副本都跟Leader中的副本同步了之后，kafka才会认为消息已提交，并反馈给消息的生产者。如果这个集合有增减，kafka会更新zookeeper上的记录。
如果某个分区的Leader不可用，Kafka就会从ISR集合中选择一个副本作为新的Leader。
显然通过ISR，kafka需要的冗余度较低，可以容忍的失败数比较高。假设某个topic有f+1个副本，kafka可以容忍f个服务器不可用。
为什么不用少数服从多数的方法
少数服从多数是一种比较常见的一致性算法和Leader选举法。它的含义是只有超过半数的副本同步了，系统才会认为数据已同步；选择Leader时也是从超过半数的同步的副本中选择。这种算法需要较高的冗余度。譬如只允许一台机器失败，需要有三个副本；而如果只容忍两台机器失败，则需要五个副本。而kafka的ISR集合方法，分别只需要两个和三个副本。
如果所有的ISR副本都失败了怎么办
此时有两种方法可选，一种是等待ISR集合中的副本复活，一种是选择任何一个立即可用的副本，而这个副本不一定是在ISR集合中。这两种方法各有利弊，实际生产中按需选择。
如果要等待ISR副本复活，虽然可以保证一致性，但可能需要很长时间。而如果选择立即可用的副本，则很可能该副本并不一致。

----kafka集群partition分布原理分析
在Kafka集群中，每个Broker都有均等分配Partition的Leader机会。
上述图Broker Partition中，箭头指向为副本，以Partition-0为例:broker1中parition-0为Leader，Broker2中Partition-0为副本。
上述图种每个Broker(按照BrokerId有序)依次分配主Partition,下一个Broker为副本，如此循环迭代分配，多副本都遵循此规则。
副本分配算法如下：
将所有N Broker和待分配的i个Partition排序.
将第i个Partition分配到第(i mod n)个Broker上.
将第i个Partition的第j个副本分配到第((i + j) mod n)个Broker上.

----Zookeeper在kafka的作用
无论是kafka集群，还是producer和consumer都依赖于zookeeper来保证系统可用性集群保存一些meta信息。
Kafka使用zookeeper作为其分布式协调框架，很好的将消息生产、消息存储、消息消费的过程结合在一起。
同时借助zookeeper，kafka能够生产者、消费者和broker在内的所以组件在无状态的情况下，建立起生产者和消费者的订阅关系，并实现生产者与消费者的负载均衡。


###Kafka单机安装 
环境配置:
操作系统：CentOS 7.6.1810
JDK版本：1.8.0_201
Zookeeper版本:zookeeper-3.4.14
Kafka版本：kafka_2.12-2.2.2

安装步骤：
1.先安装zookeeper
curl -L -O http://apache.fayea.com/zookeeper/zookeeper-3.4.14/zookeeper-3.4.14.tar.gz
tar xf zookeeper-3.4.14.tar.gz -C /usr/local/
ln -sv /usr/local/zookeeper-3.4.14/ /usr/local/zookeeper
[root@jack kafka]# cat /etc/profile.d/jdk.sh 
#!/bin/sh
JAVA_HOME=/usr/local/jdk
export PATH=$PATH:$JAVA_HOME/bin
[root@jack kafka]# cat /etc/profile.d/zookeeper.sh 
#!/bin/sh
ZOOKEEPER_HOME=/usr/local/zookeeper
export PATH=$PATH:$ZOOKEEPER_HOME/bin
[root@jack kafka]# cd /usr/local/zookeeper/conf
[root@jack conf]# cp zoo_sample.cfg zoo_sample.cfg.bak
[root@jack conf]# grep -v '^#' zoo.cfg 
tickTime=2000   #这个时间是作为 Zookeeper 服务器之间或客户端与服务器之间维持心跳的时间间隔，也就是每个 tickTime 时间就会发送一个心跳
initLimit=10
syncLimit=5
dataDir=/tmp/zookeeper  #Zookeeper 保存数据的目录,默认情况下，Zookeeper 将写数据的日志文件也保存在这个目录里
clientPort=2181  #这个端口就是客户端连接 Zookeeper 服务器的端口，Zookeeper 会监听这个端口，接受客户端的访问请求
[root@jack conf]# zkServer.sh start  #启动zookeeper
[root@jack conf]# zkServer.sh stop  #停止zookeeper
[root@jack conf]# netstat -tunlp | grep 2181
tcp6       0      0 :::2181                 :::*                    LISTEN      13529/java	
2.安装kafka:
curl -L -O https://mirrors.cnnic.cn/apache/kafka/2.2.2/kafka_2.12-2.2.2.tgz
tar xfz kafka_2.12-2.2.2.tgz -C /usr/local
ln -sv /usr/local/kafka_2.12-2.2.2/ /usr/local/kafka
[root@jack ~]# cat /etc/profile.d/kafka.sh 
#!/bin/sh
KAFKA_HOME=/usr/local/kafka
export PATH=$PATH:$KAFKA_HOME/bin
[root@jack kafka]# cd /usr/local/kafka/config/
[root@jack config]# cp server.properties server.properties.bak
[root@jack config]# egrep -v '^$|^#' server.properties
broker.id=0 #每一个broker在集群中的唯一表示，要求是正数。当该服务器的IP地址发生改变时，broker.id没有变化，则不会影响consumers的消息情况
listeners=PLAINTEXT://:9092  #kafka监听端口
num.network.threads=4 #broker处理消息的最大线程数，一般情况下数量为cpu核数
num.io.threads=8 #broker处理磁盘IO的线程数，数值为cpu核数2倍
socket.send.buffer.bytes=1024000 #socket的发送缓冲区，socket的调优参数SO_SNDBUFF
socket.receive.buffer.bytes=1024000 #socket的接受缓冲区，socket的调优参数SO_RCVBUFF
socket.request.max.bytes=104857600 #表示消息体的最大大小，单位是字节 
log.dirs=/tmp/kafka-logs #kafka数据的存放地址，多个地址的话用逗号分割,多个目录分布在不同磁盘上可以提高读写性能  /data/kafka-logs-1，/data/kafka-logs-2
num.partitions=2 #每个topic的分区个数，若是在topic创建时候没有指定的话会被topic创建时的指定参数覆盖
num.recovery.threads.per.data.dir=1 
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168  #数据文件保留多长时间， 存储的最大时间超过这个时间会根据log.cleanup.policy设置数据清除策略log.retention.bytes和log.retention.minutes或log.retention.hours任意一个达到要求，都会执行删除
log.segment.bytes=1073741824  #topic的分区是以一堆segment文件存储的，这个控制每个segment的大小，会被topic创建时的指定参数覆盖
log.retention.check.interval.ms=300000 #文件大小检查的周期时间，是否处罚 log.cleanup.policy中设置的策略
zookeeper.connect=localhost:2181 #zookeeper集群的地址，可以是多个，多个之间用逗号分割 hostname1:port1,hostname2:port2,hostname3:port3
zookeeper.connection.timeout.ms=6000  #ZooKeeper的连接超时时间
group.initial.rebalance.delay.ms=0
[root@jack config]# kafka-server-start.sh \$KAFKA_HOME/config/server.properties &  #启动kafka
[root@jack ~]# netstat -tunlp | grep 9092
tcp6       0      0 :::9092                 :::*                    LISTEN      20797/java
[root@jack config]# jps
13529 QuorumPeerMain   #对应的zookeeper实例
21148 Jps
20797 Kafka  #kafka实例
3.单机连通性测试
consumer注意事项：
对于消费者，kafka中有两个设置的地方：对于老的消费者，由--zookeeper参数设置；对于新的消费者，由--bootstrap-server参数设置
如果使用了--zookeeper参数,那么consumer的信息将会存放在zk之中,则使用bin/kafka-console-consumer.sh --zookeeper 172.168.2.222:2181 --topic dblab01 
如果使用了--bootstrap-server参数,那么consumer的信息将会存放在kafka之中,则使用bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic dblab01 --from-beginning

[root@jack ~]# kafka-topics.sh --create --bootstrap-server 127.0.0.1:9092 --topic test2 --partitions 1 --replication-factor 1 #新建个topic
[root@jack ~]# kafka-topics.sh --list --bootstrap-server 127.0.0.1:9092 #查看topic消息队列
__consumer_offsets
dblab01
test
test1
test2
[root@jack config]# kafka-console-producer.sh --broker-list 127.0.0.1:9092 --topic test1
>hello jack
[root@jack ~]# kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --topic test1 --from-beginning
adfadfa
sdfadafsdfas
safsdaf
jack    
hello world  #这些都是之前的消息
hello jack  #这是新接收到的消息



####kafka高可用集群搭建：
选举优先级：
一：对比事务ID，谁大谁为leader,集群初始没有事务ID，需要看第二步
二：对比server ID,谁大谁为leader
1.zookeeper高可用伪集群搭建：
curl -L -O http://apache.fayea.com/zookeeper/zookeeper-3.4.14/zookeeper-3.4.14.tar.gz
tar xf zookeeper-3.4.14.tar.gz -C /usr/local/
ln -sv /usr/local/zookeeper-3.4.14/ /usr/local/zookeeper
node1:编辑节点1的zookeeper配置文件：
[root@jack ~]# vim /usr/local/zookeeper/conf/zoo.cfg 
tickTime=2000  #用于计算的基础时间单元。比如session超时：N*tickTime
initLimit=10   #用于集群，允许从节点连接并同步到 master节点的初始化连接时间，以tickTime的倍数来表示
syncLimit=5    #用于集群， master主节点与从节点之间发送消息，请求和应答时间长度（心跳机制）
dataDir=/tmp/zookeeper/data1    #数据存储位置
dataLogDir=/tmp/zookeeper/log1  #日志目录
clientPort=2181    #用于客户端连接的端口，默认2181
server.1=127.0.0.1:2287:3387   #指名集群间通讯端口和选举端口
server.2=127.0.0.1:2288:3388
server.3=127.0.0.1:2289:3389   
#上面server.1 这个1是服务器的标识，可以是任意有效数字，标识这是第几个服务器节点，这个标识要写到dataDir目录下面myid文件里
[root@jack ~]# cp -a /usr/local/zookeeper /usr/local/zookeeper2
[root@jack ~]# cp -a /usr/local/zookeeper /usr/local/zookeeper3
node2:编辑节点2的zookeeper配置文件：
[root@jack ~]# vim /usr/local/zookeeper2/conf/zoo.cfg
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/tmp/zookeeper/data2
dataLogDir=/tmp/zookeeper/log2
clientPort=2182
server.1=127.0.0.1:2287:3387
server.2=127.0.0.1:2288:3388
server.3=127.0.0.1:2289:3389
node3:编辑节点3的zookeeper配置文件：
[root@jack ~]# vim /usr/local/zookeeper3/conf/zoo.cfg
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/tmp/zookeeper/data3
dataLogDir=/tmp/zookeeper/log3
clientPort=2183
server.1=127.0.0.1:2287:3387
server.2=127.0.0.1:2288:3388
server.3=127.0.0.1:2289:3389
###标识节点
分别在三个节点的数据存储目录下新建myid文件,并写入对应的节点标识。Zookeeper集群通过myid文件识别集群节点，并通过上文配置的节点通信端口和选举端口来进行节点通信，选举出leader节点。
mkdir -p  /tmp/zookeeper/data{1,2,3}
mkdir -p  /tmp/zookeeper/log{1,2,3}
[root@jack zookeeper]# echo 1 > /tmp/zookeeper/data1/myid 
[root@jack zookeeper]# echo 2 > /tmp/zookeeper/data2/myid 
[root@jack zookeeper]# echo 3 > /tmp/zookeeper/data2/myid 
/usr/local/zookeeper/bin/zkServer.sh start   #启动zookeeper
/usr/local/zookeeper2/bin/zkServer.sh start
/usr/local/zookeeper3/bin/zkServer.sh start
[root@jack zookeeper]# netstat -tunlp  | egrep '218|338'
tcp6       0      0 :::2183                 :::*                    LISTEN      9581/java           
tcp6       0      0 127.0.0.1:3387          :::*                    LISTEN      9535/java           
tcp6       0      0 127.0.0.1:3388          :::*                    LISTEN      9551/java           
tcp6       0      0 127.0.0.1:3389          :::*                    LISTEN      9581/java           
tcp6       0      0 :::2181                 :::*                    LISTEN      9535/java           
tcp6       0      0 :::2182                 :::*                    LISTEN      9551/java      

[root@jack zookeeper]# /usr/local/zookeeper/bin/zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /usr/local/zookeeper/bin/../conf/zoo.cfg
Mode: follower
[root@jack zookeeper]# /usr/local/zookeeper2/bin/zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /usr/local/zookeeper2/bin/../conf/zoo.cfg
^[[AMode: follower
[root@jack zookeeper]# /usr/local/zookeeper3/bin/zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /usr/local/zookeeper3/bin/../conf/zoo.cfg
Mode: leader    #zookeeper3为leader

2.kafka伪集群搭建
curl -L -O https://mirrors.cnnic.cn/apache/kafka/2.2.2/kafka_2.12-2.2.2.tgz
tar xfz kafka_2.12-2.2.2.tgz -C /usr/local
ln -sv /usr/local/kafka_2.12-2.2.2/ /usr/local/kafka
#node1:编辑kafka配置文件
[root@jack zookeeper]# vim /usr/local/kafka/config/server.properties
broker.id=0
listeners=PLAINTEXT://:9092
num.network.threads=4
num.io.threads=8
socket.send.buffer.bytes=1024000
socket.receive.buffer.bytes=1024000
socket.request.max.bytes=104857600  
log.dirs=/tmp/kafka1
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connect=localhost:2181,localhost:2182,localhost:2183
zookeeper.connection.timeout.ms=6000
group.initial.rebalance.delay.ms=0
replica.lag.max.messages =4000
## 如果follower落后与leader太多,将会认为此follower[或者说partition relicas]已经失效,通常,在follower与leader通讯时,因为网络延迟或者链接断开,总会导致replicas中消息同步滞后,如果消息之后太多,leader将认为此follower网络延迟较大或者消息吞吐能力有限,将会把此replicas迁移到其他follower中.在broker数量较少,或者网络不足的环境中,建议提高此值.
eplica.lag.time.max.ms =10000
## replicas响应partition leader的最长等待时间，若是超过这个时间，就将replicas列入ISR(in-sync replicas)，并认为它是死的，不会再加入管理中

#node2:编辑kafka配置文件
[root@jack zookeeper]# vim /usr/local/kafka/config/server.properties
broker.id=1
listeners=PLAINTEXT://:9093
num.network.threads=4
num.io.threads=8
socket.send.buffer.bytes=1024000
socket.receive.buffer.bytes=1024000
socket.request.max.bytes=104857600  
log.dirs=/tmp/kafka2
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connect=localhost:2181,localhost:2182,localhost:2183
zookeeper.connection.timeout.ms=6000
group.initial.rebalance.delay.ms=0
replica.lag.max.messages =4000
## 如果follower落后与leader太多,将会认为此follower[或者说partition relicas]已经失效,通常,在follower与leader通讯时,因为网络延迟或者链接断>开,总会导致replicas中消息同步滞后,如果消息之后太多,leader将认为此follower网络延迟较大或者消息吞吐能力有限,将会把此replicas迁移到其他follo
wer中.在broker数量较少,或者网络不足的环境中,建议提高此值.
eplica.lag.time.max.ms =10000
## replicas响应partition leader的最长等待时间，若是超过这个时间，就将replicas列入ISR(in-sync replicas)，并认为它是死的，不会再加入管理中

#node3:编辑kafka配置文件
[root@jack zookeeper]# vim /usr/local/kafka/config/server.properties
broker.id=2
listeners=PLAINTEXT://:9094
num.network.threads=4
num.io.threads=8
socket.send.buffer.bytes=1024000
socket.receive.buffer.bytes=1024000
socket.request.max.bytes=104857600  
log.dirs=/tmp/kafka3
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connect=localhost:2181,localhost:2182,localhost:2183
zookeeper.connection.timeout.ms=6000
group.initial.rebalance.delay.ms=0
replica.lag.max.messages =4000
## 如果follower落后与leader太多,将会认为此follower[或者说partition relicas]已经失效,通常,在follower与leader通讯时,因为网络延迟或者链接断>开,总会导致replicas中消息同步滞后,如果消息之后太多,leader将认为此follower网络延迟较大或者消息吞吐能力有限,将会把此replicas迁移到其他follo
wer中.在broker数量较少,或者网络不足的环境中,建议提高此值.
eplica.lag.time.max.ms =10000
## replicas响应partition leader的最长等待时间，若是超过这个时间，就将replicas列入ISR(in-sync replicas)，并认为它是死的，不会再加入管理中

#start kafka
/usr/local/kafka/bin/kafka-server-start.sh -daemon /usr/local/kafka/config/server.properties
/usr/local/kafka2/bin/kafka-server-start.sh -daemon /usr/local/kafka2/config/server.properties
/usr/local/kafka3/bin/kafka-server-start.sh -daemon /usr/local/kafka3/config/server.properties
#检查kafka服务
[root@jack zookeeper]# netstat -tunlp  | egrep '909'
tcp6       0      0 :::9092                 :::*                    LISTEN      9876/java           
tcp6       0      0 :::9093                 :::*                    LISTEN      10181/java          
tcp6       0      0 :::9094                 :::*                    LISTEN      10507/java    
[root@jack zookeeper]# /usr/local/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 3 --partitions 3 --topic topic
#新建一个topic,名叫topic的消息队列
[root@jack zookeeper]# /usr/local/kafka/bin/kafka-topics.sh --describe --bootstrap-server localhost:9092 --topic topic
Topic:topic	PartitionCount:3	ReplicationFactor:3	Configs:segment.bytes=1073741824
	Topic: topic	Partition: 0	Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
	Topic: topic	Partition: 1	Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: topic	Partition: 2	Leader: 0	Replicas: 0,1,2	Isr: 0,1,2
#parttionCount:3表示有3个分区，ReplicationFactor:3表示每个分区复制了3份，第一行Topic:topic表示消息队列叫topic,Partition:0表示第一个分区，Leader:2表示这个分区的Leader在第三个节点上(也就是broker.id=2的kafka服务器上),Replicas:2,0,1表示这个分区有3个副本，其中2为Learder,其它为follower，ISR:2,0,1表示isr管理器维护和同步成功了这个分区上的三个副本.
###测试集群
[root@jack zookeeper]# /usr/local/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic topic #生产者进行生产消息
>hello kafka
[root@jack ~]# /usr/local/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9093 --topic topic --from-beginning #消费者进行消费
hello kafka
##模拟故障一台broker.id=0,看topic消息队列是否受影响
[root@jack ~]# jps -m
17930 Kafka /usr/local/kafka2/config/server.properties
18298 Kafka /usr/local/kafka3/config/server.properties
16956 ConsoleConsumer --bootstrap-server localhost:9093 --topic topic --from-beginning
9581 QuorumPeerMain /usr/local/zookeeper3/bin/../conf/zoo.cfg
16669 ConsoleProducer --broker-list localhost:9092 --topic topic
17629 Kafka /usr/local/kafka/config/server.properties
9535 QuorumPeerMain /usr/local/zookeeper/bin/../conf/zoo.cfg
9551 QuorumPeerMain /usr/local/zookeeper2/bin/../conf/zoo.cfg
[root@jack ~]#  kill -9 17629  #此时kafka节点1已经下线,也就是9092已经下线
[root@jack ~]# /usr/local/kafka/bin/kafka-topics.sh --describe --bootstrap-server localhost:9093 --topic topic
Topic:topic	PartitionCount:3	ReplicationFactor:3	Configs:segment.bytes=1073741824
	Topic: topic	Partition: 0	Leader: 2	Replicas: 2,0,1	Isr: 1,2
	Topic: topic	Partition: 1	Leader: 1	Replicas: 1,2,0	Isr: 1,2
	Topic: topic	Partition: 2	Leader: 1	Replicas: 0,1,2	Isr: 1,2
[root@jack zookeeper]# /usr/local/kafka/bin/kafka-console-producer.sh --broker-list localhost:9094 --topic topic
>jack123
[root@jack kafka1]# /usr/local/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9094 --topic topic --from-beginning
jack123
#此时消息队列可以很正常生产和消费。
##模拟zookeeper一台故障
[root@jack ~]# /usr/local/zookeeper/bin/zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /usr/local/zookeeper/bin/../conf/zoo.cfg
Mode: follower
[root@jack ~]# /usr/local/zookeeper2/bin/zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /usr/local/zookeeper2/bin/../conf/zoo.cfg
Mode: leader
[root@jack ~]# /usr/local/zookeeper3/bin/zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /usr/local/zookeeper3/bin/../conf/zoo.cfg
Mode: follower
#现在模拟zookeeper node1故障
[root@jack ~]# /usr/local/zookeeper2/bin/zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /usr/local/zookeeper2/bin/../conf/zoo.cfg
Mode: leader
[root@jack ~]# /usr/local/zookeeper3/bin/zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /usr/local/zookeeper3/bin/../conf/zoo.cfg
Mode: follower
[root@jack ~]# /usr/local/zookeeper/bin/zkServer.sh status  #此时zookeeper node1已经下线
ZooKeeper JMX enabled by default
Using config: /usr/local/zookeeper/bin/../conf/zoo.cfg
Error contacting service. It is probably not running.
[root@jack ~]# netstat -tunlp | grep 218   #2181 node1快线下线
tcp6       0      0 :::2183                 :::*                    LISTEN      32192/java          
tcp6       0      0 :::2182                 :::*                    LISTEN      9551/java     

ot@jack ~]# /usr/local/kafka/bin/kafka-topics.sh --describe --bootstrap-server localhost:9094 --topic topic
Topic:topic	PartitionCount:3	ReplicationFactor:3	Configs:segment.bytes=1073741824
	Topic: topic	Partition: 0	Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
	Topic: topic	Partition: 1	Leader: 1	Replicas: 1,2,0	Isr: 2,0,1
	Topic: topic	Partition: 2	Leader: 0	Replicas: 0,1,2	Isr: 2,0,1
#kafka集群不受影响，而且生产者和消费者都正常的执行
###注意：当zookeeper集群只有一个节点在线时，则你只能通过监听端口来判断zookerper是否在线。通过zkServer.sh status是看不出来的。2.当你的kafka集群生产者连接的是node3,消费者连接的也是node3，此时当node3的kafka故障，则你的生产者和消费者会报错误日志，不能连接9094端口进行消息队列的执行。只能连接9092或9093端口进行生产和消费。
##正常使用方法
[root@jack job]# /usr/local/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092,localhost:9093,localhost:9094 --topic topic
[root@jack ~]# /usr/local/kafka/bin//kafka-console-consumer.sh --bootstrap-server localhost:9092,localhost:9093,localhost:9094 --topic topic
##注：只有生产者和消费者像上面这样进行生产和消费时，当其中任意两台broker故障时，生产者和消费者都正常实现消息传输

##kafka的故障恢复及备份
1. zookeeper多台集群，当某台集群故障时，会自己选择新的lead，自己会故障转移。当恢复备份时，复制zookeeper的安装包，并更改配置文件，然后在自己的data数据目录下新建一个myid文件，文件内空为自己所在的服务器id,跟zoo.cfg配置文件中server.1参数中1相同。重启zookeeper服务会自动加入zookeeper集群
2. kafka多台集群，当某台集群故障时，只需要重新让好的kafka broker加入，并重启服务，此新的broker会从之前topic的lead中自动同步数据到新的broker,集群ID必须和故障的broker ID一样，否则不会同步topic信息
#注意：有多少个节点时，最好把ReplicationFactor设成节点数量，可使集群高可用

#使用kafka消费组
[root@jack kafka3]# /usr/local/kafka/bin/kafka-consumer-groups.sh --list --bootstrap-server localhost:9092,localhost:9093,localhost:9094
console-consumer-13507
[root@jack kafka3]# /usr/local/kafka/bin/kafka-consumer-groups.sh --describe --bootstrap-server localhost:9092,localhost:9093,localhost:9094 --group console-consumer-13507

TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                     HOST            CLIENT-ID
topic           0          -               21              -               consumer-1-f2550944-f0a1-4f65-a144-c77ffd17490f /172.168.2.222  consumer-1
topic           1          -               19              -               consumer-1-f2550944-f0a1-4f65-a144-c77ffd17490f /172.168.2.222  consumer-1
topic           2          -               21              -               consumer-1-f2550944-f0a1-4f65-a144-c77ffd17490f /172.168.2.222  consumer-1
[root@jack kafka3]# /usr/local/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092,localhost:9093,localhost:9094 --topic test  #生产者在test topic
>1
>2
>3
>4
>5
>6
[root@jack ~]# /usr/local/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092,localhost:9093,localhost:9094 --topic test --consumer-property group.id=mygroup --from-beginning  #创建消费组，需要指定--consumer-property group.id=mygroup，否则是一个消费者,--consumer-property consumer.id=jack表示指定consumer的id
1
2
4
5
[root@jack job]# /usr/local/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092,localhost:9093,localhost:9094 --topic test --consumer-property group.id=mygroup --from-beginning
3
6
[root@jack ~]# /usr/local/kafka/bin/kafka-consumer-groups.sh --list --bootstrap-server localhost:9092,localhost:9093,localhost:9094
mygroup  #此时已经有了这个新组
console-consumer-13507


