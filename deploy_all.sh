#!/bin/bash
set -e

REPO_URL="https://github.com/Edd13Garc1a/linux-restore-project.git"
CLONE_DIR="/opt/web_project"

echo "[+] Клонируем проект с GitHub..."
rm -rf $CLONE_DIR
git clone $REPO_URL $CLONE_DIR
cd $CLONE_DIR/scripts

echo -e "\n[1/5] Установка WordPress и Nginx"
bash 2_install_nginx_wp.sh

echo -e "\n[2/5] Установка и настройка MySQL master/slave"
bash 4_install_mysql.sh

echo -e "\n[3/5] Установка ELK стека (Elasticsearch, Logstash, Kibana, Filebeat)"
bash 3_install_elk.sh

echo -e "\n[4/5] Бэкап слейва и отправка в GitHub"
bash 7_backup_slave_and_push.sh

echo -e "\n[5/5] Установка завершена успешно!"
echo "WordPress: http://192.168.33.245"
echo "Kibana: http://192.168.33.245:5601"
