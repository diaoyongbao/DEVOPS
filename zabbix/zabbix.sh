#!/bin/bash
# description:zabbix服务的启停脚本

systemctl start zabbix-server
systemctl start zabbix-agent
systemctl start zabbix-java-gateway

zabbix_get -s IP -k "KEY_"