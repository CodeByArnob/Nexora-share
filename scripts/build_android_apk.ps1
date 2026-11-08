# ==============================================================================
# NEXORA Android Production APK & Bundle Build Script
# CONNECT. SHARE. ANYWHERE.
# ==============================================================================
param(
    [switch]$SplitPerAbi,
    [switch]$BuildBundle,
    [switch]$UniversalOnly
)

if (-not $SplitPerAbi -and -not $UniversalOnly) {
    $SplitPerAbi = $true
}

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$MobileDir = Join-Path $RootDir "apps\mobile"
$DistDir = Join-Path $RootDir "dist\android"

Write-Host "=== [NEXORA] Building Production Android Release Artifacts ===" -ForegroundColor Cyan
Set-Location $MobileDir

if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
}

$BaselineBytes = 57355992 # 54.7 MB Universal baseline

if ($UniversalOnly) {
    Write-Host "--> Building Universal APK..." -ForegroundColor Yellow
    flutter build apk --release
} elseif ($SplitPerAbi) {
    Write-Host "--> Building Split-per-ABI APKs (ARM64, ARMv7, x86_64)..." -ForegroundColor Yellow
    flutter build apk --release --split-per-abi

    Write-Host "--> Building Universal APK (for fallback / direct sideloading)..." -ForegroundColor Yellow
    flutter build apk --release
} else {
    flutter build apk --release
}

if ($BuildBundle) {
    Write-Host "--> Building Google Play App Bundle (AAB)..." -ForegroundColor Yellow
    flutter build appbundle --release
}

$ApkBuildDir = Join-Path $MobileDir "build\app\outputs\flutter-apk"
$BundleBuildDir = Join-Path $MobileDir "build\app\outputs\bundle\release"

if (Test-Path $ApkBuildDir) {
    Copy-Item -Force "$ApkBuildDir\*release*.apk" $DistDir
}
if (Test-Path $BundleBuildDir) {
    Copy-Item -Force "$BundleBuildDir\*.aab" $DistDir
}

Write-Host ""
Write-Host "=== [NEXORA] Android Build Artifacts & Size Analysis Summary ===" -ForegroundColor Green
$Artifacts = Get-ChildItem -Path $DistDir | Where-Object { $_.Extension -in @(".apk", ".aab") }

$ReportLines = @()
$ReportLines += "| Artifact | Architecture | File Size | Baseline Comparison | SHA-256 Checksum |"
$ReportLines += "| :--- | :--- | :--- | :--- | :--- |"

foreach ($file in $Artifacts) {
    $sha256 = (Get-FileHash -Algorithm SHA256 $file.FullName).Hash.ToLower()
    $sizeMB = [math]::Round($file.Length / 1MB, 2)
    $reductionPercent = [math]::Round((($BaselineBytes - $file.Length) / $BaselineBytes) * 100, 1)
    
    $arch = "Universal"
    if ($file.Name -like "*arm64*") { $arch = "ARM64-v8a" }
    elseif ($file.Name -like "*armeabi-v7a*") { $arch = "ARMv7" }
    elseif ($file.Name -like "*x86_64*") { $arch = "x86_64" }
    elseif ($file.Extension -eq ".aab") { $arch = "Play Bundle (All)" }

    $comparison = if ($reductionPercent -gt 0) { "-$reductionPercent% reduced" } else { "Baseline" }

    Write-Host ("  [{0}] {1,-32} {2,8} MB  ({3,-14}) SHA: {4}..." -f $arch, $file.Name, $sizeMB, $comparison, $sha256.Substring(0, 12)) -ForegroundColor Cyan
    $ReportLines += ("| **`{0}`** | {1} | {2} MB | {3} | `{4}` |" -f $file.Name, $arch, $sizeMB, $comparison, $sha256)
}

$ReportPath = Join-Path $DistDir "APK_SIZE_ANALYSIS.md"
$ReportContent = @"
# NEXORA Android APK Size Analysis Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Baseline Universal APK Size: 54.7 MB (57,355,992 bytes)

$($ReportLines -join "`n")

### Size Optimization Summary
- **ABI Slicing (`--split-per-abi`)**: Strips multi-architecture fat binaries, saving ~60-70% bandwidth for end-user device architectures (ARM64-v8a: ~18 MB vs 54.7 MB).
- **R8 Proguard & Resource Shrinking**: Unused class files, debug attributes, and unused resources stripped.
- **SQLite FFI Native Separation**: Android runtime utilizes native Android platform SQLite, eliminating redundant desktop C binaries.
"@

Set-Content -Path $ReportPath -Value $ReportContent -Encoding UTF8
Write-Host "Size report written to $ReportPath" -ForegroundColor Green
