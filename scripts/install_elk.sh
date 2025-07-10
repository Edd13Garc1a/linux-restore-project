#!/bin/bash
set -e

apt update
apt install -y openjdk-11-jdk apt-transport-https curl gnupg

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" > /etc/apt/sources.list.d/elastic-7.x.list

apt update
apt install -y elasticsearch logstash kibana filebeat

echo "[+] Конфигурируем Elasticsearch"
sed -i 's/#network.host: .*/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml
systemctl enable elasticsearch
systemctl start elasticsearch

echo "[+] Конфигурируем Kibana"
sed -i 's/#server.host: .*/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
systemctl enable kibana
systemctl start kibana

echo "[+] Копируем logstash.conf"
cp logstash.conf /etc/logstash/conf.d/logstash.conf
systemctl enable logstash
systemctl restart logstash

echo "[+] Устанавливаем и настраиваем Filebeat"
filebeat modules enable nginx mysql
systemctl enable filebeat
systemctl restart filebeat

echo "[✔] ELK стек полностью установлен и запущен"
