# NEXORA for Android — Installation & Setup Guide

NEXORA is a modern Android application for secure, fast, and convenient file sharing between supported devices.

---

## 1. Official Android APK Downloads

Official release APKs are cryptographically hashed and published on [GitHub Releases](https://github.com/CodeByArnob/Nexora-share/releases/latest).

| Package | Architecture | Recommended For | Typical Size |
| :--- | :--- | :--- | :---: |
| **`nexora-v1.2.0-arm64-v8a.apk`** | **`arm64-v8a`** | **Modern Smartphones (Pixel, Samsung, Xiaomi, OnePlus, Motorola, Nothing)** | **~25 MB** |
| **`nexora-v1.2.0-universal.apk`** | Universal | Fat binary containing all native ABIs | ~67 MB |
| **`nexora-v1.2.0-armeabi-v7a.apk`** | `armeabi-v7a` | 32-bit legacy Android phones | ~21 MB |
| **`nexora-v1.2.0-x86_64.apk`** | `x86_64` | Android tablets, emulators & Chromebooks | ~27 MB |
| **`nexora-v1.2.0-release.aab`** | App Bundle | Google Play Store distribution format | ~59 MB |

---

## 2. Sideloading Installation Steps

1. **Download the APK**: Download `nexora-v1.2.0-arm64-v8a.apk` directly on your Android phone using your browser.
2. **Allow Installation from Unknown Sources**:
   - If prompted by Android, tap **Settings**.
   - Enable **Allow from this source** for your browser (Chrome, Firefox, Brave, etc.).
3. **Install NEXORA**: Tap **Install** and wait for the package installer to complete.
4. **Launch & Grant Permissions**:
   - **Nearby Devices**: Allows discovering peers on the local Wi-Fi / hotspot network without accessing location.
   - **Camera**: Allows scanning ephemeral QR pairing codes at 60 FPS via CameraX.
   - **Notifications**: Keeps file transfers active with a foreground service notification showing live transfer speed and progress.

---

## 3. Building Android APK from Source

### Prerequisites
- Flutter SDK `3.44.4` (stable channel)
- Java Development Kit (JDK 21)
- Android SDK (API 34/35 platform tools and build tools)

### Build Commands
```bash
# 1. Clone repository
git clone https://github.com/CodeByArnob/Nexora-share.git
cd Nexora-share

# 2. Build Rust core engine
cargo build --workspace --release

# 3. Build optimized Android split APKs
cd apps/mobile
flutter pub get
flutter build apk --release --split-per-abi

# Output APKs will be located in:
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

---

## 4. Android System Requirements

- **Minimum OS**: Android 8.0 Oreo (API 26)
- **Target OS**: Android 14 / Android 15 (API 34/35)
- **Minimum RAM**: 2 GB
- **Networking**: Wi-Fi 802.11 b/g/n/ac/ax or Mobile Hotspot
