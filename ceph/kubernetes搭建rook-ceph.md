## 简介
- Rook官网：https://rook.io
- Rook是[云原生计算基金会](https://www.cncf.io/)(CNCF)的孵化级项目.
- Rook是Kubernetes的开源**云本地存储协调**器，为各种存储解决方案提供平台，框架和支持，以便与云原生环境本地集成。
- 至于CEPH，官网在这：https://ceph.com/
- ceph官方提供的helm部署，至今我没成功过，所以转向使用rook提供的方案
- 官方指导手册https://rook.io/docs/rook/v1.1/ceph-examples.html
 
---

## 环境

```
centos 7.5
kernel 4.18.7-1.el7.elrepo.x86_64

docker 18.06

kubernetes v1.12.2
    kubeadm部署：
        网络: canal
        DNS: coredns
    集群成员：    
    192.168.1.1 kube-master
    192.168.1.2 kube-node1
    192.168.1.3 kube-node2
    192.168.1.4 kube-node3
    192.168.1.5 kube-node4

所有node节点准备一块200G的磁盘：/dev/sdb

```

---

## 准备工作
- 所有节点开启ip_forward

```
cat <<EOF >  /etc/sysctl.d/ceph.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

```

## 开始部署Operator
- 部署Rook Operator

```
#无另外说明，全部操作都在master操作

cd $HOME
git clone https://github.com/rook/rook.git

cd rook
cd cluster/examples/kubernetes/ceph
kubectl apply -f operator.yaml

```

- 查看Operator的状态

```
#执行apply之后稍等一会。
#operator会在集群内的每个主机创建两个pod:rook-discover,rook-ceph-agent

kubectl -n rook-ceph-system get pod -o wide

```

## 给节点打标签

- 运行ceph-mon的节点打上：ceph-mon=enabled

```
kubectl label nodes {kube-node1,kube-node2,kube-node3} ceph-mon=enabled

```

- 运行ceph-osd的节点，也就是存储节点，打上：ceph-osd=enabled

```
kubectl label nodes {kube-node1,kube-node2,kube-node3} ceph-osd=enabled

```

- 运行ceph-mgr的节点，打上：ceph-mgr=enabled

```
#mgr只能支持一个节点运行，这是ceph跑k8s里的局限
kubectl label nodes kube-node1 ceph-mgr=enabled

```

---

## 配置cluster.yaml文件

- 官方配置文件详解：https://rook.io/docs/rook/v0.8/ceph-cluster-crd.html

- 文件中有几个地方要注意：
  - **dataDirHostPath**: 这个路径是会在宿主机上生成的，保存的是ceph的相关的配置文件，再重新生成集群的时候要确保这个目录为空，否则mon会无法启动
  - **useAllDevices**: 使用所有的设备，建议为false，否则会把宿主机所有可用的磁盘都干掉
  - **useAllNodes**：使用所有的node节点，建议为false，肯定不会用k8s集群内的所有node来搭建ceph的
  - **databaseSizeMB和journalSizeMB**：当磁盘大于100G的时候，就注释这俩项就行了

- 本次实验用到的 cluster.yaml 文件内容如下：

```
apiVersion: v1
kind: Namespace
metadata:
  name: rook-ceph
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: rook-ceph-cluster
  namespace: rook-ceph
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: rook-ceph-cluster
  namespace: rook-ceph
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: [ "get", "list", "watch", "create", "update", "delete" ]
---
# Allow the operator to create resources in this cluster's namespace
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: rook-ceph-cluster-mgmt
  namespace: rook-ceph
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: rook-ceph-cluster-mgmt
subjects:
- kind: ServiceAccount
  name: rook-ceph-system
  namespace: rook-ceph-system
---
# Allow the pods in this namespace to work with configmaps
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: rook-ceph-cluster
  namespace: rook-ceph
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: rook-ceph-cluster
subjects:
- kind: ServiceAccount
  name: rook-ceph-cluster
  namespace: rook-ceph
---
apiVersion: ceph.rook.io/v1beta1
kind: Cluster
metadata:
  name: rook-ceph
  namespace: rook-ceph
spec:
  cephVersion:
    # The container image used to launch the Ceph daemon pods (mon, mgr, osd, mds, rgw).
    # v12 is luminous, v13 is mimic, and v14 is nautilus.
    # RECOMMENDATION: In production, use a specific version tag instead of the general v13 flag, which pulls the latest release and could result in different
    # versions running within the cluster. See tags available at https://hub.docker.com/r/ceph/ceph/tags/.
    image: ceph/ceph:v13
    # Whether to allow unsupported versions of Ceph. Currently only luminous and mimic are supported.
    # After nautilus is released, Rook will be updated to support nautilus.
    # Do not set to true in production.
    allowUnsupported: false
  # The path on the host where configuration files will be persisted. If not specified, a kubernetes emptyDir will be created (not recommended).
  # Important: if you reinstall the cluster, make sure you delete this directory from each host or else the mons will fail to start on the new cluster.
  # In Minikube, the '/data' directory is configured to persist across reboots. Use "/data/rook" in Minikube environment.
  dataDirHostPath: /var/lib/rook
  # The service account under which to run the daemon pods in this cluster if the default account is not sufficient (OSDs)
  serviceAccount: rook-ceph-cluster
  # set the amount of mons to be started
  # count可以定义ceph-mon运行的数量，这里默认三个就行了
  mon:
    count: 3
    allowMultiplePerNode: true
  # enable the ceph dashboard for viewing cluster status
  # 开启ceph资源面板
  dashboard:
    enabled: true
    # serve the dashboard under a subpath (useful when you are accessing the dashboard via a reverse proxy)
    # urlPrefix: /ceph-dashboard
  network:
    # toggle to use hostNetwork
    # 使用宿主机的网络进行通讯
    # 使用宿主机的网络貌似可以让集群外的主机挂载ceph
    # 但是我没试过，有兴趣的兄弟可以试试改成true
    # 反正这里只是集群内用，我就不改了
    hostNetwork: false
  # To control where various services will be scheduled by kubernetes, use the placement configuration sections below.
  # The example under 'all' would have all services scheduled on kubernetes nodes labeled with 'role=storage-node' and
  # tolerate taints with a key of 'storage-node'.
  placement:
#    all:
#      nodeAffinity:
#        requiredDuringSchedulingIgnoredDuringExecution:
#          nodeSelectorTerms:
#          - matchExpressions:
#            - key: role
#              operator: In
#              values:
#              - storage-node
#      podAffinity:
#      podAntiAffinity:
#      tolerations:
#      - key: storage-node
#        operator: Exists
# The above placement information can also be specified for mon, osd, and mgr components
#    mon:
#    osd:
#    mgr:
# nodeAffinity：通过选择标签的方式，可以限制pod被调度到特定的节点上
# 建议限制一下，为了让这几个pod不乱跑
    mon:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: ceph-mon
              operator: In
              values:
              - enabled
    osd:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: ceph-osd
              operator: In
              values:
              - enabled
    mgr:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: ceph-mgr
              operator: In
              values:
              - enabled
  resources:
# The requests and limits set here, allow the mgr pod to use half of one CPU core and 1 gigabyte of memory
#    mgr:
#      limits:
#        cpu: "500m"
#        memory: "1024Mi"
#      requests:
#        cpu: "500m"
#        memory: "1024Mi"
# The above example requests/limits can also be added to the mon and osd components
#    mon:
#    osd:
  storage: # cluster level storage configuration and selection
    useAllNodes: false
    useAllDevices: false
    deviceFilter:
    location:
    config:
      # The default and recommended storeType is dynamically set to bluestore for devices and filestore for directories.
      # Set the storeType explicitly only if it is required not to use the default.
      # storeType: bluestore
      # databaseSizeMB: "1024" # this value can be removed for environments with normal sized disks (100 GB or larger)
      # journalSizeMB: "1024"  # this value can be removed for environments with normal sized disks (20 GB or larger)
# Cluster level list of directories to use for storage. These values will be set for all nodes that have no `directories` set.
#    directories:
#    - path: /rook/storage-dir
# Individual nodes and their config can be specified as well, but 'useAllNodes' above must be set to false. Then, only the named
# nodes below will be used as storage resources.  Each node's 'name' field should match their 'kubernetes.io/hostname' label.
#建议磁盘配置方式如下：
#name: 选择一个节点，节点名字为kubernetes.io/hostname的标签，也就是kubectl get nodes看到的名字
#devices: 选择磁盘设置为OSD
# - name: "sdb":将/dev/sdb设置为osd
    nodes:
    - name: "kube-node1"
      devices:
      - name: "sdb"
    - name: "kube-node2"
      devices:
      - name: "sdb"
    - name: "kube-node3"
      devices:
      - name: "sdb"

#      directories: # specific directories to use for storage can be specified for each node
#      - path: "/rook/storage-dir"
#      resources:
#        limits:
#          cpu: "500m"
#          memory: "1024Mi"
#        requests:
#          cpu: "500m"
#          memory: "1024Mi"
#    - name: "172.17.4.201"
#      devices: # specific devices to use for storage can be specified for each node
#      - name: "sdb"
#      - name: "sdc"
#      config: # configuration can be specified at the node level which overrides the cluster level config
#        storeType: filestore
#    - name: "172.17.4.301"
#      deviceFilter: "^sd."

```

---

## 开始部署ceph

- 部署ceph

```
kubectl apply -f cluster.yaml

# cluster会在rook-ceph这个namesapce创建资源
# 盯着这个namesapce的pod你就会发现，它在按照顺序创建Pod

kubectl -n rook-ceph get pod -o wide  -w

# 看到所有的pod都Running就行了
# 注意看一下pod分布的宿主机，跟我们打标签的主机是一致的

kubectl -n rook-ceph get pod -o wide

```

- 切换到其他主机看一下磁盘

  - 切换到kube-node1

  ```
  lsblk

  ```

  - 切换到kube-node3

  ```
  lsblk

  ```
  
---

## 配置ceph dashboard

- 看一眼dashboard在哪个service上

```
kubectl -n rook-ceph get service
#可以看到dashboard监听了8443端口
```

- 创建个nodeport类型的service以便集群外部访问

```
kubectl apply -f dashboard-external-https.yaml

# 查看一下nodeport在哪个端口
ss -tanl
kubectl -n rook-ceph get service

```

- 找出Dashboard的登陆账号和密码

```
MGR_POD=`kubectl get pod -n rook-ceph | grep mgr | awk '{print $1}'`

kubectl -n rook-ceph logs $MGR_POD | grep password

```

- 打开浏览器输入任意一个Node的IP+nodeport端口
- 这里我的就是：https://192.168.1.2:30290



## 配置ceph为storageclass

- 官方给了一个样本文件：storageclass.yaml
- 这个文件使用的是 **RBD 块存储**
- pool创建详解：https://rook.io/docs/rook/v0.8/ceph-pool-crd.html

```
apiVersion: ceph.rook.io/v1beta1
kind: Pool
metadata:
  #这个name就是创建成ceph pool之后的pool名字
  name: replicapool
  namespace: rook-ceph
spec:
  replicated:
    size: 1
  # size 池中数据的副本数,1就是不保存任何副本
  failureDomain: osd
  #  failureDomain：数据块的故障域，
  #  值为host时，每个数据块将放置在不同的主机上
  #  值为osd时，每个数据块将放置在不同的osd上
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: ceph
   # StorageClass的名字，pvc调用时填的名字
provisioner: ceph.rook.io/block
parameters:
  pool: replicapool
  # Specify the namespace of the rook cluster from which to create volumes.
  # If not specified, it will use `rook` as the default namespace of the cluster.
  # This is also the namespace where the cluster will be
  clusterNamespace: rook-ceph
  # Specify the filesystem type of the volume. If not specified, it will use `ext4`.
  fstype: xfs
# 设置回收策略默认为：Retain
reclaimPolicy: Retain


```

- 创建StorageClass

```
kubectl apply -f storageclass.yaml
kubectl get storageclasses.storage.k8s.io  -n rook-ceph
kubectl describe storageclasses.storage.k8s.io  -n rook-ceph

```


---

- 创建个nginx pod尝试挂载

```
cat << EOF > nginx.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: ceph


---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports: 
  - port: 80
    name: nginx-port
    targetPort: 80
    protocol: TCP

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /html
          name: http-file
      volumes:
      - name: http-file
        persistentVolumeClaim:
          claimName: nginx-pvc
EOF

kubectl apply -f nginx.yaml


```

- 查看pv,pvc是否创建了

```
kubectl get pv,pvc


# 看一下nginx这个pod也运行了
kubectl get pod

```

- 删除这个pod,看pv是否还存在

```
kubectl delete -f nginx.yaml

kubectl get pv,pvc
# 可以看到，pod和pvc都已经被删除了，但是pv还在！！！
```


--- 

## 添加新的OSD进入集群

- 这次我们要把node4添加进集群，先打标签

```
kubectl label nodes kube-node4 ceph-osd=enabled

```

- 重新编辑cluster.yaml文件

```
# 原来的基础上添加node4的信息

cd $HOME/rook/cluster/examples/kubernetes/ceph/
vi cluster.yam

```

- apply一下cluster.yaml文件

```
kubectl apply -f cluster.yaml

# 盯着rook-ceph名称空间,集群会自动添加node4进来

kubectl -n rook-ceph get pod -o wide -w
kubectl -n rook-ceph get pod -o wide
```

- 去node4节点看一下磁盘

```
lsblk
```

- 再打开dashboard看一眼




## 删除一个节点
- 去掉node3的标签

```
kubectl label nodes kube-node3 ceph-osd-

```

- 重新编辑cluster.yaml文件

```
# 删除node3的信息

cd $HOME/rook/cluster/examples/kubernetes/ceph/
vi cluster.yam

```

- apply一下cluster.yaml文件

```
kubectl apply -f cluster.yaml

# 盯着rook-ceph名称空间

kubectl -n rook-ceph get pod -o wide -w
kubectl -n rook-ceph get pod -o wide


# 最后记得删除宿主机的/var/lib/rook文件夹
```


## 常见问题
- 官方解答：https://rook.io/docs/rook/v0.8/common-issues.html

- **当机器重启之后，osd无法正常的Running，无限重启**

```
#解决办法：

# 标记节点为 drain 状态
kubectl drain <node-name> --ignore-daemonsets --delete-local-data

# 然后再恢复
kubectl uncordon <node-name>

```