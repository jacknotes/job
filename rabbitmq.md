# RabbitMQ




## 一、什么是消息队列

小红是小明的姐姐。小红希望小明多读书，常寻找好书给小明看，之前的方式是这样：小红问小明什么时候有空，把书给小明送去，并亲眼监督小明读完书才走。久而久之，两人都觉得麻烦。后来的方式改成了：小红对小明说「我放到书架上的书你都要看」，然后小红每次发现不错的书都放到书架上，小明则看到书架上有书就拿下来看。书架就是一个消息队列，小红是生产者，小明是消费者。这带来的好处有：1.小红想给小明书的时候，不必问小明什么时候有空，亲手把书交给他了，小红只把书放到书架上就行了。这样小红小明的时间都更自由。2.小红相信小明的读书自觉和读书能力，不必亲眼观察小明的读书过程，小红只要做一个放书的动作，很节省时间。3.当明天有另一个爱读书的小伙伴小强加入，小红仍旧只需要把书放到书架上，小明和小强从书架上取书即可（唔，姑且设定成多个人取一本书可以每人取走一本吧，可能是拷贝电子书或复印，暂不考虑版权问题）。4.书架上的书放在那里，小明阅读速度快就早点看完，阅读速度慢就晚点看完，没关系，比起小红把书递给小明并监督小明读完的方式，小明的压力会小一些。这就是消息队列的四大好处：1.解耦每个成员不必受其他成员影响，可以更独立自主，只通过一个简单的容器来联系。小红甚至可以不知道从书架上取书的是谁，小明也可以不知道往书架上放书的人是谁，在他们眼里，都只有书架，没有对方。毫无疑问，与一个简单的容器打交道，比与复杂的人打交道容易一万倍，小红小明可以自由自在地追求各自的人生。2.提速小红选择相信「把书放到书架上，别的我不问」，为自己节省了大量时间。小红很忙，只能抽出五分钟时间，但这时间足够把书放到书架上了。3.广播小红只需要劳动一次，就可以让多个小伙伴有书可读，这大大地节省了她的时间，也让新的小伙伴的加入成本很低。4.削峰假设小明读书很慢，如果采用小红每给一本书都监督小明读完的方式，小明有压力，小红也不耐烦。反正小红给书的频率也不稳定，如果今明两天连给了五本，之后隔三个月才又给一本，那小明只要在三个月内从书架上陆续取走五本书读完就行了，压力就不那么大了。当然，使用消息队列也有其成本：1.引入复杂度毫无疑问，「书架」这东西是多出来的，需要地方放它，还需要防盗。2.暂时的不一致性假如妈妈问小红「小明最近读了什么书」，在以前的方式里，小红因为亲眼监督小明读完书了，可以底气十足地告诉妈妈，但新的方式里，小红回答妈妈之后会心想「小明应该会很快看完吧……」这中间存在着一段「妈妈认为小明看了某书，而小明其实还没看」的时期，当然，小明最终的阅读状态与妈妈的认知会是一致的，这就是所谓的「最终一致性」。那么，该使用消息队列的情况需要满足什么条件呢？1.生产者不需要从消费者处获得反馈引入消息队列之前的直接调用，其接口的返回值应该为空，这才让明明下层的动作还没做，上层却当成动作做完了继续往后走——即所谓异步——成为了可能。小红放完书之后小明到底看了没有，小红根本不问，她默认他是看了，否则就只能用原来的方法监督到看完了。2.容许短暂的不一致性妈妈可能会发现「有时候据说小明看了某书，但事实上他还没看」，只要妈妈满意于「反正他最后看了就行」，异步处理就没问题。如果妈妈对这情况不能容忍，对小红大发雷霆，小红也就不敢用书架方式了。3.确实是用了有效果即解耦、提速、广播、削峰这些方面的收益，超过放置书架、监控书架这些成本。否则如果是盲目照搬，「听说老赵家买了书架，咱们家也买一个」，买回来却没什么用，只是让步骤变多了，还不如直接把书递给对方呢，那就不对了。



**引言**
* 你是否遇到过两个（多个）系统间需要通过定时任务来同步某些数据？你是否在为异构系统的不同进程间相互调用、通讯的问题而苦恼、挣扎？如果是，那么恭喜你，消息服务让你可以很轻松地解决这些问题。
* 消息服务擅长于解决多系统、异构系统间的数据交换（消息通知/通讯）问题，你也可以把它用于系统间服务的相互调用（RPC）。本文将要介绍的RabbitMQ就是当前最主流的消息中间件之一。




## 二、RabbitMQ简介

* AMQP，即Advanced Message Queuing Protocol，高级消息队列协议，是应用层协议的一个开放标准，为面向消息的中间件设计。消息中间件主要用于组件之间的解耦，消息的发送者无需知道消息使用者的存在，反之亦然。
* AMQP的主要特征是面向消息、队列、路由（包括点对点和发布/订阅）、可靠性、安全。
* RabbitMQ是一个开源的AMQP实现，服务器端用Erlang语言编写，支持多种客户端，如：Python、Ruby、.NET、Java、JMS、C、PHP、ActionScript、XMPP、STOMP等，支持AJAX。用于在分布式系统中存储转发消息，在易用性、扩展性、高可用性等方面表现不俗。
* 下面将重点介绍RabbitMQ中的一些基础概念，了解了这些概念，是使用好RabbitMQ的基础。
* ConnectionFactory、Connection、Channel：ConnectionFactory、Connection、Channel都是RabbitMQ对外提供的API中最基本的对象。Connection是RabbitMQ的socket链接，它封装了socket协议相关部分逻辑。ConnectionFactory为Connection的制造工厂。
* Channel是我们与RabbitMQ打交道的最重要的一个接口，我们大部分的业务操作是在Channel这个接口中完成的，包括定义Queue、定义Exchange、绑定Queue与Exchange、发布消息等。
* Queue(队列)：Queue（队列）是RabbitMQ的内部对象，用于存储消息。RabbitMQ中的消息都只能存储在Queue中，生产者生产消息并最终投递到Queue中，消费者可以从Queue中获取消息并消费。多个消费者可以订阅同一个Queue，这时Queue中的消息会被平均分摊给多个消费者进行处理，而不是每个消费者都收到所有的消息并处理。
* Message acknowledgment(消息回执)：在实际应用中，可能会发生消费者收到Queue中的消息，但没有处理完成就宕机（或出现其他意外）的情况，这种情况下就可能会导致消息丢失。为了避免这种情况发生，我们可以要求消费者在消费完消息后发送一个回执给RabbitMQ，RabbitMQ收到消息回执（Message acknowledgment）后才将该消息从Queue中移除；如果RabbitMQ没有收到回执并检测到消费者的RabbitMQ连接断开，则RabbitMQ会将该消息发送给其他消费者（如果存在多个消费者）进行处理。这里不存在timeout概念，一个消费者处理消息时间再长也不会导致该消息被发送给其他消费者，除非它的RabbitMQ连接断开。
* 这里会产生另外一个问题，如果我们的开发人员在处理完业务逻辑后，忘记发送回执给RabbitMQ，这将会导致严重的bug——Queue中堆积的消息会越来越多；消费者重启后会重复消费这些消息并重复执行业务逻辑…
* Message durability(消息持久化)：如果我们希望即使在RabbitMQ服务重启的情况下，也不会丢失消息，我们可以将Queue与Message都设置为可持久化的（durable），这样可以保证绝大部分情况下我们的RabbitMQ消息不会丢失。但依然解决不了小概率丢失事件的发生（比如RabbitMQ服务器已经接收到生产者的消息，但还没来得及持久化该消息时RabbitMQ服务器就断电了），如果我们需要对这种小概率事件也要管理起来，那么我们要用到事务。由于这里仅为RabbitMQ的简单介绍，所以这里将不讲解RabbitMQ相关的事务。
* Prefetch count(预载入数)：前面我们讲到如果有多个消费者同时订阅同一个Queue中的消息，Queue中的消息会被平摊给多个消费者。这时如果每个消息的处理时间不同，就有可能会导致某些消费者一直在忙，而另外一些消费者很快就处理完手头工作并一直空闲的情况。我们可以通过设置prefetchCount来限制Queue每次发送给每个消费者的消息数，比如我们设置prefetchCount=1，则Queue每次给每个消费者发送一条消息；消费者处理完这条消息后Queue会再给该消费者发送一条消息。
* Exchange(交换器)：在上一节我们看到生产者将消息投递到Queue中，实际上这在RabbitMQ中这种事情永远都不会发生。实际的情况是，生产者将消息发送到Exchange，由Exchange将消息路由到一个或多个Queue中（或者丢弃）。
* routing key(路由key):生产者在将消息发送给Exchange的时候，一般会指定一个routing key，来指定这个消息的路由规则，而这个routing key需要与Exchange Type及binding key联合使用才能最终生效。
* 在Exchange Type与binding key固定的情况下（在正常使用时一般这些内容都是固定配置好的），我们的生产者就可以在发送消息给Exchange时，通过指定routing key来决定消息流向哪里。
* RabbitMQ为routing key设定的长度限制为255 bytes。
* Binding(绑定):RabbitMQ中通过Binding将Exchange与Queue关联起来，这样RabbitMQ就知道如何正确地将消息路由到指定的Queue了。
* Binding key(绑定key):在绑定（Binding）Exchange与Queue的同时，一般会指定一个binding key(可以有多个Binding key)；消费者将消息发送给Exchange时，一般会指定一个routing key；当binding key与routing key相匹配时，消息将会被路由到对应的Queue中。在绑定多个Queue到同一个Exchange的时候，这些Binding允许使用相同的binding key。binding key 并不是在所有情况下都生效，它依赖于Exchange Type，比如fanout类型的Exchange就会无视binding key，而是将消息路由到所有绑定到该Exchange的Queue。


**Exchange Types(交换器类型)**
* RabbitMQ常用的Exchange Type有fanout、direct、topic、headers这四种：
* fanout:fanout类型的Exchange路由规则非常简单，它会把所有发送到该Exchange的消息路由到所有与它绑定的Queue中。
* direct:direct类型的Exchange路由规则也很简单，它会把消息路由到那些binding key与routing key完全匹配的Queue中。
* topic:前面讲到direct类型的Exchange路由规则是完全匹配binding key与routing key，但这种严格的匹配方式在很多情况下不能满足实际业务需求。topic类型的Exchange在匹配规则上进行了扩展，它与direct类型的Exchage相似，也是将消息路由到binding key与routing key相匹配的Queue中，但这里的匹配规则有些不同，它约定：
* routing key为一个句点号“. ”分隔的字符串（我们将被句点号“. ”分隔开的每一段独立的字符串称为一个单词），如“stock.usd.nyse”、“nyse.vmw”、“quick.orange.rabbit”
* binding key与routing key一样也是句点号“. ”分隔的字符串
* binding key中可以存在两种特殊字符“*”与“#”，用于做模糊匹配，其中“*”用于匹配一个单词，“#”用于匹配多个单词（可以是零个）
* headers:headers类型的Exchange不依赖于routing key与binding key的匹配规则来路由消息，而是根据发送的消息内容中的headers属性进行匹配。在绑定Queue与Exchange时指定一组键值对；当消息发送到Exchange时，RabbitMQ会取到该消息的headers（也是一个键值对的形式），对比其中的键值对是否完全匹配Queue与Exchange绑定时指定的键值对；如果完全匹配则消息会路由到该Queue，否则不会路由到该Queue。该类型的Exchange没有用到过（不过也应该很有用武之地），所以不做介绍。

**RPC**
* MQ本身是基于异步的消息处理，前面的示例中所有的生产者（P）将消息发送到RabbitMQ后不会知道消费者（C）处理成功或者失败（甚至连有没有消费者来处理这条消息都不知道）。
* 但实际的应用场景中，我们很可能需要一些同步处理，需要同步等待服务端将我的消息处理完成后再进行下一步处理。这相当于RPC（Remote Procedure Call，远程过程调用）。在RabbitMQ中也支持RPC。
* RabbitMQ中实现RPC的机制是：
* 客户端发送请求（消息）时，在消息的属性（MessageProperties，在AMQP协议中定义了14中properties，这些属性会随着消息一起发送）中设置两个值replyTo（一个Queue名称，用于告诉服务器处理完成后将通知我的消息发送到这个Queue中）和correlationId（此次请求的标识号，服务器处理完成后需要将此属性返还，客户端将根据这个id了解哪条请求被成功执行了或执行失败）

* 服务器端收到消息并处理
* 服务器端处理完消息后，将生成一条应答消息到replyTo指定的Queue，同时带上correlationId属性
* 客户端之前已订阅replyTo指定的Queue，从中收到服务器的应答消息后，根据其中的correlationId属性分析哪条请求被执行了，根据执行结果进行后续业务处理

**RabbitMQ对象类型：**
* RabbitMQ Server： 也叫broker server，是一种传输服务。他的角色就是维护一条从Producer到Consumer的路线，保证数据能够按照指定的方式进行传输。但是这个保证也不是100%的保证，但是对于普通的应用来说这已经足够了。当然对于商业系统来说，可以再做一层数据一致性的guard，就可以彻底保证系统的一致性了。
* Producer：数据的发送方，一个Message有两个部分：payload（有效载荷）和label（标签）。payload顾名思义就是传输的数据。label是exchange的名字或者说是一个tag，它描述了payload，而且RabbitMQ也是通过这个label来决定把这个Message发给哪个Consumer。AMQP仅仅描述了label，而RabbitMQ决定了如何使用这个label的规则。
* Consumer：数据的接收方。把queue比作是一个有名字的邮箱。当有Message到达某个邮箱后，RabbitMQ把它发送给它的某个订阅者即Consumer。当然可能会把同一个Message发送给很多的Consumer。在这个Message中，只有payload，label已经被删掉了。对于Consumer来说，它是不知道谁发送的这个信息的。就是协议本身不支持。但是当然了如果Producer发送的payload包含了Producer的信息就另当别论了。
* Connection： 就是一个TCP的连接。Producer和Consumer都是通过TCP连接到RabbitMQ Server的。以后我们可以看到，程序的起始处就是建立这个TCP连接。
* Channels： 虚拟连接。它建立在上述的TCP连接中。数据流动都是在Channel中进行的。也就是说，一般情况是程序起始建立TCP连接，第二步就是建立这个Channel。
* 那么，为什么使用Channel，而不是直接使用TCP连接？
* 对于OS来说，建立和关闭TCP连接是有代价的，频繁的建立关闭TCP连接对于系统的性能有很大的影响，而且TCP的连接数也有限制，这也限制了系统处理高并发的能力。但是，在TCP连接中建立Channel是没有上述代价的。对于Producer或者Consumer来说，可以并发的使用多个Channel进行Publish或者Receive。有实验表明，1s的数据可以Publish10K的数据包。当然对于不同的硬件环境，不同的数据包大小这个数据肯定不一样，但是我只想说明，对于普通的Consumer或者Producer来说，这已经足够了。如果不够用，你考虑的应该是如何细化split你的设计。

**解耦**
* 消息传输过程中保存消息的容器，队列的主要目的：是提供路由并保证消息的传递如果发送消息时接收者不可用，消息队列会保留消息，直到成功为止，当然，消息队列保存消息也是有期限的。
* PTP:点对点，一个消息只有一个消费者，消费者消费后会发送确认消息给队列。
* publish/subscribe:发布和订阅，消费者需要订阅主题，分持久订阅和非持久订阅，一个消息有多信订阅者，客户端只有订阅后才能接收到消息，
* 持久订阅：订阅关系建立后，消息就不会消失，不管订阅者是否在线
* 非持久订阅：订阅者为了接收消息，必须一直在线，否则消息会消失

**简单模式（一对一）**
* 生产者发送消息给交换机
* 交换机接收消息，如果交换机没有绑定队列，消息扔进垃圾桶
* 队列接收消息，存储在内存，等待消费者连接监听获取消息，消费成功后，返回确认。
* 一些场景：短信，QQ

**工作模式（一对多）：**
* 生产者将消息发送给交换机
* 交换机发送给绑定的后端队列
* 一个队列被多个消费者同时监听，形成消息的争抢结构：根据消费者所在的系统的空闲、性能争抢队列中的消息
* 一些场景：抢红包

**发布订阅模式：**
* 交换机定义类型为：fanout
* 交换机绑定多个队列
* 生产者将消息发送给交换机，交换机复制同步消息到后端所有的队列中
* 一些场景：邮件群发

**路由模式：**
* 交换机定义类型为：direct
* 交换机绑定多个队列，队列绑定交换机时，给交换机提供了一个routingkey（路由key）
* 发布订阅时，所有fanout类型的交换机绑定后端队列用的路由key都是“”；在路由模式中需要绑定队列时提供当前队列的具体路由key
* 一些场景：错误消息的接收和提示

**主题模式：**
* 交换机定义类型为：topic
* 交换机绑定多个队列，与路由模式非常相似，做到按类划分消息
* 路由key队列绑定的通配符如下：#表示任意字符串，*表示没有特殊符号（单词）的字符串





## 三、RabbitMQ部署

RabbitMQ模式大概分为以下三种:
1. 单一模式。
2. 普通模式(默认的集群模式)。
3. 镜像模式(把需要的队列做成镜像队列，存在于多个节点，属于RabbiMQ的HA方案，在对业务可靠性要求较高的场合中比较适用)。
要实现镜像模式，需要先搭建一个普通集群模式，在这个模式的基础上再配置镜像模式以实现高可用。



### 3.1 单一模式部署

> 安装erlang版本要大于21.6，因为rabbitmq-server3.8需要


```bash
# 安装Erlang,创建Erlang的yum源：
[root@node3 yum.repos.d]# cat rabbitmq-erlang.repo 
[rabbitmq-erlang]
name=rabbitmq-erlang
baseurl=https://mirrors.tuna.tsinghua.edu.cn/erlang-solutions/centos/7
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
gpgcheck=0
# 创建rabbitmq的yum源：
[root@node3 yum.repos.d]# cat rabbitmq.repo 
[bintray-rabbitmq-server]
name=bintray-rabbitmq-rpm
baseurl=https://dl.bintray.com/rabbitmq/rpm/rabbitmq-server/v3.8.x/el/7/
gpgcheck=0
repo_gpgcheck=0
enabled=1
[root@node2 yum.repos.d]# yum clean all 
[root@node2 yum.repos.d]# yum makecache
# 安装Erlang：
sudo yum install -y erlang 			##--disablerepo=epel
# 安装启动rabbitmq
# 导入密钥：
rpm --import https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc
[root@node3 pki]# yum install -y rabbitmq-server 
[root@node3 pki]# systemctl start rabbitmq-server.service
#r abbit中配置文件夹会于/etc/rabbitmq/,下面没有配置文件，都需要新建配置文件。rabbitmq.conf是用sysctl新格式风格书写,rabbitmq.config是用erlang老格式书写。就是config后缀节尾是老格式，conf是新格式，rabbitmq-env.conf要在rabbitmq.conf之前被加载，它其实就是通过linux环境变量来影响程序的行为，比如可以通过rabbitmq-env.conf指定接下来要加载的rabbitmq.conf文件的位置。
要覆盖RabbitMQ配置文件的主要位置，请使用RABBITMQ_CONFIG_FILE  环境变量。将.conf用作新样式配置格式的文件扩展名。
某些配置设置不可能或难以使用sysctl格式进行配置。这样，可以使用Erlang术语格式的另一个配置文件（与rabbitmq.config相同）。该文件通常命名为advanced.config。它将与Rabbitmq.conf中提供的配置合并。要覆盖高级配置文件的位置，请使用RABBITMQ_ADVANCED_CONFIG_FILE 环境变量。
# 配置文件案例范本链接：https://github.com/rabbitmq/rabbitmq-server/tree/master/docs
[root@node3 ~]# netstat -tunlp | egrep '5672|4369'
tcp        0      0 0.0.0.0:25672           0.0.0.0:*               LISTEN      51619/beam.smp      
tcp        0      0 0.0.0.0:4369            0.0.0.0:*               LISTEN      30064/epmd               
tcp6       0      0 :::5672                 :::*                    LISTEN      51619/beam.smp      
tcp6       0      0 :::4369                 :::*                    LISTEN      30064/epmd          
注：端口解释：
4369：RabbitMQ节点和CLI工具使用的对等发现服务端口
5672：AMQP端口，用于API编程
25672：集群端口
# 添加用户：
[root@node3 download]# rabbitmqctl add_user admin password
Adding user "admin" ...
# 设置用户角色：
#tag（administrator，monitoring，policymaker，management）
[root@node3 download]# rabbitmqctl set_user_tags admin administrator
Setting tags for user "admin" to [administrator] ...
#设置用户权限：
#设置用户权限(接受来自所有Host的所有操作)
[root@node3 download]# rabbitmqctl set_permissions -p '/' admin '.*' '.*' '.*'
Setting permissions for user "admin" in vhost "/" ...
#列出所有用户及所属角色
[root@node3 download]# rabbitmqctl list_users
Listing users ...
user	tags
admin	[administrator]
guest	[administrator]
#列出指定用户权限
[root@node3 download]# rabbitmqctl list_user_permissions admin
Listing permissions for user "admin" ...
vhost	configure	write	read
/	.*	.*	.*
[root@node3 rabbit@node3]# rabbitmq-plugins enable rabbitmq_management #开启插件，此时会打开15652端口，可以通过web管理rabbitmq-server
Enabling plugins on node rabbit@node3:
rabbitmq_management
The following plugins have been configured:
  rabbitmq_management
  rabbitmq_management_agent
  rabbitmq_web_dispatch
Applying plugin configuration to rabbit@node3...
The following plugins have been enabled:
  rabbitmq_management
  rabbitmq_management_agent
  rabbitmq_web_dispatch
started 3 plugins.
注：此时会打开15672端口，这个端口用于web-manager 

# 添加用户
sudo rabbitmqctl add_user <username> <password>  
# 删除用户
sudo rabbitmqctl delete_user <username>  
# 修改用户密码
sudo rabbitmqctl change_password <username> <newpassword>  
# 清除用户密码（该用户将不能使用密码登陆，但是可以通过SASL登陆如果配置了SASL认证）
sudo rabbitmqctl clear_password <username> 
# 设置用户tags（相当于角色，包含administrator，monitoring，policymaker，management）
sudo rabbitmqctl set_user_tags <username> <tag>
# 列出所有用户
sudo rabbitmqctl list_users  
# 创建一个vhosts
sudo rabbitmqctl add_vhost <vhostpath>  
# 删除一个vhosts
sudo rabbitmqctl delete_vhost <vhostpath>  
# 列出vhosts
sudo rabbitmqctl list_vhosts [<vhostinfoitem> ...]  
# 针对一个vhosts给用户赋予相关权限；
sudo rabbitmqctl set_permissions [-p <vhostpath>] <user> <conf> <write> <read>  
# 清除一个用户对vhosts的权限；
sudo rabbitmqctl clear_permissions [-p <vhostpath>] <username>  
# 列出哪些用户可以访问该vhosts；
sudo rabbitmqctl list_permissions [-p <vhostpath>]   
# 列出用户访问权限；
sudo rabbitmqctl list_user_permissions <username>



###用python测试rabbitmq生产和消费：
[root@node1 ~]# pip3 install pika
[root@node3 ~]# cat rabbitmq-sent.py 
#!/usr/bin/env python3
import pika  
import random  
#input loginname and password 
credentials = pika.PlainCredentials('admin', 'password')  
#ip,port,vhost
parameters = pika.ConnectionParameters('192.168.43.203',5672,'test',credentials)    
connection = pika.BlockingConnection(parameters)    
channel = connection.channel()    
#create or declare queue,set name and durable
channel.queue_declare(queue="homsom",durable=True)    
#create or declare exchange,set name and durable
channel.exchange_declare("homsom","direct",durable=True)    
#1.queue name 2.exchange name
channel.queue_bind("homsom","homsom",routing_key="hm")
#'hm' name is routing key ,it already biding homsom queue  
for i in range(0,1000):
  number = random.randint(0,1000)  
  body = 'hello world:%s' % number  
  channel.basic_publish(exchange='homsom',
                      routing_key='hm',    
                      body=body,properties=pika.spec.BasicProperties(delivery_mode=2)) #delivery_mode=2 is persistent,equle 1 is transient
  print(" [x] Sent %s" % body)
connection.close()
[root@node3 ~]# cat rabbitmq-receive.py 
#!/usr/bin/env python3
import pika  
import random  
        
credentials = pika.PlainCredentials('admin', 'password')  
parameters = pika.ConnectionParameters('192.168.43.203',5672,'test',credentials)    
connection = pika.BlockingConnection(parameters)    
channel = connection.channel()    
#down 'homsom' is queue name  
for method_frame, properties, body in channel.consume('homsom'):
    # Display the message parts and acknowledge the message
    print(method_frame, properties, body)
    channel.basic_ack(method_frame.delivery_tag)
    # Escape out of the loop after 10 messages
    if method_frame.delivery_tag == 1000:
        break
# Cancel the consumer and return any pending messages
requeued_messages = channel.cancel()
print('Requeued %i messages' % requeued_messages)
connection.close()

#获取群集状态
$ rabbitmqctl cluster_status
Cluster status of node rabbit@computingforgeeks-centos7 ...
[{nodes,[{disc,['rabbit@computingforgeeks-centos7']}]},
{running_nodes,['rabbit@computingforgeeks-centos7']},
{cluster_name,<<"rabbit@computingforgeeks-centos7">>},
{partitions,[]},
{alarms,[{'rabbit@computingforgeeks-centos7',[]}]}]
#备份RabbitMQ配置
请注意，此备份不包含消息，因为它们存储在单独的消息存储库中，它只会备份RabbitMQ用户、vhost、队列、交换和绑定，备份文件是RabbitMQ元数据的JSON表示，我们将使用rabbitmqadmin命令行工具进行备份。
管理插件附带命令行工具rabbitmqadmin，你需要启用管理插件：
rabbitmq-plugins enable rabbitmq_management
此插件用于执行与基于Web的UI相同的一些操作，这对于自动化任务可能更方便。
#下载rabbitmqadmin
启用管理插件后，下载与HTTP API交互的rabbitmqadmin Python命令行工具，它可以从任何启用了管理插件的RabbitMQ节点下载：
http://{node-hostname}:15672/cli/
下载后，使文件可执行并将其移动到/usr/local/bin目录：
chmod +x rabbitmqadmin
sudo mv rabbitmqadmin /usr/local/bin
要备份RabbitMQ配置，请使用以下命令：
rabbitmqadmin export <backup-file-name>
比如：
$ rabbitmqadmin export rabbitmq-backup-config.json
Exported definitions for localhost to "rabbitmq-backup-config.json"
导出写入文件filerabbitmq-backup-config.json。
#恢复RabbitMQ配置备份
如果你想从备份中恢复RabbitMQ配置，请使用以下命令：
rabbitmqadmin import <JSON backup file >
比如：
$ rabbitmqadmin import rabbitmq-backup.json 
Imported definitions for localhost from "rabbitmq-backup.json"
#备份RabbitMQ数据
RabbitMQ定义和消息存储在位于节点数据目录中的内部数据库中，要获取目录路径，请针对正在运行的RabbitMQ节点运行以下命令：
rabbitmqctl eval 'rabbit_mnesia:dir().'
输出示例：
"/var/lib/rabbitmq/mnesia/rabbit@computingforgeeks-server1"
该目录包含许多文件：
# ls /var/lib/rabbitmq/mnesia/rabbit@computingforgeeks-centos7
在从3.7.0开始的RabbitMQ版本中，所有消息数据都组合在msg_stores/vhosts目录中，并存储在每个vhost的子目录中，每个vhost目录都使用散列命名，并包含带有vhost名称的.vhost文件，因此可以单独备份特定的vhost消息集。
要做RabbitMQ定义和消息数据备份，复制或归档此目录及其内容，但先需要停止RabbitMQ服务：
sudo systemctl stop rabbitmq-server.service
以下示例将创建一个存档：
tar cvf rabbitmq-backup.tgz /var/lib/rabbitmq/mnesia/rabbit@computingforgeeks-centos7
#恢复RabbitMQ数据
要从备份中还原，请将文件从备份提取到数据目录。
内部节点数据库在某些记录中存储节点的名称，如果节点名称发生更改，则必须首先使用以下rabbitmqctl命令更新数据库以便更改：
rabbitmqctl rename_cluster_node <oldnode> <newnode>
当新节点以备份目录和匹配的节点名称启动时，它会根据需要执行升级步骤并继续引导。

##单一节点备份恢复实例：
备份RabbitMQ配置:
[root@node2 ~]# rabbitmqadmin --host=192.168.43.203 --port=15672 --username=admin --password=password export backup.file
注：我这不是在本机上备份配置，如果在本机上备份无需输入host,port,username,password
恢复RabbitMQ配置：
[root@node2 ~]# rabbitmqadmin --host=192.168.43.203 --port=15672 --username=admin --password=password import backup.file
Uploaded definitions from "192.168.43.203" to backup.file. The import process may take some time. Consult server logs to track progress.
注：我在恢复配置前删除了一个队列，当恢复配置后也已经恢复了。
备份RabbitMQ数据：
[root@node3 rabbitmq]# rabbitmqctl eval 'rabbit_mnesia:dir().'
"/var/lib/rabbitmq/mnesia/rabbit@node3"
[root@node3 rabbitmq]# systemctl stop rabbitmq-server.service
[root@node3 rabbitmq]# tar cvf rabbitmq-backup.tgz /var/lib/rabbitmq/mnesia/rabbit@node3
恢复RabbitMQ数据：
模拟node3上的rabbitMQ已经故障，在node2上进行还原备份:
1.yum安装erlang和rabbitmq,更改node2主机名为node3（并且在单节点中，主机名称要一样，也就是说node3复制的数据到node2中时，node2节点要把主机名改成node3，否则恢复不成功）（当恢复的是集群节点时需要重命名下新的节点名称。总体步骤和单一节点备份恢复步骤一样）
2.[root@node2 rabbitmq]# cp enabled_plugins rabbitmq.conf /etc/rabbitmq/  #复制配置文件
[root@node2 rabbitmq]# cat enabled_plugins  #这个配置可用rabbitmq-plugins enable rabbitmq_management命令代替
[rabbitmq_management].
[root@node2 rabbitmq]# egrep -v '#|^$' rabbitmq.conf 
listeners.tcp.default = 5672
3.[root@node2 rabbitmq]# mv var/lib/rabbitmq/mnesia/rabbit@node3 /var/lib/rabbitmq/mnesia/
4.[root@node2 rabbitmq]# systemctl start rabbitmq-server.service
5.[root@node2 rabbitmq]# netstat -tunlp | egrep '5672|4369'
tcp        0      0 0.0.0.0:25672           0.0.0.0:*               LISTEN      11141/beam.smp      
tcp        0      0 0.0.0.0:4369            0.0.0.0:*               LISTEN      11067/epmd          
tcp        0      0 0.0.0.0:15672           0.0.0.0:*               LISTEN      11141/beam.smp      
tcp6       0      0 :::5672                 :::*                    LISTEN      11141/beam.smp      
tcp6       0      0 :::4369                 :::*                    LISTEN      11067/epmd  
[root@node2 ~]# rabbitmqadmin import backup.file  #前提是guest用户和guest密码生效才能成功导入，rabbitmq默认就是这个
Uploaded definitions from "localhost" to backup.file. The import process may take some time. Consult server logs to track progress.
注：此时数据和元数据都成功恢复
```



### 3.2 集群部署

> 前提：node2和node3两个rabbitmq节点都已经安装好，上面有方法安装

```bash
[root@node3 ~]# cd /etc/rabbitmq/
[root@node3 rabbitmq]# cat rabbitmq-env.conf #不设置变量也可，rabbit默认是这个
NODE_PORT=5672
NODENAME=rabbit
[root@node3 rabbitmq]# systemctl restart rabbitmq-server.service
[root@node2 mnesia]# cd /etc/rabbitmq/
[root@node2 rabbitmq]# cat rabbitmq-env.conf 
NODE_PORT=5672
NODENAME=rabbit
[root@node3 rabbitmq]# cat .erlang.cookie 
CWQUYERKZHUAGOEQMZZU
[root@node2 rabbitmq]# cat .erlang.cookie 
CWQUYERKZHUAGOEQMZZU
注：node2和node3的cookie要保持一致，不一致修改即可，权限是600，然后重启服务
[root@node2 rabbitmq]# ll -a
total 8
drwxr-xr-x   5 rabbitmq rabbitmq   70 Apr 22 17:15 .
drwxr-xr-x. 37 root     root     4096 Apr 22 15:39 ..
drwxr-x---   3 rabbitmq rabbitmq   23 Apr 22 17:27 config
-r--------   1 rabbitmq rabbitmq   21 Apr 22 17:15 .erlang.cookie
drwxr-x---   4 rabbitmq rabbitmq  119 Apr 22 17:27 mnesia
drwxr-x---   2 rabbitmq rabbitmq  101 Apr 22 15:47 schema
[root@node2 rabbitmq]# systemctl restart rabbitmq-server.service
[root@node2 rabbitmq]# rabbitmqctl stop_app 
Stopping rabbit application on node rabbit1@node2 ...
[root@node2 rabbitmq]# rabbitmqctl join_cluster rabbit@node3
Clustering node rabbit@node2 with rabbit@node3
[root@node2 rabbitmq]# rabbitmqctl start_app
Starting node rabbit@node2 ...
 completed with 3 plugins.
```

> 此时可以在web-managerment当中看到两个节点组成集群了
> 集群模式仅仅是2个实例共享了信息，但是并没有实现queue队列存储的高可用，也就是没有产生副本。需要设定策略让交换机和队列都镜像，来保证数据的高可用





## 四、RabbitMQ模式

``` bash
# RabbitMQ中队列有两种模式
1. 默认　　Default　# 默认模式时，当主节点挂了，从节点也都会跟着挂掉。其它队列将不可用，特点：高吞吐量，非高可用 
2. 镜像　　Mirror　 # 类似于mongoDB，从一直在通过主的操作日志来进行同步，主节点挂掉时，有从节点顶着，此时仍然可以调用队列。特点：较低吞吐量，高可用 

如果将队列定义为镜像模式，那么这个队列也将区分主从，从而做到了队列高可用。通过一个master（主）和多个slave（从）组成，消息发布到队列中将被复制到所有从节点上。消费者连接到主节点上。配置镜像队列只能通过policy进行配置，可以从命令行也可以通过web UI实现。

#这个策略当主节点挂掉后，从节点接管主节点，最后老的主节点在线了，老的主节点不会自动同步，只能手动同步。要想自动同步，需要加参数"ha-sync-mode":"automatic"
[root@node2 rabbitmq]# rabbitmqctl set_policy --vhost / --priority 0 --apply-to queues ha-all "^test" '{"ha-mode":"all"}' 
Setting policy "ha-all" for pattern "^test" to "{"ha-mode":"all"}" with priority "0" for vhost "/" ...
#手动同步新主节点的数据到老的主节点（本节点）
[root@node3 rabbitmq]# rabbitmqctl sync_queue test   
Synchronising queue 'test' in vhost '/' ...
#列出策略
[root@node3 rabbitmq]# rabbitmqctl list_policies 
Listing policies for vhost "/" ...
vhost	name	pattern	apply-to	definition	priority
/	ha-all	^test	queues	{"ha-mode":"all"}	0
#删除策略
[root@node3 rabbitmq]# rabbitmqctl clear_policy ha-all 
Clearing policy "ha-all" on vhost "/" ...
[root@node3 rabbitmq]# rabbitmqctl set_policy --vhost / --priority 0 --apply-to queues ha-all "^test" '{"ha-mode":"all","ha-sync-mode":"automatic"}'
Setting policy "ha-all" for pattern "^test" to "{"ha-mode":"all","ha-sync-mode":"automatic"}" with priority "0" for vhost "/" ...
#新建了一个针对任意交换机和队列的策略，他们都可以得到mirrors模式，是针对vhost:/的，优先级数字越大越优先应用。
[root@node3 rabbitmq]# rabbitmqctl set_policy --vhost / --priority 10 --apply-to 'all' all ".*" '{"ha-mode":"all","ha-sync-mode":"automatic"}' 
Setting policy "all" for pattern ".*" to "{"ha-mode":"all","ha-sync-mode":"automatic"}" with priority "10" for vhost "/" ...
#主节点下线后再上线将会自动同步数据
[root@node3 rabbitmq]# rabbitmqctl list_policies 
Listing policies for vhost "/" ...
vhost	name	pattern	apply-to	definition	priority
/	ha-all	^test	queues	{"ha-mode":"all","ha-sync-mode":"automatic"}	0
/	all	.*	all	{"ha-mode":"all","ha-sync-mode":"automatic"}	10
###在RabbitMQ集群中的节点只有两种类型：内存节点/磁盘节点，单节点系统只运行磁盘类型的节点。而在集群中，可以选择配置部分节点为内存节点。内存节点将所有的队列，交换器，绑定关系，用户，权限，和vhost的元数据信息保存在内存中。磁盘节点将这些信息保存在磁盘中，但是内存节点的性能更高，为了保证集群的高可用性，必须保证集群中有两个以上的磁盘节点，来保证当有一个磁盘节点崩溃了，集群还能对外提供访问服务。
#更改一个节点从disc（磁盘节点）到ram（内存节点），这里只是测试，生产环境只最少三个节点才能有一个内存节点
[root@node2 rabbitmq]# rabbitmqctl stop_app
Stopping rabbit application on node rabbit@node2 ...
[root@node2 rabbitmq]# rabbitmqctl change_cluster_node_type ram
Turning rabbit@node2 into a ram node
[root@node2 rabbitmq]# rabbitmqctl start_app
Starting node rabbit@node2 ...
 completed with 3 plugins.
```

> #### **`ha-sync-mode: automatic` 的影响**
>
> - `automatic`：新加入的镜像节点会**自动同步主副本上的所有消息**（包括历史消息）。
> - 缺点：如果队列很大，同步过程会消耗大量内存和网络带宽，可能导致节点 OOM 或阻塞。
> - 替代方案：`manual`（默认），需手动执行 `rabbitmqctl sync_queue` 触发同步。
>
> > 📌 生产环境建议：
> >
> > - 小队列可用 `automatic`
> > - 大队列建议用 `manual` + 监控同步状态
>
> #### **Mirrored Queues 已被弃用（重要！）**
>
> - RabbitMQ 自 **3.8.0 起推荐使用 Quorum Queues** 替代 Mirrored Queues。
> - Mirrored Queues 在未来版本中可能被移除。
> - Quorum Queues 提供更强一致性、更可靠故障恢复。
>
> ✅ 如果你使用的是 RabbitMQ ≥ 3.8，**建议改用 Quorum Queue**：
>
> ```bash
> # 声明 quorum queue（通过客户端或 rabbitmqadmin）
> # 或设置策略（仅适用于新声明的队列）：
> rabbitmqctl set_policy -p my_vhost quorum-policy ".*" '{"queue-type":"quorum"}' --apply-to queues
> 
> 
> # 最终推荐命令（Classic Mirrored Queue 场景）
> rabbitmqctl set_policy -p my_vhost ha-all ".*" '{"ha-mode":"all","ha-sync-mode":"manual"}' --priority 10 --apply-to queues
> # 对关键队列手动同步
> rabbitmqctl sync_queue -p my_vhost your_queue_name
> # 验证策略是否生效
> rabbitmqctl list_policies -p my_vhost
> # 查看队列副本
> rabbitmqctl list_queues -p my_vhost name slave_pids synchronised_slave_pids
> ```









## 五、docker部署RabbitMQ

rabbitmq集群是无主集群，任意节点可写入，一般集群都是无主集群,但是会存在选举机制。除主从集群外。

```bash
#节点1
----运行rabbitmq1:
docker run -d --restart=always \
--hostname rabbit1 \
--name myrabbit1 \
-v /home/dockerdata/rabbitmq:/var/lib/rabbitmq  \
-p 25672:25672 \
-p 15672:15672 \
-p 5672:5672 \
-p 4369:4369 \
-e RABBITMQ_ERLANG_COOKIE='rabbitcookie' \
-e RABBITMQ_DEFAULT_USER=admin \
-e RABBITMQ_DEFAULT_PASS=p@ss123.com \
--add-host rabbit2:192.168.15.202 \
--add-host rabbit3:192.168.15.203 \
rabbitmq:3.8.9-management

注：第一个节点可以不用写入其它主机主机名，因为其它节点是加入此节点为集群的。也可写入，例如：--add-host rabbit2:192.168.15.202 --add-host rabbit3:192.168.15.203
----设置集群配置：
docker exec -it myrabbit1 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl start_app
exit


#节点2
----运行rabbitmq2:
docker run -d --restart=always \
--hostname rabbit2 \
--name myrabbit2 \
-v /home/dockerdata/rabbitmq:/var/lib/rabbitmq  \
-p 25672:25672 \
-p 15672:15672 \
-p 5672:5672 \
-p 4369:4369 \
-e RABBITMQ_ERLANG_COOKIE='rabbitcookie' \
-e RABBITMQ_DEFAULT_USER=admin \
-e RABBITMQ_DEFAULT_PASS=p@ss123.com \
--add-host rabbit1:192.168.15.201 \
--add-host rabbit3:192.168.15.203 \
rabbitmq:3.8.9-management
----设置集群配置：
docker exec -it myrabbit2 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster --ram rabbit@rabbit1
rabbitmqctl start_app
exit


#节点3
----运行rabbitmq3:
docker run -d --restart=always \
--hostname rabbit3 \
--name myrabbit3 \
-v /home/dockerdata/rabbitmq:/var/lib/rabbitmq  \
-p 25672:25672 \
-p 15672:15672 \
-p 5672:5672 \
-p 4369:4369 \
-e RABBITMQ_ERLANG_COOKIE='rabbitcookie' \
-e RABBITMQ_DEFAULT_USER=admin \
-e RABBITMQ_DEFAULT_PASS=p@ss123.com \
--add-host rabbit1:192.168.15.201 \
--add-host rabbit2:192.168.15.202 \
rabbitmq:3.8.9-management
docker run -d --restart=always --add-host rabbit1:192.168.15.201 --add-host rabbit2:192.168.15.203 --hostname rabbit3 --name myrabbit3 -p 25672:25672 -p 15672:15672 -p 5672:5672 -p 4369:4369 -e RABBITMQ_ERLANG_COOKIE='rabbitcookie' rabbitmq:3.8.9-management  
----设置集群配置：
docker exec -it myrabbit3 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbit1
rabbitmqctl start_app
exit

#任意节点设置集群为HA镜像模式：
rabbitmqctl set_policy --vhost / --priority 10 --apply-to 'all' all ".*" '{"ha-mode":"all","ha-sync-mode":"automatic"}' 
注：这条策略是针对vhost为'/'的。如果增加了一个vhost为'/test'，则需要再增加一条针对'/test'的策略，'/'不包含'/test'

#用户配置
--添加一个管理员设置密码、角色、权限
rabbitmqctl add_user admin p@ss123.com
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p '/' admin '.*' '.*' '.*'
--查看所有用户、指定用户权限
rabbitmqctl list_users
rabbitmqctl list_user_permissions admin
--清除用户密码并禁用此用户
rabbitmqctl clear_password guest
--设置用户密码并启用此用户
rabbitmqctl change_password guest 123


---
Description: one node for docker rabbitmqCluster.
docker run -d --restart=always \
--hostname rabbit_test1 \
--name rabbit_test1 \
-v /home/dockerdata/rabbitmq1:/var/lib/rabbitmq  \
-p 25672:25672 \
-p 15672:15672 \
-p 5672:5672 \
-p 4369:4369 \
-e RABBITMQ_ERLANG_COOKIE='rabbitcookie!@#' \
-e RABBITMQ_DEFAULT_USER=admin \
-e RABBITMQ_DEFAULT_PASS=p@ss123.com \
rabbitmq:3.8.9-management

docker exec -it rabbit_test1 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl start_app
exit


docker run -d --restart=always \
--hostname rabbit_test2 \
--name rabbit_test2 \
-v /home/dockerdata/rabbitmq2:/var/lib/rabbitmq  \
-p 25673:25672 \
-p 15673:15672 \
-p 5673:5672 \
-p 4370:4369 \
-e RABBITMQ_ERLANG_COOKIE='rabbitcookie!@#' \
-e RABBITMQ_DEFAULT_USER=admin \
-e RABBITMQ_DEFAULT_PASS=p@ss123.com \
--link rabbit_test1:rabbit_test1 \
rabbitmq:3.8.9-management

docker exec -it rabbit_test2 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbit_test1 
rabbitmqctl start_app
exit



docker run -d --restart=always \
--hostname rabbit_test3 \
--name rabbit_test3 \
-v /home/dockerdata/rabbitmq3:/var/lib/rabbitmq  \
-p 25674:25672 \
-p 15674:15672 \
-p 5674:5672 \
-p 4371:4369 \
-e RABBITMQ_ERLANG_COOKIE='rabbitcookie!@#' \
-e RABBITMQ_DEFAULT_USER=admin \
-e RABBITMQ_DEFAULT_PASS=p@ss123.com \
--link rabbit_test1:rabbit_test1 \
--link rabbit_test2:rabbit_test2 \
rabbitmq:3.8.9-management

docker exec -it rabbit_test3 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster --ram rabbit@rabbit_test2 
rabbitmqctl start_app
exit


rabbitmqctl add_user rabbituser homsom
----角色administrator、monitoring、policymaker、management、其它
rabbitmqctl set_user_tags rabbituser users
rabbitmqctl set_permissions -p '/' rabbituser '.*' '.*' '.*'
rabbitmqctl clear_permissions -p / rabbituser
rabbitmqctl list_permissions -p '/'

192.168.13.50:5672，192.168.13.50:5673，192.168.13.50:5674



------
DATETIME: 20210302
生产环境RabbitMQ Docker部署：
rabbitmq01: 192.168.13.235
rabbitmq02: 192.168.13.65
rabbitmq03: 192.168.13.160

#节点1
----运行rabbitmq01:
docker run -d --restart=always \
--hostname rabbitmq01 \
--name rabbitmq01 \
-v /home/dockerdata/rabbitmq:/var/lib/rabbitmq  \
-p 25672:25672 \
-p 15672:15672 \
-p 5672:5672 \
-p 4369:4369 \
-e RABBITMQ_ERLANG_COOKIE='rabbitcookie@homsom' \
-e RABBITMQ_DEFAULT_USER=admin \
-e RABBITMQ_DEFAULT_PASS=p@ss123.com \
--add-host rabbitmq02:192.168.13.65 \
--add-host rabbitmq03:192.168.13.160 \
rabbitmq:3.8.9-management
----设置集群配置：
docker exec -it rabbitmq01 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl start_app
exit


#节点2
----运行rabbitmq02:
docker run -d --restart=always \
--hostname rabbitmq02 \
--name rabbitmq02 \
-v /dockerdata/rabbitmq:/var/lib/rabbitmq  \
-p 25672:25672 \
-p 15672:15672 \
-p 5672:5672 \
-p 4369:4369 \
-e RABBITMQ_ERLANG_COOKIE='rabbitcookie@homsom' \
-e RABBITMQ_DEFAULT_USER=admin \
-e RABBITMQ_DEFAULT_PASS=p@ss123.com \
--add-host rabbitmq01:192.168.13.235 \
--add-host rabbitmq03:192.168.13.160 \
rabbitmq:3.8.9-management
----设置集群配置：
docker exec -it rabbitmq02 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster --ram rabbit@rabbitmq01
rabbitmqctl start_app
exit


#节点3
----运行rabbitmq03:
docker run -d --restart=always \
--hostname rabbitmq03 \
--name rabbitmq03 \
-v /home/dockerdata/rabbitmq:/var/lib/rabbitmq  \
-p 25672:25672 \
-p 15672:15672 \
-p 5672:5672 \
-p 4369:4369 \
-e RABBITMQ_ERLANG_COOKIE='rabbitcookie@homsom' \
-e RABBITMQ_DEFAULT_USER=admin \
-e RABBITMQ_DEFAULT_PASS=p@ss123.com \
--add-host rabbitmq01:192.168.13.235 \
--add-host rabbitmq02:192.168.13.65 \
rabbitmq:3.8.9-management
----设置集群配置：
docker exec -it rabbitmq03 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbitmq02
rabbitmqctl start_app
exit


#任意节点设置集群为HA镜像模式：
rabbitmqctl set_policy --vhost / --priority 10 --apply-to 'all' all ".*" '{"ha-mode":"all","ha-sync-mode":"automatic"}' 
注：这条策略是针对vhost为'/'的。如果增加了一个vhost为'/test'，则需要再增加一条针对'/test'的策略，'/'不包含'/test'

rabbitmqctl set_policy --vhost my_vhost --priority 10 --apply-to 'all' all ".*" '{"ha-mode":"all","ha-sync-mode":"automatic"}' 

#用户配置
--添加一个管理员设置密码、角色、权限
rabbitmqctl add_user admin p@ssword
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p '/' admin '.*' '.*' '.*'
--查看所有用户、指定用户权限
rabbitmqctl list_users
rabbitmqctl list_user_permissions admin
--清除用户密码并禁用此用户
rabbitmqctl clear_password guest
--设置用户密码并启用此用户
rabbitmqctl change_password guest 123

增加普通用户：
rabbitmqctl add_user rabbituser homsom123
rabbitmqctl set_user_tags rabbituser users
rabbitmqctl set_permissions -p '/' rabbituser '.*' '.*' '.*'
rabbitmqctl list_permissions -p '/'
rabbitmqctl list_users


rabbitmqctl add_user devadmin homsom
rabbitmqctl set_user_tags devadmin administrator
rabbitmqctl set_permissions -p '/' devadmin '.*' '.*' '.*'
rabbitmqctl list_permissions -p '/'
rabbitmqctl list_users

```







## 六、小记

>  202104282012实操迁移生产rabbitmq节点



### 6.1 rabbitmq docker 集群节点移除

移除节点：192.168.13.65

```
# 在主节点,也就是发起集群的主机上进行节点的移除
[root@harbor ~]# docker exec -it rabbitmq01 /bin/sh
# rabbitmqctl cluster_status
Cluster status of node rabbit@rabbitmq01 ...
Basics
Cluster name: rabbit@rabbitmq01
# rabbitmqctl forget_cluster_node rabbit@rabbitmq02
Removing node rabbit@rabbitmq02 from the cluster
```



### 6.2 rabbitmq docker 集群节点添加

```bash
# 集群节点添加：
添加节点：192.168.13.162：
docker run -d --restart=always \
--hostname rabbitmq02 \
--name rabbitmq02 \
-v /home/dockerdata/rabbitmq:/var/lib/rabbitmq  \
-p 25672:25672 \
-p 15672:15672 \
-p 5672:5672 \
-p 4369:4369 \
-e RABBITMQ_ERLANG_COOKIE='rabbitcookie@homsom' \
-e RABBITMQ_DEFAULT_USER=admin \
-e RABBITMQ_DEFAULT_PASS=p@ss123.com \
--add-host rabbitmq01:192.168.13.235 \
--add-host rabbitmq03:192.168.13.160 \
rabbitmq:3.8.9-management

[root@linux03 dockerdata]# docker exec -it rabbitmq02 /bin/sh
#rabbitmqctl cluster_status
Cluster status of node rabbit@rabbitmq02 ...
Basics
Cluster name: rabbit@rabbitmq02
#rabbitmqctl stop_app
Stopping rabbit application on node rabbit@rabbitmq02 ...
#rabbitmqctl reset
Resetting node rabbit@rabbitmq02 ...
# rabbitmqctl join_cluster --ram rabbit@rabbitmq01
Clustering node rabbit@rabbitmq02 with rabbit@rabbitmq01
#rabbitmqctl start_app
Starting node rabbit@rabbitmq02 ...
# rabbitmqctl cluster_status
Cluster status of node rabbit@rabbitmq02 ...
Basics
Cluster name: rabbit@rabbitmq01

Disk Nodes
rabbit@rabbitmq01
rabbit@rabbitmq03

RAM Nodes
rabbit@rabbitmq02

Running Nodes
rabbit@rabbitmq01
rabbit@rabbitmq02
rabbit@rabbitmq03
```



### 6.3 rabbitmq参数调整

[docs01](https://www.rabbitmq.com/docs/3.13/configure#supported-environment-variables)
[docs02](https://github.com/rabbitmq/rabbitmq-server/blob/v3.8.9/docs/rabbitmq.conf.example)



#### 6.3.1 动态调整

```
# 动态调整rabbitmq节点的内存限制大小
# 内存限制: 通过 vm_memory_high_watermark 设置，合理调整内存占用比例可以避免 RabbitMQ 因内存溢出而出现问题。
rabbitmqctl set_vm_memory_high_watermark 0.6

# 动态调整rabbitmq节点的磁盘可用空间限制大小，当小于此值时，rabbitmq整个集群将不可用，因此此值是越小越好，避免频繁触发
# 磁盘空间限制: 通过 disk_free_limit 动态配置，确保磁盘空间不足时 RabbitMQ 不会进一步占用磁盘资源。设置 disk_free_limit 为 48MB 并不会造成问题，因为它是一个用于防止磁盘空间耗尽的保护机制。
rabbitmqctl set_disk_free_limit 1GB
#rabbitmqctl set_disk_free_limit 10%

# 文件描述符和套接字描述符: 可以通过操作系统的 ulimit 命令调整，在docker中只能通过宿主机操作系统的ulimit命令和docker中的rabbitmq.conf配置文件进行更改


# Erlang 进程的限制:通过内存和系统资源的分配动态管理，适时增加内存和调整高水位限制可以控制进程数量，rabbitmq自动调整


```



#### 6.3.1 静态调整

```
# 定入配置文件/etc/rabbitmq/rabbitmq.conf，并重启rabbitmq服务

# file_descriptor_limit = 65536
vm_memory_high_watermark.relative = 0.4
# vm_memory_high_watermark.absolute = 2GB
disk_free_limit.absolute = 500mb
```



### 6.4 宿主机ulimit调整后，docker容器中值还未改变，如何调整容器ulimit

```bash
[root@test ~]# docker stop rabbit
[root@test ~]# docker rm -fv rabbit
[root@test ~]# docker run -d --restart=always \
--hostname rabbit \
--name rabbit \
--ulimit nofile=80000:80000 \
-v /data/rabbitmq:/var/lib/rabbitmq  \
-p 25672:25672 \
-p 15672:15672 \
-p 5672:5672 \
-p 4369:4369 \
-e RABBITMQ_ERLANG_COOKIE='test666666' \
-e RABBITMQ_DEFAULT_USER=admin \
-e RABBITMQ_DEFAULT_PASS=p@ss123.com \
harborrepo.hs.com/ops/rabbitmq:3.8.9-management

[root@test ~]# docker exec rabbit sh -c 'ulimit -n'
80000
```

> --ulimit nofile=80000:80000设置容器内的文件描述符限制为 80000。此参数表示容器内软限制和硬限制都为80000
