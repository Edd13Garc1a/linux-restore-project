#!/bin/bash
set -e

echo "[+] Скачиваем и устанавливаем Elasticsearch, Kibana, Logstash, Filebeat (v7.17.13)"

cd /tmp

wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.13-amd64.deb
wget https://artifacts.elastic.co/downloads/kibana/kibana-7.17.13-amd64.deb
wget https://artifacts.elastic.co/downloads/logstash/logstash-7.17.13-amd64.deb
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.17.13-amd64.deb

dpkg -i elasticsearch-7.17.13-amd64.deb
dpkg -i kibana-7.17.13-amd64.deb
dpkg -i logstash-7.17.13-amd64.deb
dpkg -i filebeat-7.17.13-amd64.deb

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

echo "[+] Настройка Filebeat"
cp filebeat.yml /etc/filebeat/filebeat.yml
filebeat modules enable nginx mysql
systemctl enable filebeat
systemctl restart filebeat

echo "[✔] ELK стек успешно установлен из .deb"
