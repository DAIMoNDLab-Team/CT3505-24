# CT3505-24 Windows installer
# Installs Miniconda, SUMO, and VS Code (if missing), creates the "ct3505"
# conda environment, installs the required Python packages, and points
# SUMO_HOME at the SUMO install folder. Safe to re-run.

$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvName = "ct3505"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

function Test-CommandExists($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Get-PersistedEnvVar($name) {
    $val = [Environment]::GetEnvironmentVariable($name, "Machine")
    if (-not $val) { $val = [Environment]::GetEnvironmentVariable($name, "User") }
    return $val
}

# --- Elevate to admin (needed for machine-wide winget installs) ---
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This installer needs administrator privileges. Approve the prompt that appears -"
    Write-Host "a new window will open and do the actual install; this window will close."
    Start-Sleep -Seconds 2
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "CT3505-24 installer"
Write-Host "===================="

# --- 1. winget ---
Write-Step "Checking for winget..."
if (-not (Test-CommandExists "winget")) {
    Write-Host "winget was not found. Please install 'App Installer' from the Microsoft Store, then re-run this installer." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
$wingetArgs = @("--accept-package-agreements", "--accept-source-agreements", "--silent", "-e")

# --- 2. Miniconda ---
Write-Step "Checking for conda..."
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
    Write-Host "Installing Miniconda (this can take a few minutes)..."
    winget install --id Anaconda.Miniconda3 @wingetArgs
    foreach ($c in $condaCandidates) {
        if (Test-Path $c) { $condaExe = $c; break }
    }
}

if (-not $condaExe) {
    Write-Host "Could not locate conda after installation. Please close this window, open a new terminal, and re-run this installer." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Using conda: $condaExe"

# --- 3. SUMO ---
Write-Step "Checking for SUMO..."
$sumoHome = Get-PersistedEnvVar "SUMO_HOME"
$sumoCandidates = @(
    "C:\Program Files (x86)\Eclipse\Sumo",
    "C:\Program Files\Eclipse\Sumo"
)
if (-not $sumoHome) {
    foreach ($s in $sumoCandidates) {
        if (Test-Path $s) { $sumoHome = $s; break }
    }
}
if (-not $sumoHome) {
    Write-Host "Installing SUMO..."
    winget install --id EclipseFoundation.SUMO @wingetArgs
    $sumoHome = Get-PersistedEnvVar "SUMO_HOME"
    if (-not $sumoHome) {
        foreach ($s in $sumoCandidates) {
            if (Test-Path $s) { $sumoHome = $s; break }
        }
    }
}
if ($sumoHome) {
    Write-Host "Using SUMO_HOME: $sumoHome"
    [Environment]::SetEnvironmentVariable("SUMO_HOME", $sumoHome, "User")
} else {
    Write-Host "Could not automatically locate the SUMO install folder. You may need to set SUMO_HOME manually (see FAQs.md)." -ForegroundColor Yellow
}

# --- 4. VS Code ---
Write-Step "Checking for Visual Studio Code..."
if (-not (Test-CommandExists "code")) {
    Write-Host "Installing Visual Studio Code..."
    winget install --id Microsoft.VisualStudioCode @wingetArgs
} else {
    Write-Host "Visual Studio Code is already installed."
}

# --- 5. Accept conda Terms of Service ---
Write-Step "Accepting conda's Terms of Service for the main and r channels..."
& $condaExe tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
if ($LASTEXITCODE -ne 0) {
    Write-Host "Note: could not run 'conda tos accept' for the main channel (fine on older conda versions that don't require it)." -ForegroundColor Yellow
}
& $condaExe tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
if ($LASTEXITCODE -ne 0) {
    Write-Host "Note: could not run 'conda tos accept' for the r channel (fine on older conda versions that don't require it)." -ForegroundColor Yellow
}

# --- 6. Conda environment ---
Write-Step "Setting up the '$EnvName' conda environment..."
$envList = & $condaExe env list
if ($envList -match "^\s*$EnvName\s") {
    Write-Host "Environment '$EnvName' already exists."
} else {
    & $condaExe create -y -n $EnvName python=3.11 pip
}

# --- 7. Python packages ---
Write-Step "Installing lxml, tud-sumo, mercury, pandas, and python-dotenv..."
& $condaExe run -n $EnvName pip install --upgrade pip
& $condaExe run -n $EnvName pip install lxml tud-sumo mercury pandas python-dotenv

# --- 8. .env file ---
Write-Step "Writing SUMO_HOME to .env..."
$envFile = Join-Path $ProjectDir ".env"
if ($sumoHome) {
    $sumoLine = "SUMO_HOME=$sumoHome"
    if (Test-Path $envFile) {
        $content = @(Get-Content $envFile | Where-Object { $_ -notmatch "^SUMO_HOME=" })
        $content += $sumoLine
        Set-Content -Path $envFile -Value $content
    } else {
        Set-Content -Path $envFile -Value $sumoLine
    }
}

Write-Step "Done!"
Write-Host "Open VS Code, then File -> Open Folder... and select:"
Write-Host "  $ProjectDir"
Write-Host "Open Assignment_1.ipynb or Assignment_2.ipynb, click 'Select Kernel...' -> 'Python Environments...' and choose '$EnvName'."
Write-Host "For Assignment 1, run 'mercury --working-dir .' in the VS Code terminal (with the '$EnvName' environment active), or double-click run-assignment1-windows.bat."
Read-Host "`nPress Enter to close this window"
