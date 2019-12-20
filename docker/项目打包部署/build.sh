#!/bin/bash
# 2018/12/22 08:00:29

DOCKER_REGISTRY='172.18.61.24'
CITY='jiangsu'
PROJECT_NAME='service.statistics'

bin=`dirname "${BASH_SOURCE-$0}"`
bin=`cd "$bin"; pwd`

# dev qa prod
case "$1" in
  'dev')
    ;;
  'qa')
    ;;
  'prod')
    ;;
  *)
    echo "docker build args error $1"
    exit 1
esac

ENV=$1

rm -rf *.jar
cp -rf ../../sttp-service-statistics-1.8-SNAPSHOT.jar .

### 
docker rmi      ${DOCKER_REGISTRY}/${CITY}/${PROJECT_NAME}.${ENV}
docker rmi      ${CITY}/${PROJECT_NAME}.${ENV}
docker build -t ${CITY}/${PROJECT_NAME}.${ENV} .

docker tag ${CITY}/${PROJECT_NAME}.${ENV} ${DOCKER_REGISTRY}/${CITY}/${PROJECT_NAME}.${ENV}

docker push ${DOCKER_REGISTRY}/${CITY}/${PROJECT_NAME}.${ENV}


rm -rf *.jar