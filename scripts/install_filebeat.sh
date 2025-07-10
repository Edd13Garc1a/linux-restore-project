#!/bin/bash
set -e

echo "[+] Установка Filebeat"
apt update
apt install -y curl
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.17.13-amd64.deb
dpkg -i filebeat-7.17.13-amd64.deb

cp filebeat.yml /etc/filebeat/filebeat.yml
filebeat modules enable nginx mysql
systemctl enable filebeat
systemctl restart filebeat
