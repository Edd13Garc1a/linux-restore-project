#!/bin/bash

MASTER_IP="192.168.33.245"
SLAVE_IP="192.168.33.246"
SLAVE_SSH_USER="odmin"
SLAVE_SSH_PASS="Mimino_321"
MYSQL_ROOT_PASS="Testpass1$"
REPL_USER="replicator"
REPL_PASS="strong_repl_password"
DB_NAME="Otus_test"

function install_mysql_if_needed() {
  if ! dpkg -l | grep -q mysql-server; then
    echo "[+] Устанавливаем MySQL Server..."
    echo "$1" | sudo -S apt update
    echo "$1" | sudo -S apt install -y mysql-server
  fi

  echo "[+] Проверка запуска MySQL..."
  systemctl is-active --quiet mysql || {
    echo "$1" | sudo -S systemctl restart mysql
  }

  sleep 3
  systemctl is-active --quiet mysql || {
    echo "❌ MySQL не запущен!" >&2
    exit 1
  }
}

function mysql_exec() {
  MYSQL_PWD="$MYSQL_ROOT_PASS" mysql -uroot -e "$1" 2>/dev/null || {
    echo "ОШИБКА MySQL: $1" >&2
    return 1
  }
}

function ssh_exec() {
  sshpass -p "$SLAVE_SSH_PASS" ssh -o StrictHostKeyChecking=no "$SLAVE_SSH_USER@$SLAVE_IP" "$1" || {
    echo "ОШИБКА SSH: $1" >&2
    return 1
  }
}

function ssh_exec_sudo() {
  CMD="$1"
  sshpass -p "$SLAVE_SSH_PASS" ssh -o StrictHostKeyChecking=no "$SLAVE_SSH_USER@$SLAVE_IP" \
    "echo '$SLAVE_SSH_PASS' | sudo -S bash -c '$CMD'" || {
    echo "ОШИБКА SSH-SUDO: $CMD" >&2
    return 1
  }
}

echo "[== MASTER ==]"

install_mysql_if_needed "Mimino_321"

sudo hostnamectl set-hostname mysql-master

cat <<EOF | sudo tee /etc/mysql/mysql.conf.d/replication.cnf
[mysqld]
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = $DB_NAME
bind-address = $MASTER_IP
EOF

sudo systemctl restart mysql

mysql_exec "CREATE USER IF NOT EXISTS '$REPL_USER'@'$SLAVE_IP' IDENTIFIED BY '$REPL_PASS';"
mysql_exec "GRANT REPLICATION SLAVE ON *.* TO '$REPL_USER'@'$SLAVE_IP';"
mysql_exec "FLUSH PRIVILEGES;"
mysql_exec "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql_exec "USE $DB_NAME; CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_ip VARCHAR(45) NOT NULL,
    request_url VARCHAR(255) NOT NULL,
    destination_port INT NOT NULL,
    user_agent VARCHAR(255),
    referrer VARCHAR(255)
);"
mysql_exec "FLUSH TABLES WITH READ LOCK;"
MASTER_STATUS=$(mysql -uroot -p"$MYSQL_ROOT_PASS" -e "SHOW MASTER STATUS\\G")
LOG_FILE=$(echo "$MASTER_STATUS" | grep "File:" | awk '{print $2}')
LOG_POS=$(echo "$MASTER_STATUS" | grep "Position:" | awk '{print $2}')
mysql_exec "UNLOCK TABLES;"

DUMP_FILE="/tmp/replication_dump.sql"
mysqldump -uroot -p"$MYSQL_ROOT_PASS" $DB_NAME > $DUMP_FILE
sshpass -p "$SLAVE_SSH_PASS" scp -o StrictHostKeyChecking=no $DUMP_FILE $SLAVE_SSH_USER@$SLAVE_IP:/tmp/

echo "[== SLAVE ==]"

ssh_exec_sudo "apt update && apt install -y mysql-server"
ssh_exec_sudo "hostnamectl set-hostname mysql-slave"

ssh_exec_sudo "cat > /etc/mysql/mysql.conf.d/replication.cnf <<EOF
[mysqld]
server-id = 2
relay-log = /var/log/mysql/mysql-relay-bin.log
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = $DB_NAME
read_only = 1
EOF"

ssh_exec_sudo "systemctl restart mysql"

ssh_exec_sudo "mysql -uroot -e 'CREATE DATABASE IF NOT EXISTS $DB_NAME;'"
ssh_exec_sudo "mysql -uroot $DB_NAME < /tmp/replication_dump.sql && rm /tmp/replication_dump.sql"
ssh_exec_sudo "mysql -uroot -e 'STOP SLAVE;'"
ssh_exec_sudo "mysql -uroot -e \"
CHANGE MASTER TO
  MASTER_HOST='$MASTER_IP',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_LOG_FILE='$LOG_FILE',
  MASTER_LOG_POS=$LOG_POS;\""
ssh_exec_sudo "mysql -uroot -e 'START SLAVE;'"

echo "[✔] MySQL master/slave конфигурация завершена"
