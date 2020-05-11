# CEPH

# ceph 介绍

## ceph 功能

ceph 目前提供对象存储（RADOSGW）、块存储 RDB 以及 CephFS 文件系统这 3 种功能。对于这 3 种功能介绍，分别如下：

1.对象存储，也就是通常意义的键值存储，其接口就是简单的 GET、PUT、DEL 和其他扩展，代表主要有 Swift 、S3 以及 Gluster 等；

2.块存储，这种接口通常以 QEMU Driver 或者 Kernel Module 的方式存在，这种接口需要实现 Linux 的 Block Device 的接口或者 QEMU 提供的 Block Driver 接口，如 Sheepdog，AWS 的 EBS，××× 的云硬盘和阿里云的盘古系统，还有 Ceph 的 RBD（RBD 是 Ceph 面向块存储的接口）。在常见的存储中 DAS、SAN 提供的也是块存储；

3.文件存储，通常意义是支持 POSIX 接口，它跟传统的文件系统如 Ext4 是一个类型的，但区别在于分布式存储提供了并行化的能力，如 Ceph 的 CephFS (CephFS 是 Ceph 面向文件存储的接口)，但是有时候又会把 GlusterFS ，HDFS 这种非 POSIX 接口的类文件存储接口归入此类。当然 NFS、NAS 也是属于文件系统存储

## ceph 组件介绍

Ceph 的核心构成包括：Ceph OSD(对象存出设备)、Ceph Monitor(监视器) 、Ceph MSD(元数据服务器)、Object、PG、RADOS、Libradio、CRUSH、RDB、RGW、CephFS

OSD：全称 Object Storage Device，真正存储数据的组件，一般来说每块参与存储的磁盘都需要一个 OSD 进程，如果一台服务器上又 10 块硬盘，那么该服务器上就会有 10 个 OSD 进程。

MON：MON 通过保存一系列集群状态 map 来监视集群的组件，使用 map 保存集群的状态，为了防止单点故障，因此 monitor 的服务器需要奇数台（大于等于 3 台），如果出现意见分歧，采用投票机制，少数服从多数。

MDS：全称 Ceph Metadata Server，元数据服务器，只有 Ceph FS 需要它。

Object：Ceph 最底层的存储单元是 Object 对象，每个 Object 包含元数据和原始数据。

PG：全称 Placement Grouops，是一个逻辑的概念，一个 PG 包含多个 OSD。引入 PG 这一层其实是为了更好的分配数据和定位数据。

RADOS：全称 Reliable Autonomic Distributed Object Store，是 Ceph 集群的精华，可靠自主分布式对象存储，它是 Ceph 存储的基础，保证一切都以对象形式存储。

Libradio：Librados 是 Rados 提供库，因为 RADOS 是协议很难直接访问，因此上层的 RBD、RGW 和 CephFS 都是通过 librados 访问的，目前仅提供 PHP、Ruby、Java、Python、C 和 C++支持。

CRUSH：是 Ceph 使用的数据分布算法，类似一致性哈希，让数据分配到预期的地方。

RBD：全称 RADOS block device，它是 RADOS 块设备，对外提供块存储服务。

RGW：全称 RADOS gateway，RADOS 网关，提供对象存储，接口与 S3 和 Swift 兼容。

CephFS：提供文件系统级别的存储。

# ceph 集群手动搭建

添加第二个网段。

1. 虚拟一个 IP 即可
2. 使用网桥虚拟化一个网段 并连接

## 生产环境实现高可用性所推荐的节点数量：

Ceph-Mon：3 个+

Ceph-Mgr：2 个+

Ceph-Mds：2 个+

## 添加 aliyun 的 repo、

```
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

## 角色设置

### 各节点 cephadm 用户添加 sudo 权限

```shell
useradd cephadm
echo '111111' | passwd --stdin cephadm
echo "cephadm ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/cephadm
chmod 0440 /etc/sudoers.d/cephadm
```

### 在管理节点上以 cephadm 用户的身份来做各节点 ssh 免密登录

```shell
su - cephadm
ssh-keygen -t rsa -P ''
ssh-copy-id cephadm@node1
ssh-copy-id cephadm@node2
ssh-copy-id cephadm@node3
```

### 安装依赖，否则会出现缺少依赖的错误

yum install -y yum-utils && yum-config-manager --add-repo https://dl.fedoraproject.org/pub/epel/7/x86_64/ && yum install --nogpgcheck -y epel-release && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 && rm -f /etc/yum.repos.d/dl.fedoraproject.org\*

管理节点安装 ceph-deploy

```shell
yum install ceph-deploy  python-setuptools python2-subprocess32 ceph-common
```

管理节点以 cephadm 用户身份在家目录建立 ceph-cluster 目录

```
su - cephadm
mkdir ceph-cluster
```

切换至 ceph-cluster 目录

```shell
cd ceph-cluster
```

## Mon 安装

在管理节点以 cephadm 用户运行

```shell
ceph-deploy new ceph-mon1 --cluster-network 192.168.100.0/24  --public-network 192.168.200.0/24
#mon节点，可以写第一个，也可以写多个
```

然后在所有节点——mon、mgr、osd 都要安装，一定要把源的地址改成阿里云的，不然卡半天，翻墙都没用。

```
sudo yum install ceph ceph-radosgw -y
```

在管理节点以 cephadm 用户运行

````shell
cd ceph-cluster
ceph-deploy install --no-adjust-repos node1 node2 node3

在管理节点以cephadm用户运行

```shell
ceph-deploy mon create-initial
#这一步其实是在生成keyring文件
````

在管理节点以 cephadm 用户运行

```shell
ceph-deploy admin ceph-mon1 ceph-mon2 ceph-mon3 ceph-osd4
#将配置和client.admin秘钥环推送到远程主机。
#每次更改ceph的配置文件，都可以用这个命令推送到所有节点上
```

在所有节点以 root 的身份运行

```shell
setfacl -m u:cephadm:r /etc/ceph/ceph.client.admin.keyring
#ceph.client.admin.keyring文件是 ceph命令行 所需要使用的keyring文件
#不管哪个节点，只要需要使用cephadm用户执行命令行工具，这个文件就必须要让cephadm用户拥有访问权限，就必须执行这一步
#这一步如果不做，ceph命令是无法在非sudo环境执行的。
```

## Mgr 部署

```shell
su - cephadm
cd ceph-cluster
ceph-deploy mgr create ceph-mon1
```

执行完成之后，在管理节点查看集群的健康状态，不过，这一步同样需要/etc/ceph/ceph.client.admin.keyring 文件

```shell
su - cephadm
sudo cp ceph-cluster/{ceph.client.admin.keyring,ceph.conf} /etc/ceph/
ceph -s
```

### mgr dashboard 启用

1. 开启 mgr 功能 `ceph mgr module enable dashboard`
2. 创建证书 `ceph dashboard create-self-signed-cert`
3. 创建用户和登录密码 `ceph dashboard set-login-credentials admin admin`
4. 查看服务访问方式 `ceph mgr services`
5. 在/etc/ceph/ceph.conf 中添加
   [mgr]
   mgr modules = dashboard
6. 设置 dashboard 的 ip 和端口

```
ceph config-key put mgr/dashboard/server_addr  172.18.63.111
ceph config-key put mgr/dashboard/server_port 7000
```

7. 在浏览器中访问即可

# 使用

## pool 的使用

### pool 的含义

Pool 是 ceph 中的存储池的盖南，要想使用 ceph 的存储功能，必须先创建存储池；是存储对象的逻辑分区，它规定了数据冗余的类型和对应的副本分布策略；支持两种类型：副本（replicated）和 纠删码（ Erasure Code）。

对于 pool、osd、pg 的理解大致如下：
osd 是管理物理磁盘的，而 pg 是一个放置策略组，相同 pg 内的对象会放置在相同的磁盘上，务端数据均衡和恢复的最小粒度就是 pg。

- 一个 pool 里可以有多个 pg
- 一个 pg 包含多个对象，一个对象只能属于一个 pg
- pg 有主从之分，一个 pg 分布在不同的 osd 上（针对多副本）

### pool 的创建

`ceph osd pool create mypool 64 64` 此命令的含义是创建了一个名为 mypool，pg 数量是 64 的存储池，的 完整的创建命令如下：
`osd pool create <poolname> <int[0-]> {<int[0-]>} {replicated|erasure} {<erasure_code_profile>} {<rule>} {<int>}`
`ceph osd pool application enable mypool rbd` 根据pool的使用不同需要分配不同的application,完整命令集含义如下
`osd pool application enable <poolname> <app> {--yes-i-really-mean-it}    enable use of an application <app> [cephfs,rbd,rgw] on pool <poolname>`

<!-- TODO 待完善内容 -->

## cephFS 的使用

1. 首先在 admin 节点上创建 mds 服务`ceph-deploy mds create node1 node2 node3`
2. 创建存储池`ceph osd pool create fs_data 32`
3. 创建元数据池`ceph osd pool create fs_metadata 32`
4. 创建名为 fs 的文件系统`ceph fs new fs fs_data fs_metadata`
5. 使用客户端挂载文件系统

- 安装 ceph-fuse `yum install ceph-fuse`
- 将 ceph.conf 和 ceph.client.admin.keyring 文件拷贝到客户端机器的/etc/ceph/目录下
- 在客户端目录创建测试文件夹`mkdir /test`
- 使用命令连接 cephfs `ceph-fuse -m 172.18.63.111,172.18.63.112,172.18.63.113:6789 /test`
- 拷贝文件至test文件夹，在另一台客户端机器上查看是否有此文件，目前cephfs的默认是一个，可使用命令建立多个。

## rdb的使用
块设备是ceph中使用最多的一种方式，下面讲下怎么使用
1. 创建pool存储池
2. 创建images对象`rbd create mypool/image --image-feature layering --size 10G`
3. 镜像伸缩容`rbd resize --size 15G mypool/image`，此操作后还需要在挂载的磁盘上进行扩容的操作
4. 删除镜像`rbd rm mypool/image`
5. 客户端挂载镜像
* 安装客户端`yum install ceph-common`
* 执行挂载镜像命令`rbd map mypool/image`
* 查看磁盘`lsblk`或`rbd showmapped`
* 上述命令的作用就像是给机器新加了一块磁盘，因此需要格式化、挂载后才能使用
6. 镜像添加快照`rbd snap create mypool/image --snap image-sn1`
7. 查看镜像快照`rbd snap ls mypool/image`
8. 删除镜像快照`rbd snap remove`
9. 还原镜像快照`rbd snap rollback`,需要重新挂载文件系统

## rgw对象存储的使用

1. 安装对象存储网关`ceph-deploy install --rgw node1`
2. 创建rgw实例`ceph-deploy  [--overwrite-conf] rgw create node1`，--overwrite可选，如果提示配置文件冲突，可添加此参数
3. 成功后可查看到在7480端口上可以访问
4. 创建有权限的用户`radosgw-admin user create --uid="admin" --display-name="admin"`,保留access_key和secret_key
"access_key": "EVK7AQ36LND5L8C11C2R",
"secret_key": "xXiBZn8v7plELwmAghMd9UZjjTAwNzoGeNtYiEfc"
5. 使用s3客户端进行访问测试，配置好.s3cfg文件，修改host_base 和host_bucket 的内容
6. s3cmd 创建bucket并上传文件  `s3cmd mb s3://test` `s3cmd put ceph.conf s3://test`

### mgr dashboard中的 Object Gateway 配置
可以使用上面的admin来连接，也可新建用户进行连接
具体配置信息可参考![官网文档](https://docs.ceph.com/docs/mimic/mgr/dashboard/#enabling-the-object-gateway-management-frontend)，此处不做解释
```
radosgw-admin user create --uid=system --display-name=system  --system
ceph dashboard set-rgw-api-access-key VH9L1XY18PKEX7AECPSN
ceph dashboard set-rgw-api-secret-key TRexoIvxMEFKvsEmBMykgfY0XeGQEBxM2rg8 
ceph dashboard set-rgw-api-host 172.18.63.111
ceph dashboard set-rgw-api-port 7480
ceph dashboard set-rgw-api-scheme http
ceph dashboard set-rgw-api-admin-resource all
ceph dashboard set-rgw-api-user-id system
ceph dashboard set-rgw-api-ssl-verify False
# 需要重启mgr dashboard
ceph mgr module disable dashboard
ceph mgr module enable dashboard
```

## k8s集群接入ceph
使用mypool这个pool作为自动配置的pvc
1. 创建用于k8s集群连接secret，可新建用户也可使用目前的admin用户
* 将此用户的密码进行base64加密`ceph auth get-key client.admin | base64`
* 编写secret.yaml
```
apiVersion: v1
kind: Secret
metadata:
  name: storage-secret
  namespace: default
data:
  key: QVFEOHc3aGVVZGRyS1JBQXVEUWxhK1RnTFYvbmVQbjVwM0I3SXc9PQ==
type:
  kubernetes.io/rbd
```
2. 编写storageclass用于pvc的动态创建
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph
  namespace: default
  annotations:
   storageclass.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/rbd
reclaimPolicy: Retain
parameters:
  monitors: 172.18.63.111:6789
  adminId: admin
  adminSecretName: storage-secret
  adminSecretNamespace: default
  pool: mypool
  fsType: xfs
  userId: admin
  userSecretName: storage-secret
  imageFormat: "2"
  imageFeatures: "layering"
```
3. 测试ceph的使用
随便建一个pvc的连接，查看是否可以成功bound，以及ceph对应的pool中是否有此image