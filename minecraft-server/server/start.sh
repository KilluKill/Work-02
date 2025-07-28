#!/bin/bash

# Minecraft Server 1.21.8 - Автозапуск для хостинга
# Этот скрипт автоматически запустит сервер на любом Linux хостинге

echo "🎮 Запуск Minecraft Server 1.21.8..."
echo "📅 $(date)"
echo "📍 Директория: $(pwd)"

# Проверка Java
if ! command -v java &> /dev/null; then
    echo "❌ Java не найдена! Устанавливаем..."
    # Для Ubuntu/Debian хостингов
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y openjdk-21-jdk
    # Для CentOS/RHEL хостингов  
    elif command -v yum &> /dev/null; then
        sudo yum install -y java-21-openjdk
    fi
fi

# Создание необходимых папок
mkdir -p logs backups worlds plugins

# Проверка EULA
if [ ! -f "eula.txt" ]; then
    echo "eula=true" > eula.txt
    echo "✅ EULA принята автоматически"
fi

# Определение RAM
TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
if [ $TOTAL_RAM -gt 8 ]; then
    XMX="6G"
    XMS="2G"
elif [ $TOTAL_RAM -gt 4 ]; then
    XMX="3G" 
    XMS="1G"
else
    XMX="2G"
    XMS="512M"
fi

echo "💾 Доступно RAM: ${TOTAL_RAM}GB"
echo "⚙️ Настройки JVM: -Xmx$XMX -Xms$XMS"

# Проверка файла сервера
if [ ! -f "paper-1.21.8.jar" ]; then
    echo "❌ Файл paper-1.21.8.jar не найден!"
    echo "📥 Скачиваем Paper сервер..."
    wget -O paper-1.21.8.jar https://api.papermc.io/v2/projects/paper/versions/1.21.1/builds/132/downloads/paper-1.21.1-132.jar
fi

# Оптимизированные JVM флаги для хостинга
JVM_FLAGS="-Xmx$XMX -Xms$XMS"
JVM_FLAGS="$JVM_FLAGS -XX:+UseG1GC"
JVM_FLAGS="$JVM_FLAGS -XX:+ParallelRefProcEnabled"
JVM_FLAGS="$JVM_FLAGS -XX:MaxGCPauseMillis=200"
JVM_FLAGS="$JVM_FLAGS -XX:+UnlockExperimentalVMOptions"
JVM_FLAGS="$JVM_FLAGS -XX:+DisableExplicitGC"
JVM_FLAGS="$JVM_FLAGS -XX:+AlwaysPreTouch"
JVM_FLAGS="$JVM_FLAGS -XX:G1HeapWastePercent=5"
JVM_FLAGS="$JVM_FLAGS -XX:G1MixedGCCountTarget=4"
JVM_FLAGS="$JVM_FLAGS -XX:InitiatingHeapOccupancyPercent=15"
JVM_FLAGS="$JVM_FLAGS -XX:G1MixedGCLiveThresholdPercent=90"
JVM_FLAGS="$JVM_FLAGS -XX:G1RSetUpdatingPauseTimePercent=5"
JVM_FLAGS="$JVM_FLAGS -XX:SurvivorRatio=32"
JVM_FLAGS="$JVM_FLAGS -XX:+PerfDisableSharedMem"
JVM_FLAGS="$JVM_FLAGS -XX:MaxTenuringThreshold=1"
JVM_FLAGS="$JVM_FLAGS -Dusing.aikars.flags=https://mcflags.emc.gs"
JVM_FLAGS="$JVM_FLAGS -Daikars.new.flags=true"

echo "🚀 Запуск сервера..."
echo "📝 Логи сохраняются в logs/latest.log"

# Запуск с автоперезапуском
while true; do
    java $JVM_FLAGS -jar paper-1.21.8.jar nogui
    
    EXIT_CODE=$?
    echo "🔄 Сервер остановлен с кодом: $EXIT_CODE"
    
    if [ $EXIT_CODE -ne 0 ]; then
        echo "❌ Сервер завершился с ошибкой!"
        echo "⏰ Перезапуск через 10 секунд..."
        sleep 10
    else
        echo "✅ Сервер остановлен корректно"
        break
    fi
done