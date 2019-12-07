使用kubeadm安装k8s 1.15.3 版本
====================
## 环境初始化
1. docker安装(略)
1. 使用yum安装kubeadm,kubelet,kubectl,配置yum源(略)
`yum install -y  kubelet kubeadm kubectl`
1. 设置bridge-nf-call-iptables
`echo "1" >  /proc/sys/net/bridge/bridge-nf-call-ip6tables`
`echo "1" >  /proc/sys/net/bridge/bridge-nf-call-iptables`
1. 查看需要的image文件
`kubeadm config images list`
1. 禁用交换分区
```
swapoff -a
vim /etc/fstab
    #/dev/mapper/centos-swap swap                    swap    defaults        0 0
vim /etc/sysconfig/kubelet
    KUBELET_EXTRA_ARGS="--fail-swap-on=false"
```

## 安装
```
kubeadm init  --image-repository registry.aliyuncs.com/google_containers --kubernetes-version=v1.15.3 --pod-network-cidr=10.10.0.0/16  --service-cidr=10.20.0.0/12 --apiserver-advertise-address=172.28.128.3
# --image-repository registry.aliyuncs.com/google_containers 设置阿里镜像源
# --kubernetes-version=v1.15.3  设置k8s版本
# --pod-network-cidr=10.10.0.0/16 --service-cidr=10.20.0.0/12 设置pod的子网地址和service 的子网地址
# --apiserver-advertise-address=172.28.128.3 设置为本机网卡IP地址
>>>
To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.28.128.3:6443 --token vwdg2q.30zc380zz9lia98p \
    --discovery-token-ca-cert-hash sha256:d5f93bb4c2eabe5986d575b808b91dc7be9bcb22eafd93d67c00a3abb4ed0bfd 

## kubectl认证,root用户
export KUBECONFIG=/etc/kubernetes/admin.conf
## 非root用户
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
## 部署flannel网络插件
1. 获取kube-flannel.yaml文件https://github.com/coreos/flannel/blob/master/Documentation/kube-flannel.yml
1. 根据文件中的flannel版本下载镜像 https://quay.io/repository/coreos/flannel
或使用`docker pull quay.io/coreos/flannel:v0.11.0-arm64`
1. 部署flannel
`kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`

## 添加node节点
1. 同上环境初始化
1. 使用`kubeadm join 172.28.128.3:6443 --token vwdg2q.30zc380zz9lia98p \
    --discovery-token-ca-cert-hash sha256:d5f93bb4c2eabe5986d575b808b91dc7be9bcb22eafd93d67c00a3abb4ed0bfd ` 加入master节点
1. 查看节点信息
`kubectl get node`