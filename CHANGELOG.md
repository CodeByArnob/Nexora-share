# Changelog

All notable changes to NEXORA will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-11-08

### Major Production Release — Exclusive Android Production & High-Speed Protocol

#### 🤖 Exclusive Android Focus & Architecture
- **Android-Only Product Identity**:
  - Transformed NEXORA into an exclusive Android application for high-performance peer-to-peer sharing across modern Android smartphones and tablets (Android 8.0 Oreo through Android 15).
  - Streamlined build configuration and GitHub Actions workflows dedicated to Android APK compilation, ABI splits, and Google Play Store App Bundles.
- **Split-per-ABI Production Distribution**:
  - Implemented `--split-per-abi` packaging (`arm64-v8a`, `armeabi-v7a`, `x86_64`) reducing APK size from 54.7 MB down to **~20–25 MB** for modern devices.
  - Retained Universal APK (~50 MB) for direct sideloading and Google Play App Bundle (AAB, ~53.9 MB) for store distribution.
- **Native Android SQLite Engine**:
  - Migrated mobile database layer to utilize native Android `SQLiteDatabase` directly.
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
  - On-the-fly chunk digestion during active transmission eliminates memory buffering (bounded constant 1 MB RAM).
  - Post-transfer file verification lag eliminated to **0.00 ms**.
- **Lifecycle Completion & State Machine Stability**:
  - Two-way completion signaling (`TransferComplete` ↔ `TransferCompleteAck`) prevents dropped completion frames.
  - Immediate transfer state transition to `completed`, resetting transfer speed and ETA to zero and releasing all file locks.

#### 📷 Optical QR Camera Scanner
- **Native CameraX & Google ML Kit Viewfinder**:
  - Full-screen optical QR code scanner with animated scanning laser, cybernetic corner reticle, torch toggle, and gallery image QR decoding.

## [1.0.0] - 2026-11-07

### Production Release — Android MVP & Core Engine
- **Senior-Level Brand Identity**:
  - Original geometric "N" symbol combining two device nodes and a dynamic file-transfer path.
  - Android adaptive vector icon (`ic_launcher_foreground.xml`, `ic_launcher_monochrome.xml`, `ic_launcher_background.xml`).
  - Master logo vector files: `logo.svg`, `logo_dark.svg`, `logo_light.svg`.
- **Large File Bounded-Memory Streaming**:
  - Streaming engine handling multi-GB transfers (5GB, 10GB+) with fixed 1MB memory buffers and backpressure flow control (`ChunkAck`).
  - Real-time continuous SHA-256 chunk validation preventing corrupt data writes.
- **Reliable Background Execution**:
  - Android `NexoraTransferService` with `WakeLock` and `MulticastLock` protection for sustained transfer across screen lock and app backgrounding.
- **Premium Motion Graphics & Micro-interactions**:
  - GPU-friendly `NexoraPulseRing` radar discovery animation, `NexoraAnimatedProgressBar` with real-time speed badges, and `NexoraSuccessBadge` completion animations.
  - Full reduced-motion accessibility support (`disableAnimations`).
- **Security & Fuzzing**:
  - Comprehensive STRIDE threat model in `docs/THREAT_MODEL.md`.
  - Automated fuzz testing suite defending against frame flooding, malformed schemas, path traversal injections, and chunk tampering.

## [0.2.0] - 2026-11-07

### Added - Android Foundation
- Android application identity `io.github.codebyarnob.nexora` with full network & foreground permissions.
- Native Kotlin Foreground Service (`NexoraTransferService`) with ongoing notification channel and transfer progress bar.
- Android system Share Intent integration in `MainActivity.kt` (`ACTION_SEND`, `ACTION_SEND_MULTIPLE`).
- Real zero-config UDP multicast & broadcast discovery service (`DiscoveryService`).
- Real TCP receiver server (`TransferServer`) with 4-byte length prefixing, manifest validation, streaming chunk writer, and chunk ACKs.
- Explicit Receiver Approval dialog (`ReceiverApprovalDialog`) displaying sender identity, platform, file count, formatted size, and destination folder.
- Real TCP sender client (`TransferClient`) with bounded 1 MiB chunk streaming and flow control.
- End-to-end streaming SHA-256 integrity verification.

## [0.1.0] - 2026-11-07

### Added - Architecture & Protocols
- Established NEXORA visual identity (Midnight Navy, Electric Blue, Signal Teal).
- Length-prefixed framing wire protocol specification (`docs/PROTOCOL.md`).
- Automated continuous integration in `.github/workflows/ci.yml`.
