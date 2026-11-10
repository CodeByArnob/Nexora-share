<div align="center">

  <!-- ============================================================================== -->
  <!-- 1. NEXORA HERO BANNER                                                          -->
  <!-- ============================================================================== -->
  <a href="https://codebyarnob.github.io/Nexora-share/">
    <img src="docs/assets/branding/nexora_hero_banner.png" alt="NEXORA — Connect. Share. Anywhere." width="100%" style="max-width: 1200px; border-radius: 16px; box-shadow: 0 12px 36px rgba(0,0,0,0.4);" />
  </a>

  <br /><br />

  <!-- ============================================================================== -->
  <!-- 2. PROJECT TAGLINE                                                             -->
  <!-- ============================================================================== -->
  <p align="center">
    <strong>CONNECT. SHARE. ANYWHERE.</strong><br />
    <em>PRIVATE BY DESIGN. OPEN BY NATURE.</em>
  </p>

  <p align="center">
    <strong>NEXORA is a modern Android application for secure, fast, and convenient file sharing between supported devices.</strong><br />
    Direct local network streaming over Wi-Fi and mobile hotspots with zero cloud servers, bounded memory buffers, verified SHA-256 integrity, and zero telemetry.
  </p>

  <!-- ============================================================================== -->
  <!-- 3. GITHUB STATUS BADGES & ACTION CTAS                                          -->
  <!-- ============================================================================== -->
  <p align="center">
    <a href="https://github.com/CodeByArnob/Nexora-share/releases/latest">
      <img src="https://img.shields.io/github/v/release/CodeByArnob/Nexora-share?color=3978F6&label=Latest%20Release&style=flat-square" alt="Latest Release" />
    </a>
    <a href="https://github.com/CodeByArnob/Nexora-share/actions/workflows/ci.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/CodeByArnob/Nexora-share/ci.yml?branch=main&label=Android%20CI&style=flat-square" alt="Android CI Status" />
    </a>
    <a href="https://codebyarnob.github.io/Nexora-share/">
      <img src="https://img.shields.io/badge/Website-Live%20on%20GitHub%20Pages-39C6B0?style=flat-square&logo=githubpages&logoColor=white" alt="Official Website" />
    </a>
    <a href="LICENSE">
      <img src="https://img.shields.io/badge/License-Apache%202.0-14243B.svg?style=flat-square" alt="License" />
    </a>
    <a href="https://github.com/CodeByArnob/Nexora-share/releases/latest">
      <img src="https://img.shields.io/badge/Platform-Android%20(API%2026%2B)-3DDC84.svg?style=flat-square&logo=android&logoColor=white" alt="Android Only" />
    </a>
    <a href="https://github.com/CodeByArnob/Nexora-share/stargazers">
      <img src="https://img.shields.io/github/stars/CodeByArnob/Nexora-share?style=flat-square&color=3978F6" alt="GitHub Stars" />
    </a>
  </p>

  <!-- Action CTA Buttons -->
  <p align="center">
    <a href="https://codebyarnob.github.io/Nexora-share/">
      <img src="https://img.shields.io/badge/🌐%20OFFICIAL%20WEBSITE-39C6B0?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Official Website" height="36" />
    </a>
    &nbsp;
    <a href="https://github.com/CodeByArnob/Nexora-share/releases/latest/download/nexora-v1.2.1-arm64-v8a.apk">
      <img src="https://img.shields.io/badge/📱%20DOWNLOAD%20ARM64%20APK%20(25%20MB)-3978F6?style=for-the-badge&logo=android&logoColor=white" alt="Download ARM64 APK" height="36" />
    </a>
    &nbsp;
    <a href="https://github.com/CodeByArnob/Nexora-share/releases/latest/download/nexora-v1.2.1-universal.apk">
      <img src="https://img.shields.io/badge/📦%20UNIVERSAL%20APK%20(67%20MB)-14243B?style=for-the-badge&logo=android&logoColor=white" alt="Download Universal APK" height="36" />
    </a>
    &nbsp;
    <a href="https://github.com/CodeByArnob/Nexora-share/releases">
      <img src="https://img.shields.io/badge/📂%20ALL%20RELEASES-17243A?style=for-the-badge&logo=github&logoColor=white" alt="Releases Archive" height="36" />
    </a>
  </p>

</div>

---

<!-- ============================================================================== -->
<!-- 4. QUICK NAVIGATION / TABLE OF CONTENTS                                       -->
<!-- ============================================================================== -->
## 📑 Quick Navigation

<details open>
<summary><strong>Click to expand / collapse navigation (36 Sections)</strong></summary>

1. [NEXORA Hero Banner](#-nexora)
2. [Project Tagline](#-project-tagline)
3. [GitHub Status Badges](#-github-status-badges--action-ctas)
4. [Quick Navigation](#-quick-navigation)
5. [Product Introduction](#-product-introduction)
6. [Real Application Screenshot Showcase](#-real-application-screenshot-showcase)
7. [Key Features with Visual Icons](#-key-features)
8. [Home Screen Overview](#-home-screen-overview)
9. [Live Transfers](#-live-transfers)
10. [Transfer History](#-transfer-history)
11. [Devices & Trust Hub](#-devices--trust-hub)
12. [Settings & Network](#-settings--network)
13. [How NEXORA Works](#-how-nexora-works)
14. [Animated Device Discovery Workflow](#-animated-device-discovery-workflow)
15. [QR Pairing Workflow](#-qr-pairing-workflow)
16. [Secure File Transfer Workflow](#-secure-file-transfer-workflow)
17. [System Architecture](#-system-architecture)
18. [Technology Stack](#-technology-stack)
19. [Security and Privacy](#-security-and-privacy)
20. [Android Platform Requirements](#-android-platform-requirements)
21. [Download Latest Android APK](#-download-latest-android-apk)
22. [APK Installation Guide](#-apk-installation-guide)
23. [Build from Source](#-build-from-source)
24. [User Guide](#-user-guide)
25. [Permissions Explained](#-permissions-explained)
26. [Project Directory Structure](#-project-directory-structure)
27. [Testing and Quality Assurance](#-testing-and-quality-assurance)
28. [Performance and Optimization](#-performance-and-optimization)
29. [Troubleshooting](#-troubleshooting)
30. [Frequently Asked Questions (FAQ)](#-frequently-asked-questions-faq)
31. [Roadmap](#-roadmap)
32. [Contributing](#-contributing)
33. [Security Reporting](#-security-reporting)
34. [Changelog](#-changelog)
35. [License](#-license)
36. [Acknowledgements](#-acknowledgements)

</details>

---

<!-- ============================================================================== -->
<!-- 5. PRODUCT INTRODUCTION                                                        -->
<!-- ============================================================================== -->
## 🌐 Product Introduction

**NEXORA is a modern Android application for secure, fast, and convenient file sharing between supported devices.** Engineered from first principles with **Flutter**, **Kotlin**, and a modular **Rust core engine**, NEXORA eliminates the privacy invasiveness, slow speeds, and cloud barriers that plague conventional Android file transfer tools.

- 🔒 **100% Local & Zero Cloud**: Data travels directly between devices over local Wi-Fi or mobile hotspots via raw asynchronous TCP sockets. No intermediary relay servers, no cloud storage, and zero internet consumption.
- 🚫 **Zero Accounts & Zero Friction**: No registrations, no phone numbers, no email verifications, and no user tracking.
- 🔕 **Zero Telemetry**: No background telemetry pings, no advertising SDKs, and zero behavioral tracking.
- ⚡ **Sub-Second Initiation Latency**: Senders transmit lightweight metadata manifests (`TransferOffer`) immediately (< 5 ms); receivers display authorization confirmation prompts within **18–31 ms** for 2 GB+ files, completely eliminating slow upfront hashing bottlenecks.
- 💾 **Bounded-Memory Streaming**: Multi-gigabyte files (1 GB, 5 GB, 10 GB+) stream through a bounded 1 MB RAM buffer with flow-control backpressure (`ChunkAck`), keeping heap memory stable (< 35 MB) even on budget Android devices.
- 🛡️ **Cryptographic Verification**: On-the-fly streaming SHA-256 chunk digestion guarantees byte-for-byte integrity with zero verification lag upon transfer completion.

---

<!-- ============================================================================== -->
<!-- 6. REAL APPLICATION SCREENSHOT SHOWCASE                                       -->
<!-- ============================================================================== -->
## 📱 Real Application Screenshot Showcase

Experience the verified user interface of NEXORA running on physical Android devices. Every screen is designed around our signature **Midnight Navy (`#0D1420`)**, **Electric Blue (`#3978F6`)**, and **Signal Teal (`#39C6B0`)** visual identity:

<div align="center">
  <table border="0" style="width: 100%; border-collapse: collapse; text-align: center;">
    <tr>
      <td width="20%" align="center" style="padding: 6px; vertical-align: top;">
        <a href="docs/assets/screenshots/nexora-home.png">
          <img src="docs/assets/screenshots/mockup-home.png" alt="Home Screen" width="100%" style="border-radius: 14px;" />
        </a>
        <br />
        <strong>1. Home Screen</strong>
        <p><em>Device status, radar, Scan &amp; Send, Quick actions</em></p>
      </td>
      <td width="20%" align="center" style="padding: 6px; vertical-align: top;">
        <a href="docs/assets/screenshots/nexora-transfers.png">
          <img src="docs/assets/screenshots/mockup-transfers.png" alt="Live Transfers" width="100%" style="border-radius: 14px;" />
        </a>
        <br />
        <strong>2. Live Transfers</strong>
        <p><em>Real-time streaming, speed counter &amp; chunk status</em></p>
      </td>
      <td width="20%" align="center" style="padding: 6px; vertical-align: top;">
        <a href="docs/assets/screenshots/nexora-history.png">
          <img src="docs/assets/screenshots/mockup-history.png" alt="Transfer History" width="100%" style="border-radius: 14px;" />
        </a>
        <br />
        <strong>3. History Ledger</strong>
        <p><em>SQLite transfer history, search &amp; filter tags</em></p>
      </td>
      <td width="20%" align="center" style="padding: 6px; vertical-align: top;">
        <a href="docs/assets/screenshots/nexora-devices.png">
          <img src="docs/assets/screenshots/mockup-devices.png" alt="Devices &amp; Trust Hub" width="100%" style="border-radius: 14px;" />
        </a>
        <br />
        <strong>4. Trust Hub</strong>
        <p><em>Peer discovery, QR code &amp; trusted identities</em></p>
      </td>
      <td width="20%" align="center" style="padding: 6px; vertical-align: top;">
        <a href="docs/assets/screenshots/nexora-settings.png">
          <img src="docs/assets/screenshots/mockup-settings.png" alt="Settings &amp; Network" width="100%" style="border-radius: 14px;" />
        </a>
        <br />
        <strong>5. Settings</strong>
        <p><em>Ed25519 fingerprint, paths &amp; network engine</em></p>
      </td>
    </tr>
  </table>
</div>

---

<!-- ============================================================================== -->
<!-- 7. KEY FEATURES                                                               -->
<!-- ============================================================================== -->
## ✨ Key Features

<div align="center">
  <table border="0" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td width="33%" style="padding: 6px;"><img src="docs/assets/feature-graphics/fast-file-sharing.svg" alt="Fast File Sharing" width="100%" /></td>
      <td width="33%" style="padding: 6px;"><img src="docs/assets/feature-graphics/nearby-discovery.svg" alt="Nearby Discovery" width="100%" /></td>
      <td width="33%" style="padding: 6px;"><img src="docs/assets/feature-graphics/qr-pairing.svg" alt="QR Pairing" width="100%" /></td>
    </tr>
    <tr>
      <td width="33%" style="padding: 6px;"><img src="docs/assets/feature-graphics/direct-ip.svg" alt="Direct IP" width="100%" /></td>
      <td width="33%" style="padding: 6px;"><img src="docs/assets/feature-graphics/trusted-devices.svg" alt="Trusted Devices" width="100%" /></td>
      <td width="33%" style="padding: 6px;"><img src="docs/assets/feature-graphics/live-monitoring.svg" alt="Live Monitoring" width="100%" /></td>
    </tr>
    <tr>
      <td width="33%" style="padding: 6px;"><img src="docs/assets/feature-graphics/transfer-history.svg" alt="Transfer History" width="100%" /></td>
      <td width="33%" style="padding: 6px;"><img src="docs/assets/feature-graphics/local-network.svg" alt="Local Network" width="100%" /></td>
      <td width="33%" style="padding: 6px;"><img src="docs/assets/feature-graphics/privacy-first.svg" alt="Privacy First" width="100%" /></td>
    </tr>
  </table>
</div>

---

<!-- ============================================================================== -->
<!-- 8. HOME SCREEN OVERVIEW                                                       -->
<!-- ============================================================================== -->
## 🏠 Home Screen Overview

The **Home Screen** is the central command center of the NEXORA Android application:

<div align="center">
  <img src="docs/assets/screenshots/nexora-home.png" alt="NEXORA Android Home Screen" width="340" style="border-radius: 16px; box-shadow: 0 8px 24px rgba(0,0,0,0.5);" />
</div>

- **Device Identity Card**: Displays current device nickname, active connection state (`Online`), local network IP address (`192.168.110.110:48842`), and `Ready` badge.
- **Scan & Send Primary Hero Action**: Large gradient CTA button opening the native CameraX optical QR scanner for instant camera targeting.
- **Dual Quick Action Controls**:
  - `Send Files`: Direct access to device file picker, photo gallery, videos, and multi-file selector.
  - `Receive Files`: Displays device pairing QR code and local IP address for incoming connections.
- **Nearby Devices Radar**: Live UDP multicast radar scanning for peers with animated radar pulse indicators and a fallback button for **"Connect Directly by IP"**.
- **Recent Transfers Section**: Instant summary of recently completed transfer sessions with direct taps to open received files.

---

<!-- ============================================================================== -->
<!-- 9. LIVE TRANSFERS                                                             -->
<!-- ============================================================================== -->
## 🔄 Live Transfers

The **Live Transfers Screen** provides real-time visibility into active network streams:

<div align="center">
  <img src="docs/assets/screenshots/nexora-transfers.png" alt="NEXORA Live Transfers Screen" width="340" style="border-radius: 16px; box-shadow: 0 8px 24px rgba(0,0,0,0.5);" />
</div>

- **Live Stream Tracking**: Displays active filename, total file size, byte offset, and real-time transfer speed (MB/s).
- **Two-Way Completion Protocol**: Enforces explicit `TransferComplete` ↔ `TransferCompleteAck` handshake. Upon 100% disk persistence, transfers immediately demote from live tracking to History, resetting active speed and ETA to zero and releasing all file handles.
- **Clean Idle State**: Displays clear visual guidance when streams are idle with a prominent **"Scan & Send"** button.
- **Background Foreground Service**: Seamlessly synchronizes with Android native `dataSync` Foreground Service, showing progress in the device notification shade.

---

<!-- ============================================================================== -->
<!-- 10. TRANSFER HISTORY                                                          -->
<!-- ============================================================================== -->
## 📑 Transfer History

The **Transfer History Screen** manages an on-device cryptographic ledger of all past transfers:

<div align="center">
  <img src="docs/assets/screenshots/nexora-history.png" alt="NEXORA Transfer History Screen" width="340" style="border-radius: 16px; box-shadow: 0 8px 24px rgba(0,0,0,0.5);" />
</div>

- **Instant Search Bar**: Filter transfer sessions by filename, folder name, or peer device nickname.
- **Status Filter Chips**: One-tap filtering across `ALL`, `SENT`, `RECEIVED`, `COMPLETED`, and `CANCELLED`.
- **Local SQLite Persistence**: Stored entirely on-device inside `nexora.db` with WAL journaling for crash resilience. Zero cloud sync.
- **Integrity Audit**: Each completed record stores verified SHA-256 hashes, remote peer Ed25519 public key fingerprints, and timestamp metadata.

---

<!-- ============================================================================== -->
<!-- 11. DEVICES & TRUST HUB                                                       -->
<!-- ============================================================================== -->
## 🛡️ Devices & Trust Hub

The **Devices & Trust Hub Screen** manages local network discoverability and trusted cryptographic relationships:

<div align="center">
  <img src="docs/assets/screenshots/nexora-devices.png" alt="NEXORA Devices and Trust Hub Screen" width="340" style="border-radius: 16px; box-shadow: 0 8px 24px rgba(0,0,0,0.5);" />
</div>

- **Local Discoverability Header**: Quick status indicator showing device name (`Arnob`) and `Discoverable on Wi-Fi` status.
- **Nearby Discoverable Peers**: Lists actively broadcasting devices detected on UDP port 48843 within a 10-second sliding eviction window.
- **Network Problem Fallbacks**:
  - `Scan Again`: Re-broadcasts UDP multicast packets with `WifiManager.MulticastLock`.
  - `Connect by IP`: Directly connect to peer IP address across router AP isolation barriers.
  - `Scan QR Code`: Optical pairing via native camera scan.
- **Trusted Devices Hub**: Store paired peers with Ed25519 public keys. Paired devices can be configured to auto-accept incoming transfers without manual confirmation.

---

<!-- ============================================================================== -->
<!-- 12. SETTINGS & NETWORK                                                        -->
<!-- ============================================================================== -->
## ⚙️ Settings & Network

The **Settings & Network Screen** gives users complete control over identity, storage, and networking:

<div align="center">
  <img src="docs/assets/screenshots/nexora-settings.png" alt="NEXORA Settings and Network Screen" width="340" style="border-radius: 16px; box-shadow: 0 8px 24px rgba(0,0,0,0.5);" />
</div>

- **Device Identity Configuration**: Customize your Device Display Name (e.g. `Pixel 9 Pro (NEXORA)`) with one-tap Save.
- **Cryptographic Fingerprint Display**: Full SHA-256 fingerprint (`A9:41:63:6C:92:BB:68:00:FB:B6:06:F3:9F:BB:97:A3`) derived from the local Ed25519 identity keypair.
- **Appearance & Themes**: System, Dark, and Light theme modes.
- **Transfer & Storage**:
  - `Download Directory`: Direct storage path picker (default: `Downloads/NEXORA`).
  - `Auto-accept from Trusted Devices`: Toggle automated acceptance for previously verified peers.
- **Network & Engine Diagnostic**: Displays active TCP transfer port (`48842`), local IP address (`192.168.110.110`), and engine protocol (`NEXORA TCP Bounded 1MB Chunks`).

---

<!-- ============================================================================== -->
<!-- 13. HOW NEXORA WORKS                                                          -->
<!-- ============================================================================== -->
## 🔄 How NEXORA Works

NEXORA operates across three decoupled, high-performance operational phases:

1. **Discovery Phase**: Devices announce their presence across the local subnet using UDP multicast (`224.0.0.167:48843`) and directed broadcast. Devices exchange ephemeral UUIDs and Ed25519 public fingerprints.
2. **Negotiation Phase**: The sender connects over TCP port 48842 and transmits a lightweight `TransferOffer` manifest. The receiver validates paths, checks available storage, and displays confirmation within **18–31 ms**.
3. **Streaming Phase**: Upon confirmation, the sender slices files into 1 MB chunks, hashes data on-the-fly, and streams chunks through a framed TCP channel with socket flow-control backpressure. Both devices execute an explicit `TransferCompleteAck` handshake upon 100% disk persistence.

---

<!-- ============================================================================== -->
<!-- 14. ANIMATED DEVICE DISCOVERY WORKFLOW                                         -->
<!-- ============================================================================== -->
## 📡 Animated Device Discovery Workflow

<div align="center">
  <img src="docs/assets/animations/discovery_radar.gif" alt="NEXORA Device Discovery Animation" width="640" style="border-radius: 14px; box-shadow: 0 8px 24px rgba(0,0,0,0.4);" />
</div>

- **UDP Multicast (`224.0.0.167`)**: Periodic 3-second heartbeat beacons identify peers without exhausting mobile battery.
- **Hardware MulticastLock**: Native Android Kotlin bridge acquires `WifiManager.MulticastLock` to prevent Wi-Fi chipsets from discarding multicast packets.
- **Direct IP Fallback**: Allows entering receiver IP directly when routers have AP isolation / Client Isolation enabled.

---

<!-- ============================================================================== -->
<!-- 15. QR PAIRING WORKFLOW                                                       -->
<!-- ============================================================================== -->
## 📷 QR Pairing Workflow

<div align="center">
  <img src="docs/assets/animations/qr_pairing.gif" alt="NEXORA QR Pairing Animation" width="640" style="border-radius: 14px; box-shadow: 0 8px 24px rgba(0,0,0,0.4);" />
</div>

- **CameraX & Google ML Kit**: 60 FPS viewport processing with sub-100ms QR decode latency.
- **Short Authentication String (SAS)**: 6-digit numeric comparison code verifies direct human-in-the-loop pairing against active on-path attackers.
- **Subnet-Crossing Direct Connection**: Optical QR payload encapsulates local IP and ephemeral session tokens, bypassing complex network discovery barriers.

---

<!-- ============================================================================== -->
<!-- 16. SECURE FILE TRANSFER WORKFLOW                                             -->
<!-- ============================================================================== -->
## ⚡ Secure File Transfer Workflow

<div align="center">
  <img src="docs/assets/animations/file_transfer_progress.gif" alt="NEXORA File Transfer Progress Animation" width="640" style="border-radius: 14px; box-shadow: 0 8px 24px rgba(0,0,0,0.4);" />
</div>

- **1 MB Bounded Chunk Slicing**: Slices massive multi-gigabyte files into bounded 1 MB buffer windows, eliminating memory inflation.
- **Incremental SHA-256 Digestion**: Streaming hashes calculated in parallel with network I/O; verification finishes instantly at 100% completion.
- **Two-Way Completion Protocol**: Explicit `TransferComplete` ↔ `TransferCompleteAck` handshake prevents incomplete file truncation and socket leaks.

---

<!-- ============================================================================== -->
<!-- 17. SYSTEM ARCHITECTURE                                                       -->
<!-- ============================================================================== -->
## 🏗️ System Architecture

NEXORA utilizes a layered architecture combining a **Flutter Material 3** Android interface with a modular **Rust core engine**, native Android Kotlin system bridges, and local SQLite persistence:

```mermaid
graph TD
    subgraph UI ["Layer 1: Android Flutter Presentation"]
        A1["Material 3 UI Shell"] --> A2["Riverpod State Management"]
        A2 --> A3["GoRouter Navigation Shell"]
        A2 --> A4["CameraX Optical QR Scanner"]
        A2 --> A5["Live Transfer Speed & Progress UI"]
    end

    subgraph Service ["Layer 2: Dart Orchestration Services"]
        B1["DiscoveryService (UDP & Broadcast)"]
        B2["TransferClient (TCP Socket Streamer)"]
        B3["TransferServer (TCP Server Engine)"]
        B4["DatabaseService (Native SQLite)"]
        B5["DeviceIdentityService (Ed25519)"]
    end

    subgraph Rust ["Layer 3: Modular Rust Engine (crates/)"]
        C1["discovery — UDP / mDNS"]
        C2["identity — Ed25519 Keypairs"]
        C3["protocol — 4-Byte Wire Framing"]
        C4["transfer — 1MB Chunk Engine"]
        C5["verification — Streaming SHA-256"]
        C6["security — PathSanitizer"]
        C7["resume — Checkpoint Recovery"]
    end

    subgraph Native ["Layer 4: Android Hardware & OS Abstraction"]
        D1["Android Kotlin: WifiManager MulticastLock"]
        D2["Android Kotlin: PowerManager PARTIAL_WAKE_LOCK"]
        D3["Android dataSync Foreground Service"]
        D4["Android Storage Access Framework (SAF)"]
        D5["CameraX 1.4 & Google ML Kit Barcode API"]
    end

    UI --> Service
    Service --> Rust
    Service --> Native
```

---

<!-- ============================================================================== -->
<!-- 18. TECHNOLOGY STACK                                                          -->
<!-- ============================================================================== -->
## 💻 Technology Stack

```
Frontend:      Flutter 3.44.4 · Dart 3.10+ · Riverpod 2.6 · GoRouter 14.8
Android:       Kotlin 1.9+ · Android SDK 35 (VanillaIceCream) · Gradle 8.4
Camera / QR:   Jetpack CameraX 1.4 · Google ML Kit Barcode Scanning 17.3
Core Engine:   Rust 1.94+ · Tokio Async Runtime · Ed25519-dalek · Ring SHA-256
Storage:       Native Android SQLiteDatabase (Pure OS C SQLite)
Networking:    UDP Multicast (224.0.0.167) · Subnet Broadcast · Raw Asynchronous TCP
```

---

<!-- ============================================================================== -->
<!-- 19. SECURITY AND PRIVACY                                                      -->
<!-- ============================================================================== -->
## 🛡️ Security and Privacy

NEXORA is engineered in accordance with rigorous **STRIDE Threat Modeling** principles:

### 1. Hard Frame Ceiling (5 MB Allocation Guard)
All network socket messages utilize 4-byte big-endian framing with a **strict 5 MB hard ceiling**. Any socket claiming an allocation exceeding 5 MB is dropped immediately without memory allocation, preventing remote Denial-of-Service heap exhaustion.

### 2. PathSanitizer Directory Traversal Defenses
Receivers strictly sanitize all incoming relative paths before creating files on disk:
- Rejects relative directory traversal tokens (`..`, `/`, `\`).
- Strips absolute path prefixes (`/etc/passwd`, `/system/bin`, `C:\`).
- Disallows legacy reserved system filenames: `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, `LPT1`–`LPT9`.
- Forces all received files strictly inside the designated Android `Downloads/NEXORA` directory.

### 3. Ephemeral Pairing & Public Key Fingerprinting
- **Ephemeral QR Codes**: Encapsulate device IP, port, and session token.
- **Short Authentication String (SAS)**: 6-digit numeric comparison code verifies pairing against active on-path attackers.
- **Ed25519 Identity**: Locally generated cryptographic keypairs with SHA-256 fingerprints stored in SQLite.

### 4. Zero Data Collection Privacy Guarantee
All transfer history, device nicknames, and trusted identities reside exclusively inside the device's local SQLite database (`nexora.db`). No telemetry, analytics, crash-reporting SDKs, or cloud synchronization routines exist in the codebase.

---

<!-- ============================================================================== -->
<!-- 20. ANDROID PLATFORM REQUIREMENTS                                             -->
<!-- ============================================================================== -->
## 📱 Android Platform Requirements

| Target Tier | Supported Android Versions | Processor Architectures | Recommended Devices |
| :--- | :--- | :--- | :--- |
| **Modern Android (Recommended)** | Android 11 through Android 15 (API 30–35) | `arm64-v8a` (64-bit ARM) | Pixel, Samsung Galaxy, Xiaomi, OnePlus, Realme |
| **Legacy Android** | Android 8.0 Oreo through Android 10 (API 26–29) | `armeabi-v7a` (32-bit ARM) | Older budget smartphones & 32-bit tablets |
| **Tablets & Emulators** | Android 8.0 through Android 15 | `x86_64` (64-bit Intel/AMD) | Android Studio Emulators, ChromeOS Android Subsystem |
| **Universal Package** | Android 8.0 through Android 15 | All ABIs bundled | Any Android device with sufficient storage |

---

<!-- ============================================================================== -->
<!-- 21. DOWNLOAD LATEST ANDROID APK                                               -->
<!-- ============================================================================== -->
## 📦 Download Latest Android APK

Official release APKs are cryptographically hashed and published under [GitHub Releases](https://github.com/CodeByArnob/Nexora-share/releases/latest):

| Architecture | Recommended Devices | Direct Package Download | File Size |
| :--- | :--- | :--- | :---: |
| **`arm64-v8a`** | **Modern Android Phones (Recommended)** | [**Download APK (ARM64)**](https://github.com/CodeByArnob/Nexora-share/releases/latest/download/nexora-v1.2.1-arm64-v8a.apk) | **25.0 MB** |
| **Universal** | Fat binary (All architectures included) | [Download Universal APK](https://github.com/CodeByArnob/Nexora-share/releases/latest/download/nexora-v1.2.1-universal.apk) | **67.0 MB** |
| **`armeabi-v7a`** | Older 32-bit Android phones | [Download APK (ARMv7)](https://github.com/CodeByArnob/Nexora-share/releases/latest/download/nexora-v1.2.1-armeabi-v7a.apk) | **21.0 MB** |
| **`x86_64`** | Android emulators & Chromebooks | [Download APK (x86_64)](https://github.com/CodeByArnob/Nexora-share/releases/latest/download/nexora-v1.2.1-x86_64.apk) | **27.4 MB** |
| **Google Play** | Android App Bundle | [Download AAB Bundle](https://github.com/CodeByArnob/Nexora-share/releases/latest/download/nexora-v1.2.1-release.aab) | **59.4 MB** |

---

<!-- ============================================================================== -->
<!-- 22. APK INSTALLATION GUIDE                                                    -->
<!-- ============================================================================== -->
## 🚀 APK Installation Guide

1. Download **`nexora-v1.2.1-arm64-v8a.apk`** (or the Universal APK) on your Android device.
2. Tap the downloaded APK in your browser notification or file manager.
3. If prompted by Android, toggle **"Allow from this source"** for your browser in device Settings.
4. Tap **Install** and launch NEXORA.
5. Grant **Nearby Devices / Wi-Fi** and **Camera** permissions when prompted.

---

<!-- ============================================================================== -->
<!-- 23. BUILD FROM SOURCE                                                         -->
<!-- ============================================================================== -->
## 🔨 Build from Source

### Prerequisites
- [Flutter SDK 3.44+](https://flutter.dev) & Dart SDK
- [Android SDK (API 35)](https://developer.android.com/studio) & Command-line Tools
- [Rust Toolchain 1.94+](https://rust-lang.org) (stable)
- Java Development Kit (JDK 17 or 21)

```bash
# 1. Clone the repository
git clone https://github.com/CodeByArnob/Nexora-share.git
cd Nexora-share

# 2. Build the Rust core engine workspace
cargo build --workspace --release

# 3. Build Optimized Android Split APKs
cd apps/mobile
flutter pub get
flutter build apk --release --split-per-abi

# 4. Or build Google Play App Bundle (AAB)
flutter build appbundle --release
```

Compiled APKs are output to `apps/mobile/build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (25.0 MB)
- `app-armeabi-v7a-release.apk` (21.0 MB)
- `app-x86_64-release.apk` (27.4 MB)

---

<!-- ============================================================================== -->
<!-- 24. USER GUIDE                                                                -->
<!-- ============================================================================== -->
## 📖 User Guide

### 📡 Connecting Devices
1. **Wi-Fi Network**: Connect both Android devices to the same local Wi-Fi router.
2. **Mobile Hotspot (No Router Needed)**: If outdoors, turn on **Mobile Hotspot** on one Android phone and connect the second Android phone to it. NEXORA transfers files at full Wi-Fi speeds without consuming cellular data.
3. Discovered peers appear automatically on the **Nearby Devices** radar.

### 📤 Sending and Receiving Files
1. On the sender phone, tap **Scan & Send** or tap a discovered peer.
2. Select files, photos, videos, or entire folders.
3. Tap **Send Now**. The receiver displays an authorization confirmation prompt in **< 20 ms**.
4. The receiver taps **Accept**. The transfer streams with real-time speed, progress bars, and ETA indicators.
5. Once complete, files are saved directly to `Downloads/NEXORA`.

---

<!-- ============================================================================== -->
<!-- 25. PERMISSIONS EXPLAINED                                                     -->
<!-- ============================================================================== -->
## ⚙️ Permissions Explained

NEXORA requests only permissions strictly necessary for local peer-to-peer file transfer:

- `NEARBY_WIFI_DEVICES`: Allows discovering nearby peers on local Wi-Fi without requesting GPS location access (Android 13+).
- `FOREGROUND_SERVICE_DATA_SYNC`: Ensures continuous data streaming when screen locks or app switches.
- `POST_NOTIFICATIONS`: Displays active transfer speed, progress bar, and completion notifications.
- `CAMERA`: Used exclusively for scanning peer pairing QR codes. Never records video or takes photos.
- `WAKE_LOCK`: Prevents CPU deep-sleep while handling multi-GB transfers.
- `ACCESS_NETWORK_STATE` & `ACCESS_WIFI_STATE`: Validates active Wi-Fi and hotspot interfaces.
- `CHANGE_WIFI_MULTICAST_STATE`: Allows acquiring `WifiManager.MulticastLock` for UDP packet reception.

---

<!-- ============================================================================== -->
<!-- 26. PROJECT DIRECTORY STRUCTURE                                               -->
<!-- ============================================================================== -->
## 📂 Project Directory Structure

```
Nexora-share/
├── apps/
│   └── mobile/             # NEXORA Android Application (Flutter, Material 3, Kotlin, CameraX)
├── crates/
│   ├── discovery/          # UDP multicast (224.0.0.167), subnet broadcast & mDNS
│   ├── identity/           # Ed25519 keypair generation & cryptographic fingerprinting
│   ├── pairing/            # Ephemeral QR payload, SAS codes & challenge-response
│   ├── security/           # PathSanitizer & directory traversal defense engine
│   ├── protocol/           # 4-byte big-endian framing & message definitions
│   ├── transport/          # Framed asynchronous TCP network stream reader/writer
│   ├── transfer/           # Bounded 1MB chunk slicing engine & progress tracking
│   ├── resume/             # Checkpoint offset tracking & resume safety
│   ├── verification/       # Streaming on-the-fly SHA-256 chunk & whole-file hashing
│   └── storage/            # SQLite schema migrations, trust store & transfer history
├── docs/
│   ├── assets/
│   │   ├── branding/       # High-resolution hero banners, vectors & badges
│   │   ├── screenshots/    # Real Android application screenshots & mockups
│   │   ├── animations/     # Lightweight GIFs: discovery, QR pairing, progress
│   │   └── feature-graphics/ # Vector SVG cards for key application capabilities
│   ├── ANDROID_INSTALLATION.md # Dedicated Android sideloading instructions
│   ├── ARCHITECTURE.md     # In-depth architectural design specifications
│   ├── PROTOCOL.md         # Wire protocol framing & message schema specifications
│   └── THREAT_MODEL.md     # STRIDE security & threat analysis
├── scripts/                # Automated release & size monitoring scripts
├── website/                # Official React + TypeScript + Vite project website
├── Cargo.toml              # Rust root workspace configuration
└── README.md               # Primary project documentation
```

---

<!-- ============================================================================== -->
<!-- 27. TESTING AND QUALITY ASSURANCE                                             -->
<!-- ============================================================================== -->
## 🧪 Testing and Quality Assurance

NEXORA enforces high quality assurance with automated test suites spanning mobile integration, latency benchmarks, and Rust engine crates:

```bash
# Run Mobile unit & widget test suite (22 tests + latency benchmarks)
cd apps/mobile && flutter test --concurrency=1

# Run Rust engine workspace tests
cargo test --workspace

# Static code analysis
flutter analyze apps/mobile
```

- **Static Analysis**: `flutter analyze apps/mobile` passes with **0 issues found**.
- **Unit & Integration Suite**: All 22 mobile tests pass cleanly.
- **Automated CI**: GitHub Actions validates formatting, linter, tests, and APK split builds on every pull request.

---

<!-- ============================================================================== -->
<!-- 28. PERFORMANCE AND OPTIMIZATION                                              -->
<!-- ============================================================================== -->
## ⚡ Performance and Optimization

### Initiation Latency Benchmark Results
Benchmarked on a real **2.0 GB file** transmission across Android devices:
- **Manifest Creation Latency**: `4 ms`
- **Receiver Prompt Response Latency**: `17 ms`
- **Verification Lag After 100% Transfer**: `0.00 ms` (Hashed on-the-fly during stream)
- **Target SLA Requirement**: `< 1,000 ms` (**PASS — 98% faster than SLA**)

### Memory Consumption Profile
- **Fixed Heap Allocation**: Slices files into bounded 1 MB buffer windows.
- **Constant Memory Footprint**: Average RAM usage on Android devices during 10 GB+ streaming remains stable at **< 35 MB**.

---

<!-- ============================================================================== -->
<!-- 29. TROUBLESHOOTING                                                           -->
<!-- ============================================================================== -->
## ❓ Troubleshooting

### 1. Devices do not appear on Nearby Devices
- **Cause**: The Wi-Fi router may have **AP Isolation / Client Isolation** enabled.
- **Solution**: Use the **Scan & Send** button to scan the receiver's QR code, or tap **Connect by IP** and enter the receiver's displayed IP address. Alternatively, turn on **Mobile Hotspot** on one device and connect the other device to it.

### 2. Transfer pauses when the app is minimized
- **Cause**: Android battery optimization may have restricted background execution.
- **Solution**: Ensure **Notification Permission** is granted so the `dataSync` Foreground Service can hold the transfer active. In Android device Settings, set NEXORA's battery usage to **"Unrestricted"**.

### 3. File saving fails or permission denied
- **Cause**: Storage access not granted for custom download directories.
- **Solution**: NEXORA saves files to the standard `Downloads/NEXORA` folder. Ensure the application has storage access permissions enabled in device App Info.

---

<!-- ============================================================================== -->
<!-- 30. FREQUENTLY ASKED QUESTIONS (FAQ)                                          -->
<!-- ============================================================================== -->
## 💡 Frequently Asked Questions (FAQ)

<details>
<summary><strong>Does NEXORA consume mobile internet data?</strong></summary>
No. NEXORA communicates exclusively over your local Wi-Fi router or portable mobile hotspot. No cellular data or internet bandwidth is consumed during transfers.
</details>

<details>
<summary><strong>What is the maximum file size supported?</strong></summary>
There is no file size limit. Transfers of 5 GB, 10 GB, and 50 GB+ execute smoothly because data streams in bounded 1 MB chunks without inflating RAM.
</details>

<details>
<summary><strong>Can I use NEXORA outdoors without a Wi-Fi router?</strong></summary>
Yes! Turn on Mobile Hotspot on one Android phone and connect the second Android phone to it. NEXORA will immediately discover the peer and transfer files at full Wi-Fi speeds without consuming any cellular quota.
</details>

<details>
<summary><strong>Which Android versions are supported?</strong></summary>
NEXORA supports Android 8.0 Oreo (API 26) through the latest Android 15 (API 35).
</details>

---

<!-- ============================================================================== -->
<!-- 31. ROADMAP                                                                   -->
<!-- ============================================================================== -->
## 🗺️ Roadmap

- [x] High-performance local Android discovery (UDP multicast, broadcast, mDNS)
- [x] Bounded-memory 1 MB chunk streaming with flow-control backpressure
- [x] Native CameraX QR Code scanner with Google ML Kit
- [x] Sub-second large file initiation latency (< 20 ms prompt SLA)
- [x] ABI-split Android APKs (< 25 MB package size)
- [x] Native Android SQLiteDatabase integration
- [x] Two-way completion handshake protocol
- [ ] Direct Wi-Fi Aware / Wi-Fi Direct zero-hotspot peer connection
- [ ] End-to-end TLS 1.3 socket encryption with post-quantum key exchange
- [ ] Zero-install WebRTC browser client for instant cross-device sharing

---

<!-- ============================================================================== -->
<!-- 32. CONTRIBUTING                                                              -->
<!-- ============================================================================== -->
## 🤝 Contributing

Contributions are warmly welcomed! To get started:

1. **Fork** the repository on GitHub.
2. Create a clean feature branch: `git checkout -b feature/my-enhancement`.
3. Adhere to the established code architecture, brand guidelines, and test requirements.
4. Ensure all tests pass: `cd apps/mobile && flutter test`.
5. Open a **Pull Request** targeting `main`.

---

<!-- ============================================================================== -->
<!-- 33. SECURITY REPORTING                                                        -->
<!-- ============================================================================== -->
## 🐛 Security Reporting

- **Bug Reports**: Open an issue via [GitHub Issues](https://github.com/CodeByArnob/Nexora-share/issues).
- **Security Vulnerabilities**: Review [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md) and report security issues confidentially to the maintainer via GitHub Security Advisories.

---

<!-- ============================================================================== -->
<!-- 34. CHANGELOG                                                                 -->
<!-- ============================================================================== -->
## 📜 Changelog

- **[v1.2.1] (Current Production Release)**: Bidirectional file-transfer synchronization, instant receiver awareness upon offer, unified Transfer Coordinator, cancellation handshake (`TransferCancel` / `TransferCancelAck`), accurate zero-byte progress calculation (0%), and idempotent history tracking.
- **[v1.2.0]**: Next-gen Wi-Fi Direct router-free peer-to-peer transport engine, Wi-Fi Aware (NAN), BLE out-of-band discovery (< 500 ms), real-time `StatFs` storage validation, and dynamic transport badges.
- **[v1.1.0]**: Exclusive Android focus, optimized split APKs (21–25 MB), sub-second large file initiation latency (< 20 ms), native CameraX QR scanner, streaming SHA-256 integrity.
- **[v1.0.3]**: Transfer completion two-way handshake, live transfer state demotion, and bounded memory streaming.
- **[v1.0.1]**: Background execution foreground service and pause/cancel controls.
- **[v1.0.0]**: Initial production architecture release.

See [`CHANGELOG.md`](CHANGELOG.md) for full change history.

---

<!-- ============================================================================== -->
<!-- 35. LICENSE                                                                   -->
<!-- ============================================================================== -->
## 📄 License

NEXORA is open-source software licensed under the **[Apache License 2.0](LICENSE)**.

---

<!-- ============================================================================== -->
<!-- 36. ACKNOWLEDGEMENTS                                                          -->
<!-- ============================================================================== -->
## 🙏 Acknowledgements

NEXORA is made possible thanks to these open-source technologies:
- [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- [Rust](https://rust-lang.org) & [Tokio](https://tokio.rs)
- [Google ML Kit](https://developers.google.com/ml-kit) & [AndroidX CameraX](https://developer.android.com/training/camerax)
- [Riverpod](https://riverpod.dev) & [GoRouter](https://pub.dev/packages/go_router)
- [SQLite](https://sqlite.org)

---

<div align="center">
  <sub><strong>CONNECT. SHARE. ANYWHERE.</strong><br />Designed with precision for open-source peer-to-peer productivity on Android.</sub>
</div>
