#!/bin/bash
set -e

ROLE=$1  # frontend или backend
WP_DIR="/var/www/wordpress"

if [[ "$ROLE" != "frontend" && "$ROLE" != "backend" ]]; then
  echo "Usage: $0 [frontend|backend]"
  exit 1
fi

apt update
apt install -y nginx php php-fpm php-mysql mariadb-client wget unzip

if [ ! -d "$WP_DIR" ]; then
  cd /var/www/
  wget https://wordpress.org/latest.zip
  unzip latest.zip
  rm latest.zip
  chown -R www-data:www-data wordpress
echo "[+] Генерируем wp-config.php"
cd /var/www/wordpress
cp wp-config-sample.php wp-config.php

sed -i "s/database_name_here/Otus_test/" wp-config.php
sed -i "s/username_here/root/" wp-config.php
sed -i "s/password_here/Testpass1\\\$/" wp-config.php
sed -i "s/localhost/localhost/" wp-config.php

fi

if [ "$ROLE" == "frontend" ]; then
  cat > /etc/nginx/sites-available/wordpress <<EOF
upstream backend {
    server 192.168.33.245;
    server 192.168.33.246;
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
else
  cat > /etc/nginx/sites-available/wordpress <<EOF
server {
    listen 80;
    server_name _;
    root /var/www/wordpress;

    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }

    location ~ /\\.ht {
        deny all;
    }
}
EOF
fi

ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

systemctl reload php*-fpm || true
systemctl restart nginx

echo "[+] Nginx + WordPress установлен в режиме: $ROLE"
