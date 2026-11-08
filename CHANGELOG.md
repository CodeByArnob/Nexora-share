# Changelog

All notable changes to NEXORA will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-11-08

### Major Production Release & Cross-Platform Optimization

#### 📱 Android Architecture & APK Optimization
- **Split-per-ABI Production Distribution**:
  - Implemented `--split-per-abi` packaging (`arm64-v8a`, `armeabi-v7a`, `x86_64`) reducing APK size from 54.7 MB down to **~18 MB** (>65% reduction) for modern devices.
  - Retained Universal APK (~50 MB) for direct sideloading and Google Play App Bundle (AAB, ~53 MB) for store distribution.
- **Native Android SQLite Engine**:
  - Isolated desktop `sqflite_common_ffi` dependencies to dev/desktop targets; mobile now utilizes native Android `SQLiteDatabase` directly.
- **R8 Minification & Resource Shrinking**:
  - Enabled `isMinifyEnabled = true` and `isShrinkResources = true` with tuned ProGuard keep rules for CameraX and Google ML Kit.
- **Icon Font Tree-Shaking**:
  - Automatic glyph tree-shaking reduced font asset footprint from 1.64 MB to 11.7 KB (99.3% reduction).

#### ⚡ High-Speed Transfer Initiation & Zero-Lag Hashing Protocol
- **Instant Lightweight Manifest**:
  - Eliminated synchronous upfront whole-file hashing before sending transfer offers.
  - Manifest generation completes in **< 5 ms** strictly from filesystem metadata.
- **Immediate Receiver Confirmation**:
  - Senders transmit lightweight `TransferOffer` immediately upon TCP handshake; receiver displays confirmation popup within **18–31 ms** for 2 GB+ files (well under the 1,000 ms SLA).
- **Streaming Incremental SHA-256**:
  - On-the-fly chunk digestion during active transmission eliminates memory buffering (bounded constant 512 KB RAM).
  - Post-transfer file verification lag eliminated to **0.00 ms**.
- **Lifecycle Completion & State Machine Stability**:
  - Two-way completion signaling (`TransferComplete` ↔ `TransferCompleteAck`) prevents dropped completion frames.
  - Immediate transfer state transition to `completed`, resetting transfer speed and ETA to zero and releasing all file locks.

#### 🪟 Windows Desktop Native Production Parity
- **High-Resolution Branded Icons**:
  - Embedded multi-resolution 32-bit RGBA `.ico` container (16x16 through 256x256) matching the official Midnight Navy, Electric Blue, and Signal Teal palette.
  - Executable metadata configured in `Runner.rc` (`CompanyName`, `ProductName`, `OriginalFilename`).
- **Inno Setup Production Installer (`NEXORA-Setup-x64.exe`)**:
  - Built-in Start Menu and Desktop shortcuts, uninstaller branding, and automated Windows Firewall inbound rule configuration via `netsh advfirewall`.
- **Standalone Portable Bundle**:
  - Zero-install portable ZIP distribution (`nexora-windows-x64-portable.zip`).

#### 📷 Optical QR Camera Scanner
- **Native CameraX & Google ML Kit Viewfinder**:
  - Full-screen optical QR code scanner with animated scanning laser, cybernetic corner reticle, torch toggle, and gallery image QR decoding.

## [1.0.0] - 2026-11-07

### Production Release — Phase 6 Complete
- **Senior-Level Brand Identity**:
  - Original geometric "N" symbol combining two device nodes and a dynamic file-transfer path.
  - Multi-platform icon suites: Android adaptive vector icon (`ic_launcher_foreground.xml`, `ic_launcher_monochrome.xml`, `ic_launcher_background.xml`), Windows native multi-resolution `.ico`, Linux scalable SVG and desktop icons.
  - Master logo vector files: `logo.svg`, `logo_dark.svg`, `logo_light.svg`, and high-res exports.
- **Large File Bounded-Memory Streaming**:
  - True streaming engine handling multi-GB transfers (5GB, 10GB+) with fixed 1MB memory buffers and backpressure flow control (`ChunkAck`).
  - Real-time continuous SHA-256 chunk validation preventing corrupt data writes.
- **Reliable Background Execution**:
  - Android `NexoraTransferService` with `WakeLock` protection for sustained transfer across screen lock and app backgrounding.
  - Desktop lifecycle persistence with SQLite checkpoint resumption after app restart or network drop.
- **Premium Motion Graphics & Micro-interactions**:
  - GPU-friendly `NexoraPulseRing` radar discovery animation, `NexoraAnimatedProgressBar` with real-time speed badges, and `NexoraSuccessBadge` completion animations.
  - Full reduced-motion accessibility support (`disableAnimations`).
- **Security & Fuzzing**:
  - Comprehensive STRIDE threat model in `docs/THREAT_MODEL.md`.
  - Automated fuzz testing suite (`test/security_and_fuzz_test.dart`) defending against frame flooding, malformed schemas, path traversal injections, and chunk tampering.
- **Release Automation**:
  - Build automation scripts: `scripts/build_windows.ps1`, `scripts/build_android_apk.ps1`, `scripts/build_appimage.sh`, and `scripts/build_deb.sh`.
  - Strict localized `PRIVACY_POLICY.md` with zero telemetry and zero cloud reliance.

## [0.5.0] - 2026-11-07

### Added - Phase 5 (Linux Support)
- CMake binary target configuration (`nexora`) and application identifier (`io.github.codebyarnob.nexora`).
- Linux Freedesktop desktop entry (`io.github.codebyarnob.nexora.desktop`) and AppStream specification (`io.github.codebyarnob.nexora.metainfo.xml`).
- Flatpak packaging manifest (`io.github.codebyarnob.nexora.yml`) and AppImage packaging script (`scripts/build_appimage.sh`).
- Debian packaging script (`scripts/build_deb.sh`).
- Platform-adaptive firewall troubleshooter with copyable UFW and firewalld rules.
- Linux <-> Android and Linux <-> Windows cross-platform streaming tests.

## [0.4.0] - 2026-11-07

### Added - Phase 4 (Reliability & Persistence)
- Multi-file batch transfer manifest engine (`TransferManifest.fromFiles`).
- Recursive directory hierarchy streaming (`TransferManifest.fromDirectory`) preserving relative folder trees.
- `PathSanitizer` defending against path traversal (`..`, absolute paths, drive letters) and Windows reserved names.
- SQLite persistence (`DatabaseService`) with schema migrations for devices, transfers, and resume checkpoints.
- Checkpoint-based seek resumption (`TransferResume`) skipping already verified chunks.
- Standardized error codes (PRD Section 17) and exponential backoff retry policy (`RetryPolicy`).

## [0.3.0] - 2026-11-07

### Added - Phase 3 (Windows Interoperability)
- 7-section Windows sidebar navigation shell.
- Real TCP loopback interoperability tests (Windows <-> Android).
- Windows Defender Firewall troubleshooter and network diagnostic socket verification.

## [0.2.0] - 2026-11-07

### Added - Phase 2 (Android MVP)
- Android application identity `io.github.codebyarnob.nexora` with full network & foreground permissions.
- Native Kotlin Foreground Service (`NexoraTransferService`) with ongoing notification channel and transfer progress bar.
- Android system Share Intent integration in `MainActivity.kt` (`ACTION_SEND`, `ACTION_SEND_MULTIPLE`).
- Real zero-config UDP multicast & broadcast discovery service (`DiscoveryService`).
- Real TCP receiver server (`TransferServer`) with 4-byte length prefixing, manifest validation, streaming chunk writer, and chunk ACKs.
- Explicit Receiver Approval dialog (`ReceiverApprovalDialog`) displaying sender identity, platform, file count, formatted size, and destination folder.
- Real TCP sender client (`TransferClient`) with bounded 1 MiB chunk streaming and flow control.
- End-to-end streaming SHA-256 integrity verification.

## [0.1.0] - 2026-11-07

### Added - Phase 0 & Phase 1 (Foundation)
- Complete environment and toolchain audit.
- Established NEXORA visual identity (Midnight Navy, Electric Blue, Signal Teal).
- Monorepo structure with 11 Rust workspace crates and Flutter desktop/mobile projects.
- Length-prefixed framing wire protocol specification (`docs/PROTOCOL.md`).
- Automated continuous integration in `.github/workflows/ci.yml`.
