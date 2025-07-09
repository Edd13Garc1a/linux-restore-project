# 🔧 Демонстрация аварийного восстановления веб-стенда с MySQL Master-Slave и централизованным сбором логов (ELK)

## 📌 Описание проекта

Проект демонстрирует настройку отказоустойчивого веб-стенда на базе CMS WordPress с:

- Репликацией MySQL (master-slave)
- Централизованным сбором логов через стек ELK (Elasticsearch, Logstash, Kibana)
- Автоматическим аварийным бэкапом и восстановлением слейва
- Полностью автоматизированным деплоем через bash-скрипты

---

## 🧱 Архитектура


---

## ⚙️ Требования

- 2 виртуальные машины:
  - VM1 (192.168.33.245) — master
  - VM2 (192.168.33.246) — slave
- Пользователь: `odmin`
- Пароль: `Mimino_321`
- Root-доступ или `sudo`
- Git установлен
- SSH от VM1 → VM2

---

## 🚀 Установка

На VM1 (192.168.33.245):

git clone https://github.com/Edd13Garc1a/linux-restore-project.git
cd linux-restore-project/scripts
bash deploy_all.sh

---

## 🔍  Проверка результата
WordPress: http://192.168.33.245

Kibana: http://192.168.33.245:5601

Проверка репликации:
mysql -uroot -e 'SHOW SLAVE STATUS\\G'  # на VM2

🧠 Автор
📧 Email: Eddie.it.mt@gmail.com

💻 GitHub: Edd13Garc1a
