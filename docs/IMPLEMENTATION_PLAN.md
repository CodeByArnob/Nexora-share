# NEXORA Implementation Plan

## Phase Overview

| Phase | Title | Objective | Target Platforms | Status |
|---|---|---|---|---|
| **Phase 0** | **Environment & Repository Audit** | Audit toolchains, SDKs, linkers, document blockers, prepare environment. | All | **COMPLETED** |
| **Phase 1** | **Foundation** | Branding, monorepo layout, Rust workspace, Flutter projects, protocol docs, CI, base tests. | Android, Windows, Linux | **COMPLETED** |
| **Phase 2** | **Android MVP** | End-to-end device identity, mDNS discovery, QR/SAS pairing, receiver approval, streaming transfer, SHA-256 verification. | Android | **COMPLETED** |
| **Phase 3** | **Windows Interoperability** | Windows discovery, pairing, file pickers, drag & drop, transfers with Android. | Windows, Android | NOT_STARTED |
| **Phase 4** | **Reliability & Advanced Features**| Multiple files, folder hierarchies, chunk-level resume, transfer history, trusted devices, foreground service. | Android, Windows | NOT_STARTED |
| **Phase 5** | **Linux Support** | Linux discovery, GTK file pickers, Flatpak/AppImage packaging, cross-platform interoperability. | Linux, Android, Windows | NOT_STARTED |
| **Phase 6** | **Production Release** | Security audit, fuzzing, 10 GB file benchmarks, accessibility, documentation, signed release artifacts. | All | NOT_STARTED |

---

## Detailed Phase Tasks

### Phase 0: Environment and Repository Audit
- [x] Inspect workspace and Git configuration.
- [x] Audit Flutter toolchain (`Flutter 3.44.4`, `Dart 3.12.2`).
- [x] Audit Rust toolchain (`rustc 1.94.1`, `cargo 1.94.1`).
- [x] Audit Android toolchain (`Android SDK 36.1.0`, `NDK 28.2 / 27.0`, `Java 21 LTS`, `cargo-ndk`).
- [x] Audit Windows host linker requirements (`link.exe` / MSVC Build Tools requirement documented).
- [x] Install `flutter_rust_bridge_codegen 2.14.0-beta.2`.
- [x] Document environment constraints in `docs/KNOWN_LIMITATIONS.md`.

### Phase 1: Foundation
- [x] Establish official NEXORA visual identity (Midnight Navy `#14243B`, Electric Blue `#3978F6`, Signal Teal `#39C6B0`).
- [x] Create original geometric vector & raster logo and icon assets (`logo.svg`, `logo.png`, `app_icon.png`, `favicon.png`).
- [x] Create monorepo directory layout (`apps/`, `crates/`, `packages/`, `assets/`, `docs/`, `tests/`).
- [x] Initialize 11 Rust workspace crates (`nexora-core`, `nexora-discovery`, `nexora-identity`, `nexora-pairing`, `nexora-security`, `nexora-protocol`, `nexora-transport`, `nexora-transfer`, `nexora-resume`, `nexora-verification`, `nexora-storage`).
- [x] Implement wire protocol, framing, and standardized error codes in `crates/protocol`.
- [x] Implement Ed25519 identity and fingerprinting in `crates/identity`.
- [x] Implement path traversal sanitization and replay guards in `crates/security`.
- [x] Implement streaming SHA-256 verification in `crates/verification`.
- [x] Implement chunk-level resume tracking in `crates/resume`.
- [x] Implement QR payload and SAS pairing in `crates/pairing`.
- [x] Implement SQLite schema and persistence in `crates/storage`.
- [x] Implement framed async transport in `crates/transport`.
- [x] Implement peer registry in `crates/discovery`.
- [x] Implement chunk streaming and progress estimator in `crates/transfer`.
- [x] Initialize Flutter mobile project `apps/mobile` (`io.github.codebyarnob.nexora`).
- [x] Initialize Flutter desktop project `apps/desktop`.
- [x] Initialize `packages/rust_bridge`.
- [x] Author `docs/PROTOCOL.md`, `docs/ARCHITECTURE.md`, `docs/BRAND_GUIDELINES.md`, `docs/TESTING.md`, `docs/DEVELOPMENT.md`.
- [x] Configure GitHub Actions CI workflow.

### Phase 2: Android MVP
- [x] Configure Android app ID `io.github.codebyarnob.nexora` and permissions (`INTERNET`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `POST_NOTIFICATIONS`).
- [x] Implement native Kotlin Foreground Service (`NexoraTransferService`) with ongoing notification channel (`nexora_transfers`).
- [x] Implement native `MainActivity.kt` MethodChannel for Foreground Service control and system Share Intent (`ACTION_SEND`, `ACTION_SEND_MULTIPLE`) handling.
- [x] Implement real UDP multicast discovery service (`DiscoveryService`) with 3s presence broadcasts and 10s stale peer eviction.
- [x] Implement real TCP receiver server (`TransferServer`) with 4-byte length prefixing, manifest parsing, chunk writing, and chunk ACKs.
- [x] Implement explicit Receiver Approval dialog (`ReceiverApprovalDialog`) displaying sender name, platform, file count, formatted size, and destination.
- [x] Implement real TCP sender client (`TransferClient`) with manifest generation, 1 MiB chunk streaming, backpressure flow control, and speed/ETA calculation.
- [x] Implement end-to-end streaming SHA-256 integrity verification.
- [x] Create comprehensive automated integration tests (`test/transfer_streaming_test.dart`, `test/receiver_approval_dialog_test.dart`, `test/network_protocol_test.dart`).
- [x] Validate zero analysis issues (`flutter analyze` clean).
