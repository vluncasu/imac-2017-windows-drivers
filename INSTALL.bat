@echo off
title iMac 2017 Driver Installer
echo.
echo   iMac 27" 2017 (iMac18,3) - Windows Driver Installer
echo   ====================================================
echo.

:: Check admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo   Requesting administrator privileges...
    powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d \"%~dp0\" && \"%~f0\"'"
    exit /b
)

cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
