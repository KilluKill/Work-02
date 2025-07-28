@echo off
title Minecraft Server 1.21.8
echo ========================================
echo    ЗАПУСК MINECRAFT СЕРВЕРА 1.21.8
echo ========================================
echo.

cd /d "%~dp0server"

:: Проверка файла сервера
if not exist "paper-1.21.8.jar" (
    echo [ERROR] Файл paper-1.21.8.jar не найден!
    echo Запустите сначала START-WINDOWS.bat
    pause
    exit /b 1
)

echo [INFO] Запуск Minecraft сервера...
echo [INFO] Для остановки нажмите Ctrl+C
echo [INFO] Консоль сервера будет доступна ниже
echo ========================================
echo.

:: Запуск сервера с оптимизированными флагами
java -Xmx4G -Xms2G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8m -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -jar paper-1.21.8.jar nogui

echo.
echo [INFO] Сервер остановлен
pause