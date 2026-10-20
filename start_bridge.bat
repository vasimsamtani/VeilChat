@echo off
title VeilChat WhatsApp Multi-Device Bridge
echo =============================================================
echo   VeilChat Local WhatsApp Bridge (Noise Protocol Daemon)
echo   Listening on: ws://localhost:5055
echo =============================================================
cd /d "%~dp0server"
if not exist node_modules (
    echo Installing bridge dependencies...
    call npm.cmd install
)
echo Starting bridge daemon...
node bridge.js
pause
