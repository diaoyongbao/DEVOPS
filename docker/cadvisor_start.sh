docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --link influxdb:influxsrv \
  google/cadvisor:latest \
  -storage_driver=influxdb \
  -storage_driver_db=cadvisor \
  -storage_driver_host=influxsrv:8086
