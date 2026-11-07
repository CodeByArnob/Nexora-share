# Changelog

All notable changes to NEXORA will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-07

### Added
- Phase 0: Complete environment and repository toolchain audit.
- Phase 1: Established official NEXORA visual identity (Midnight Navy, Electric Blue, Signal Teal).
- Original geometric NEXORA vector and raster logo assets (`logo.svg`, `app_icon.png`, `favicon.png`).
- Monorepo structure with 11 Rust workspace crates:
  - `nexora-protocol`: Length-prefixed framing and official wire schema.
  - `nexora-identity`: Ed25519 keypair and SHA-256 fingerprinting.
  - `nexora-security`: Path traversal protection, nonces, and replay guards.
  - `nexora-verification`: Streaming SHA-256 integrity verification.
  - `nexora-resume`: Chunk-level recovery tracking and checkpoints.
  - `nexora-pairing`: 6-digit SAS codes and challenge-response handshake.
  - `nexora-storage`: SQLite migrations, trusted device records, and transfer history.
  - `nexora-transport`: Framed async TCP/TLS reader/writer.
  - `nexora-discovery`: Zero-config mDNS peer registry.
  - `nexora-transfer`: 1 MiB chunk streaming and progress estimator.
  - `nexora-core`: Application coordinator and public typed API.
- Initialized Flutter mobile application (`apps/mobile`) and desktop application (`apps/desktop`).
- Initialized `packages/rust_bridge`.
- Initialized comprehensive documentation suite (`docs/`).
- Automated CI workflow in `.github/workflows/ci.yml`.
