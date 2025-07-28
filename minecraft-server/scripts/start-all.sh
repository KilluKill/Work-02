#!/bin/bash

echo "🎮 Запуск полного Minecraft Server проекта"
echo "=========================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функция для цветного вывода
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}$1${NC}"
}

# Проверка прав пользователя
if [[ $EUID -eq 0 ]]; then
   print_error "Не запускайте этот скрипт от имени root"
   exit 1
fi

# Переход в директорию проекта
cd "$(dirname "$0")/.." || exit 1

print_header "🔧 Проверка системных требований..."

# Проверка Java
if ! command -v java &> /dev/null; then
    print_error "Java не установлена. Запустите сначала ./scripts/install.sh"
    exit 1
fi

# Проверка Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js не установлен. Запустите сначала ./scripts/install.sh"
    exit 1
fi

# Проверка MySQL
if ! command -v mysql &> /dev/null; then
    print_error "MySQL не установлен. Запустите сначала ./scripts/install.sh"
    exit 1
fi

print_status "Все системные требования выполнены ✅"

# Проверка файлов проекта
print_header "📁 Проверка файлов проекта..."

required_files=(
    "server/paper-1.21.8.jar"
    "website/server.js"
    "website/package.json"
    "database/config.js"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Файл $file не найден. Запустите ./scripts/install.sh"
        exit 1
    fi
done

print_status "Все файлы проекта найдены ✅"

# Проверка базы данных
print_header "🗄️ Проверка подключения к базе данных..."

if ! mysql -u minecraft -pminecraft_password_2024 -e "USE minecraft_server;" 2>/dev/null; then
    print_error "Не удается подключиться к базе данных. Запустите ./scripts/setup-database.sh"
    exit 1
fi

print_status "Подключение к базе данных успешно ✅"

# Установка зависимостей веб-сайта
print_header "📦 Установка зависимостей веб-сайта..."
cd website
if [ ! -d "node_modules" ]; then
    print_status "Установка npm пакетов..."
    npm install
fi
cd ..

# Создание .env файла для веб-сайта
print_header "⚙️ Создание конфигурационных файлов..."
cat > website/.env << 'EOF'
# Конфигурация для Minecraft Server Website
NODE_ENV=production
PORT=3000

# База данных
DB_HOST=localhost
DB_USER=minecraft
DB_PASSWORD=minecraft_password_2024
DB_NAME=minecraft_server

# Сессии
SESSION_SECRET=minecraft_secret_key_2024_super_secure

# RCON
RCON_HOST=localhost
RCON_PORT=25575
RCON_PASSWORD=admin123

# Платежные системы (настройте свои ключи)
STRIPE_SECRET_KEY=sk_test_your_stripe_key
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret

# Email настройки
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# Discord интеграция
DISCORD_BOT_TOKEN=your_discord_bot_token
DISCORD_GUILD_ID=your_discord_guild_id
EOF

print_status "Конфигурационные файлы созданы ✅"

# Создание systemd сервисов
print_header "🔧 Создание системных сервисов..."

# Сервис для Minecraft сервера
sudo tee /etc/systemd/system/minecraft-server.service > /dev/null << EOF
[Unit]
Description=Minecraft Server 1.21.8
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)/server
ExecStart=$(pwd)/scripts/start-server.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Сервис для веб-сайта
sudo tee /etc/systemd/system/minecraft-website.service > /dev/null << EOF
[Unit]
Description=Minecraft Website
After=network.target mysql.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)/website
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка systemd
sudo systemctl daemon-reload

print_status "Системные сервисы созданы ✅"

# Создание скрипта мониторинга
print_header "📊 Создание системы мониторинга..."
cat > scripts/monitor.sh << 'EOF'
#!/bin/bash

# Мониторинг Minecraft Server проекта

check_service() {
    local service=$1
    if systemctl is-active --quiet $service; then
        echo "✅ $service: Запущен"
    else
        echo "❌ $service: Остановлен"
        return 1
    fi
}

check_port() {
    local port=$1
    local name=$2
    if nc -z localhost $port 2>/dev/null; then
        echo "✅ $name (порт $port): Доступен"
    else
        echo "❌ $name (порт $port): Недоступен"
        return 1
    fi
}

echo "🔍 Мониторинг Minecraft Server проекта"
echo "======================================"

# Проверка сервисов
check_service mysql
check_service minecraft-server
check_service minecraft-website

echo ""

# Проверка портов
check_port 3306 "MySQL"
check_port 25565 "Minecraft Server"
check_port 3000 "Website"
check_port 25575 "RCON"

echo ""

# Проверка ресурсов
echo "💾 Использование ресурсов:"
echo "RAM: $(free -h | awk 'NR==2{printf "%.1f/%.1f GB (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Диск: $(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3, $2, $5}')"

echo ""

# Проверка логов
echo "📋 Последние записи в логах:"
echo "Minecraft Server:"
tail -n 3 ../server/logs/latest.log 2>/dev/null || echo "Логи не найдены"
echo ""
echo "Website:"
journalctl -u minecraft-website --no-pager -n 3 2>/dev/null || echo "Логи не найдены"
EOF

chmod +x scripts/monitor.sh

print_status "Система мониторинга создана ✅"

# Функция запуска
start_services() {
    print_header "🚀 Запуск всех сервисов..."
    
    # Запуск MySQL
    print_status "Запуск MySQL..."
    sudo systemctl start mysql
    
    # Ожидание запуска MySQL
    sleep 3
    
    # Запуск веб-сайта
    print_status "Запуск веб-сайта..."
    sudo systemctl start minecraft-website
    
    # Ожидание запуска веб-сайта
    sleep 5
    
    # Запуск Minecraft сервера
    print_status "Запуск Minecraft сервера..."
    sudo systemctl start minecraft-server
    
    # Включение автозапуска
    sudo systemctl enable mysql
    sudo systemctl enable minecraft-website
    sudo systemctl enable minecraft-server
    
    print_status "Все сервисы запущены ✅"
}

# Функция остановки
stop_services() {
    print_header "🛑 Остановка всех сервисов..."
    
    sudo systemctl stop minecraft-server
    sudo systemctl stop minecraft-website
    
    print_status "Все сервисы остановлены ✅"
}

# Функция перезапуска
restart_services() {
    print_header "🔄 Перезапуск всех сервисов..."
    
    stop_services
    sleep 5
    start_services
    
    print_status "Все сервисы перезапущены ✅"
}

# Функция статуса
show_status() {
    print_header "📊 Статус сервисов..."
    
    ./scripts/monitor.sh
}

# Обработка аргументов командной строки
case "${1:-start}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    monitor)
        watch -n 5 './scripts/monitor.sh'
        ;;
    *)
        echo "Использование: $0 {start|stop|restart|status|monitor}"
        echo ""
        echo "Команды:"
        echo "  start   - Запустить все сервисы"
        echo "  stop    - Остановить все сервисы"
        echo "  restart - Перезапустить все сервисы"
        echo "  status  - Показать статус сервисов"
        echo "  monitor - Мониторинг в реальном времени"
        exit 1
        ;;
esac

# Показать информацию после запуска
if [ "${1:-start}" = "start" ]; then
    sleep 10
    
    print_header "🎉 Minecraft Server проект запущен!"
    echo ""
    echo "📱 Доступные сервисы:"
    echo "  🌐 Веб-сайт:        http://localhost:3000"
    echo "  🎮 Minecraft:       localhost:25565"
    echo "  🗄️ MySQL:           localhost:3306"
    echo "  🔧 RCON:            localhost:25575"
    echo ""
    echo "👤 Админ аккаунт:"
    echo "  Логин: admin"
    echo "  Email: admin@server.com"
    echo "  Пароль: admin123"
    echo ""
    echo "🔧 Управление:"
    echo "  Мониторинг:         ./scripts/start-all.sh status"
    echo "  Перезапуск:         ./scripts/start-all.sh restart"
    echo "  Остановка:          ./scripts/start-all.sh stop"
    echo ""
    echo "📚 Документация:"
    echo "  README:             ./README.md"
    echo "  Плагины:            ./server/plugins/plugins-list.md"
    echo ""
    print_status "Проект готов к использованию! 🚀"
fi