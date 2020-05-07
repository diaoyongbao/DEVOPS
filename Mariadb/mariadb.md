参照 innobackupex 对此镜像进行修改，增加功能
docker images

innobackupex  备份的原理
redolog idb 文件拷贝




innobackupex --host=172.18.63.113 --user=root --password=root@nj --databases=jiangsu_demand /data/backup/

 docker run -it -v $pwd:/target -v /data/mysql/data/:/data/mysql/data  -e MYSQL_HOST=172.18.63.113 -e MYSQL_USER=root -e MYSQL_PASSWORD=root@nj ipunktbs/xtrabackup run innobackupex --host=172.18.63.113 --user=root --password=root@nj --databases=jiangsu_demand /target