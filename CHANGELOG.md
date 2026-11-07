# Changelog

All notable changes to NEXORA will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
