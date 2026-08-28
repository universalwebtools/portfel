@echo off
chcp 65001 >nul
title Wspólny Portfel - wersja testowa
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0serwer-lokalny.ps1"
if errorlevel 1 (
  echo.
  echo Nie udało sie uruchomic aplikacji.
  echo Zrob zrzut tego okna i wyslij go do ChatGPT.
  pause
)
