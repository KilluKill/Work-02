# 🚀 ДЕПЛОЙ НА ХОСТИНГ - ГОТОВ К ЗАГРУЗКЕ!

## 📦 Что у вас есть:

### ✅ **Полностью готовый сервер для хостинга:**
- **Minecraft сервер** с автозапуском
- **Веб-сайт** с автоустановкой
- **База данных** с готовым SQL
- **Все зависимости** включены

## 🎯 **Простой деплой (3 шага):**

### **1. Загрузите на хостинг**
Загрузите всю папку `minecraft-server/` на ваш Linux хостинг через:
- **FTP/SFTP** (FileZilla, WinSCP)
- **SSH + SCP** 
- **Панель хостинга** (cPanel, Plesk)

### **2. Запустите автоматические скрипты**

#### **Для Minecraft сервера:**
```bash
cd /path/to/minecraft-server/server
chmod +x start.sh
./start.sh
```

#### **Для веб-сайта:**
```bash
cd /path/to/minecraft-server/website  
chmod +x start-website.sh
./start-website.sh
```

#### **Для базы данных (если есть MySQL):**
```bash
mysql -u root -p < database/setup.sql
```

### **3. Готово! Сервер работает**
- 🎮 **Minecraft:** your-server-ip:25565
- 🌐 **Веб-сайт:** http://your-server-ip:3000
- 👤 **Админ:** admin / admin123

---

## 🔧 **Что делают скрипты автоматически:**

### **start.sh (Minecraft сервер):**
- ✅ Проверяет и устанавливает Java 21
- ✅ Создает необходимые папки
- ✅ Принимает EULA автоматически
- ✅ Определяет RAM и настраивает JVM
- ✅ Скачивает Paper сервер если нужно
- ✅ Запускает с оптимизированными флагами
- ✅ Автоперезапуск при сбоях

### **start-website.sh (Веб-сайт):**
- ✅ Проверяет и устанавливает Node.js
- ✅ Устанавливает npm зависимости
- ✅ Создает .env файл автоматически
- ✅ Проверяет MySQL и создает БД
- ✅ Выбирает версию (с БД или без)
- ✅ Запускает с автоперезапуском

### **setup.sql (База данных):**
- ✅ Создает базу данных minecraft_server
- ✅ Создает пользователя minecraft
- ✅ Создает все необходимые таблицы
- ✅ Вставляет тестовые данные
- ✅ Настраивает индексы для скорости

---

## 🌐 **Популярные хостинги:**

### **VPS/Dedicated серверы:**
- **Timeweb** - https://timeweb.com/
- **REG.RU** - https://www.reg.ru/
- **Selectel** - https://selectel.ru/
- **DigitalOcean** - https://digitalocean.com/
- **Vultr** - https://vultr.com/

### **Minecraft хостинги:**
- **MCProHosting** - https://mcprohosting.com/
- **Apex Hosting** - https://apexminecrafthosting.com/
- **Shockbyte** - https://shockbyte.com/
- **BisectHosting** - https://bisecthosting.com/

### **Требования к хостингу:**
- **ОС:** Linux (Ubuntu 18+, CentOS 7+)
- **RAM:** минимум 2GB, рекомендуется 4GB+
- **CPU:** 2 ядра минимум
- **Диск:** 10GB+ свободного места
- **Порты:** 25565 (Minecraft), 3000 (веб-сайт)

---

## 📋 **Пошаговая инструкция:**

### **Шаг 1: Подготовка хостинга**
```bash
# Подключение по SSH
ssh username@your-server-ip

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка базовых пакетов
sudo apt install -y wget curl unzip screen htop
```

### **Шаг 2: Загрузка файлов**
```bash
# Загрузка через SCP (с вашего компьютера)
scp -r minecraft-server/ username@your-server-ip:/home/username/

# Или загрузка через wget (если файлы в интернете)
wget -O minecraft-server.zip "ссылка-на-архив"
unzip minecraft-server.zip
```

### **Шаг 3: Настройка прав**
```bash
cd minecraft-server/
chmod +x server/start.sh
chmod +x website/start-website.sh
```

### **Шаг 4: Запуск в screen**
```bash
# Minecraft сервер
screen -S minecraft
cd server && ./start.sh
# Нажмите Ctrl+A, затем D для выхода из screen

# Веб-сайт  
screen -S website
cd ../website && ./start-website.sh
# Нажмите Ctrl+A, затем D для выхода из screen
```

### **Шаг 5: Проверка работы**
```bash
# Проверка процессов
ps aux | grep java
ps aux | grep node

# Проверка портов
netstat -tlnp | grep :25565
netstat -tlnp | grep :3000

# Просмотр логов
screen -r minecraft  # Подключиться к серверу
screen -r website    # Подключиться к сайту
```

---

## 🔧 **Настройка домена (опционально):**

### **Для веб-сайта:**
```bash
# Установка Nginx
sudo apt install -y nginx

# Создание конфига
sudo nano /etc/nginx/sites-available/minecraft-website

# Содержимое конфига:
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# Активация
sudo ln -s /etc/nginx/sites-available/minecraft-website /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### **Для Minecraft сервера:**
```bash
# В панели управления доменом создайте A-запись:
# Тип: A
# Имя: mc (или @)  
# Значение: IP-адрес сервера
# TTL: 300

# Игроки смогут подключаться: mc.your-domain.com:25565
```

---

## 🛡️ **Безопасность:**

### **Firewall (UFW):**
```bash
sudo ufw enable
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 25565/tcp   # Minecraft
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 3000/tcp    # Website (временно)
```

### **Автозапуск через systemd:**
```bash
# Создание сервиса для Minecraft
sudo nano /etc/systemd/system/minecraft.service

[Unit]
Description=Minecraft Server
After=network.target

[Service]
Type=simple
User=minecraft
WorkingDirectory=/home/minecraft/minecraft-server/server
ExecStart=/home/minecraft/minecraft-server/server/start.sh
Restart=always

[Install]
WantedBy=multi-user.target

# Активация
sudo systemctl enable minecraft
sudo systemctl start minecraft
```

---

## ✅ **Готово к использованию!**

**После деплоя у вас будет:**
- 🎮 Полностью рабочий Minecraft сервер
- 🌐 Веб-сайт с донат-магазином  
- 🗄️ База данных с тестовыми данными
- 🔄 Автоматический перезапуск при сбоях
- 📊 Логирование всех действий
- 🛡️ Базовая защита от ошибок

**Просто загрузите, запустите скрипты и играйте! 🚀**