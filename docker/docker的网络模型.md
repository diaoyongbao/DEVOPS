# 网络名称空间的使用
net namespaces是6个名称空间中的一个，可用于隔离网络设备和服务，只有拥有同样网络名称空间的设备猜能看到彼此。而构造一个网络名称空间只需要用到ip netns及ip link相关的子命令即可，下面是一些简单用法。
```
ip netns add n1 #添加一个网络名称空间
ip netns add n2 
ip netns list   #查看当前的网络名称空间
ip link add name veth1.1 t
ype veth peer name veth1.2 #创建一对虚拟网卡
ip link show  #查看当前的网络接口
ip link set dev veth1.1 netns n1 #将veth1.1接到n1名称空间中,同样的方式设置veth1.2
ip netns exec n1 ip link set dev veth1.1 name eth0 #将n1名称空间的veth1.1命名为eth0
ip netns exec n1 ifconfig eth0 10.0.0.1/24 up #设置n1名称空间中的网络地址并激活使用
ip netns exec n2 ifconfig eth0 10.0.0.2/24 up
ip netns exec n2 ping 10.0.0.1 #测试两个名称空间的网络
```
# docker的四种网络模型

* none模式，使用--network none指定
* bridge模式，使用--network bridge指定
* container模式，使用--network container:CNAME_CID指定
* host模式，使用--network host指定

## none模式
此模式中，docker容器拥有自己的network namespace，但是不创建任何网络设备，仅有lo网络，即为封闭式容器。

```
docker run -it --network none busybox:latest
/ # ifconfig
lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

## bridge模式(默认)
docker安装后会默认启用172.17.0.1/16的网络，并创建docker0网桥作为网关，使用此网络创建的容器会生成一对以veth开头的虚拟网卡，一半在容器中，一半在docker0桥上，此方式实现了容器与宿主机间的通信。docker0桥是NAT桥，因此容器获得的是私有网络地址，可将容器想象为主机NAT服务背后的主机，如果开发容器或其上的服务为外部网络访问，需要在宿主机上为其定义DNAT规则。
* 对宿主机某IP地址的访问全部映射给某容器地址
    
    `-A PREROUTING -d 主机IP -j DNAT --to-destination 容器IP`
* 对宿主机某IP地址的某端口的访问映射给某容器地址的某端口
   
    `-A PREROUTING -d 主机IP -p [tcp|udp] --dport 主机端口 -j DNAT --to-destination 容器IP:容器PORT`

```
[root@node01 ~]# docker run -it -d -p 80:80 nginx:1.14-alpine
9e0c8389537082bc2dd2b03e4386d57e12a3f084ff4f464ae8234f4e313a1c29
[root@node01 ~]# docker exec -it 9e0c /bin/sh
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:02  
          inet addr:172.17.0.2  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:656 (656.0 B)  TX bytes:0 (0.0 B)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
Chain POSTROUTING (policy ACCEPT 6 packets, 360 bytes)
 pkts bytes target     prot opt in     out     source               destination             
    0     0 MASQUERADE  tcp  --  *      *       172.17.0.2           172.17.0.2           tcp dpt:80
```

## container模式
又称联盟式容器，此模式下，新创建的容器会使用指定容器的net、ipc、uts名称空间，基于lo进行互相通信，而mount、user、pid名称空间依旧是隔离的。

```
docker run -it --network container:c8dddac96e38 busybox:latest  #创建一个容器连接到上一个容器中
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:02  
          inet addr:172.17.0.2  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:9 errors:0 dropped:0 overruns:0 frame:0
          TX packets:5 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:698 (698.0 B)  TX bytes:334 (334.0 B)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

/ # wget -O - -q localhost
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
```

## host模式
共享宿主机的网络名称空间，容器不会虚拟自己的网卡设备及ip地址,而直接使用宿主机的ip地址与外部进行通信，且不需要任何NAT转换。

```
[root@node01 ~]# docker run -it -d --network host nginx:1.14-alpine 
9fd88c8dc7ed7c3489e5202f4809f29f0266e369ec82b030da5099eb38514374
[root@node01 ~]# docker exec -it 9fd88 /bin/sh
/ # ifconfig
docker0   Link encap:Ethernet  HWaddr 02:42:08:64:66:20  
          inet addr:172.17.0.1  Bcast:172.17.255.255  Mask:255.255.0.0
          inet6 addr: fe80::42:8ff:fe64:6620/64 Scope:Link
          UP BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:42 errors:0 dropped:0 overruns:0 frame:0
          TX packets:56 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:6302 (6.1 KiB)  TX bytes:4053 (3.9 KiB)

enp0s8    Link encap:Ethernet  HWaddr 08:00:27:56:C7:9D  
          inet addr:172.28.128.6  Bcast:172.28.128.255  Mask:255.255.255.0
          inet6 addr: fe80::4b03:37d0:c28d:ccd5/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:8669 errors:0 dropped:0 overruns:0 frame:0
          TX packets:35690 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:958944 (936.4 KiB)  TX bytes:2761926 (2.6 MiB)

eth0      Link encap:Ethernet  HWaddr 08:00:27:29:73:07  
          inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fe29:7307/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:3458 errors:0 dropped:0 overruns:0 frame:0
          TX packets:3076 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:1333104 (1.2 MiB)  TX bytes:268337 (262.0 KiB)
```

# docker桥的其他用法
## 修改docker0桥的默认IP
1. 在/etc/docker/daemon.json配置文件中添加
`"bip":"10.0.0.1/16"`
1. 重启docker服务`systemctl restart docker`
1. 使用`ifconfig`查看docker0的地址

## 添加一个新的docker桥

```
docker network create -d bridge --subnet "192.168.0.0/24" --gateway "192.168.0.1" mybr  #添加一个叫mybr的桥，子网为192.168.0.0/24
docker network ls  #查看当前的网络
NETWORK ID          NAME                DRIVER              SCOPE
ea08a5af48d4        bridge              bridge              local
206de06c064a        host                host                local
df506bd1407b        mybr                bridge              local
c25bc3fc6dde        none                null                local
docker run -it --network mybr busybox # 创建一个容器并加入此网桥
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:C0:A8:00:02  
          inet addr:192.168.0.2  Bcast:192.168.0.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:13 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:1102 (1.0 KiB)  TX bytes:0 (0.0 B)
```