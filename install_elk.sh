#!/bin/bash
set -e

apt update
apt install -y openjdk-11-jdk apt-transport-https curl gnupg

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list

apt update
apt install -y elasticsearch logstash kibana filebeat

sed -i 's/#network.host: .*/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml
systemctl enable elasticsearch
systemctl start elasticsearch

sed -i 's/#server.host: .*/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
systemctl enable kibana
systemctl start kibana

filebeat modules enable nginx
filebeat setup --index-management -E setup.kibana.host=localhost:5601
systemctl enable filebeat
systemctl start filebeat

echo "[+] ELK стек установлен. Kibana доступна на порту 5601"
