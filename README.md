# NEXORA

<div align="center">
  <img src="assets/branding/logo/logo.svg" alt="NEXORA Logo" width="160" height="160" />
  <h3>CONNECT. SHARE. ANYWHERE.</h3>
  <p><strong>PRIVATE BY DESIGN. OPEN BY NATURE.</strong></p>
  <p>
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg" alt="License" /></a>
    <img src="https://img.shields.io/badge/platforms-Android%20%7C%20Windows%20%7C%20Linux-teal.svg" alt="Platforms" />
    <img src="https://img.shields.io/badge/core-Rust%20%2B%20Flutter-14243B.svg" alt="Tech" />
  </p>
</div>

---

## 1. What is NEXORA?

NEXORA is a high-performance, privacy-first peer-to-peer file sharing platform for Android, Windows, and Linux.

- **Zero Cloud**: Transfers occur directly between devices over your local network.
- **Zero Accounts**: No registration, no login, no central servers.
- **Zero Telemetry**: No hidden analytics or user behavior tracking.
- **Verified Integrity**: End-to-end cryptographic integrity verification via SHA-256 and Ed25519 signatures.

---

## 2. Core Features

- **Local Discovery**: Instant zero-configuration local network discovery via mDNS / DNS-SD.
- **Secure Pairing**: Ephemeral QR pairing, 6-digit Short Authentication String (SAS) confirmation, and cryptographic challenge-response validation.
- **Receiver Approval**: Senders cannot push unapproved files; receivers inspect file manifests, sizes, and file counts before explicitly approving.
- **High-Throughput Streaming**: Memory-bounded streaming with 1 MiB chunking, backpressure handling, and support for gigabyte-scale files.
- **Verified Resume**: Interrupted transfers automatically resume from the last verified chunk without retransmitting already-received data.
- **Trusted Device Management**: Store trusted peers with cryptographic public-key fingerprints for streamlined workflows.
- **Transfer History**: Complete local SQLite history recording transfer status, byte counts, and timestamps (never file contents).

---

## 3. Technology Stack

- **User Interface**: Flutter & Dart (Material 3, Midnight Navy & Electric Blue palette, Riverpod state management, GoRouter)
- **Core Engine**: Rust (Zero-copy networking, async Tokio runtime, Ed25519 cryptographic identity, SHA-256 verification)
- **Native Android**: Kotlin (Foreground service, Storage Access Framework, Notification channels, Share intents)
- **Storage**: SQLite with versioned migrations
- **Bridge**: Typed FFI / `flutter_rust_bridge`

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
(mDNS/DNS-SD) (Ed25519)     (1MB Chunks)
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

## 5. Security Model

Security is an essential first-class requirement in NEXORA:
- **No Plaintext Fallback**: Connections run over TLS 1.3 or authenticated Ed25519 signed sessions.
- **Path Traversal Protection**: Incoming filenames and relative paths are parsed component by component. Any `..`, root paths, or reserved OS names (`CON`, `PRN`, `AUX`, `NUL`, etc.) are rejected immediately.
- **Replay Protection**: Handshake and pairing messages enforce timestamp drift checks and nonce uniqueness caching.
- **Explicit Consent**: Automatic file execution or silent file writes are strictly prevented.

---

## 6. Monorepo Organization

```
nexora-share/
  apps/
    mobile/         # Android Flutter application
    desktop/        # Windows & Linux Flutter application
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
  packages/
    rust_bridge/    # Dart/Flutter bindings to Rust core
  assets/
    branding/       # Official logo, icons, colors, typography
  docs/             # Architectural and protocol specifications
  .github/          # CI/CD workflows and issue templates
```

---

## 7. Getting Started

### Prerequisites
- [Flutter 3.44+](https://flutter.dev) & Dart SDK
- [Rust 1.94+](https://rust-lang.org) (stable)
- Android SDK & NDK (for mobile builds)

### Building the Rust Workspace
```bash
# Check all workspace crates
cargo check

# Run tests
cargo test
```

### Running the Flutter Mobile App
```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## 8. License

NEXORA is licensed under the [Apache License 2.0](LICENSE).
Private by design. Open by nature.
