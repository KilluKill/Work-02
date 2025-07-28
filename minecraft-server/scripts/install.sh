#!/bin/bash

echo "🎮 Установка Minecraft Server 1.21.8 - Крутая сборка"
echo "=================================================="

# Проверка прав root
if [[ $EUID -eq 0 ]]; then
   echo "❌ Не запускайте этот скрипт от имени root"
   exit 1
fi

# Обновление системы
echo "📦 Обновление системы..."
sudo apt update && sudo apt upgrade -y

# Установка Java 21 (требуется для Minecraft 1.21.8)
echo "☕ Установка Java 21..."
sudo apt install -y openjdk-21-jdk openjdk-21-jre

# Проверка версии Java
java -version

# Установка MySQL
echo "🗄️ Установка MySQL..."
sudo apt install -y mysql-server mysql-client

# Установка Node.js и npm для веб-сайта
echo "🌐 Установка Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Установка дополнительных пакетов
echo "🔧 Установка дополнительных пакетов..."
sudo apt install -y wget curl unzip screen htop git

# Создание пользователя minecraft
echo "👤 Создание пользователя minecraft..."
sudo useradd -r -m -U -d /opt/minecraft -s /bin/bash minecraft || echo "Пользователь minecraft уже существует"

# Скачивание Paper сервера
echo "📥 Скачивание Paper Server 1.21.8..."
cd server
if [ ! -f "paper-1.21.8.jar" ]; then
    wget -O paper-1.21.8.jar "https://api.papermc.io/v2/projects/paper/versions/1.21.8/builds/latest/downloads/paper-1.21.8-latest.jar"
fi

# Создание скрипта запуска сервера
echo "📝 Создание скрипта запуска..."
cat > start.sh << 'EOF'
#!/bin/bash
java -Xmx4G -Xms2G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8m -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar paper-1.21.8.jar nogui
EOF
chmod +x start.sh

cd ..

# Создание базовых конфигураций
echo "⚙️ Создание базовых конфигураций..."
cat > server/server.properties << 'EOF'
# Minecraft server properties
server-name=Крутой Сервер 1.21.8
server-port=25565
level-name=world
gamemode=survival
difficulty=normal
allow-nether=true
allow-flight=true
announce-player-achievements=true
enable-command-block=true
generate-structures=true
level-seed=
level-type=minecraft:normal
max-build-height=320
max-players=100
max-world-size=29999984
motd=§6§l🎮 Крутой Сервер Minecraft 1.21.8 §r§a- §b§lДонат §7| §c§lПВП §7| §e§lМини-игры
online-mode=false
op-permission-level=4
player-idle-timeout=0
pvp=true
spawn-animals=true
spawn-monsters=true
spawn-npcs=true
spawn-protection=16
view-distance=10
white-list=false
enforce-whitelist=false
enable-rcon=true
rcon.port=25575
rcon.password=admin123
enable-query=true
query.port=25565
EOF

# Установка плагинов
echo "🔌 Скачивание плагинов..."
cd server/plugins

# Основные плагины
echo "📦 Скачивание основных плагинов..."
plugins=(
    "https://github.com/EssentialsX/Essentials/releases/latest/download/EssentialsX-2.20.1.jar"
    "https://github.com/EssentialsX/Essentials/releases/latest/download/EssentialsXChat-2.20.1.jar"
    "https://github.com/EssentialsX/Essentials/releases/latest/download/EssentialsXSpawn-2.20.1.jar"
    "https://github.com/AuthMe/AuthMeReloaded/releases/latest/download/AuthMe-5.6.0.jar"
    "https://github.com/LuckPerms/LuckPerms/releases/latest/download/LuckPerms-Bukkit-5.4.102.jar"
    "https://dev.bukkit.org/projects/vault/files/latest"
    "https://dev.bukkit.org/projects/worldedit/files/latest"
    "https://dev.bukkit.org/projects/worldguard/files/latest"
)

for plugin in "${plugins[@]}"; do
    echo "Скачивание: $plugin"
    wget -q "$plugin" || echo "Не удалось скачать: $plugin"
done

cd ../..

# Настройка веб-сайта
echo "🌐 Настройка веб-сайта..."
cd website
npm init -y
npm install express mysql2 bcryptjs jsonwebtoken cors helmet express-rate-limit multer nodemailer stripe paypal-rest-sdk body-parser express-session connect-mysql-session

cd ..

# Установка завершена
echo ""
echo "✅ Установка завершена!"
echo "🚀 Для запуска сервера выполните: ./scripts/start-server.sh"
echo "🌐 Для запуска веб-сайта: cd website && npm start"
echo "🔧 Настройте MySQL: ./scripts/setup-database.sh"
echo ""
echo "📋 Порты:"
echo "   - Minecraft сервер: 25565"
echo "   - Веб-сайт: 3000"
echo "   - MySQL: 3306"
echo "   - RCON: 25575"