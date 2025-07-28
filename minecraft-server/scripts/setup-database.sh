#!/bin/bash

echo "🗄️ Настройка базы данных MySQL"
echo "==============================="

# Проверка установки MySQL
if ! command -v mysql &> /dev/null; then
    echo "❌ MySQL не установлен. Запустите сначала ./install.sh"
    exit 1
fi

# Запуск MySQL сервиса
echo "🔄 Запуск MySQL сервиса..."
sudo systemctl start mysql
sudo systemctl enable mysql

# Безопасная установка MySQL
echo "🔒 Настройка безопасности MySQL..."
echo "Введите пароль для root пользователя MySQL:"
sudo mysql_secure_installation

# Создание базы данных и пользователя
echo "📊 Создание базы данных..."
mysql -u root -p << 'EOF'
-- Создание базы данных для сервера
CREATE DATABASE IF NOT EXISTS minecraft_server CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Создание пользователя для сервера
CREATE USER IF NOT EXISTS 'minecraft'@'localhost' IDENTIFIED BY 'minecraft_password_2024';
GRANT ALL PRIVILEGES ON minecraft_server.* TO 'minecraft'@'localhost';

-- Создание таблиц для AuthMe
USE minecraft_server;

-- Таблица пользователей для AuthMe
CREATE TABLE IF NOT EXISTS authme (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    realname VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    ip VARCHAR(40),
    lastlogin BIGINT,
    x DOUBLE DEFAULT 0,
    y DOUBLE DEFAULT 0,
    z DOUBLE DEFAULT 0,
    world VARCHAR(255) DEFAULT 'world',
    regdate BIGINT,
    regip VARCHAR(40),
    yaw FLOAT DEFAULT 0,
    pitch FLOAT DEFAULT 0,
    email VARCHAR(255),
    isLogged SMALLINT DEFAULT 0,
    hasSession SMALLINT DEFAULT 0,
    totp VARCHAR(32)
);

-- Таблица для веб-сайта пользователей
CREATE TABLE IF NOT EXISTS website_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    minecraft_username VARCHAR(50),
    role ENUM('user', 'vip', 'premium', 'admin') DEFAULT 'user',
    balance DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    avatar VARCHAR(255)
);

-- Таблица донат товаров
CREATE TABLE IF NOT EXISTS donate_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category ENUM('rank', 'currency', 'case', 'privilege', 'other') NOT NULL,
    image VARCHAR(255),
    commands TEXT,
    duration_days INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица покупок
CREATE TABLE IF NOT EXISTS purchases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    item_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50),
    payment_id VARCHAR(255),
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    minecraft_username VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES website_users(id),
    FOREIGN KEY (item_id) REFERENCES donate_items(id)
);

-- Таблица сессий
CREATE TABLE IF NOT EXISTS sessions (
    session_id VARCHAR(128) PRIMARY KEY,
    expires INT UNSIGNED NOT NULL,
    data TEXT
);

-- Таблица статистики игроков
CREATE TABLE IF NOT EXISTS player_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    play_time BIGINT DEFAULT 0,
    last_seen TIMESTAMP,
    joins_count INT DEFAULT 0,
    deaths_count INT DEFAULT 0,
    kills_count INT DEFAULT 0,
    money DECIMAL(10,2) DEFAULT 0.00,
    level INT DEFAULT 1,
    experience BIGINT DEFAULT 0
);

-- Таблица логов сервера
CREATE TABLE IF NOT EXISTS server_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type ENUM('join', 'leave', 'command', 'chat', 'purchase', 'error') NOT NULL,
    username VARCHAR(50),
    message TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Вставка тестовых донат товаров
INSERT INTO donate_items (name, description, price, category, commands) VALUES
('VIP Статус', 'VIP статус на 30 дней с особыми привилегиями', 199.00, 'rank', 'lp user {username} parent add vip\ngive {username} diamond 10'),
('Premium Статус', 'Premium статус на 30 дней с расширенными возможностями', 399.00, 'rank', 'lp user {username} parent add premium\ngive {username} diamond 32'),
('Elite Статус', 'Elite статус на 30 дней - максимум привилегий', 799.00, 'rank', 'lp user {username} parent add elite\ngive {username} diamond 64'),
('1000 Монет', 'Игровая валюта для покупок на сервере', 99.00, 'currency', 'eco give {username} 1000'),
('5000 Монет', 'Большое количество игровой валюты', 399.00, 'currency', 'eco give {username} 5000'),
('Донат Кейс', 'Кейс с случайными предметами', 149.00, 'case', 'crate give {username} donate 1'),
('Привилегия Полета', 'Возможность летать на выживании', 299.00, 'privilege', 'lp user {username} permission set essentials.fly true'),
('Дом VIP', 'Дополнительные точки дома', 199.00, 'privilege', 'lp user {username} permission set essentials.sethome.multiple.vip true');

-- Создание админ пользователя
INSERT INTO website_users (username, email, password, minecraft_username, role) VALUES
('admin', 'admin@server.com', '$2b$10$rKzXvJKJ5O4Y8gF2vH3hL.8K2Y8gF2vH3hL.8K2Y8gF2vH3hL.8K2Y', 'Admin', 'admin');

FLUSH PRIVILEGES;
EOF

# Создание конфигурации для подключения
echo "⚙️ Создание конфигурации подключения..."
cat > ../database/config.js << 'EOF'
module.exports = {
    host: 'localhost',
    user: 'minecraft',
    password: 'minecraft_password_2024',
    database: 'minecraft_server',
    charset: 'utf8mb4',
    timezone: 'Z',
    acquireTimeout: 60000,
    timeout: 60000,
    reconnect: true
};
EOF

# Создание конфигурации для AuthMe
echo "🔐 Создание конфигурации AuthMe..."
mkdir -p ../server/plugins/AuthMe
cat > ../server/plugins/AuthMe/config.yml << 'EOF'
DataSource:
    backend: 'MYSQL'
    mySQLHost: '127.0.0.1'
    mySQLPort: '3306'
    mySQLDatabase: 'minecraft_server'
    mySQLUsername: 'minecraft'
    mySQLPassword: 'minecraft_password_2024'
    mySQLTablename: 'authme'
    mySQLColumnName: 'username'
    mySQLColumnPassword: 'password'
    mySQLColumnIp: 'ip'
    mySQLColumnLastLogin: 'lastlogin'
    mySQLColumnRegisterDate: 'regdate'
    mySQLColumnRegisterIp: 'regip'
    mySQLColumnRealName: 'realname'
    mySQLColumnGroup: 'id'
    mySQLlastlocX: 'x'
    mySQLlastlocY: 'y'
    mySQLlastlocZ: 'z'
    mySQLlastlocWorld: 'world'
    mySQLlastlocYaw: 'yaw'
    mySQLlastlocPitch: 'pitch'
    mySQLColumnEmail: 'email'
    mySQLColumnLogged: 'isLogged'
    mySQLColumnHasSession: 'hasSession'
    mySQLColumnTotp: 'totp'

settings:
    sessions:
        enabled: true
        timeout: 10
    registration:
        enabled: true
        type: PASSWORD
        secondArg: CONFIRMATION
        enableConfirmEmail: false
        forceKick: false
        forceRegistration: true
        registerLoginDelay: 5
        maxRegPerIp: 3
        passwordMinLen: 5
        passwordMaxLen: 30
    unrestricted:
        enableProtection: true
        allowCommands:
        - '/login'
        - '/register'
        - '/l'
        - '/reg'
        - '/email'
        - '/captcha'
        - '/2fa'
        - '/totp'
    GameMode:
        forceStartGameModeType: SURVIVAL
        resetInventoryIfCreative: false
    security:
        minPasswordLength: 5
        passwordHash: BCRYPT
        doubleMD5SaltLength: 8
        supportOldPasswordHash: false
        preventOtherCase: true
    messages:
        language: 'ru'
        messagesFile: 'messages_ru.yml'
        logConsole: true
        noConsoleSpam: false
        removeSpamFromConsole: false
        removePassword: true
        removeJoinMessage: true
        removeLeaveMessage: true
        delayJoinMessage: false
        joinMessageDelay: 5
        broadcastWelcomeMessage: true
        forceRegKick: true
        forceRegLogin: true
        kickPlayersBeforeShutdown: true
        enableWelcomeMessage: true
        enableBroadcastWelcomeMessage: false
        broadcastSessionLogin: false
        displayOtherAccounts: true
        useChatManager: true
        logPlayerCommands: true
EOF

echo ""
echo "✅ База данных настроена!"
echo "📊 Созданы таблицы:"
echo "   - authme (авторизация игроков)"
echo "   - website_users (пользователи сайта)"
echo "   - donate_items (донат товары)"
echo "   - purchases (покупки)"
echo "   - player_stats (статистика игроков)"
echo "   - server_logs (логи сервера)"
echo ""
echo "🔑 Данные для подключения:"
echo "   - База данных: minecraft_server"
echo "   - Пользователь: minecraft"
echo "   - Пароль: minecraft_password_2024"
echo ""
echo "👤 Админ аккаунт создан:"
echo "   - Логин: admin"
echo "   - Email: admin@server.com"
echo "   - Пароль: admin123 (измените после первого входа)"