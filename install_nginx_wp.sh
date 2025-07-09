#!/bin/bash
set -e

apt update
apt install -y nginx php php-fpm php-mysql mariadb-client wget unzip

cd /var/www/
wget https://wordpress.org/latest.zip
unzip latest.zip
rm latest.zip
chown -R www-data:www-data wordpress

cat > /etc/nginx/sites-available/wordpress <<EOF
server {
    listen 80;
    server_name _;
    root /var/www/wordpress;

    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

systemctl reload php*-fpm
systemctl restart nginx

echo "WordPress установлен. Перейдите по IP сервера в браузере для завершения настройки."
