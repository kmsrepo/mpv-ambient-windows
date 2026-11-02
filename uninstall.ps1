<#
.SYNOPSIS
    Uninstalls or reverts mpv ambient configuration on Windows.
#>

param(
    [string]$PortablePath = ""
)

$ErrorActionPreference = "SilentlyContinue"

$TargetDir = ""
if ($PortablePath -ne "" -and (Test-Path $PortablePath)) {
    $TargetDir = $PortablePath
} elseif (Test-Path ".\portable_config") {
    $TargetDir = ".\portable_config"
} else {
    $TargetDir = "$env:APPDATA\mpv"
}

Write-Host "Reverting configuration in: $TargetDir" -ForegroundColor Cyan

# Look for latest backup
$LatestMpvBak = Get-ChildItem -Path $TargetDir -Filter "mpv.conf.bak_*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($LatestMpvBak) {
    Copy-Item $LatestMpvBak.FullName (Join-Path $TargetDir "mpv.conf") -Force
    Write-Host "[OK] Restored mpv.conf from $($LatestMpvBak.Name)" -ForegroundColor Green
}

$LatestInputBak = Get-ChildItem -Path $TargetDir -Filter "input.conf.bak_*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($LatestInputBak) {
    Copy-Item $LatestInputBak.FullName (Join-Path $TargetDir "input.conf") -Force
    Write-Host "[OK] Restored input.conf from $($LatestInputBak.Name)" -ForegroundColor Green
}

Write-Host "Uninstallation/revert finished." -ForegroundColor Green
