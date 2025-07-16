#!/bin/bash
set -e

DEB_DIR="/home/odmin/ELK"
SCRIPT_DIR="/home/odmin/linux_restore_scripts"

echo "[1/9] Проверка наличия .deb пакетов в $DEB_DIR"
cd "$DEB_DIR" || { echo "❌ Каталог $DEB_DIR не найден"; exit 1; }

echo "[2/9] Устанавливаем Elasticsearch, Kibana, Logstash, Filebeat"
sudo dpkg -i elasticsearch-8.9.1-amd64.deb || sudo apt install -f -y
sudo dpkg -i kibana-8.9.1-amd64.deb || sudo apt install -f -y
sudo dpkg -i logstash-8.9.1-amd64.deb || sudo apt install -f -y
sudo dpkg -i filebeat-8.9.1-amd64.deb || sudo apt install -f -y

echo "[3/9] Настройка памяти Elasticsearch"
echo "-Xms1g" | sudo tee /etc/elasticsearch/jvm.options.d/jvm.options
echo "-Xmx1g" | sudo tee -a /etc/elasticsearch/jvm.options.d/jvm.options

echo "[4/9] Конфигурация Elasticsearch"
sudo tee /etc/elasticsearch/elasticsearch.yml > /dev/null <<EOF
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

xpack.security.enabled: false
xpack.security.enrollment.enabled: false

http.host: 0.0.0.0
network.host: localhost
cluster.initial_master_nodes: ["elk"]
EOF

sudo systemctl daemon-reexec
sudo systemctl enable elasticsearch
sudo systemctl restart elasticsearch

echo "[5/9] Конфигурация Kibana"
sudo tee /etc/kibana/kibana.yml > /dev/null <<EOF
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
elasticsearch.ssl.verificationMode: none
EOF

sudo systemctl enable kibana
sudo systemctl restart kibana

echo "[6/9] Конфигурация Logstash"
sudo tee /etc/logstash/logstash.yml > /dev/null <<EOF
path.config: /etc/logstash/conf.d
EOF

sudo tee /etc/logstash/conf.d/logstash-nginx-es.conf > /dev/null <<EOF
input {
    beats {
        port => 5400
    }
}

filter {
 grok {
   match => [ "message" , "%{COMBINEDAPACHELOG}+%{GREEDYDATA:extra_fields}"]
   overwrite => [ "message" ]
 }
 mutate {
   convert => ["response", "integer"]
   convert => ["bytes", "integer"]
   convert => ["responsetime", "float"]
 }
 date {
   match => [ "timestamp" , "dd/MMM/YYYY:HH:mm:ss Z" ]
   remove_field => [ "timestamp" ]
 }
 useragent {
   source => "agent"
 }
}

output {
 elasticsearch {
   hosts => ["http://localhost:9200"]
   index => "weblogs-%{+YYYY.MM.dd}"
   document_type => "nginx_logs"
 }
 stdout { codec => rubydebug }
}
EOF

sudo systemctl enable logstash
sudo systemctl restart logstash

echo "[7/9] Конфигурация Filebeat"
sudo tee /etc/filebeat/filebeat.yml > /dev/null <<EOF
filebeat.inputs:
- type: filestream
  id: my-filestream-id
  enabled: true
  exclude_files: ['.gz$']
  prospector.scanner.exclude_files: ['.gz$']
  paths:
    - /var/log/nginx/*.log

output.logstash:
  hosts: ["localhost:5400"]
EOF

sudo filebeat modules enable nginx
sudo systemctl enable filebeat
sudo systemctl restart filebeat

echo "[8/9] Настройка Filebeat nginx module"
sudo tee /etc/filebeat/modules.d/nginx.yml > /dev/null <<EOF
- module: nginx
  access:
    enabled: true
    var.paths: ["/var/log/nginx/access.log*"]
  error:
    enabled: true
    var.paths: ["/var/log/nginx/error.log*"]
EOF

echo "[9/9] Проверка конфигурации и загрузка шаблонов"
sudo filebeat test config -e
sudo filebeat setup -e

echo "[✔] Elastic Stack 8.9.1 успешно установлен и настроен"
