<#
.SYNOPSIS
    Configures mpv on Windows to display vertical/shortform videos with ambient blurred borders out-of-the-box.
.DESCRIPTION
    Supports both standard Windows installations (%APPDATA%\mpv) and Portable mpv installations (portable_config).
    Automatically backs up existing configurations before writing changes.
.PARAMETER PortablePath
    Optional path to portable mpv directory containing mpv.exe or portable_config.
.EXAMPLE
    irm https://raw.githubusercontent.com/kmsrepo/mpv-ambient-windows/main/install.ps1 | iex
#>

param(
    [string]$PortablePath = ""
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

Write-Host "==========================================================" -ForegroundColor Magenta
Write-Host "   mpv Ambient Mode Setup for Windows (Out-of-the-Box)   " -ForegroundColor Magenta
Write-Host "==========================================================" -ForegroundColor Magenta

# Determine Target Directory
$TargetDir = ""

if ($PortablePath -ne "") {
    if (Test-Path "$PortablePath\portable_config") {
        $TargetDir = "$PortablePath\portable_config"
    } elseif (Test-Path "$PortablePath\mpv.exe") {
        $TargetDir = "$PortablePath\portable_config"
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    } else {
        $TargetDir = $PortablePath
    }
} elseif (Test-Path ".\mpv.exe") {
    $TargetDir = ".\portable_config"
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
} else {
    $AppDataMpv = "$env:APPDATA\mpv"
    $TargetDir = $AppDataMpv
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
        Write-Step "Created directory: $TargetDir"
    }
}

Write-Step "Target configuration path: $TargetDir"

# Configuration contents
$MpvConfContent = @"
# ==============================================================================
# mpv Configuration for Windows - Out-of-the-Box Ambient Mode
# Project: https://github.com/kmsrepo/mpv-ambient-windows
# ==============================================================================

# --- Video Output Configuration ---
vo=gpu-next
gpu-api=auto
hwdec=auto-safe

# --- Native Ambient Border Blur (Requires vo=gpu-next, mpv >= 0.38) ---
border-background=blur
background-blur-radius=25

# --- Window & UX ---
keep-open=yes
autofit-larger=90%x90%
force-window=immediate
"@

$InputConfContent = @"
# ==============================================================================
# mpv Keybindings for Windows - Ambient Mode Controls
# Project: https://github.com/kmsrepo/mpv-ambient-windows
# ==============================================================================

# Toggle native ambient border blur on/off (solid black vs blurred video)
b cycle-values border-background color blur

# Dynamically adjust ambient blur radius
Ctrl+[ add background-blur-radius -5 ; show-text "Blur radius: \${background-blur-radius}"
Ctrl+] add background-blur-radius 5 ; show-text "Blur radius: \${background-blur-radius}"

# Toggle fallback FFmpeg lavfi ambient filter
Alt+b vf toggle "lavfi=[split[fg][bg];[bg]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=25:5,eq=brightness=-0.08[bgblur];[fg]scale=-1:1080[fgscaled];[bgblur][fgscaled]overlay=(W-w)/2:(H-h)/2]"
"@

$Timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")

# Install mpv.conf
$TargetMpvConf = Join-Path $TargetDir "mpv.conf"
if (Test-Path $TargetMpvConf) {
    $BackupConf = "$TargetMpvConf.bak_$Timestamp"
    Copy-Item $TargetMpvConf $BackupConf -Force
    Write-Warn "Existing mpv.conf backed up to: $BackupConf"
    
    # Check if border-background is already present
    $Existing = Get-Content $TargetMpvConf -Raw
    if ($Existing -notmatch "border-background") {
        Add-Content -Path $TargetMpvConf -Value "`n# --- Ambient Mode Config ---`nvo=gpu-next`nborder-background=blur`nbackground-blur-radius=25`n"
        Write-Success "Appended ambient configuration to existing mpv.conf"
    } else {
        Write-Warn "border-background already configured in mpv.conf. Kept existing file."
    }
} else {
    Set-Content -Path $TargetMpvConf -Value $MpvConfContent -Encoding UTF8
    Write-Success "Created new mpv.conf at $TargetMpvConf"
}

# Install input.conf
$TargetInputConf = Join-Path $TargetDir "input.conf"
if (Test-Path $TargetInputConf) {
    $BackupInput = "$TargetInputConf.bak_$Timestamp"
    Copy-Item $TargetInputConf $BackupInput -Force
    Write-Warn "Existing input.conf backed up to: $BackupInput"
    
    $ExistingInput = Get-Content $TargetInputConf -Raw
    if ($ExistingInput -notmatch "border-background") {
        Add-Content -Path $TargetInputConf -Value "`n# --- Ambient Mode Toggle ---`nb cycle-values border-background color blur`nCtrl+[ add background-blur-radius -5`nCtrl+] add background-blur-radius 5`n"
        Write-Success "Appended keybindings to existing input.conf"
    } else {
        Write-Warn "Keybindings already configured in input.conf. Kept existing file."
    }
} else {
    Set-Content -Path $TargetInputConf -Value $InputConfContent -Encoding UTF8
    Write-Success "Created new input.conf at $TargetInputConf"
}

Write-Host ""
Write-Success "Installation complete!"
Write-Host "Play any vertical (9:16 Shorts / Reels / TikTok) video in mpv to see the ambient effect." -ForegroundColor Green
Write-Host "Key controls: Press 'b' to toggle ambient blur on/off, 'Ctrl+[' or 'Ctrl+]' to adjust blur." -ForegroundColor Cyan
