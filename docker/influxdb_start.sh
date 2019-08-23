#!/bin/bash
#
docker run -d -p 8086:8086 -p 8083:8083 \
    -e INFLUXDB_ADMIN_ENABLED=true \
    --name influxdb tutum/influxdb
