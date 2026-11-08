# ==============================================================================
# NEXORA Automated APK Size Monitoring Script
# Enforces APK size limits in Continuous Integration
# ==============================================================================
param(
    [string]$ArtifactsDir = "dist/android",
    [int]$MaxSplitApkMB = 30,
    [int]$MaxUniversalApkMB = 72
)

$ErrorActionPreference = "Stop"

Write-Host "=== [NEXORA] Automated APK Size Monitoring Verification ===" -ForegroundColor Cyan

if (-not (Test-Path $ArtifactsDir)) {
    Write-Error "Artifact directory not found: $ArtifactsDir"
    exit 1
}

$ApkFiles = Get-ChildItem -Path $ArtifactsDir -Filter "*.apk" | Where-Object { $_.Name -notlike "*debug*" }
if ($ApkFiles.Count -eq 0) {
    Write-Error "No APK files found in $ArtifactsDir"
    exit 1
}

$Failed = $false
foreach ($apk in $ApkFiles) {
    $sizeMB = [math]::Round($apk.Length / 1MB, 2)
    $isSplit = ($apk.Name -like "*arm64*" -or $apk.Name -like "*armeabi*" -or $apk.Name -like "*x86*")
    $limit = if ($isSplit) { $MaxSplitApkMB } else { $MaxUniversalApkMB }

    if ($sizeMB -gt $limit) {
        Write-Host " [FAIL] $($apk.Name): $sizeMB MB exceeds budget of $limit MB!" -ForegroundColor Red
        $Failed = $true
    } else {
        Write-Host " [PASS] $($apk.Name): $sizeMB MB (Budget: $limit MB)" -ForegroundColor Green
    }
}

if ($Failed) {
    Write-Error "APK size monitoring budget exceeded."
    exit 1
}

Write-Host "All APKs passed size budgeting requirements." -ForegroundColor Green
