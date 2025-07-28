-- Minecraft Server Database Setup
-- Автоматическая настройка базы данных для хостинга

-- Создание базы данных
CREATE DATABASE IF NOT EXISTS minecraft_server 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE minecraft_server;

-- Создание пользователя (если не существует)
CREATE USER IF NOT EXISTS 'minecraft'@'localhost' IDENTIFIED BY 'minecraft_password_2024';
CREATE USER IF NOT EXISTS 'minecraft'@'%' IDENTIFIED BY 'minecraft_password_2024';

-- Выдача прав
GRANT ALL PRIVILEGES ON minecraft_server.* TO 'minecraft'@'localhost';
GRANT ALL PRIVILEGES ON minecraft_server.* TO 'minecraft'@'%';
FLUSH PRIVILEGES;

-- Таблица пользователей AuthMe
CREATE TABLE IF NOT EXISTS authme (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    realname VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    ip VARCHAR(40) DEFAULT NULL,
    lastlogin BIGINT DEFAULT NULL,
    x DOUBLE DEFAULT 0,
    y DOUBLE DEFAULT 0,
    z DOUBLE DEFAULT 0,
    world VARCHAR(255) DEFAULT 'world',
    regdate BIGINT DEFAULT NULL,
    regip VARCHAR(40) DEFAULT NULL,
    yaw FLOAT DEFAULT 0,
    pitch FLOAT DEFAULT 0,
    email VARCHAR(255) DEFAULT NULL,
    isLogged SMALLINT DEFAULT 0,
    hasSession SMALLINT DEFAULT 0,
    totp VARCHAR(32) DEFAULT NULL
);

-- Таблица пользователей веб-сайта
CREATE TABLE IF NOT EXISTS website_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    minecraft_username VARCHAR(16) DEFAULT NULL,
    role ENUM('user', 'moderator', 'admin') DEFAULT 'user',
    balance DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    avatar VARCHAR(255) DEFAULT NULL
);

-- Таблица донат товаров
CREATE TABLE IF NOT EXISTS donate_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category ENUM('rank', 'currency', 'case', 'privilege', 'other') DEFAULT 'other',
    image VARCHAR(255) DEFAULT NULL,
    commands TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица покупок
CREATE TABLE IF NOT EXISTS purchases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    item_id INT NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    payment_method ENUM('card', 'paypal', 'qiwi', 'yandex') NOT NULL,
    transaction_id VARCHAR(255) DEFAULT NULL,
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES website_users(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES donate_items(id) ON DELETE CASCADE
);

-- Таблица сессий
CREATE TABLE IF NOT EXISTS sessions (
    session_id VARCHAR(128) PRIMARY KEY,
    expires INT UNSIGNED NOT NULL,
    data MEDIUMTEXT
);

-- Таблица статистики игроков
CREATE TABLE IF NOT EXISTS player_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(16) NOT NULL UNIQUE,
    play_time BIGINT DEFAULT 0,
    joins_count INT DEFAULT 0,
    last_join TIMESTAMP NULL,
    money DECIMAL(10,2) DEFAULT 0.00,
    kills INT DEFAULT 0,
    deaths INT DEFAULT 0,
    blocks_broken BIGINT DEFAULT 0,
    blocks_placed BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Таблица логов сервера
CREATE TABLE IF NOT EXISTS server_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type ENUM('join', 'leave', 'chat', 'command', 'purchase', 'error') NOT NULL,
    username VARCHAR(16) DEFAULT NULL,
    message TEXT NOT NULL,
    ip VARCHAR(40) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (type),
    INDEX idx_username (username),
    INDEX idx_created_at (created_at)
);

-- Вставка тестовых данных

-- Админ пользователь для веб-сайта
INSERT IGNORE INTO website_users (username, email, password, minecraft_username, role, balance) VALUES
('admin', 'admin@server.com', '$2b$12$rKzXvJKJ5O4Y8gF2vH3hL.8K2Y8gF2vH3hL.8K2Y8gF2vH3hL.8K2Y', 'Admin', 'admin', 1000.00);

-- Тестовые донат товары
INSERT IGNORE INTO donate_items (name, description, price, category, commands) VALUES
('VIP Статус', 'VIP статус на 30 дней с особыми привилегиями', 199.00, 'rank', 'lp user {player} parent add vip\nbc {player} получил VIP статус!'),
('Premium Статус', 'Premium статус на 30 дней с расширенными возможностями', 399.00, 'rank', 'lp user {player} parent add premium\nbc {player} получил Premium статус!'),
('MVP Статус', 'MVP статус на 30 дней - максимальные привилегии', 699.00, 'rank', 'lp user {player} parent add mvp\nbc {player} получил MVP статус!'),
('1000 Монет', 'Игровая валюта для покупок на сервере', 99.00, 'currency', 'eco give {player} 1000\nmsg {player} Вы получили 1000 монет!'),
('5000 Монет', 'Большое количество игровой валюты', 399.00, 'currency', 'eco give {player} 5000\nmsg {player} Вы получили 5000 монет!'),
('Донат Кейс', 'Кейс с случайными предметами и бонусами', 149.00, 'case', 'crate give physical common 1 {player}\nmsg {player} Вы получили донат кейс!'),
('Премиум Кейс', 'Кейс с редкими предметами', 299.00, 'case', 'crate give physical rare 1 {player}\nmsg {player} Вы получили премиум кейс!'),
('Легендарный Кейс', 'Кейс с легендарными предметами', 499.00, 'case', 'crate give physical legendary 1 {player}\nmsg {player} Вы получили легендарный кейс!'),
('Привилегия Полет', 'Возможность летать в выживании', 299.00, 'privilege', 'lp user {player} permission set essentials.fly true\nmsg {player} Теперь вы можете летать!'),
('Цветной Ник', 'Возможность использовать цвета в нике', 199.00, 'privilege', 'lp user {player} permission set essentials.nick.color true\nmsg {player} Теперь вы можете красить ник!');

-- Тестовая статистика игроков
INSERT IGNORE INTO player_stats (username, play_time, joins_count, money, kills, deaths) VALUES
('Admin', 86400000, 50, 1000.00, 25, 5),
('TestPlayer', 43200000, 25, 500.00, 10, 8);

-- Тестовые логи
INSERT INTO server_logs (type, username, message) VALUES
('join', 'Admin', 'Администратор зашел на сервер'),
('purchase', 'Admin', 'Куплен VIP статус за 199 рублей'),
('join', 'TestPlayer', 'Игрок зашел на сервер'),
('chat', 'TestPlayer', 'Привет всем!');

-- Создание индексов для оптимизации
CREATE INDEX idx_authme_username ON authme(username);
CREATE INDEX idx_website_users_email ON website_users(email);
CREATE INDEX idx_purchases_user_id ON purchases(user_id);
CREATE INDEX idx_purchases_status ON purchases(status);

-- Завершение
SELECT 'База данных minecraft_server успешно настроена!' as status;