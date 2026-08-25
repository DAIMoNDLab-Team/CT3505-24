# CT3505-24 Windows uninstaller.
# Removes the "ct3505" conda environment and this project's .env file, plus
# ONLY the system-wide tools (Miniconda, SUMO, VS Code) that
# install-windows.ps1 itself installed - never software you already had on
# your PC before running it.
#
# This relies on the install manifest install-windows.ps1 writes
# (.ct3505-install-manifest, in this project folder) to know what it
# actually installed vs. what it found already present. If that manifest
# is missing (e.g. an older install-windows.ps1 was used, or the file was
# deleted), this script assumes it installed no system-wide tools and
# leaves Miniconda/SUMO/VS Code alone entirely - it will still remove the
# "ct3505" conda environment and this project's .env file, since those are
# unambiguously project-specific either way.

$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvName = "ct3505"
$ManifestFile = Join-Path $ProjectDir ".ct3505-install-manifest"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

function Test-CommandExists($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

$InstalledMiniconda = $false
$InstalledSumo = $false
$InstalledVSCode = $false
if (Test-Path $ManifestFile) {
    $manifestData = Get-Content $ManifestFile | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' } | ConvertFrom-StringData
    if ($manifestData.ContainsKey('INSTALLED_MINICONDA')) { $InstalledMiniconda = [bool]::Parse($manifestData['INSTALLED_MINICONDA']) }
    if ($manifestData.ContainsKey('INSTALLED_SUMO')) { $InstalledSumo = [bool]::Parse($manifestData['INSTALLED_SUMO']) }
    if ($manifestData.ContainsKey('INSTALLED_VSCODE')) { $InstalledVSCode = [bool]::Parse($manifestData['INSTALLED_VSCODE']) }
} else {
    Write-Host "No install manifest found at $ManifestFile - assuming install-windows.ps1 never put any system-wide tools in place here, so none of them will be touched."
}

# --- Elevate to admin (needed for machine-wide winget uninstalls) ---
# Done before the confirmation prompt below so the prompt is only ever
# shown once, in the elevated window that actually performs the removal.
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This uninstaller needs administrator privileges. Approve the prompt that appears -"
    Write-Host "a new window will open and do the actual removal; this window will close."
    Start-Sleep -Seconds 2
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "CT3505-24 uninstaller"
Write-Host "======================"
Write-Host "This will remove:"
Write-Host "  - the '$EnvName' conda environment"
Write-Host "  - $ProjectDir\.env"
if ($InstalledSumo)      { Write-Host "  - SUMO (installed by install-windows.ps1)" }
if ($InstalledVSCode)    { Write-Host "  - Visual Studio Code (installed by install-windows.ps1)" }
if ($InstalledMiniconda) { Write-Host "  - Miniconda, and ALL conda environments, not just '$EnvName' (installed by install-windows.ps1)" }
Write-Host ""
Write-Host "Anything not listed above was already on your PC before install-windows.ps1 ran, and will be left alone."
$confirm = Read-Host "Type 'yes' to continue"
if ($confirm -ne "yes") {
    Write-Host "Aborted."
    Read-Host "Press Enter to close"
    exit 1
}

# --- 1. Conda environment ---
# Always removed: this environment name is unique to this course, so it can
# never be something that pre-existed for an unrelated reason.
Write-Step "Removing the '$EnvName' conda environment..."
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
if ($condaExe) {
    & $condaExe env remove -y -n $EnvName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Environment '$EnvName' not found, skipping."
    }
} else {
    Write-Host "conda not found, skipping."
}

# --- 2. SUMO ---
# The SUMO_HOME env var this project sets is only touched here too, since
# install-windows.ps1 only ever writes it as part of this same "we just
# installed SUMO" branch when it wasn't already found pre-existing - if
# SUMO pre-existed, install-windows.ps1 re-writes SUMO_HOME to the same
# value it already had, so there's nothing to undo in that case.
if ($InstalledSumo) {
    Write-Step "Removing SUMO (installed by install-windows.ps1)..."
    if (Test-CommandExists "winget") {
        winget uninstall --id EclipseFoundation.SUMO --silent 2>$null
    }
    [Environment]::SetEnvironmentVariable("SUMO_HOME", $null, "User")
} else {
    Write-Step "Skipping SUMO (not installed by install-windows.ps1)."
}

# --- 3. Visual Studio Code ---
if ($InstalledVSCode) {
    Write-Step "Removing Visual Studio Code (installed by install-windows.ps1)..."
    if (Test-CommandExists "winget") {
        winget uninstall --id Microsoft.VisualStudioCode --silent 2>$null
    }
} else {
    Write-Step "Skipping Visual Studio Code (not installed by install-windows.ps1)."
}

# --- 4. Miniconda ---
if ($InstalledMiniconda) {
    Write-Step "Removing Miniconda (installed by install-windows.ps1)..."
    if (Test-CommandExists "winget") {
        winget uninstall --id Anaconda.Miniconda3 --silent 2>$null
    }
} else {
    Write-Step "Skipping Miniconda (not installed by install-windows.ps1)."
}

# --- 5. Project files ---
Write-Step "Removing $ProjectDir\.env and the install manifest..."
Remove-Item -Path (Join-Path $ProjectDir ".env") -ErrorAction SilentlyContinue
Remove-Item -Path $ManifestFile -ErrorAction SilentlyContinue

Write-Step "Done!"
Write-Host "Anything not removed above (Miniconda, SUMO, VS Code) was already on your PC before install-windows.ps1 ran, and has been left untouched."
Read-Host "`nPress Enter to close this window"
