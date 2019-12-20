FROM 172.18.61.24/base/java
MAINTAINER xuwannian
# 开发的姓名
RUN mkdir -pv /jstec/bin
RUN mkdir -pv /jstec/lib

ENV zk_ip=${zk_ip:-172.18.61.74} \ 
    zk_port=${zk_port:-2181}   \
    mysql_ip=${mysql_ip:-172.18.61.57} \
    mysql_port=${mysql_port:-8066} \
    mysql_user=${mysql_user:-root} \
    mysql_pass=${mysql_pass:-root@nj} \
    mongo_ip=${mongo_ip:-172.18.61.57} \
    mongo_port=${mongo_port:-27017}  \
    es=${es:-172.18.61.58:9200} \
    redis=${redis:-172.18.61.74:6000,172.18.61.74:6001,172.18.61.74:6002,172.18.61.74:6003,172.18.61.74:6004,172.18.61.74:6005}

ADD start.sh /jstec/bin/start.sh
ADD sttp-service-statistics-1.8-SNAPSHOT.jar /jstec/lib/sttp-service-statistics-1.8-SNAPSHOT.jar

CMD sh /jstec/bin/start.sh

