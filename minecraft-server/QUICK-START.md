# ⚡ Быстрый старт на хостинге

## 🎯 За 15 минут от архива до работающего сервера

### 1. 🏠 Купите VPS
**Рекомендуемые тарифы:**
- **Timeweb:** VPS SSD-4 (4GB RAM, 2 CPU) - 300₽/мес
- **Beget:** VPS SSD Start (4GB RAM, 2 CPU) - 250₽/мес  
- **DigitalOcean:** Basic Droplet (4GB RAM, 2 CPU) - $24/мес

**Выберите:** Ubuntu 22.04 LTS

### 2. 📤 Загрузите проект на сервер
```bash
# Подключитесь к серверу
ssh root@YOUR_SERVER_IP

# Загрузите архив (замените на свой URL)
wget https://your-file-host.com/minecraft-server-complete.tar.gz

# Распакуйте
tar -xzf minecraft-server-complete.tar.gz
cd minecraft-server
```

### 3. 🚀 Запустите автоустановку
```bash
# Сделайте скрипты исполняемыми
chmod +x scripts/*.sh

# Установите все зависимости (5-10 минут)
./scripts/install.sh

# Настройте базу данных (введите пароль для MySQL)
./scripts/setup-database.sh

# Запустите все сервисы
./scripts/start-all.sh
```

### 4. 🌐 Настройте домен (опционально)
```bash
# Установите Nginx
sudo apt install nginx certbot python3-certbot-nginx

# Создайте конфигурацию Nginx
sudo nano /etc/nginx/sites-available/minecraft-server
```

Вставьте:
```nginx
server {
    listen 80;
    server_name your-domain.com;
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
# Активируйте сайт
sudo ln -s /etc/nginx/sites-available/minecraft-server /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Получите SSL сертификат
sudo certbot --nginx -d your-domain.com
```

### 5. 🔧 Настройте файрвол
```bash
sudo ufw allow 22 80 443 25565
sudo ufw enable
```

## 🎉 Готово!

**Ваши сервисы доступны:**
- 🌐 **Сайт:** http://YOUR_SERVER_IP:3000 (или https://your-domain.com)
- 🎮 **Minecraft:** YOUR_SERVER_IP:25565
- 👤 **Админ:** admin / admin123

## 📋 Первые шаги после запуска

### 1. Тестирование (сделайте сразу)
```bash
# Проверьте статус всех сервисов
./scripts/start-all.sh status

# Подключитесь к Minecraft серверу
# IP: YOUR_SERVER_IP:25565
# Зарегистрируйтесь: /register пароль пароль
```

### 2. Настройка платежей
Отредактируйте `website/.env`:
```env
# Замените на реальные ключи
STRIPE_SECRET_KEY=sk_live_your_real_key
PAYPAL_CLIENT_ID=your_real_client_id
PAYPAL_CLIENT_SECRET=your_real_secret
```

### 3. Безопасность
```bash
# Смените пароли MySQL
mysql -u root -p
ALTER USER 'minecraft'@'localhost' IDENTIFIED BY 'новый_сложный_пароль';

# Обновите в .env
nano website/.env
```

## 🔧 Управление сервером

```bash
# Статус всех сервисов
./scripts/start-all.sh status

# Перезапуск
./scripts/start-all.sh restart

# Остановка
./scripts/start-all.sh stop

# Мониторинг в реальном времени
./scripts/start-all.sh monitor
```

## 🚨 Если что-то не работает

### Minecraft сервер не запускается
```bash
# Проверьте логи
journalctl -u minecraft-server -f

# Проверьте Java
java -version

# Проверьте память
free -h
```

### Сайт недоступен
```bash
# Проверьте Node.js сервис
sudo systemctl status minecraft-website

# Проверьте порт
netstat -tlnp | grep :3000
```

### MySQL не работает
```bash
# Проверьте статус
sudo systemctl status mysql

# Перезапустите
sudo systemctl restart mysql
```

## 💡 Полезные команды

```bash
# Логи Minecraft сервера
tail -f server/logs/latest.log

# Логи веб-сайта  
journalctl -u minecraft-website -f

# Использование ресурсов
htop

# Создать бэкап
cd server && ./backup.sh
```

## 📞 Нужна помощь?

1. **Проверьте файл `DEPLOYMENT.md`** - подробная инструкция
2. **Посмотрите логи** - они покажут причину проблемы
3. **Перезапустите сервисы** - часто помогает

---

## 🎮 Ваш сервер готов!

**Что дальше:**
1. 👥 Пригласите друзей
2. 🎨 Настройте дизайн сайта
3. 💰 Настройте реальные платежи
4. 📈 Добавьте сервер на мониторинги
5. 🚀 Развивайте сообщество!

**Удачи с вашим Minecraft сервером! 🎯✨**