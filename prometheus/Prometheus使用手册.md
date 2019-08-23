# Promethus 实战
> 手册https://songjiayang.gitbooks.io/prometheus/
## 核心组件
* Prometheus Server， 主要用于抓取数据和存储时序数据，另外还提供查询和 Alert Rule 配置管理。
* client libraries，用于对接 Prometheus Server, 可以查询和上报数据。
* push gateway ，用于批量，短期的监控数据的汇总节点，主要用于业务数据汇报等。
* 各种汇报数据的 exporters ，例如汇报机器数据的 node_exporter, 汇报 MongoDB 信息的 MongoDB exporter 等等。
* 用于告警通知管理的 alertmanager 
## Promethus 安装使用
*   解压安装
`tar zxvf prometheus-*.tar.gz -C /usr/local`
*   启动默认服务`nohup ./promethes --config.file="prometheus.yml"`
*   访问服务，默认配置访问0.0.0.0:9090/graph,收集的数据可访问/metrics


## 配置文件说明
```
# 全局配置项
global:
  scrape_interval:     15s # 设定抓取数据的周期，默认为1min
  evaluation_interval: 15s # 设定更新rules文件的周期，默认为1min
  scrape_timeout: 15s # 设定抓取数据的超时时间，默认10s

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - alertmanager:9093  # 设定alertmanager和prometheus交互的接口，即alertmanager监听的ip和端口

# rule配置，首次读取默认加载，之后根据evalution_interval设定的周期加载
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  # job_name默认写入timeseries的labels中，可用于查询使用
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    # 静态配置
    static_configs:
      # prometheus 所要抓取数据的地址，即instance实例项
    - targets: ['localhost:9090']
```
## Promethus 基础概念

## 结合Grafana使用
### Grafana安装
wget https://dl.grafana.com/oss/release/grafana-6.3.3.linux-amd64.tar.gz 
tar -zxvf grafana-6.3.3.linux-amd64.tar.gz -C /software/

