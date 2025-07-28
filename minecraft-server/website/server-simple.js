const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcryptjs');

const app = express();
const PORT = process.env.PORT || 3000;

// Временная база данных в памяти (для тестирования)
const users = [
    {
        id: 1,
        username: 'admin',
        email: 'admin@server.com',
        password: '$2b$10$rKzXvJKJ5O4Y8gF2vH3hL.8K2Y8gF2vH3hL.8K2Y8gF2vH3hL.8K2Y', // admin123
        minecraft_username: 'Admin',
        role: 'admin',
        balance: 1000
    }
];

const donateItems = [
    { id: 1, name: 'VIP Статус', description: 'VIP статус на 30 дней', price: 199, category: 'rank' },
    { id: 2, name: 'Premium Статус', description: 'Premium статус на 30 дней', price: 399, category: 'rank' },
    { id: 3, name: '1000 Монет', description: 'Игровая валюта', price: 99, category: 'currency' },
    { id: 4, name: 'Донат Кейс', description: 'Кейс с случайными предметами', price: 149, category: 'case' }
];

const purchases = [];

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

app.use(session({
    secret: 'minecraft_secret_key_2024',
    resave: false,
    saveUninitialized: false,
    cookie: { maxAge: 24 * 60 * 60 * 1000 }
}));

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Routes
app.get('/', (req, res) => {
    const user = req.session.userId ? users.find(u => u.id === req.session.userId) : null;
    res.render('index', {
        user,
        stats: {
            online_players: Math.floor(Math.random() * 50) + 10,
            total_players: 1250,
            server_version: '1.21.8',
            uptime: '99.9%'
        }
    });
});

app.get('/login', (req, res) => {
    if (req.session.userId) {
        return res.redirect('/profile');
    }
    res.render('login');
});

app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    
    const user = users.find(u => u.username === username || u.email === username);
    if (!user) {
        return res.status(400).json({ error: 'Неверные данные для входа' });
    }
    
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
        return res.status(400).json({ error: 'Неверные данные для входа' });
    }
    
    req.session.userId = user.id;
    req.session.username = user.username;
    req.session.role = user.role;
    
    res.json({ success: true, message: 'Вход выполнен успешно!' });
});

app.get('/register', (req, res) => {
    if (req.session.userId) {
        return res.redirect('/profile');
    }
    res.render('register');
});

app.post('/register', async (req, res) => {
    const { username, email, password, minecraft_username } = req.body;
    
    if (users.find(u => u.username === username || u.email === email)) {
        return res.status(400).json({ error: 'Пользователь уже существует' });
    }
    
    const hashedPassword = await bcrypt.hash(password, 12);
    const newUser = {
        id: users.length + 1,
        username,
        email,
        password: hashedPassword,
        minecraft_username,
        role: 'user',
        balance: 0
    };
    
    users.push(newUser);
    req.session.userId = newUser.id;
    req.session.username = newUser.username;
    
    res.json({ success: true, message: 'Регистрация успешна!' });
});

app.post('/logout', (req, res) => {
    req.session.destroy();
    res.json({ success: true });
});

app.get('/profile', (req, res) => {
    if (!req.session.userId) {
        return res.redirect('/login');
    }
    
    const user = users.find(u => u.id === req.session.userId);
    const userPurchases = purchases.filter(p => p.user_id === req.session.userId);
    
    res.render('profile', {
        user,
        purchases: userPurchases,
        stats: { play_time: 12345, joins_count: 50, money: 1000 }
    });
});

app.get('/shop', (req, res) => {
    const user = req.session.userId ? users.find(u => u.id === req.session.userId) : null;
    
    const categories = {
        rank: donateItems.filter(item => item.category === 'rank'),
        currency: donateItems.filter(item => item.category === 'currency'),
        case: donateItems.filter(item => item.category === 'case'),
        privilege: [],
        other: []
    };
    
    res.render('shop', { user, categories });
});

app.post('/purchase', (req, res) => {
    if (!req.session.userId) {
        return res.status(401).json({ error: 'Требуется авторизация' });
    }
    
    const { item_id, payment_method } = req.body;
    const item = donateItems.find(i => i.id == item_id);
    const user = users.find(u => u.id === req.session.userId);
    
    if (!item) {
        return res.status(404).json({ error: 'Товар не найден' });
    }
    
    const purchase = {
        id: purchases.length + 1,
        user_id: req.session.userId,
        item_id: item.id,
        item_name: item.name,
        price: item.price,
        payment_method,
        status: 'completed',
        created_at: new Date()
    };
    
    purchases.push(purchase);
    
    res.json({
        success: true,
        message: 'Покупка успешно завершена! Товар выдан на сервере.',
        purchase_id: purchase.id
    });
});

app.get('/admin', (req, res) => {
    if (!req.session.userId) {
        return res.redirect('/login');
    }
    
    const user = users.find(u => u.id === req.session.userId);
    if (user.role !== 'admin') {
        return res.status(403).send('Недостаточно прав');
    }
    
    res.render('admin', {
        user,
        stats: {
            users: users.length,
            purchases: purchases.length,
            revenue: purchases.reduce((sum, p) => sum + p.price, 0),
            online: Math.floor(Math.random() * 50) + 10
        },
        recentPurchases: purchases.slice(-10),
        serverLogs: [
            { type: 'join', username: 'TestPlayer', message: 'Игрок зашел на сервер', created_at: new Date() },
            { type: 'purchase', username: 'Admin', message: 'Куплен VIP статус', created_at: new Date() }
        ]
    });
});

app.get('/api/server-status', (req, res) => {
    res.json({
        online: true,
        players: {
            online: Math.floor(Math.random() * 50) + 10,
            max: 100
        },
        version: '1.21.8',
        motd: 'Крутой Сервер Minecraft 1.21.8'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).send(`
        <h1>404 - Страница не найдена</h1>
        <p><a href="/">Вернуться на главную</a></p>
    `);
});

app.listen(PORT, () => {
    console.log('🌐 Веб-сайт запущен на порту', PORT);
    console.log('🔗 Откройте: http://localhost:' + PORT);
    console.log('👤 Админ: admin / admin123');
    console.log('📊 Админ-панель: http://localhost:' + PORT + '/admin');
});

module.exports = app;