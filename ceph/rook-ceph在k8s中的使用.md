
> https://rook.io/docs/rook/v1.1/ceph-examples.html rook-ceph官方指导

> https://github.com/rook/rook/tree/master/cluster/examples/kubernetes/ceph github项目地址

> gitlab上传的附件

## cluster.yaml修改的内容

1. 修改 hostNetwork: true，设为false后运行一段时间出现osd掉线的情况，可能是内部网络的问题
2. 修改 node的调度策略，只要ceph-osd为enabled的node才可调度osd的pod，其他类似
   ```
    osd:
     nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: ceph-osd
              operator: In
              values:
              - enabled
    ```
3. 选择node运行的存储
   ```
   - node:
    - name: "k8s-node03"
      devices: # specific devices to use for storage can be specified for each node
      - name: "vdb"
   ```
4. 开启mgr dashbord
   ```
    dashboard:
        enabled: true
   ```
        

## rbd的使用
执行storageclass-delete.yaml文件，此文件大致执行如下内容：
1. 创建pool
2. 创建storageclass
	* 目前的版本中可使用两种方式使用storageclass，flexvolumn和csi模式
	* flexvolum为插件模式
	* csi即CSI container storage insterface 容器存储接口
	* 官方对此两种的使用方式为
    > The storage classes are found in different sub-directories depending on the driver:
    >
    > csi/rbd: The CSI driver for block devices. This is the preferred driver going forward.
    > 
    > flex: The flex driver will be deprecated in a future release to be determined.

    * 所以此处使用csi这种面向未来的方式
  
3. xfs和ext4的选择，centos7.2后的标准文件系统为xfs，详细可查看ext4和xfs的区别
4. reclaimPolicy: Delete选择为Delete，在删除pvc后可直接删除对应的pv，默认此选项供测试使用
5. 另一种模式为Retained，只删除pvc让不会对pv有任何的操作，需要手动删除
6. 需要注意的是rbd模式只支持RWO模式，ReadWriteOnce
7. 动态存储卷调用实例
    ```
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
    name: nginx-pvc
    spec:
    accessModes:
        - ReadWriteOnce
    resources:
        requests:
        storage: 1Gi
    storageClassName: rook-ceph
    ```
## cephfs的使用

有问题(略)

## object store对象存储的使用
1. 执行object-store.yaml文件，生成rgw pod
2. 执行storageclass-bucket-retain.yaml文件，生成storageclass存储
3. 执行ingress-rgw-mystore.yaml文件，将此对象存储映射出来可供访问
4. 执行cephobjstoreUser.yaml文件，生成对象存储的用户
   ```
    获取Access key
    kubectl get secret rook-ceph-object-user-my-store-admin -o yaml -n rook-ceph|grep AccessKey | awk '{print $2}' | base64 --decode
    获取Secret Key
    kubectl get secret rook-ceph-object-user-my-store-admin -o yaml -n rook-ceph|grep SecretKey | awk '{print $2}' | base64 --decode
   ```
5. 使用s3 browser访问对象存储
6. 使用s3 cmd访问对象存储
   * s3cmd --configure 生成配置文件
   * 修改生成的配置文件.s3cfg,需对应修改如下几项
    ```
    access_key = SH48VDNKNIIZT45TYO1P
    host_base = oss.jwt.com
    host_bucket = %(*)s.oss.jwt.com
    secret_key = wTjY1bU3UH4AvDB7w6s4VnP97O5IsoeWbEkxwCP2
    use_https = False
    ```  
    * 其他命令使用
    ```
    s3cmd ls 查看bucket列表
    s3cmd mb s3://my-bucket-name 创建bucket，且bucket名称是唯一的，不可重复
    s3cmd rb s3://my-bucket-name 删除空的bucket
    s3cmd rb s3://my-bucket-name 列举bucket中的内容
    s3cmd put file.txt s3://my-bucket-name/file.txt 上传文件到bucket的指定目录下
    s3cmd put ./* s3://my-bucket-name/ 批量上传
    s3cmd get s3://my-bucket-name/file.txt file.txt 下载bucket中的指定文件
    s3cmd get s3://my-bucket-name/* ./ 批量下载
    s3cmd del s3://my-bucket-name/file.txt 删除bucket中的文件
    ```
    * 其他使用方式 https://docs.aws.amazon.com/zh_cn/AmazonS3/latest/dev/Introduction.html
7. 设置mgr dashbord中的object gateway,根据官方设置，未成功
>Enabling Dashboard Object Gateway managementProvided you have deployed the Ceph Toolbox, created an Object Store and a user, you can enable Object Gateway management by providing the user credentials to the dashboard:

>Access toolbox CLI:
>kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash

>Enable system flag on the user:
>radosgw-admin user modify --uid=my-user --system

>Provide the user credentials:
>ceph dashboard set-rgw-api-user-id my-user
>ceph dashboard set-rgw-api-access-key <access-key>
>ceph dashboard set-rgw-api-secret-key <secret-key> -->
  
## rook-ceph-tools使用
1. 执行toolbox.yaml，生成rook-ceph-tools-xxxx pod
2. 使用kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
` 命令进入ceph的管理中

3. ceph常用命令
    ```
    ceph -s 查看集群状态
    ceph osd status 查看osd状态
    ceph pg stat 查看pg状态
    ceph osd pool set pool pg_num 64 设置pg数量
    ceph osd pool set pool pgp_num 64 设置pgp数量，在集群规模较小，pg数量过少会导致监控警告，此两条命令需一起使用
    ```

