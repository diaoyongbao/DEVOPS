#!/bin/bash

bin=`dirname "${BASH_SOURCE-$0}"`
bin=`cd "$bin"; pwd`
#echo "bin=$bin"

JAVA_OPTS="-Xms1024m -Xmx1024m"

DUBBO_OPTS="-Ddubbo.registry.address=zookeeper://${zk_ip}:${zk_port}"

JARBALL="$bin/../lib/sttp-service-statistics-1.8-SNAPSHOT.jar"
JDBC_URL="-Djdbc.url=jdbc:mysql://${mysql_ip}:${mysql_port}/jiangsu_statistics?useUnicode=true&characterEncoding=utf8&autoReconnect=true&serverTimezone=CTT&useSSL=false"

JDBC_USERNAME="-Djdbc.username=${mysql_user}"
JDBC_PASSWORD="-Djdbc.password=${mysql_pass}"
SERVER_PORT="30020"
DUBBO_APPLICATION_PORT="20020"
LOGSDIR="-DLOG_HOME=$bin/../"

DUBBO_APPLICATION_NAME="sttp-service-statistics"
DUBBO_SHUTDOWN_HOOK="-Ddubbo.shutdown.hook=true"

DUBBO_REGISTRY_FILE="-Ddubbo.registry.file=$bin/sttp-service-statistics.30000.properties"

REDIS_PASSWORD="-Dspring.redis.password="

MONGODB_HOST="-Dspring.data.mongodb.host=${mongo_ip}"
MONGODB_PORT="-Dspring.data.mongodb.port=${mongo_port}"
MONGODB_USERNAME="-Dspring.data.mongodb.username=sttp"
MONGODB_PASSWORD="-Dspring.data.mongodb.password=sttp@2018"
MONGODB_DATABASE="-Dspring.data.mongodb.database=sttp"

#REDIS_CLUSTER_ENABLE="-Dspring.redis.cluster.enable=true"
#REDIS_CLUSTER_NODES="-Dspring.redis.cluster.nodes=172.18.61.74:6000,172.18.61.74:6001,172.18.61.74:6002,172.18.61.74:6003,172.18.61.74:6004,172.18.61.74:6005"

REDIS_CLUSTER_ENABLE="-Dspring.redis.cluster.enable=true"
REDIS_CLUSTER_NODES="-Dspring.redis.cluster.nodes=${redis}"

# for dev
REDIS_HOST="-Dspring.redis.host=172.18.61.74"
REDIS_PORT="-Dspring.redis.port=6000"

REDIS_PREFIX="-Dspring.redis.namespace.prefix=dev"



CUSTOM_PARAMS=


ES_CLUSTER="-Des.cluster-nodes=${es}"
ES_SCHEME="-Des.scheme=http"


pidfile=/tmp/sttp-service-statistics.30000.pid

if [ -f $pidfile ]
then
  echo "process id: $DUBBO_APPLICATION_NAME already exist"
  exit 1
fi

SERVICE_RUNNING_OPTIONS="$JAVA_OPTS \
      $DUBBO_OPTS \
      -Dpid.file=$pidfile \
      -Dfile.encoding=utf-8 \
      -Duser.timezone=GMT+8 \
      -Duser.language=zh \
      -Duser.region=CN \
      -Ddubbo.ignore.path=sttp.common.dubbo.swagger.service.DubboSwaggerService,sttp.service.common.service.CommonService \
      $JDBC_URL \
      $JDBC_USERNAME \
      $JDBC_PASSWORD \
      -Dserver.port=$SERVER_PORT \
      -Ddubbo.application.port=$DUBBO_APPLICATION_PORT \
      -Ddubbo.application.name=$DUBBO_APPLICATION_NAME \
      $LOGSDIR \
      $DUBBO_SHUTDOWN_HOOK \
      $REDIS_CLUSTER_ENABLE $REDIS_PASSWORD $REDIS_CLUSTER_NODES $REDIS_HOST $REDIS_PORT $REDIS_PREFIX \
      $ES_CLUSTER $ES_SCHEME \
      $DUBBO_REGISTRY_FILE \
      $MONGODB_HOST \
      $MONGODB_PORT \
      $MONGODB_USERNAME \
      $MONGODB_PASSWORD \
      $MONGODB_DATABASE \
      $CUSTOM_PARAMS"

case "$1" in
  '-d')
    nohup java $SERVICE_RUNNING_OPTIONS -jar $JARBALL>/dev/null 2>&1 &
    ;;
  *)
    java $SERVICE_RUNNING_OPTIONS -jar $JARBALL
esac
