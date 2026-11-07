# ==============================================================================
# NEXORA Windows Release Packaging Script
# CONNECT. SHARE. ANYWHERE.
# ==============================================================================
param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$DesktopDir = Join-Path $RootDir "apps\desktop"
$DistDir = Join-Path $RootDir "dist\windows"

Write-Host "=== [NEXORA] Building Windows Desktop Release Bundle ===" -ForegroundColor Cyan
Set-Location $DesktopDir

flutter build windows --release

$BuildDir = Join-Path $DesktopDir "build\windows\x64\runner\Release"
if (-not (Test-Path $BuildDir)) {
    Write-Error "Build directory not found at $BuildDir"
    exit 1
}

Write-Host "=== [NEXORA] Staging Windows Release Files ===" -ForegroundColor Cyan
if (Test-Path $DistDir) {
    Remove-Item -Recurse -Force $DistDir
}
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

Copy-Item -Recurse -Force "$BuildDir\*" $DistDir

Write-Host "=== [NEXORA] Windows Release Package Built Successfully at $DistDir ===" -ForegroundColor Green
Get-ChildItem -Path $DistDir
