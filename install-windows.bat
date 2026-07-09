@echo off
REM CT3505-24 Windows installer launcher.
REM Double-click this file to install everything needed for Assignments 1 & 2.
setlocal
set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install-windows.ps1"
