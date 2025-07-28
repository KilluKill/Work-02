# 🌐 Развертывание на хостинге

## 📋 Выбор хостинга

### Рекомендуемые VPS провайдеры:
- **Timeweb** (Россия) - от 300₽/мес
- **Beget** (Россия) - от 250₽/мес  
- **DigitalOcean** (США) - от $6/мес
- **Vultr** (Глобально) - от $6/мес
- **Hetzner** (Германия) - от €4/мес

### Минимальные требования:
- **RAM:** 4GB (рекомендуется 8GB)
- **CPU:** 2 ядра
- **SSD:** 40GB
- **ОС:** Ubuntu 22.04 LTS

## 🚀 Пошаговое развертывание

### Шаг 1: Подключение к серверу
```bash
# Подключитесь по SSH
ssh root@YOUR_SERVER_IP

# Или если есть пользователь
ssh username@YOUR_SERVER_IP
```

### Шаг 2: Загрузка проекта
```bash
# Вариант 1: Через SCP (если архив у вас локально)
scp minecraft-server-complete.tar.gz root@YOUR_SERVER_IP:/root/

# Вариант 2: Через wget (если архив в интернете)
wget https://your-domain.com/minecraft-server-complete.tar.gz

# Распаковка
tar -xzf minecraft-server-complete.tar.gz
cd minecraft-server
```

### Шаг 3: Установка зависимостей
```bash
# Сделать скрипты исполняемыми
chmod +x scripts/*.sh

# Запустить установку
./scripts/install.sh
```

### Шаг 4: Настройка базы данных
```bash
# Настроить MySQL
./scripts/setup-database.sh

# Введите пароль для root пользователя MySQL
```

### Шаг 5: Настройка домена и SSL

#### Настройка Nginx (рекомендуется)
```bash
# Установить Nginx
sudo apt install nginx

# Создать конфигурацию
sudo nano /etc/nginx/sites-available/minecraft-server
```

Добавьте конфигурацию:
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Активировать сайт
sudo ln -s /etc/nginx/sites-available/minecraft-server /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### Установка SSL сертификата
```bash
# Установить Certbot
sudo apt install certbot python3-certbot-nginx

# Получить SSL сертификат
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

### Шаг 6: Настройка переменных окружения
```bash
# Отредактировать конфигурацию
nano website/.env
```

Обновите настройки:
```env
NODE_ENV=production
PORT=3000

# Домен вашего сайта
WEBSITE_URL=https://your-domain.com

# Настройки базы данных (оставьте как есть)
DB_HOST=localhost
DB_USER=minecraft
DB_PASSWORD=minecraft_password_2024
DB_NAME=minecraft_server

# ВАЖНО: Замените на реальные ключи!
STRIPE_SECRET_KEY=sk_live_your_real_stripe_key
PAYPAL_CLIENT_ID=your_real_paypal_client_id
PAYPAL_CLIENT_SECRET=your_real_paypal_client_secret

# Email настройки
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
```

### Шаг 7: Запуск всех сервисов
```bash
# Запустить весь проект
./scripts/start-all.sh
```

## 🔧 Настройка файрвола

```bash
# Разрешить необходимые порты
sudo ufw allow 22          # SSH
sudo ufw allow 80          # HTTP
sudo ufw allow 443         # HTTPS
sudo ufw allow 25565       # Minecraft
sudo ufw enable
```

## 📊 Мониторинг и обслуживание

### Проверка статуса
```bash
# Статус всех сервисов
./scripts/start-all.sh status

# Мониторинг в реальном времени
./scripts/start-all.sh monitor
```

### Логи
```bash
# Логи Minecraft сервера
tail -f server/logs/latest.log

# Логи веб-сайта
journalctl -u minecraft-website -f

# Логи Nginx
tail -f /var/log/nginx/access.log
```

## 💰 Настройка платежных систем

### Stripe
1. Зарегистрируйтесь на https://stripe.com
2. Получите API ключи в Dashboard
3. Замените `STRIPE_SECRET_KEY` в `.env`

### PayPal
1. Создайте приложение на https://developer.paypal.com
2. Получите Client ID и Secret
3. Замените соответствующие ключи в `.env`

### QIWI (для России)
1. Зарегистрируйтесь в QIWI Кошелек API
2. Получите токен
3. Добавьте настройки в `.env`

## 🎮 Настройка Minecraft сервера

### Изменение IP в конфигурации
```bash
# Отредактировать server.properties
nano server/server.properties
```

Измените:
```properties
server-ip=YOUR_SERVER_IP
motd=§6§l🎮 Ваш Крутой Сервер §r§a- §b§lДонат §7| §c§lПВП
```

### Настройка домена для Minecraft
Создайте SRV запись в DNS:
- **Тип:** SRV
- **Имя:** _minecraft._tcp.your-domain.com
- **Значение:** 0 5 25565 your-domain.com

Теперь игроки смогут подключаться через `your-domain.com`

## 🔄 Автоматические обновления

### Создание скрипта обновления
```bash
nano scripts/update.sh
```

```bash
#!/bin/bash
# Скрипт автоматического обновления

echo "🔄 Обновление сервера..."

# Остановить сервисы
./scripts/start-all.sh stop

# Создать бэкап
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf "backup_before_update_$DATE.tar.gz" server/ website/ database/

# Обновить зависимости
cd website && npm update && cd ..

# Запустить сервисы
./scripts/start-all.sh start

echo "✅ Обновление завершено!"
```

### Настройка cron для автообновлений
```bash
crontab -e
```

Добавьте:
```bash
# Автообновление каждое воскресенье в 3:00
0 3 * * 0 /path/to/minecraft-server/scripts/update.sh
```

## 📈 Оптимизация производительности

### Настройка JVM для большого количества игроков
```bash
# Отредактировать start-server.sh
nano scripts/start-server.sh
```

Для сервера с 8GB RAM:
```bash
java -Xmx6G -Xms4G \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    # ... остальные флаги
```

### Настройка MySQL
```bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

Добавьте оптимизации:
```ini
[mysqld]
innodb_buffer_pool_size = 2G
innodb_log_file_size = 256M
max_connections = 200
```

## 🛡️ Безопасность

### Смена паролей по умолчанию
```bash
# MySQL root пароль
sudo mysql_secure_installation

# Пароль пользователя minecraft в БД
mysql -u root -p
ALTER USER 'minecraft'@'localhost' IDENTIFIED BY 'новый_сложный_пароль';

# Обновить в .env файле
nano website/.env
```

### Настройка автоматических бэкапов
```bash
# Создать скрипт бэкапа
nano scripts/backup-to-cloud.sh
```

```bash
#!/bin/bash
# Бэкап в облако (например, на другой сервер)

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="minecraft_backup_$DATE.tar.gz"

# Создать архив
tar -czf "/tmp/$BACKUP_NAME" server/ website/ database/

# Загрузить на другой сервер (замените на свои данные)
scp "/tmp/$BACKUP_NAME" backup-user@backup-server.com:/backups/

# Удалить локальный архив
rm "/tmp/$BACKUP_NAME"

echo "✅ Бэкап $BACKUP_NAME загружен в облако"
```

## 📞 Техподдержка и мониторинг

### Настройка уведомлений в Discord
Добавьте в `website/.env`:
```env
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR_WEBHOOK_URL
```

### Мониторинг через Telegram бота
1. Создайте бота через @BotFather
2. Получите токен
3. Добавьте уведомления в скрипты мониторинга

## 🎯 Что делать после запуска

### 1. Тестирование (первые 24 часа)
- ✅ Проверить работу сайта
- ✅ Подключиться к Minecraft серверу
- ✅ Протестировать регистрацию
- ✅ Проверить донат-магазин
- ✅ Протестировать платежи (в тестовом режиме)

### 2. Настройка контента (первая неделя)
- 🎨 Загрузить логотип и фавикон
- 📝 Написать правила сервера
- 🏗️ Построить спавн и основные локации
- 👥 Настроить роли и права
- 📢 Создать Discord сервер

### 3. Маркетинг и продвижение
- 📱 Добавить сервер на мониторинги
- 🎥 Создать трейлер сервера
- 📢 Реклама в соцсетях
- 🤝 Партнерство с блогерами
- 🎁 Акции для первых игроков

### 4. Развитие (первый месяц)
- 📊 Анализ статистики
- 🔧 Оптимизация производительности
- 🎮 Добавление новых мини-игр
- 💰 Расширение донат-магазина
- 👥 Набор администрации

## 🚨 Частые проблемы и решения

### Сервер не запускается
```bash
# Проверить логи
journalctl -u minecraft-server -f

# Проверить порты
netstat -tlnp | grep :25565

# Проверить память
free -h
```

### Сайт недоступен
```bash
# Проверить Nginx
sudo systemctl status nginx

# Проверить Node.js процесс
pm2 status  # если используете PM2
```

### Высокая нагрузка
```bash
# Мониторинг ресурсов
htop

# Проверить процессы Java
jps -v
```

---

## 🎉 Готово к запуску!

После выполнения всех шагов у вас будет:

✅ **Полностью рабочий Minecraft сервер** на вашем домене  
✅ **Красивый сайт с донат-магазином**  
✅ **Настроенные платежные системы**  
✅ **Автоматические бэкапы и мониторинг**  
✅ **SSL сертификат и безопасность**  

**Ваш сервер готов принимать игроков! 🎮🚀**