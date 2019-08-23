#!/bin/bash
#
docker run -d \
  -p 3000:3000 \
  -e INFLUXDB_HOST=influxdb \
  -e INFLUXDB_PORT=8086 \
  -e INFLUXDB_NAME=caddvisor \
  -e INFLUXDB_PASS=cadvisor \
  --link influxdb:influxsrv \
  grafana/grafana
