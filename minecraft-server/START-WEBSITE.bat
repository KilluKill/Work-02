@echo off
title Minecraft Website
echo ========================================
echo      ЗАПУСК ВЕБ-САЙТА С ДОНАТОМ
echo ========================================
echo.

cd /d "%~dp0website"

:: Проверка Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js не найден!
    echo Скачайте с https://nodejs.org/
    pause
    exit /b 1
)

:: Проверка package.json
if not exist "package.json" (
    echo [ERROR] package.json не найден!
    echo Запустите сначала START-WINDOWS.bat
    pause
    exit /b 1
)

:: Установка зависимостей если нужно
if not exist "node_modules" (
    echo [INFO] Установка npm пакетов...
    npm install
)

echo [INFO] Запуск веб-сайта...
echo [INFO] Сайт будет доступен по адресу: http://localhost:3000
echo [INFO] Админ панель: http://localhost:3000/admin
echo [INFO] Логин: admin, Пароль: admin123
echo [INFO] Для остановки нажмите Ctrl+C
echo ========================================
echo.

:: Запуск сайта
node server.js

echo.
echo [INFO] Веб-сайт остановлен
pause