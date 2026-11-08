# NEXORA

<div align="center">
  <img src="assets/branding/logo/logo.svg" alt="NEXORA Logo" width="160" height="160" />
  <h3>CONNECT. SHARE. ANYWHERE.</h3>
  <p><strong>PRIVATE BY DESIGN. OPEN BY NATURE.</strong></p>
  <p>
    <a href="https://codebyarnob.github.io/Nexora-share/"><img src="https://img.shields.io/badge/Website-Live%20on%20GitHub%20Pages-39C6B0?style=flat-square&logo=githubpages&logoColor=white" alt="Website" /></a>
    <a href="https://github.com/CodeByArnob/Nexora-share/releases/latest"><img src="https://img.shields.io/github/v/release/CodeByArnob/Nexora-share?color=3978F6&label=Latest%20Release&style=flat-square" alt="Latest Version" /></a>
    <a href="https://github.com/CodeByArnob/Nexora-share/releases/latest/download/NEXORA-Setup-x64.exe"><img src="https://img.shields.io/badge/Download-Windows%20Installer-3978F6?style=flat-square&logo=windows&logoColor=white" alt="Download Windows Installer" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-14243B.svg?style=flat-square" alt="License" /></a>
    <img src="https://img.shields.io/badge/platforms-Android%20%7C%20Windows%20%7C%20Linux-17243A.svg?style=flat-square" alt="Platforms" />
  </p>

  <p>
    <a href="https://codebyarnob.github.io/Nexora-share/">
      <img src="https://img.shields.io/badge/🌐%20OFFICIAL%20WEBSITE-39C6B0?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Official Website" height="38" />
    </a>
    &nbsp;&nbsp;
    <a href="https://github.com/CodeByArnob/Nexora-share/releases/latest/download/NEXORA-Setup-x64.exe">
      <img src="https://img.shields.io/badge/⬇%20DOWNLOAD%20WINDOWS%20INSTALLER-3978F6?style=for-the-badge&logo=windows&logoColor=white" alt="Download NEXORA for Windows" height="38" />
    </a>
    &nbsp;&nbsp;
    <a href="https://github.com/CodeByArnob/Nexora-share/releases">
      <img src="https://img.shields.io/badge/📦%20RELEASE%20ARCHIVE-14243B?style=for-the-badge&logo=github&logoColor=white" alt="Release Archive" height="38" />
    </a>
  </p>
</div>

---

## 🌐 Official Project Links

- 🚀 **Live Website**: [https://codebyarnob.github.io/Nexora-share/](https://codebyarnob.github.io/Nexora-share/)
- 🪟 **Windows Installer**: [NEXORA-Setup-x64.exe](https://github.com/CodeByArnob/Nexora-share/releases/latest/download/NEXORA-Setup-x64.exe)
- 🔒 **Privacy Policy**: [https://codebyarnob.github.io/Nexora-share/privacy](https://codebyarnob.github.io/Nexora-share/privacy)
- 🛡️ **Security Policy**: [https://codebyarnob.github.io/Nexora-share/security](https://codebyarnob.github.io/Nexora-share/security)
- 📦 **Latest Release Notes**: [https://github.com/CodeByArnob/Nexora-share/releases/latest](https://github.com/CodeByArnob/Nexora-share/releases/latest)

---

## 🪟 Download NEXORA for Windows

<div align="center">
  <a href="https://github.com/CodeByArnob/Nexora-share/releases/latest/download/NEXORA-Setup-x64.exe">
    <img src="https://img.shields.io/badge/DOWNLOAD%20FOR%20WINDOWS-x64%20INSTALLER-3978F6?style=for-the-badge&logo=windows&logoColor=white" alt="Download NEXORA for Windows x64" />
  </a>
  <p><strong>Windows 10 / 11 · 64-bit</strong></p>
  <p>Download the latest stable NEXORA installer directly from GitHub Releases.</p>
</div>

| Detail | Information |
| :--- | :--- |
| Package | `NEXORA-Setup-x64.exe` |
| Platform | Windows 10 / 11 (x64) |
| Distribution | Official GitHub Release |
| Integrity | SHA-256 checksum published alongside the installer |
| Release history | [View all NEXORA releases](https://github.com/CodeByArnob/Nexora-share/releases) |

### Installation

1. Select **Download for Windows** above.
2. Run `NEXORA-Setup-x64.exe` after the download completes.
3. Follow the setup wizard. A desktop shortcut can be selected during installation.
4. Launch NEXORA from the Start Menu or desktop shortcut.

**Security note:** The installer is currently not code-signed. Windows may show an unknown-publisher or SmartScreen warning. Verify the published SHA-256 checksum and download only from this repository's official Releases page.

> **Release availability:** The direct download link becomes active after the Windows installer is attached to a published GitHub Release. Until then, use the [Releases page](https://github.com/CodeByArnob/Nexora-share/releases) to check availability. Historical Android packages, if present, remain in the release archive and are not the current Windows download.

---

## 1. What is NEXORA?

NEXORA is a high-performance, privacy-first cross-platform peer-to-peer file sharing platform for Android, Windows, and Linux.

- **Zero Cloud**: Transfers occur directly between devices over your local Wi-Fi or LAN.
- **Zero Accounts**: No registration, no login, no central servers.
- **Zero Telemetry**: No hidden analytics or user behavior tracking.
- **Verified Integrity**: End-to-end cryptographic integrity verification via SHA-256 and Ed25519 signatures.
- **Bounded-Memory Streaming**: Handles multi-GB files (5GB, 10GB+) with fixed 1MB RAM buffers and receiver flow-control backpressure.
- **Reliable Background Transfer**: Android `dataSync` Foreground Service with WakeLock; desktop lifecycle persistence with SQLite checkpoint resumption.

---

## 2. Core Features

- **Local Discovery**: Instant zero-configuration local network discovery via UDP multicast (`224.0.0.167:48843`), subnet-directed broadcast (`192.168.x.255`), and mDNS.
- **Native Android MulticastLock**: Hardware-level Wi-Fi multicast lock prevents packet drops on Android power-saving chipsets.
- **Unique Device Identity**: Automated hardware model identification (`device_info_plus`) and persistent cryptographic UUID.
- **Direct IP & QR Pairing**: Connect directly by IP or QR code on corporate or guest networks with router AP Isolation / Client Isolation.
- **Secure Pairing**: Ephemeral QR pairing, 6-digit Short Authentication String (SAS) confirmation, and cryptographic challenge-response validation.
- **Receiver Approval**: Senders cannot push unapproved files; receivers inspect file manifests, sizes, and file counts before explicitly approving.
- **Folder & Multi-File Hierarchy**: Recursive directory streaming preserving relative folder structures with path traversal defenses.
- **Verified Resume**: Interrupted transfers automatically resume from the last verified chunk without retransmitting already-received data.
- **Trusted Device Management**: Store trusted peers with cryptographic public-key fingerprints for streamlined workflows.
- **Transfer History**: Complete local SQLite history recording transfer status, byte counts, and timestamps (never file contents).
- **Motion Design**: GPU-accelerated discovery radar pulse, animated transfer progress bars with live speed badges, and reduced-motion accessibility.

---

## 3. Technology Stack & Design System

- **User Interface**: Flutter & Dart (Material 3, Riverpod state management, GoRouter)
- **Palette**:
  - **Midnight Navy**: `#14243B`
  - **Electric Blue**: `#3978F6`
  - **Signal Teal**: `#39C6B0`
  - **Light Background**: `#F5F7FB`
  - **Dark Background**: `#0D1420`
  - **Dark Surface**: `#17243A`
- **Core Engine**: Rust (Zero-copy networking, async Tokio runtime, Ed25519 cryptographic identity, SHA-256 verification)
- **Native Android**: Kotlin (Foreground service with `WakeLock`, `MulticastLock`, Storage Access Framework, Share intents)
- **Native Desktop**: C++ / CMake runner for Windows & Linux
- **Storage**: SQLite with versioned migrations (`DatabaseService`)

---

## 4. Architecture

```
Flutter Material 3 UI (Mobile & Desktop)
                 │
       Application State (Riverpod)
                 │
        Typed Rust FFI Bridge
                 │
        NEXORA Rust Core Engine
  ┌──────────────┼──────────────┐
  │              │              │
Discovery    Identity        Transfer
(mDNS/UDP)   (Ed25519)      (1MB Chunks)
  │              │              │
Security     Pairing         Resume
(Traversal)   (QR / SAS)   (Checkpoints)
  │              │              │
Transport    Verification    Storage
(TCP/TLS)     (SHA-256)      (SQLite)
                 │
        Local Wi-Fi Network
                 │
        Remote NEXORA Peer
```

---

## 5. Security & Privacy

- **[Threat Model Specification](docs/THREAT_MODEL.md)**: Documented STRIDE threat analysis, asset classification, and mitigations.
- **[Privacy Policy](PRIVACY_POLICY.md)**: Zero telemetry, zero cloud, and strictly localized peer-to-peer data handling.
- **Hard Frame Ceiling**: 4-byte big-endian framing enforces a strict 5MB frame ceiling, instantly dropping oversized headers to prevent RAM exhaustion.
- **Path Sanitization**: `PathSanitizer` neutralizes directory traversal attacks (`..`, `C:\`, `/etc/passwd`, and Windows reserved device names `CON`, `PRN`, `AUX`, `NUL`).

---

## 6. Monorepo Organization

```
nexora-share/
  apps/
    mobile/         # Android Flutter application (io.github.codebyarnob.nexora)
    desktop/        # Windows & Linux Flutter desktop application
  crates/
    nexora_core/    # Core orchestrator and public engine API
    discovery/      # mDNS zero-config network discovery
    identity/       # Ed25519 keypair and device fingerprinting
    pairing/        # QR payload, SAS codes, challenge-response
    security/       # Path sanitization, nonces, replay guards
    protocol/       # Wire framing, message definitions, error codes
    transport/      # Framed async network stream reader/writer
    transfer/       # Streaming chunk engine, progress calculation
    resume/         # Chunk-level resume tracking & checkpoints
    verification/   # Streaming SHA-256 file and chunk integrity
    storage/        # SQLite persistence, migrations, history
  packaging/
    flatpak/        # Linux Flatpak packaging manifest
    appimage/       # Linux AppRun entrypoint
  scripts/          # Production release build automation scripts
  website/          # Production React + TypeScript + Vite project website
  assets/
    branding/       # Geometric N logo, platform icons, colors
  docs/             # Architectural, protocol, and testing specifications
  .github/          # CI/CD workflows and validation pipelines
```

---

## 7. Getting Started & Building

### Prerequisites
- [Flutter 3.44+](https://flutter.dev) & Dart SDK
- [Rust 1.94+](https://rust-lang.org) (stable)
- Android SDK & NDK (for mobile APK builds)
- Node.js 20+ (for website)

### Running Tests
```bash
# Run all Desktop & Linux test suites (28 tests)
cd apps/desktop
flutter test --concurrency=1

# Run all Android mobile test suites (11 tests)
cd apps/mobile
flutter test --concurrency=1

# Static analysis
flutter analyze apps/desktop apps/mobile
```

### Production Release Packaging

#### Android APK
```powershell
./scripts/build_android_apk.ps1               # Universal Release APK
./scripts/build_android_apk.ps1 -SplitPerAbi  # Split ABI APKs (ARM64, ARMv7, x86_64)
```

#### Windows Desktop
```powershell
./scripts/build_windows.ps1                   # Staged to dist/windows
```

#### Linux AppImage & Debian
```bash
./scripts/build_appimage.sh                   # Builds dist/NEXORA-x86_64.AppImage
./scripts/build_deb.sh                        # Builds dist/nexora_1.0.0_amd64.deb
```

---

## 8. License & Maintainer

- **Maintainer**: [CodeByArnob](https://github.com/CodeByArnob)
- **Repository**: [https://github.com/CodeByArnob/Nexora-share](https://github.com/CodeByArnob/Nexora-share)
- **Website**: [https://codebyarnob.github.io/Nexora-share/](https://codebyarnob.github.io/Nexora-share/)
- **License**: [Apache License 2.0](LICENSE)

*CONNECT. SHARE. ANYWHERE.*  
*PRIVATE BY DESIGN. OPEN BY NATURE.*
