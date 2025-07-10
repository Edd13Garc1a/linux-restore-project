#!/bin/bash

MASTER_IP="192.168.33.245"
SLAVE_IP="192.168.33.246"
SLAVE_SSH_USER="odmin"
SLAVE_SSH_PASS="Mimino_321"
MYSQL_ROOT_PASS="Testpass1$"
DB_NAME="Otus_test"
GIT_REPO="https://github.com/Edd13Garc1a/linux-restore-project.git"
BACKUP_DIR="/tmp/mysql_backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"
ARCHIVE_FILE="${BACKUP_FILE}.tar.gz"
GIT_CLONE_DIR="/tmp/otus_repo"

execute_on_slave() {
    sshpass -p "$SLAVE_SSH_PASS" ssh -o StrictHostKeyChecking=no "${SLAVE_SSH_USER}@${SLAVE_IP}" "$@"
}

echo "[1] Останавливаем репликацию на слейве"
execute_on_slave "mysql -uroot -p'$MYSQL_ROOT_PASS' -e 'STOP SLAVE;'"

echo "[2] Создаём дамп базы $DB_NAME"
execute_on_slave "mkdir -p ${BACKUP_DIR}"
execute_on_slave "mysqldump -uroot -p'$MYSQL_ROOT_PASS' $DB_NAME > ${BACKUP_FILE}"

echo "[3] Архивируем бэкап"
execute_on_slave "tar -czf ${ARCHIVE_FILE} -C ${BACKUP_DIR} $(basename ${BACKUP_FILE})"

echo "[4] Клонируем и пушим в GitHub"
execute_on_slave "rm -rf ${GIT_CLONE_DIR}"
execute_on_slave "git config --global user.email 'Eddie.it.mt@gmail.com'"
execute_on_slave "git config --global user.name 'Edd13Garc1a'"
execute_on_slave "git clone ${GIT_REPO} ${GIT_CLONE_DIR}"
execute_on_slave "cp ${ARCHIVE_FILE} ${GIT_CLONE_DIR}/"
execute_on_slave "cd ${GIT_CLONE_DIR} && git add . && git commit -m 'MySQL backup ${TIMESTAMP}' && git push origin main"

echo "[5] Запускаем репликацию заново"
execute_on_slave "mysql -uroot -p'$MYSQL_ROOT_PASS' -e 'START SLAVE;'"

echo "[✔] Бэкап выполнен и отправлен в репозиторий"
