# 🔧 Linux Restore Project: отказоустойчивый веб-стенд с балансировкой, репликацией и логированием

## 📌 Описание проекта

Проект демонстрирует развёртывание отказоустойчивой архитектуры на двух виртуальных машинах (VM1 и VM2), включая:

- CMS WordPress на обеих ВМ
- Балансировку нагрузки через Nginx на VM1
- MySQL master-slave репликацию
- Централизованный сбор логов (nginx, mysql) с помощью Filebeat → Logstash → Elasticsearch
- Веб-интерфейс Kibana для анализа логов
- Резервное копирование слейва и пуш в GitHub

---

## 🧱 Архитектура

- **VM1 (192.168.33.245)**:
  - Nginx (балансировщик)
  - WordPress
  - MySQL (Master)
  - ELK стек: Elasticsearch, Logstash, Kibana
  - Filebeat

- **VM2 (192.168.33.246)**:
  - Nginx + WordPress
  - MySQL (Slave)
  - Filebeat
  - Git backup

---

## 🚀 Быстрый запуск

На **VM1**:

```bash
sudo apt install sshpass git -y
git clone https://github.com/Edd13Garc1a/linux-restore-project.git
cd linux-restore-project/scripts
bash deploy.sh
```

> ⚠ Убедитесь, что на VM2 разрешён SSH-доступ пользователю `odmin`, пароль `Mimino_321`

---

## 📜 Описание скриптов

| Скрипт                  | Назначение |
|--------------------------|------------|
| `deploy.sh`              | Главный установочный скрипт. Клонирует проект, копирует скрипты на VM2, выполняет все шаги деплоя на обеих ВМ |
| `nginx_wp.sh`            | Устанавливает Nginx + WordPress. Аргументы: `frontend` (балансировщик) или `backend` (бекенд) |
| `install_mysql.sh`       | Устанавливает и настраивает MySQL master на VM1 и slave на VM2. Использует SSH |
| `install_elk.sh`         | Устанавливает Elasticsearch, Logstash, Kibana, включает nginx-модуль Filebeat |
| `install_filebeat.sh`    | Устанавливает Filebeat, копирует конфигурацию и запускает Filebeat для логов nginx и mysql |
| `filebeat.yml`           | Конфигурация Filebeat: логи nginx и mysql, отправка на Logstash (VM1) |
| `logstash.conf`          | Конфигурация Logstash: приём логов с Filebeat, парсинг и отправка в Elasticsearch |
| `backup_slave_and_push.sh` | На VM2: создаёт дамп MySQL, архивирует и пушит в GitHub-репозиторий |

---

## 🔍 Проверка

- **WordPress**: http://192.168.33.245
- **Kibana**: http://192.168.33.245:5601
- **MySQL репликация** (на VM2):

```bash
mysql -uroot -e 'SHOW SLAVE STATUS\G'
```

---

## 🧠 Автор

- 📧 Email: Eddie.it.mt@gmail.com  
- 💻 GitHub: [Edd13Garc1a](https://github.com/Edd13Garc1a/linux-restore-project)
