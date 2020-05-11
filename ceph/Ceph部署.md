# Ceph的部署工具：

- ceph-deploy：官方的部署工具
- ceph-ansible：红帽的部署工具
- ceph-chef：利用chef进行自动部署Ceph的工具
- puppet-ceph：puppet的ceph模块



Public Network  192.168.200.161-164

Cluster Network  192.168.100.161-164



#### 版本

Mimic   13版

#### 部署前提

这是一个前提条件

关闭SELinux

关闭firewalld，并禁止开机自启

禁止开机自启

网卡 准备两块，一块公网用于对外提供服务，一块私网用于Ceph内部通信以及协调

四台虚拟机个准备2块200G的硬盘

共四个节点

在管理节点上，做各节点的免密登陆，在本文档中，使用的是ceph-mon1节点作为管理节点

```shell
ssh-keygen -t rsa -P ''
ssh-copy-id ceph-mon1
ssh-copy-id ceph-mon2
ssh-copy-id ceph-mon3
ssh-copy-id ceph-osd4
```





#### Ceph-Deploy

ceph-deploy应该部署在专用的节点，也就是管理节点AdminHost上。

ceph-deploy无法处理客户端工具，如果你需要使用Ceph集群，需要自己安装和配置客户端，这个客户端可能是一个内核模块（librbd），也可能只是一个命令行工具。



#### 集群拓扑和网络

![.\图片\3.png](.\图片\3.png)

Ceph集群内有两类流量：

- Cluster Network：私网，集群内部各节点间的通信流量
- Public Network：公网，Ceph对外提供服务的网络



Cluster Network : 192.168.100.0/24

Public Network : 192.168.200.0/24

**161-164**

划重点，IP是这个







#### 生产环境实现高可用性所推荐的节点数量：

Ceph-Mon：3个+

Ceph-Mgr：2个+

Ceph-Mds：2个+



# 开始

## yum源和初始化准备

安装过程中尽量使用阿里云的源，请事先在所有节点上配置好阿里云的ceph源

```ini
#vi /etc/yum.repos.d/ceph.repo
[Ceph]
name=Ceph packages for $basearch
baseurl=http://mirrors.aliyun.com/ceph/rpm-mimic/el7/$basearch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc

[Ceph-noarch]
name=Ceph noarch packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-mimic/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-mimic/el7/SRPMS
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc
```



各节点cephadm用户添加sudo权限

```shell
useradd cephadm
echo '111111' | passwd --stdin cephadm 
echo "cephadm ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/cephadm
chmod 0440 /etc/sudoers.d/cephadm
```

在管理节点上以cephadm用户的身份来做各节点ssh免密登录

```shell
su - cephadm
ssh-keygen -t rsa -P ''
ssh-copy-id cephadm@ceph-mon1
ssh-copy-id cephadm@ceph-mon2	
ssh-copy-id cephadm@ceph-mon3
ssh-copy-id cephadm@ceph-osd4
```
安装依赖，否则会出现缺少依赖的错误

$ yum install -y yum-utils && yum-config-manager --add-repo https://dl.fedoraproject.org/pub/epel/7/x86_64/ && yum install --nogpgcheck -y epel-release && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 && rm -f /etc/yum.repos.d/dl.fedoraproject.org*

管理节点安装ceph-deploy

```shell
yum install ceph-deploy  python-setuptools python2-subprocess32 ceph-common 
```

管理节点以cephadm用户身份在家目录建立ceph-cluster目录

```
su - cephadm
mkdir ceph-cluster
```

切换至ceph-cluster目录

```shell
cd ceph-cluster
```

## Mon

在管理节点以cephadm用户运行

```shell
ceph-deploy new ceph-mon1 --cluster-network 192.168.100.0/24  --public-network 192.168.200.0/24
#mon节点，可以写第一个，也可以写多个
```

然后在所有节点——mon、mgr、osd都要安装，一定要把源的地址改成阿里云的，不然卡半天，翻墙都没用。

```
sudo yum install ceph ceph-radosgw -y
```

在管理节点以cephadm用户运行

```shell
cd ceph-cluster
ceph-deploy install --no-adjust-repos ceph-mon1 ceph-mon2 ceph-mon3 ceph-osd4
```

在管理节点以cephadm用户运行

```shell
ceph-deploy mon create-initial
#这一步其实是在生成keyring文件
```

在管理节点以cephadm用户运行

```shell
ceph-deploy admin ceph-mon1 ceph-mon2 ceph-mon3 ceph-osd4
#将配置和client.admin秘钥环推送到远程主机。
#每次更改ceph的配置文件，都可以用这个命令推送到所有节点上
```

在所有节点以root的身份运行

```shell
setfacl -m u:cephadm:r /etc/ceph/ceph.client.admin.keyring 
#ceph.client.admin.keyring文件是 ceph命令行 所需要使用的keyring文件
#不管哪个节点，只要需要使用cephadm用户执行命令行工具，这个文件就必须要让cephadm用户拥有访问权限，就必须执行这一步
#这一步如果不做，ceph命令是无法在非sudo环境执行的。
```

## Mgr

L版本之后Ceph，必须要有一个mgr节点，所以我们在管理节点执行：

```shell
su - cephadm
cd ceph-cluster
ceph-deploy mgr create ceph-mon1
```

执行完成之后，在管理节点查看集群的健康状态，不过，这一步同样需要/etc/ceph/ceph.client.admin.keyring文件

```shell
su - cephadm
sudo cp ceph-cluster/{ceph.client.admin.keyring,ceph.conf} /etc/ceph/
ceph -s
```

## OSD

列出osd节点上的所有可用磁盘

```shell
ceph-deploy disk list ceph-mon1 ceph-mon2 ceph-mon3 ceph-osd4
#要以cephadm用户在~/ceph-cluster/目录下执行
```

清空osd节点上用来作为osd设备的磁盘

```shell
ceph-deploy disk zap ceph-mon1 /dev/sdb /dev/sdc
ceph-deploy disk zap ceph-mon2 /dev/sdb /dev/sdc
ceph-deploy disk zap ceph-mon3 /dev/sdb /dev/sdc
ceph-deploy disk zap ceph-osd4 /dev/sdb /dev/sdc
#注意，这里其实是在执行dd命令，执行错了就麻烦打了，全盘清空。

```

创建OSD

```shell
ceph-deploy osd create ceph-mon1 --data /dev/sdb 
ceph-deploy osd create ceph-mon2 --data /dev/sdb
ceph-deploy osd create ceph-mon3 --data /dev/sdb
ceph-deploy osd create ceph-osd4 --data /dev/sdb
ceph-deploy osd create ceph-mon1 --data /dev/sdc
ceph-deploy osd create ceph-mon2 --data /dev/sdc
ceph-deploy osd create ceph-mon3 --data /dev/sdc
ceph-deploy osd create ceph-osd4 --data /dev/sdc
```

查看集群状态

```shell
ceph -s
#到这一步其实已经基本能用了
#我们来试一下
```

创建一个存储池，要想使用ceph的存储功能，必须先创建存储池

```shell
ceph osd pool create mypool 64 64 
```

列出当前集群所有存储池

```shell
 ceph osd pool ls
 rados lspools
```

上传一个文件

```shell
rados put issue /etc/issue --pool=mypool
```

获取一个文件

```shell
rados get issue my_issue -p mypool
#issue是对象的ID
#my_issue是outfile，即输出文件叫啥名字
#-p指定存储池
```

删除一个文件

```shell
rados rm issue -p mypool
```

列出指定存储池有哪些文件

```shell
rados ls --pool=mypool
```

查看指定文件在Ceph集群内是怎样做映射的

```shell
ceph osd map mypool issue
#mypool是存储池的名称
#issue是文件的名称
```

ceph map信息简要说明

```shell
osdmap e39 pool 'mypool' (1) object 'issue' -> pg 1.651f88da (1.1a) -> up ([3,6,5], p3) acting ([3,6,5], p3)

#pg 1.651f88da (1.1a),表示第1号存储池的1a号pg
#up  Ceph的存储池是三副本存储的，后面的三个数字是存储了此文件的三个osd的编号，p3表示3号osd是主osd
#acting同理
```

到此为止，安装已经完成，接下来我们来扩展Ceph集群



# 扩展Ceph集群

添加mon节点：

```shell
#为了尽量完善一点，我们来演示一下。
su - cephadm;cd ceph-cluster
ceph-deploy mon add ceph-mon2
ceph-deploy mon add ceph-mon3
```

查看mon的quorum状态

```shell
ceph quorum_status --format json-pretty
```

添加mgr节点，mgr是无状态的

```shell
ceph-deploy mgr create ceph-mon2
```

查看集群状态

```shell
ceph -s
```





#### 删除一个存储池

```shell
ceph osd pool rm mypool mypool --yes-i-really-really-mean-it
#要求存储池的名字要写两遍
#后面必须加--yes-i-really-really-mean-it
#即便你写那么烦，
```



#### ceph命令高级玩法

```shell
ceph-deploy install --no-adjust-repos 
#装包的时候不更改yum源
#如果不指明这个选项，即便你提前配置了阿里云的yum源，它也会改成ceph官方的那个yum源

ceph-deploy osd create {node} --data /path/to/data --block-db /path/to/db-device --block-wal /path/to/wal-device
#创建OSD时，将OSD的三类数据都分开存放——Object Data Blobs、SST文件、wal文件
#--data选项指定的是Object Data存放的硬盘
#--block-db选项指定的是SST文件
#--block-wal选项指定的是wal文件

ceph-deploy config push ceph-mon1
#把ceph.conf配置文件推送到节点上，如果你不特意指明，推送的其实是/home/cephadm/ceph-cluster目录下的ceph.conf文件

ceph osd pool stats {<poolname>}
#查看一个存储池的状态
```



osd的四个状态：

up：启动状态

down：停止状态

in：在RADOS集群里面

out：在RADOS集群外边



至此，部署已经完成。
后面我会出一个如何启用RBD、CephFS、RGW存储接口的视频。



- mon：提供Ceph集群存储拓扑、数据分布的Cluster Map以及认证，
- mgr：提供集群数据的收集、检测等功能。
- mds：CephFS文件系统接口的一个守护进程，
- rgw：RGW对象存储接口的一个守护进程
- osd：Object Stroage Device，用于管理Ceph存储数据所用的硬盘设备的一个守护进程。

Ceph的客户端是直接与OSD进行通信的

Ceph的客户端，通过与Mon节点进行通信，获取完整的Cluster Map，然后在客户端本地，用CRUSH算法，根据Cluster Map，以及对应存储池的放置组规则，进行计算，获得所需数据存储于哪些OSD上面，然后直接与OSD建立通信进行读写。







背锅侠带你手把手安装一套Ceph分布式存储