#!/bin/bash
set -e

echo "[+] Установка Elasticsearch, Kibana, Logstash, Filebeat, Metricbeat (из локальных .deb)"
ELK_DIR="/home/odmin/elk"

cd "$ELK_DIR" || { echo "❌ Каталог $ELK_DIR не найден"; exit 1; }

### === Elasticsearch ===
dpkg -i elasticsearch-8.9.1-amd64.deb

cat > /etc/elasticsearch/jvm.options.d/jvm.options <<EOF
-Xms1g
-Xmx1g
EOF

cat > /etc/elasticsearch/elasticsearch.yml <<EOF
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

xpack.security.enabled: false
xpack.security.enrollment.enabled: true

xpack.security.http.ssl.enabled: false

xpack.security.transport.ssl.enabled: false
cluster.initial_master_nodes: ["elk"]
http.host: 0.0.0.0
EOF

systemctl daemon-reload
systemctl enable --now elasticsearch.service

echo "[✔] Elasticsearch установлен и запущен"

### === Kibana ===
dpkg -i kibana-8.9.1-amd64.deb

cat > /etc/kibana/kibana.yml <<EOF
server.port: 5601
server.host: "0.0.0.0"
EOF

systemctl daemon-reload
systemctl enable --now kibana.service

echo "[✔] Kibana установлен и запущен"

### === Logstash ===
dpkg -i logstash-8.9.1-amd64.deb
mkdir -p /etc/logstash/conf.d

cat > /etc/logstash/conf.d/logstash-nginx-es.conf <<EOF
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

systemctl enable --now logstash.service

echo "[✔] Logstash установлен и запущен"

### === Filebeat ===
dpkg -i filebeat-8.9.1-amd64.deb
filebeat modules enable nginx

cat > /etc/filebeat/filebeat.yml <<EOF
filebeat.inputs:
- type: filestream
  enabled: true
  paths:
    - /var/log/nginx/*.log
  exclude_files: ['.gz$']

output.logstash:
  hosts: ["localhost:5400"]
EOF

cat > /etc/filebeat/modules.d/nginx.yml <<EOF
- module: nginx
  access:
    enabled: true
    var.paths: ["/var/log/nginx/access.log*"]
  error:
    enabled: true
    var.paths: ["/var/log/nginx/error.log*"]
EOF

systemctl restart filebeat
filebeat setup -e

echo "[✔] Filebeat установлен и настроен"

### === Metricbeat ===
dpkg -i metricbeat-8.9.1-amd64.deb
systemctl enable --now metricbeat
metricbeat setup --dashboards

echo "[✔] Metricbeat установлен и настроен"

echo "[✅] Установка ELK стека завершена!"
