# CT3505-24 Assignment 1 launcher (Windows).
# Activates the "ct3505" conda environment and starts Mercury for
# Assignment 1 - your browser will open automatically.
# Run install-windows.bat first if you haven't already.

$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvName = "ct3505"
Set-Location $ProjectDir

Write-Host "CT3505-24 - Assignment 1"
Write-Host "========================="

function Test-CommandExists($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

$condaCandidates = @(
    "$env:USERPROFILE\miniconda3\Scripts\conda.exe",
    "$env:USERPROFILE\anaconda3\Scripts\conda.exe",
    "$env:LOCALAPPDATA\miniconda3\Scripts\conda.exe",
    "C:\ProgramData\miniconda3\Scripts\conda.exe",
    "C:\ProgramData\anaconda3\Scripts\conda.exe"
)
$condaExe = $null
if (Test-CommandExists "conda") {
    $condaExe = (Get-Command conda).Source
} else {
    foreach ($c in $condaCandidates) {
        if (Test-Path $c) { $condaExe = $c; break }
    }
}

if (-not $condaExe) {
    Write-Host "Could not find conda. Please run install-windows.bat first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$envList = & $condaExe env list
if (-not ($envList -match "^\s*$EnvName\s")) {
    Write-Host "The '$EnvName' conda environment was not found. Please run install-windows.bat first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Starting Mercury for Assignment 1..."
Write-Host "Your browser will open automatically. Close this window (or press Ctrl+C) to stop the server when you're done."
& $condaExe run --no-capture-output -n $EnvName mercury run

Read-Host "`nPress Enter to close this window"
