# mariadb安装
## 系统环境
* centos 7.6
* mariadb 5.5.64

### cmake安装
- yum install cmake

### mariadb编译安装
- 指定安装文件的安装路径时常用的选项：
```
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql  #指定安装目录
-DMYSQL_DATADIR=/data/mysql # 指定数据目录
-DSYSCONFDIR=/etc  #指定配置文件位置
```
- 默认编译的存储引擎包括：csv、myisam、myisammrg和heap。若要安装其它存储引擎，可以使用类似如下编译选项：
```
-DWITH_INNOBASE_STORAGE_ENGINE=1
-DWITH_ARCHIVE_STORAGE_ENGINE=1
-DWITH_BLACKHOLE_STORAGE_ENGINE=1
-DWITH_FEDERATED_STORAGE_ENGINE=1
```
- 若要明确指定不编译某存储引擎，可以使用类似如下的选项：
```
-DWITHOUT_<ENGINE>_STORAGE_ENGINE=1
-DWITHOUT_EXAMPLE_STORAGE_ENGINE=1
-DWITHOUT_FEDERATED_STORAGE_ENGINE=1
-DWITHOUT_PARTITION_STORAGE_ENGINE=1
```
- 如若要编译进其它功能，如SSL等，则可使用类似如下选项来实现编译时使用某库或不使用某库：
-DWITH_READLINE=1
-DWITH_SSL=system
-DWITH_ZLIB=system
-DWITH_LIBWRAP=0
```
- 其它常用的选项：
```
-DMYSQL_TCP_PORT=3306
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock
-DENABLED_LOCAL_INFILE=1
-DEXTRA_CHARSETS=all
-DDEFAULT_CHARSET=utf8
-DDEFAULT_COLLATION=utf8_general_ci
-DWITH_DEBUG=0
-DENABLE_PROFILING=1
```
- 安装脚本
```
# 创建mysql用户
groupadd -r mysql
useradd -g mysql -r -d /mysql/data mysql
# 解压缩
tar zxvf mariadb-5.5.64.tar.gz
cd /mariadb-5.5.64-x86_64
# 使用cmake编译安装
cmake  -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/mysql/data -DSYSCONFDIR=/etc -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DWITH_SSL=system -DWITH_ZLIB=system -DWITH_LIBWRAP=0 -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci
make
make install
```
###启动并初始化
```
chown -R mysql.mysql /usr/local/mysql
# 数据初始化
./scripts/mysql_install_db --user=mysql --datadir=/mysql/data
# 复制配置文件
cp support-files/my-large.cnf /etc/my.cnf
# 复制service文件
cp support-files/mysql.server /etc/rc.d/init.d/mysqld
chmod +x /etc/rc.d/init.d/mysqld
chkconfig -add mysqld
service mysqld start
# 客户端连接
ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
# 初始化
/usr/local/mysql/bin/mysql_secure_installation

1. 设置root管理员在数据库中的密码值（注意，该密码并非root管理员在系统中的密码，这里的密码值默认应该为空，可直接按回车键）。
2. 设置root管理员在数据库中的专有密码。
3. 随后删除匿名账户，并使用root管理员从远程登录数据库，以确保数据库上运行的业务的安全性。
4. 删除默认的测试数据库，取消测试数据库的一系列访问权限。
刷新授权列表，让初始化的设定立即生效


### 使用rpm包的安装方式

 
## Mariadb备份
### 备份策略
- 备份的意义
灾难恢复：硬件故障、软件故障、自然灾害、黑客攻击；误操作；
- 备份类型
    - 完全备份：
    - 增量备份：
    - 差异备份：
    - 热备：
    - 温备：
    - 冷备：
- 备份工具及备份方案
    1. mysqldump+binlog: mysqldump：完全备份，通过备份二进制日志实现增量备份；
    1. lvm2快照+binlog：几乎热备，物理备份
    1. xtrabackup: 
			对InnoDB：热备，支持完全备份和增量备份
			对MyISAM引擎：温备，只支持完全备份
### 基于文件系统的冷备
 停止服务，使用tar、cp等命令对mysql的data文件夹进行打包、压缩、拷贝

### 使用lvm2实现的快照备份
 - lvm2配置略
 - 将lvm存储卷挂载到/mydata文件夹下，将mysql的/data文件数据存放到/mydata文件夹下，重启mysql服务
 - 施加全局写锁，使用lvm的快照命令对/mydata文件夹进行备份，释放全局写锁。
## 热备
### 使用mysqldump对innodb存储引擎进行热备
    - mysqldump [options] [db_name [tbl_name ...]] 不会自动创建create database语句
    - mysqldump [options] --databases db_name ...  自动创建create databases语句
    - mysqldump [options] --all-databases
    - 使用--single-transaction 对innodb进行热备
### 使用xtrabackup对数据库进行备份
- 下载安装
    1. 进入[https://www.percona.com/downloads/Percona-XtraBackup-LATEST/]进行下载，选择对应系统的版本即可，选择2.4版本，mysql8.0及往后可选择8.0版本
    1. yum localinstall -y percona-xtrabackup-24-2.4.14-1.el7.x86_64.rpm
- 备份
    1. 完全备份
    `# innobackupex --user=root --password=Admin1234  ~/backup/`
    此命令会在/root/backup文件夹下生成当前日期命名的文件夹
- 还原
    1. 整理
    `innobackupex --apply-log 2019-06-18_21-18-42/`
    1. 恢复
   `innobackupex --copy-back 2019-06-18_21-18-42/`
    1. 改变data文件夹属主属组,否则服务启动不了
    `chown -R mysql.mysql *`







### 出现的问题
- 缺少ncurses-devel和openssl-devel，使用yum安装即可。

- CMake Error: cmake_symlink_library: System Error: Protocol error
不要在windows的共享文件夹中编译

