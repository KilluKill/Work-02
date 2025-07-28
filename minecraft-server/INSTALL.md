# 🚀 Инструкция по установке Minecraft Server 1.21.8

## 📋 Что включено в проект

✅ **Minecraft сервер Paper 1.21.8** с оптимизацией  
✅ **50+ плагинов** для всех нужд  
✅ **Система авторизации** AuthMe + MySQL  
✅ **Веб-сайт** с донат-магазином  
✅ **Админ-панель** для управления  
✅ **Автоматические бэкапы** и мониторинг  
✅ **Платежные системы** (Stripe, PayPal, QIWI)  
✅ **RCON управление** сервером  

## 🔧 Системные требования

- **ОС**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- **RAM**: Минимум 4GB (рекомендуется 8GB+)
- **CPU**: 2+ ядра
- **Диск**: 10GB+ свободного места
- **Интернет**: Стабильное подключение

## 📦 Быстрая установка

### 1. Установка зависимостей
```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

### 2. Настройка базы данных
```bash
./scripts/setup-database.sh
```
*Введите пароль для MySQL root пользователя*

### 3. Запуск всего проекта
```bash
./scripts/start-all.sh
```

🎉 **Готово!** Сервер запущен и готов к использованию!

## 🌐 Доступ к сервисам

После установки доступны следующие сервисы:

| Сервис | Адрес | Описание |
|--------|-------|----------|
| 🌐 **Веб-сайт** | http://localhost:3000 | Главный сайт с донат-магазином |
| 🎮 **Minecraft** | localhost:25565 | Сервер для подключения игроков |
| 🗄️ **MySQL** | localhost:3306 | База данных |
| 🔧 **RCON** | localhost:25575 | Удаленное управление сервером |

## 👤 Админ доступ

**Веб-сайт:**
- Логин: `admin`
- Email: `admin@server.com`
- Пароль: `admin123`

**Minecraft сервер:**
- Выполните: `/op admin` в консоли сервера

**MySQL:**
- Пользователь: `minecraft`
- Пароль: `minecraft_password_2024`
- База: `minecraft_server`

## 🎮 Подключение к серверу

1. Откройте Minecraft 1.21.8
2. Добавьте сервер: `localhost:25565`
3. Зарегистрируйтесь: `/register пароль пароль`
4. Войдите: `/login пароль`

## 🛠️ Управление сервером

### Основные команды
```bash
# Запуск всех сервисов
./scripts/start-all.sh start

# Остановка сервисов
./scripts/start-all.sh stop

# Перезапуск
./scripts/start-all.sh restart

# Статус сервисов
./scripts/start-all.sh status

# Мониторинг в реальном времени
./scripts/start-all.sh monitor
```

### Управление отдельными компонентами
```bash
# Только Minecraft сервер
./scripts/start-server.sh

# Только веб-сайт
cd website && npm start

# Только база данных
sudo systemctl start mysql
```

## 📊 Мониторинг

### Веб-интерфейс
- Админ-панель: http://localhost:3000/admin
- Статистика игроков и доходов
- Логи сервера в реальном времени

### Командная строка
```bash
# Быстрый статус
./scripts/start-all.sh status

# Непрерывный мониторинг
./scripts/start-all.sh monitor

# Логи сервера Minecraft
tail -f server/logs/latest.log

# Логи веб-сайта
journalctl -u minecraft-website -f
```

## 🔧 Конфигурация

### Настройка сервера Minecraft
Основные файлы конфигурации:
- `server/server.properties` - Настройки сервера
- `server/plugins/AuthMe/config.yml` - Авторизация
- `server/plugins/LuckPerms/` - Права доступа

### Настройка веб-сайта
- `website/.env` - Переменные окружения
- `website/server.js` - Основной файл сервера
- `database/config.js` - Настройки БД

### Настройка платежей
В файле `website/.env` замените:
```env
STRIPE_SECRET_KEY=sk_live_your_real_stripe_key
PAYPAL_CLIENT_ID=your_real_paypal_client_id
PAYPAL_CLIENT_SECRET=your_real_paypal_client_secret
```

## 🎯 Плагины и функции

### 🔐 Авторизация
- Регистрация и вход в игре
- Защита паролем
- Сессии для удобства
- Интеграция с сайтом

### 💰 Экономика
- Игровая валюта (монеты)
- Магазины игроков
- Аукционы
- Банковская система

### 🏠 Территории
- Приватные зоны
- Защита от гриферов
- Система резиденций
- WorldGuard регионы

### 🎮 Мини-игры
- BedWars арены
- SkyWars батлы
- Паркур трассы
- Дуэли игроков

### 👑 VIP система
- VIP, Premium, Elite статусы
- Особые команды и привилегии
- Цветные ники
- Приоритетный вход

## 💳 Донат-магазин

### Категории товаров
- **VIP статусы** - Привилегии на сервере
- **Игровая валюта** - Монеты для покупок
- **Донат кейсы** - Случайные награды
- **Привилегии** - Особые возможности
- **Разное** - Дополнительные товары

### Способы оплаты
- 💳 Банковские карты (Visa, MasterCard)
- 🌐 PayPal
- 📱 QIWI кошелек
- 💰 Яндекс.Деньги
- 🏦 Банковские переводы

## 🚨 Решение проблем

### Сервер не запускается
```bash
# Проверьте статус
./scripts/start-all.sh status

# Проверьте логи
journalctl -u minecraft-server -f

# Проверьте Java
java -version
```

### Веб-сайт недоступен
```bash
# Проверьте Node.js
node --version

# Проверьте порт
netstat -tlnp | grep :3000

# Перезапустите
sudo systemctl restart minecraft-website
```

### База данных не работает
```bash
# Проверьте MySQL
sudo systemctl status mysql

# Проверьте подключение
mysql -u minecraft -p minecraft_server

# Перезапустите
sudo systemctl restart mysql
```

### Плагины не работают
```bash
# Проверьте логи сервера
tail -f server/logs/latest.log

# Перезагрузите плагины
# В консоли сервера: reload confirm

# Проверьте совместимость версий
```

## 🔄 Обновления

### Обновление Minecraft сервера
```bash
# Остановите сервер
./scripts/start-all.sh stop

# Скачайте новую версию Paper
wget -O server/paper-new.jar "URL_новой_версии"

# Замените файл
mv server/paper-new.jar server/paper-1.21.8.jar

# Запустите сервер
./scripts/start-all.sh start
```

### Обновление веб-сайта
```bash
cd website
npm update
sudo systemctl restart minecraft-website
```

### Обновление плагинов
1. Скачайте новые версии плагинов
2. Замените файлы в `server/plugins/`
3. Перезапустите сервер

## 🛡️ Безопасность

### Рекомендации
- Измените пароли по умолчанию
- Настройте файрвол
- Регулярно обновляйте компоненты
- Делайте бэкапы

### Бэкапы
Автоматические бэкапы создаются каждые 6 часов в папке `backups/`

Ручной бэкап:
```bash
cd server
./backup.sh
```

## 📞 Поддержка

### Документация
- `README.md` - Общая информация
- `server/plugins/plugins-list.md` - Список плагинов
- Логи в `server/logs/`

### Полезные ссылки
- [Paper MC](https://papermc.io/) - Документация Paper
- [SpigotMC](https://www.spigotmc.org/) - Плагины
- [Bukkit](https://bukkit.org/) - API документация

---

## 🎉 Готово!

Ваш крутой Minecraft сервер 1.21.8 готов к использованию!

**Что дальше:**
1. 🎮 Пригласите друзей на сервер
2. 🛠️ Настройте плагины под свои нужды  
3. 💰 Настройте реальные платежные системы
4. 📈 Развивайте сообщество
5. 🚀 Наслаждайтесь игрой!

**Удачи в создании лучшего Minecraft сервера! 🎮✨**