#!/bin/sh
# 编译安装
groupadd -r mysql
useradd -g mysql -r -d /mysql/data mysql
cd /vagrant/mariadb-5.5.64-linux-x86_64
cmake  -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/mysql/data -DSYSCONFDIR=/etc -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DWITH_SSL=system -DWITH_ZLIB=system -DWITH_LIBWRAP=0 -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci
make
make install

# 启动
chown -R mysql.mysql /usr/local/mysql
./scripts/mysql_install_db --user=mysql --datadir=/mysql/data
cp support-files/my-large.cnf /etc/my.cnf
cp support-files/mysql.server /etc/rc.d/init.d/mysqld
chmod +x /etc/rc.d/init.d/mysqld
chkconfig -add mysqld
service mysqld start

# 客户端连接
ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
# 初始化
/usr/local/mysql/bin/mysql_secure_installation
# 常用管理员命令
# 授权远程访问
grant all privileges on *.* to 'root'@'%' identified by 'Admin1234' with grant option;
# 刷新数据库
FLUSH PRIVILEGES;

# docker运行mysql
docker run -d -p 3306:3306 --name mysql -e  MYSQL_ROOT_PASSWORD=123456  mysql 


# mysql常用命令
## 事件日志查看

# mysqldunp备份工具使用
# mysqldump [OPTIONS] database [tables]：备份单个库，或库指定的一个或多个表
# mysqldump [OPTIONS] --databases [OPTIONS] DB1 [DB2 DB3...]：备份一个或多个库
# mysqldump [OPTIONS] --all-databases [OPTIONS]：备份所有库
mysqldump -uroot -p  --databases zabbix > /root/backup/zabbix.sql

# 备份文件的还原，mysql导入表
# 进入mysql客户端使用source命令
# mysql[xxx]> source /Path/file
source /root/backup/zabbix.sql
# 未进入mysql命令行模式下的表导入，需检查sql文件中的库与命令要导入的库是否一致
mysql -uroot -pAdmin1234 ydyw < /root/backup/zabbix.sql 

