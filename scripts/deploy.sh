#!/bin/bash
set -e

REPO_URL="https://github.com/Edd13Garc1a/linux-restore-project.git"
CLONE_DIR="/opt/web_project"
SLAVE_IP="192.168.33.246"
SLAVE_USER="odmin"
SLAVE_PASS="Mimino_321"

echo "[+] Клонируем проект на VM1..."
rm -rf $CLONE_DIR
git clone $REPO_URL $CLONE_DIR
cd $CLONE_DIR/scripts

echo "[+] Копируем скрипты на VM2..."
sshpass -p "$SLAVE_PASS" scp -r -o StrictHostKeyChecking=no ./ "$SLAVE_USER@$SLAVE_IP:/home/$SLAVE_USER/linux_restore_scripts"

echo "[+] Устанавливаем WordPress + Nginx на VM2 (backend)..."
sshpass -p "$SLAVE_PASS" ssh -o StrictHostKeyChecking=no "$SLAVE_USER@$SLAVE_IP" "cd ~/linux_restore_scripts && sudo bash nginx_wp.sh backend"

echo "[+] Устанавливаем WordPress + Nginx на VM1 (балансировщик)..."
sudo bash nginx_wp.sh frontend

echo "[+] Устанавливаем MySQL master/slave..."
sudo bash install_mysql.sh

echo "[+] Устанавливаем ELK стек..."
sudo bash install_elk.sh

echo "[+] Устанавливаем Filebeat на VM2..."
sshpass -p "$SLAVE_PASS" ssh -o StrictHostKeyChecking=no "$SLAVE_USER@$SLAVE_IP" "cd ~/linux_restore_scripts && sudo bash install_filebeat.sh"

echo "[+] Устанавливаем Filebeat на VM1..."
sudo bash install_filebeat.sh

echo "[+] Бэкап с VM2 и пуш в GitHub..."
sudo bash backup_slave_and_push.sh

echo "[✔] Установка завершена. WordPress: http://192.168.33.245, Kibana: http://192.168.33.245:5601"
