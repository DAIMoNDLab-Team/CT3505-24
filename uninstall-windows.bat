@echo off
REM CT3505-24 Windows uninstaller launcher.
REM Double-click this file to remove what install-windows.ps1 installed.
setlocal
set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%uninstall-windows.ps1"
