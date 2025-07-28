#!/bin/bash

# Minecraft Website - Автозапуск для хостинга
# Этот скрипт автоматически запустит веб-сайт на любом Linux хостинге

echo "🌐 Запуск Minecraft Website..."
echo "📅 $(date)"
echo "📍 Директория: $(pwd)"

# Проверка Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js не найден! Устанавливаем..."
    # Для Ubuntu/Debian хостингов
    if command -v apt-get &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    # Для CentOS/RHEL хостингов
    elif command -v yum &> /dev/null; then
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        sudo yum install -y nodejs npm
    fi
fi

# Проверка версий
echo "📦 Node.js версия: $(node --version)"
echo "📦 NPM версия: $(npm --version)"

# Установка зависимостей
if [ ! -d "node_modules" ]; then
    echo "📥 Устанавливаем npm пакеты..."
    npm install --production
fi

# Создание .env файла если его нет
if [ ! -f ".env" ]; then
    echo "⚙️ Создаем .env файл..."
    cat > .env << EOF
NODE_ENV=production
PORT=3000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=minecraft_server
SESSION_SECRET=minecraft_secret_key_$(date +%s)
RCON_HOST=localhost
RCON_PORT=25575
RCON_PASSWORD=admin123
STRIPE_SECRET_KEY=your_stripe_secret_key
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_email_password
DOMAIN=localhost
EOF
    echo "✅ .env файл создан"
fi

# Проверка MySQL (опционально)
if command -v mysql &> /dev/null; then
    echo "🗄️ MySQL доступен"
    # Создание базы данных если не существует
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS minecraft_server;" 2>/dev/null || echo "⚠️ Не удалось создать базу данных"
else
    echo "⚠️ MySQL не найден, используем простую версию без БД"
    # Используем упрощенную версию
    if [ -f "server-simple.js" ]; then
        SERVER_FILE="server-simple.js"
    else
        SERVER_FILE="server.js"
    fi
fi

# Определение файла сервера
if [ -z "$SERVER_FILE" ]; then
    if [ -f "server.js" ]; then
        SERVER_FILE="server.js"
    else
        echo "❌ Файл сервера не найден!"
        exit 1
    fi
fi

echo "🚀 Запуск веб-сайта..."
echo "📝 Файл сервера: $SERVER_FILE"
echo "🌐 Сайт будет доступен на порту 3000"

# Запуск с автоперезапуском
while true; do
    node $SERVER_FILE
    
    EXIT_CODE=$?
    echo "🔄 Веб-сайт остановлен с кодом: $EXIT_CODE"
    
    if [ $EXIT_CODE -ne 0 ]; then
        echo "❌ Веб-сайт завершился с ошибкой!"
        echo "⏰ Перезапуск через 5 секунд..."
        sleep 5
    else
        echo "✅ Веб-сайт остановлен корректно"
        break
    fi
done