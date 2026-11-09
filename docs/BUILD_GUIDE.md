# NEXORA Android Build Guide

This document provides complete, reproducible instructions for building production-ready NEXORA Android artifacts (split APKs, universal APK, and Android App Bundle).

---

## 1. Prerequisites

| Tool | Version / Requirement | Purpose |
|---|---|---|
| **Flutter SDK** | `3.44.4+` (Channel `stable`) | UI framework & Dart runtime |
| **Dart SDK** | `3.12+` | Embedded within Flutter SDK |
| **Android SDK** | API 34+ (Build-Tools 34+) | Android compilation & packaging |
| **Java Development Kit** | OpenJDK 17 or 21 (Temurin recommended) | Gradle execution |
| **Rust Toolchain** | `1.94.0+` (stable) | Shared protocol and cryptography engine |

---

## 2. Secure Keystore & Signing Configuration

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

### A. ABI-Split Release APKs (Recommended for Production Distribution)
Splitting APKs per target ABI produces the smallest, most efficient downloads for users:
```bash
cd apps/mobile
flutter pub get
flutter build apk --release --split-per-abi
```
Generated artifacts in `apps/mobile/build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (**~25.0 MB**) &mdash; Modern 64-bit Android smartphones.
- `app-armeabi-v7a-release.apk` (**~20.9 MB**) &mdash; 32-bit legacy devices.
- `app-x86_64-release.apk` (**~27.4 MB**) &mdash; Tablets, Chromebooks & Emulators.

### B. Universal Release APK (Fat Binary)
Contains native code for all CPU architectures in a single standalone package:
```bash
cd apps/mobile
flutter build apk --release
```
* Output path: `apps/mobile/build/app/outputs/flutter-apk/app-release.apk` (~67 MB)

### C. Android App Bundle (Google Play Store)
Format required for publishing on the Google Play Store:
```bash
cd apps/mobile
flutter build appbundle --release
```
* Output path: `apps/mobile/build/app/outputs/bundle/release/app-release.aab` (~59 MB)

---

## 4. Automated CI/CD Compilation

NEXORA's GitHub Actions workflow (`.github/workflows/ci.yml`) automatically compiles and verifies the Android release split APKs on an `ubuntu-latest` runner upon every push to `main` or release branch, enforcing strict APK size limits via `scripts/monitor_apk_size.ps1`.
