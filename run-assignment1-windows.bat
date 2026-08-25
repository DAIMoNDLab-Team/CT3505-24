@echo off
REM CT3505-24 Assignment 1 launcher.
REM Double-click this file to start Mercury for Assignment 1.
setlocal
set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%run-assignment1-windows.ps1"
