# ==============================================================================
# NEXORA Windows Release Packaging Script
# CONNECT. SHARE. ANYWHERE.
# ==============================================================================
param(
    [string]$Configuration = "Release",
    [switch]$CreateInstaller = $true
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$DesktopDir = Join-Path $RootDir "apps\desktop"
$DistDir = Join-Path $RootDir "dist\windows"
$IssPath = Join-Path $RootDir "packaging\windows\nexora_setup.iss"

Write-Host "=== [NEXORA] Building Windows Desktop Release Bundle ===" -ForegroundColor Cyan
Set-Location $DesktopDir

flutter build windows --release

$BuildDir = Join-Path $DesktopDir "build\windows\x64\runner\Release"
if (-not (Test-Path $BuildDir)) {
    Write-Error "Build directory not found at $BuildDir"
    exit 1
}

Write-Host "=== [NEXORA] Staging Windows Release Files ===" -ForegroundColor Cyan
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
}

$PortableZip = Join-Path $DistDir "nexora-windows-x64-portable.zip"
if (Test-Path $PortableZip) {
    Remove-Item -Force $PortableZip
}
Compress-Archive -Path "$BuildDir\*" -DestinationPath $PortableZip

Write-Host "=== [NEXORA] Portable ZIP created at $PortableZip ===" -ForegroundColor Green

# Check for Inno Setup compiler (ISCC)
$Iscc = Get-Command "iscc" -ErrorAction SilentlyContinue
if (-not $Iscc) {
    # Check default installation paths
    $CommonPaths = @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        "${env:LOCALAPPDATA}\Programs\Inno Setup 6\ISCC.exe"
    )
    foreach ($p in $CommonPaths) {
        if (Test-Path $p) {
            $Iscc = $p
            break
        }
    }
}

if ($CreateInstaller -and $Iscc) {
    Write-Host "=== [NEXORA] Compiling Inno Setup Windows Installer ===" -ForegroundColor Cyan
    & $Iscc $IssPath
    Write-Host "=== [NEXORA] Inno Setup Installer created at $DistDir\NEXORA-Setup-x64.exe ===" -ForegroundColor Green
} elseif ($CreateInstaller) {
    Write-Host "Notice: Inno Setup compiler (ISCC.exe) not found on host machine. (Installer will be generated in GitHub Actions CI/CD runner)." -ForegroundColor Yellow
}

# Generate SHA-256 Checksums
Set-Location $DistDir
Get-ChildItem -Path $DistDir -Filter "*.*" | Where-Object { $_.Extension -in @(".zip", ".exe") } | ForEach-Object {
    $hash = (Get-FileHash -Algorithm SHA256 $_.FullName).Hash.ToLower()
    Write-Host ("{0}  {1}" -f $hash, $_.Name)
}
