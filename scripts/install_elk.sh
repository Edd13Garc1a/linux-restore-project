#!/bin/bash
set -e

DEB_DIR="/home/odmin/elk"

echo "[1/6] Проверка наличия .deb пакетов в $DEB_DIR"
if [ ! -d "$DEB_DIR" ]; then
  echo "❌ Папка $DEB_DIR не найдена. Помести туда .deb файлы ELK!" >&2
  exit 1
fi

cd "$DEB_DIR"

echo "[2/6] Устанавливаем .deb пакеты Elastic Stack 8.9.1"
sudo dpkg -i elasticsearch-8.9.1-amd64.deb \
             kibana-8.9.1-amd64.deb \
             logstash-8.9.1-amd64.deb \
             filebeat-8.9.1-amd64.deb || sudo apt install -f -y

echo "[3/6] Отключаем X-Pack Security (Elasticsearch)"
sudo bash -c "echo '
network.host: localhost
xpack.security.enabled: false
' >> /etc/elasticsearch/elasticsearch.yml"

sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

echo "[4/6] Конфигурируем Kibana"
sudo bash -c "echo '
server.host: \"0.0.0.0\"
elasticsearch.hosts: [\"http://localhost:9200\"]
elasticsearch.ssl.verificationMode: none
' >> /etc/kibana/kibana.yml"

sudo systemctl enable kibana
sudo systemctl start kibana

echo "[5/6] Настраиваем Logstash"
sudo cp ~/linux_restore_scripts/logstash.conf /etc/logstash/conf.d/logstash.conf
sudo systemctl enable logstash
sudo systemctl restart logstash

echo "[6/6] Настраиваем Filebeat"
sudo cp ~/linux_restore_scripts/filebeat.yml /etc/filebeat/filebeat.yml
sudo filebeat modules enable nginx mysql
sudo systemctl enable filebeat
sudo systemctl restart filebeat

echo "[✔] Elastic Stack 8.9.1 установлен и запущен (без авторизации)"
