@echo off
echo ============================================
echo    MINECRAFT SERVER 1.21.8 - WINDOWS
echo ============================================
echo.

:: Проверка Java
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Java не найдена!
    echo Скачайте Java 21 с https://adoptium.net/
    pause
    exit /b 1
)

:: Проверка Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js не найден!
    echo Скачайте Node.js с https://nodejs.org/
    pause
    exit /b 1
)

echo [INFO] Проверка зависимостей прошла успешно
echo.

:: Создание директорий
if not exist "server\plugins" mkdir server\plugins
if not exist "server\worlds" mkdir server\worlds
if not exist "server\logs" mkdir server\logs
if not exist "website\node_modules" (
    echo [INFO] Установка npm пакетов...
    cd website
    npm install
    cd ..
)

:: Создание EULA
echo eula=true > server\eula.txt

:: Создание server.properties
echo server-port=25565 > server\server.properties
echo level-name=world >> server\server.properties
echo gamemode=survival >> server\server.properties
echo difficulty=normal >> server\server.properties
echo allow-nether=true >> server\server.properties
echo allow-flight=true >> server\server.properties
echo max-players=100 >> server\server.properties
echo motd=§6§l🎮 Крутой Сервер Minecraft 1.21.8 §r§a- §b§lДонат §7^| §c§lПВП §7^| §e§lМини-игры >> server\server.properties
echo online-mode=false >> server\server.properties
echo enable-rcon=true >> server\server.properties
echo rcon.port=25575 >> server\server.properties
echo rcon.password=admin123 >> server\server.properties

:: Скачивание Paper сервера если нет
if not exist "server\paper-1.21.8.jar" (
    echo [INFO] Скачивание Paper сервера...
    powershell -Command "Invoke-WebRequest -Uri 'https://api.papermc.io/v2/projects/paper/versions/1.21.1/builds/latest/downloads/paper-1.21.1-latest.jar' -OutFile 'server\paper-1.21.8.jar'"
)

:: Создание .env файла для сайта
echo NODE_ENV=development > website\.env
echo PORT=3000 >> website\.env
echo DB_HOST=localhost >> website\.env
echo DB_USER=root >> website\.env
echo DB_PASSWORD= >> website\.env
echo DB_NAME=minecraft_server >> website\.env
echo SESSION_SECRET=minecraft_secret_key_2024 >> website\.env
echo RCON_HOST=localhost >> website\.env
echo RCON_PORT=25575 >> website\.env
echo RCON_PASSWORD=admin123 >> website\.env

echo.
echo [SUCCESS] Настройка завершена!
echo.
echo Теперь запустите:
echo 1. START-MINECRAFT.bat - для запуска Minecraft сервера
echo 2. START-WEBSITE.bat - для запуска веб-сайта
echo.
echo После запуска:
echo - Minecraft сервер: localhost:25565
echo - Веб-сайт: http://localhost:3000
echo - Админ: admin / admin123
echo.
pause