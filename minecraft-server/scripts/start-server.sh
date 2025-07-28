#!/bin/bash

echo "🚀 Запуск Minecraft Server 1.21.8"
echo "=================================="

# Переход в директорию сервера
cd "$(dirname "$0")/../server" || exit 1

# Проверка наличия файла сервера
if [ ! -f "paper-1.21.8.jar" ]; then
    echo "❌ Файл сервера не найден. Запустите сначала ./scripts/install.sh"
    exit 1
fi

# Проверка Java
if ! command -v java &> /dev/null; then
    echo "❌ Java не установлена. Запустите сначала ./scripts/install.sh"
    exit 1
fi

# Проверка версии Java
java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$java_version" -lt 21 ]; then
    echo "❌ Требуется Java 21 или выше. Текущая версия: $java_version"
    exit 1
fi

# Создание EULA если не существует
if [ ! -f "eula.txt" ]; then
    echo "📝 Создание EULA..."
    echo "eula=true" > eula.txt
fi

# Создание директорий если не существуют
mkdir -p logs backups worlds plugins

# Проверка свободной памяти
total_ram=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
echo "💾 Доступно RAM: ${total_ram}GB"

# Настройка параметров JVM в зависимости от RAM
if [ "$total_ram" -ge 8 ]; then
    XMX="6G"
    XMS="4G"
elif [ "$total_ram" -ge 4 ]; then
    XMX="3G"
    XMS="2G"
else
    XMX="2G"
    XMS="1G"
fi

echo "🔧 Параметры JVM: -Xmx$XMX -Xms$XMS"

# Создание скрипта бэкапа
echo "💾 Настройка автоматических бэкапов..."
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="../backups"
mkdir -p "$BACKUP_DIR"

echo "Создание бэкапа: $DATE"
tar -czf "$BACKUP_DIR/backup_$DATE.tar.gz" worlds plugins server.properties *.yml *.json
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +7 -delete
echo "Бэкап завершен: backup_$DATE.tar.gz"
EOF
chmod +x backup.sh

# Создание cron задачи для бэкапов (каждые 6 часов)
(crontab -l 2>/dev/null; echo "0 */6 * * * $(pwd)/backup.sh") | crontab -

# Функция остановки сервера
cleanup() {
    echo ""
    echo "🛑 Остановка сервера..."
    if [ -n "$SERVER_PID" ]; then
        kill -TERM "$SERVER_PID"
        wait "$SERVER_PID"
    fi
    echo "✅ Сервер остановлен"
    exit 0
}

# Обработка сигналов
trap cleanup SIGINT SIGTERM

echo "🎮 Запуск сервера..."
echo "📊 Мониторинг: http://localhost:3000/admin"
echo "🔧 RCON порт: 25575 (пароль: admin123)"
echo "🌐 Сервер порт: 25565"
echo ""
echo "Для остановки нажмите Ctrl+C"
echo "=========================="

# Запуск сервера с оптимизированными флагами
java -Xmx$XMX -Xms$XMS \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1NewSizePercent=30 \
    -XX:G1MaxNewSizePercent=40 \
    -XX:G1HeapRegionSize=8m \
    -XX:G1ReservePercent=20 \
    -XX:G1HeapWastePercent=5 \
    -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=15 \
    -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:G1RSetUpdatingPauseTimePercent=5 \
    -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem \
    -XX:MaxTenuringThreshold=1 \
    -Dusing.aikars.flags=https://mcflags.emc.gs \
    -Daikars.new.flags=true \
    -Dpaper.playerconnection.keepalive=60 \
    -jar paper-1.21.8.jar nogui &

SERVER_PID=$!

# Ожидание завершения сервера
wait $SERVER_PID