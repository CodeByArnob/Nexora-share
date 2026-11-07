# ==============================================================================
# NEXORA Android Production APK Build Script
# CONNECT. SHARE. ANYWHERE.
# ==============================================================================
param(
    [switch]$SplitPerAbi = $false
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$MobileDir = Join-Path $RootDir "apps\mobile"
$DistDir = Join-Path $RootDir "dist\android"

Write-Host "=== [NEXORA] Building Production Android APK ===" -ForegroundColor Cyan
Set-Location $MobileDir

if ($SplitPerAbi) {
    flutter build apk --release --split-per-abi
} else {
    flutter build apk --release
}

$ApkBuildDir = Join-Path $MobileDir "build\app\outputs\flutter-apk"
if (-not (Test-Path $ApkBuildDir)) {
    Write-Error "APK output directory not found at $ApkBuildDir"
    exit 1
}

if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
}

Copy-Item -Force "$ApkBuildDir\*.apk" $DistDir

Write-Host "=== [NEXORA] Android APK(s) Created Successfully at $DistDir ===" -ForegroundColor Green
Get-ChildItem -Path $DistDir -Filter "*.apk"
