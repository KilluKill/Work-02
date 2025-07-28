const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const session = require('express-session');
const MySQLStore = require('connect-mysql-session')(session);
const { body, validationResult } = require('express-validator');
const moment = require('moment');
const path = require('path');
const fs = require('fs');
const http = require('http');
const socketIo = require('socket.io');
const { Rcon } = require('rcon-client');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server);
const PORT = process.env.PORT || 3000;

// Конфигурация базы данных
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'minecraft',
    password: process.env.DB_PASSWORD || 'minecraft_password_2024',
    database: process.env.DB_NAME || 'minecraft_server',
    charset: 'utf8mb4'
};

// Создание пула соединений с БД
const pool = mysql.createPool(dbConfig);

// Настройка сессий
const sessionStore = new MySQLStore({
    host: dbConfig.host,
    port: 3306,
    user: dbConfig.user,
    password: dbConfig.password,
    database: dbConfig.database
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

// Настройка сессий
app.use(session({
    key: 'minecraft_session',
    secret: process.env.SESSION_SECRET || 'minecraft_secret_key_2024',
    store: sessionStore,
    resave: false,
    saveUninitialized: false,
    cookie: {
        maxAge: 24 * 60 * 60 * 1000, // 24 часа
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production'
    }
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 минут
    max: 100, // максимум 100 запросов за окно
    message: 'Слишком много запросов, попробуйте позже'
});
app.use(limiter);

// Строгий лимит для авторизации
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    message: 'Слишком много попыток входа, попробуйте через 15 минут'
});

// Настройка шаблонизатора
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware для проверки авторизации
const requireAuth = (req, res, next) => {
    if (!req.session.userId) {
        return res.status(401).json({ error: 'Требуется авторизация' });
    }
    next();
};

// Middleware для проверки роли администратора
const requireAdmin = async (req, res, next) => {
    if (!req.session.userId) {
        return res.status(401).json({ error: 'Требуется авторизация' });
    }
    
    try {
        const [rows] = await pool.execute(
            'SELECT role FROM website_users WHERE id = ?',
            [req.session.userId]
        );
        
        if (rows.length === 0 || rows[0].role !== 'admin') {
            return res.status(403).json({ error: 'Недостаточно прав' });
        }
        
        next();
    } catch (error) {
        console.error('Ошибка проверки прав:', error);
        res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
};

// RCON подключение к серверу Minecraft
let rconClient = null;
const connectRcon = async () => {
    try {
        rconClient = new Rcon({
            host: 'localhost',
            port: 25575,
            password: 'admin123'
        });
        await rconClient.connect();
        console.log('✅ RCON подключение установлено');
    } catch (error) {
        console.error('❌ Ошибка подключения RCON:', error.message);
    }
};

// Функция выполнения команд на сервере
const executeServerCommand = async (command) => {
    if (!rconClient) {
        await connectRcon();
    }
    
    try {
        const response = await rconClient.send(command);
        return response;
    } catch (error) {
        console.error('Ошибка выполнения команды:', error);
        return null;
    }
};

// ============ МАРШРУТЫ ============

// Главная страница
app.get('/', async (req, res) => {
    try {
        // Получение статистики сервера
        const [onlineStats] = await pool.execute(
            'SELECT COUNT(*) as total_players FROM player_stats WHERE last_seen > DATE_SUB(NOW(), INTERVAL 24 HOUR)'
        );
        
        const [serverInfo] = await pool.execute(
            'SELECT COUNT(*) as total_registered FROM website_users WHERE is_active = 1'
        );
        
        res.render('index', {
            user: req.session.userId ? await getUserById(req.session.userId) : null,
            stats: {
                online_players: Math.floor(Math.random() * 50) + 10, // Имитация онлайна
                total_players: serverInfo[0].total_registered,
                server_version: '1.21.8',
                uptime: '99.9%'
            }
        });
    } catch (error) {
        console.error('Ошибка загрузки главной страницы:', error);
        res.status(500).render('error', { error: 'Ошибка загрузки страницы' });
    }
});

// Страница регистрации
app.get('/register', (req, res) => {
    if (req.session.userId) {
        return res.redirect('/profile');
    }
    res.render('register');
});

// Регистрация пользователя
app.post('/register', authLimiter, [
    body('username').isLength({ min: 3, max: 20 }).matches(/^[a-zA-Z0-9_]+$/),
    body('email').isEmail(),
    body('password').isLength({ min: 6 }),
    body('minecraft_username').isLength({ min: 3, max: 16 }).matches(/^[a-zA-Z0-9_]+$/)
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { username, email, password, minecraft_username } = req.body;

        // Проверка существования пользователя
        const [existing] = await pool.execute(
            'SELECT id FROM website_users WHERE username = ? OR email = ? OR minecraft_username = ?',
            [username, email, minecraft_username]
        );

        if (existing.length > 0) {
            return res.status(400).json({ error: 'Пользователь уже существует' });
        }

        // Хеширование пароля
        const hashedPassword = await bcrypt.hash(password, 12);

        // Создание пользователя
        const [result] = await pool.execute(
            'INSERT INTO website_users (username, email, password, minecraft_username) VALUES (?, ?, ?, ?)',
            [username, email, hashedPassword, minecraft_username]
        );

        // Создание записи в статистике игрока
        await pool.execute(
            'INSERT INTO player_stats (username) VALUES (?) ON DUPLICATE KEY UPDATE username = username',
            [minecraft_username]
        );

        req.session.userId = result.insertId;
        req.session.username = username;

        res.json({ success: true, message: 'Регистрация успешна!' });
    } catch (error) {
        console.error('Ошибка регистрации:', error);
        res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
});

// Страница входа
app.get('/login', (req, res) => {
    if (req.session.userId) {
        return res.redirect('/profile');
    }
    res.render('login');
});

// Авторизация пользователя
app.post('/login', authLimiter, [
    body('username').notEmpty(),
    body('password').notEmpty()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { username, password } = req.body;

        // Поиск пользователя
        const [users] = await pool.execute(
            'SELECT * FROM website_users WHERE (username = ? OR email = ?) AND is_active = 1',
            [username, username]
        );

        if (users.length === 0) {
            return res.status(400).json({ error: 'Неверные данные для входа' });
        }

        const user = users[0];

        // Проверка пароля
        const isValidPassword = await bcrypt.compare(password, user.password);
        if (!isValidPassword) {
            return res.status(400).json({ error: 'Неверные данные для входа' });
        }

        // Обновление времени последнего входа
        await pool.execute(
            'UPDATE website_users SET last_login = NOW() WHERE id = ?',
            [user.id]
        );

        req.session.userId = user.id;
        req.session.username = user.username;
        req.session.role = user.role;

        res.json({ success: true, message: 'Вход выполнен успешно!' });
    } catch (error) {
        console.error('Ошибка авторизации:', error);
        res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
});

// Выход
app.post('/logout', (req, res) => {
    req.session.destroy((err) => {
        if (err) {
            return res.status(500).json({ error: 'Ошибка выхода' });
        }
        res.json({ success: true, message: 'Выход выполнен успешно' });
    });
});

// Профиль пользователя
app.get('/profile', requireAuth, async (req, res) => {
    try {
        const user = await getUserById(req.session.userId);
        const [purchases] = await pool.execute(
            `SELECT p.*, di.name as item_name, di.price 
             FROM purchases p 
             JOIN donate_items di ON p.item_id = di.id 
             WHERE p.user_id = ? 
             ORDER BY p.created_at DESC LIMIT 10`,
            [req.session.userId]
        );

        const [stats] = await pool.execute(
            'SELECT * FROM player_stats WHERE username = ?',
            [user.minecraft_username]
        );

        res.render('profile', {
            user,
            purchases,
            stats: stats[0] || {}
        });
    } catch (error) {
        console.error('Ошибка загрузки профиля:', error);
        res.status(500).render('error', { error: 'Ошибка загрузки профиля' });
    }
});

// Донат-магазин
app.get('/shop', async (req, res) => {
    try {
        const [items] = await pool.execute(
            'SELECT * FROM donate_items WHERE is_active = 1 ORDER BY category, price'
        );

        const categories = {
            rank: items.filter(item => item.category === 'rank'),
            currency: items.filter(item => item.category === 'currency'),
            case: items.filter(item => item.category === 'case'),
            privilege: items.filter(item => item.category === 'privilege'),
            other: items.filter(item => item.category === 'other')
        };

        res.render('shop', {
            user: req.session.userId ? await getUserById(req.session.userId) : null,
            categories
        });
    } catch (error) {
        console.error('Ошибка загрузки магазина:', error);
        res.status(500).render('error', { error: 'Ошибка загрузки магазина' });
    }
});

// Покупка товара
app.post('/purchase', requireAuth, async (req, res) => {
    try {
        const { item_id, payment_method } = req.body;
        const user = await getUserById(req.session.userId);

        // Получение информации о товаре
        const [items] = await pool.execute(
            'SELECT * FROM donate_items WHERE id = ? AND is_active = 1',
            [item_id]
        );

        if (items.length === 0) {
            return res.status(404).json({ error: 'Товар не найден' });
        }

        const item = items[0];

        // Создание записи о покупке
        const [result] = await pool.execute(
            `INSERT INTO purchases (user_id, item_id, price, payment_method, minecraft_username, status) 
             VALUES (?, ?, ?, ?, ?, 'pending')`,
            [user.id, item.id, item.price, payment_method, user.minecraft_username]
        );

        // Имитация обработки платежа (в реальности здесь будет интеграция с платежными системами)
        setTimeout(async () => {
            try {
                // Обновление статуса покупки
                await pool.execute(
                    'UPDATE purchases SET status = "completed", completed_at = NOW() WHERE id = ?',
                    [result.insertId]
                );

                // Выполнение команд на сервере
                if (item.commands) {
                    const commands = item.commands.split('\n');
                    for (const command of commands) {
                        const processedCommand = command.replace('{username}', user.minecraft_username);
                        await executeServerCommand(processedCommand);
                    }
                }

                // Логирование покупки
                await pool.execute(
                    'INSERT INTO server_logs (type, username, message) VALUES (?, ?, ?)',
                    ['purchase', user.minecraft_username, `Куплен товар: ${item.name}`]
                );

                console.log(`✅ Покупка завершена: ${user.minecraft_username} купил ${item.name}`);
            } catch (error) {
                console.error('Ошибка обработки покупки:', error);
            }
        }, 2000);

        res.json({ 
            success: true, 
            message: 'Покупка в обработке. Товар будет выдан в течение нескольких минут.',
            purchase_id: result.insertId
        });
    } catch (error) {
        console.error('Ошибка покупки:', error);
        res.status(500).json({ error: 'Ошибка обработки покупки' });
    }
});

// Админ-панель
app.get('/admin', requireAdmin, async (req, res) => {
    try {
        // Статистика
        const [userStats] = await pool.execute('SELECT COUNT(*) as total FROM website_users');
        const [purchaseStats] = await pool.execute('SELECT COUNT(*) as total, SUM(price) as revenue FROM purchases WHERE status = "completed"');
        const [onlineStats] = await pool.execute('SELECT COUNT(*) as online FROM player_stats WHERE last_seen > DATE_SUB(NOW(), INTERVAL 5 MINUTE)');

        // Последние покупки
        const [recentPurchases] = await pool.execute(
            `SELECT p.*, u.username, di.name as item_name 
             FROM purchases p 
             JOIN website_users u ON p.user_id = u.id 
             JOIN donate_items di ON p.item_id = di.id 
             ORDER BY p.created_at DESC LIMIT 10`
        );

        // Логи сервера
        const [serverLogs] = await pool.execute(
            'SELECT * FROM server_logs ORDER BY created_at DESC LIMIT 20'
        );

        res.render('admin', {
            user: await getUserById(req.session.userId),
            stats: {
                users: userStats[0].total,
                purchases: purchaseStats[0].total || 0,
                revenue: purchaseStats[0].revenue || 0,
                online: onlineStats[0].online || 0
            },
            recentPurchases,
            serverLogs
        });
    } catch (error) {
        console.error('Ошибка загрузки админ-панели:', error);
        res.status(500).render('error', { error: 'Ошибка загрузки админ-панели' });
    }
});

// API для получения статистики сервера
app.get('/api/server-status', async (req, res) => {
    try {
        // Имитация получения статуса сервера
        const status = {
            online: true,
            players: {
                online: Math.floor(Math.random() * 50) + 10,
                max: 100
            },
            version: '1.21.8',
            motd: 'Крутой Сервер Minecraft 1.21.8 - Донат | ПВП | Мини-игры'
        };

        res.json(status);
    } catch (error) {
        console.error('Ошибка получения статуса сервера:', error);
        res.status(500).json({ error: 'Ошибка получения статуса' });
    }
});

// Вспомогательная функция получения пользователя
async function getUserById(userId) {
    const [users] = await pool.execute(
        'SELECT id, username, email, minecraft_username, role, balance, created_at, last_login FROM website_users WHERE id = ?',
        [userId]
    );
    return users[0] || null;
}

// Socket.IO для реального времени
io.on('connection', (socket) => {
    console.log('Пользователь подключился:', socket.id);

    socket.on('disconnect', () => {
        console.log('Пользователь отключился:', socket.id);
    });
});

// Обработка ошибок
app.use((err, req, res, next) => {
    console.error('Необработанная ошибка:', err);
    res.status(500).render('error', { error: 'Внутренняя ошибка сервера' });
});

// 404 страница
app.use((req, res) => {
    res.status(404).render('404');
});

// Запуск сервера
server.listen(PORT, async () => {
    console.log(`🌐 Веб-сайт запущен на порту ${PORT}`);
    console.log(`🔗 Адрес: http://localhost:${PORT}`);
    
    // Подключение к RCON
    await connectRcon();
    
    // Периодическое обновление статистики
    setInterval(async () => {
        try {
            // Обновление статистики онлайна (имитация)
            const onlinePlayers = Math.floor(Math.random() * 50) + 10;
            io.emit('server-stats', { online: onlinePlayers });
        } catch (error) {
            console.error('Ошибка обновления статистики:', error);
        }
    }, 30000); // каждые 30 секунд
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🛑 Получен сигнал SIGTERM, завершение работы...');
    server.close(() => {
        console.log('✅ Сервер остановлен');
        process.exit(0);
    });
});

module.exports = app;