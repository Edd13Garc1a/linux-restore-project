# Установка на VM1 (192.168.33.245)

## Шаги:

1. Установите Nginx + WordPress в режиме балансировщика:
```bash
sudo ./install_nginx_wp.sh --role balancer
```

2. Установите MySQL Master:
```bash
sudo ./install_mysql.sh --role master
```

3. Установите стек ELK (версия 8.9.1):
```bash
sudo ./install_elk_local_891.sh
```
