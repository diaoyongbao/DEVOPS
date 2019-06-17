# zabbix
## zabbix介绍

## zabbix安装
参考文档：https://www.zabbix.com/download?zabbix=4.0&os_distribution=centos&os_version=7&db=mysql
1. 创建zabbix的repo文件

    ```
    # rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm
    # yum clean all
    ```

1. 安装zabbix服务，前台及agent
`# yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-agent`

1. 创建数据库及加载表
    ```
    mysql> create database zabbix character set utf8 collate utf8_bin;
    mysql> grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';
    mysql> quit;
    # zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix
    ```
1. 修改配置文件
    ```
    /etc/zabbix/zabbix_server.conf
    DBPassword=zabbix
    /etc/httpd/conf.d/zabbix.conf
    php value data.timezone Asia/Shanghai

    ```
1. 启动服务
```
# systemctl restart zabbix-server zabbix-agent httpd
# systemctl enable zabbix-server zabbix-agent httpd
```

## zabbix简单使用
1. 访问地址
`http://server_ip_or_name/zabbix `
1. 修改中文
    点击右上用户头像，进行语言设定，选择chinese即可


## zabbix进阶