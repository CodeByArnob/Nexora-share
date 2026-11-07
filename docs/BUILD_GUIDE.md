# NEXORA Build Guide

This document provides complete, reproducible instructions for building production-ready NEXORA artifacts for Android, Windows, and Linux.

---

## 1. Prerequisites

| Platform | Required Toolchains & Dependencies |
|---|---|
| **All Platforms** | Flutter SDK 3.44+ (Channel `stable`), Dart 3.12+, Git |
| **Android** | Android SDK 34+ (Build-Tools 36+), OpenJDK 17 or 21, Android NDK |
| **Windows PC** | Visual Studio 2022 with **"Desktop development with C++"** workload |
| **Linux** | `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `liblzma-dev` |

---

## 2. Secure Keystore & Signing Configuration (Android)

NEXORA release signing keys must **NEVER** be committed to the Git repository.

### Step 1: Generate Private Keystore (Outside Git)
Generate the keystore in your home directory or secure secrets store:
```bash
keytool -genkey -v \
  -keystore "$HOME/.android/nexora-release-key.jks" \
  -alias nexora \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=Arnob, OU=NEXORA, O=CodeByArnob, L=Dhaka, ST=Dhaka, C=BD"
```

### Step 2: Configure `key.properties`
Create `apps/mobile/android/key.properties` (strictly ignored by `.gitignore`):
```properties
storePassword=<YOUR_STORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=nexora
storeFile=C:/Users/Arnob/.android/nexora-release-key.jks
```

---

## 3. Building Android Artifacts

### Production Release APK (Direct Sideload / Distributable)
```bash
cd apps/mobile
flutter pub get
flutter build apk --release
```
* Output path: `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`
* Form-factor size: ~54 MB (with R8 optimization and resource tree-shaking)

### Android App Bundle (Google Play Store)
```bash
cd apps/mobile
flutter pub get
flutter build appbundle --release
```
* Output path: `apps/mobile/build/app/outputs/bundle/release/app-release.aab`
* Form-factor size: ~53.5 MB

---

## 4. Building Windows PC Executable (`nexora.exe`)

### Step 1: Ensure Visual Studio C++ Workload
If not already installed, install the C++ build tools via Windows Package Manager:
```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools --override "--passive --config vsbuildtools.config --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

### Step 2: Build Release Binary
```powershell
cd apps/desktop
flutter config --enable-windows-desktop
flutter pub get
flutter build windows --release
```
* Output directory: `apps/desktop/build/windows/x64/runner/Release/`
* Binary executable: `nexora.exe`

### Automated Cloud Build
If building on a machine without Visual Studio, NEXORA's GitHub Actions workflow (`.github/workflows/ci.yml`) automatically builds the Windows `nexora.exe` on `windows-latest` runners upon push to `main` or release branches.

---

## 5. Building Linux Desktop Binary

```bash
cd apps/desktop
flutter config --enable-linux-desktop
flutter pub get
flutter build linux --release
```
* Output binary: `apps/desktop/build/linux/x64/release/bundle/nexora`

---

## 6. Checksum Verification

```bash
# Verify integrity of generated release files
sha256sum release/android/nexora-v1.0.0-release.apk
```
