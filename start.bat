@echo off
title 视频号下载器

echo ========================================
echo   视频号下载器 - 一键启动
echo ========================================
echo.

:: 检查 wx-dl.exe 是否存在
if not exist "%~dp0bin\wx-dl.exe" (
    echo [ERROR] 找不到 bin\wx-dl.exe
    pause
    exit /b 1
)

:: 启动代理服务（不加 server 子命令，直接启动 MITM 代理 + 注入下载按钮）
echo [INFO] 启动视频号代理服务...
echo [INFO] API 地址: http://127.0.0.1:2022
echo [INFO] 代理端口: 2023
echo.
echo 启动后请在微信 PC 客户端中打开视频号，页面会自动出现下载按钮。
echo 按 Ctrl+C 退出
echo.

"%~dp0bin\wx-dl.exe" --hostname 127.0.0.1 --port 2023

pause
