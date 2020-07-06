需要更改的地方：
1. 需要更改mani.sh主脚本中的变量：UNZIP_ORACLE_SOURCE=/download/database。默认值是oracle程序解压后的目录，需要更改成自己的oracle程序解压目录。
2. 需要更改mani.sh主脚本中的变量：HOSTNAME=node1。默认值是主机名node1，需要更改为自己安装oracle程序的主机名。
3. 需要更改mani.sh主脚本中的变量：TOTAL_MEMORY=4。默认值是4G内存，需要更改为自己机器上的物理内存容量。
4. 此脚本运行时需要放到普通用户可执行的目录下。

脚本注解：
1. oracle程序默认需要主机上存在swap内存，没有swap则不允许安装，所以脚本默认建立了2G的swap。
2. 脚本默认配置了主机名的解析记录在/etc/hosts中。脚本是hosts.sh
3. 脚本默认给oracle程序在安装时新建了用户oracle,组oinstall,dba。oracle密码是oracle。脚本是user.sh
4. 脚本配置并执行了linux上的系统调优，使其满足oracle安装，脚本是conffile.sh
5. 为oracle配置了目录，用于安装、数据存储等用处。脚本是oracledir.sh
6. oracle需要一些依赖包，脚本中安装了特定的包。
7. USE_MEMORY=$(echo ${TOTAL_MEMORY}*0.8*1024 | /usr/bin/bc | awk -F '.' '{print $1}')。此变量是将TOTAL_MEMORY变量内存单位为G的值转换为M，并且将总值乘于0.8，表示把主机上的80%内存分配给oracle程序。
