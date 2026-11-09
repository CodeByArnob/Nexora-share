# NEXORA Development Guide

## 1. Prerequisites

Before contributing or building NEXORA locally, ensure the following toolchains are installed:

- **Flutter SDK**: 3.44.0 or newer (Stable channel)
- **Dart SDK**: 3.12.0 or newer
- **Rust**: 1.94.0 or newer (Stable channel)
  ```bash
  rustup update stable
  ```
- **Android SDK & NDK**:
  - Android API level 34+
  - NDK r25+
  - Set `ANDROID_HOME` or `ANDROID_SDK_ROOT`

---

## 2. Monorepo Workflow

NEXORA uses a unified monorepo containing the Rust core engine and Flutter Android mobile application.

### 2.1 Rust Workspace (Core Protocol & Cryptography Engine)
```bash
# Verify all workspace crates compile
cargo check --workspace

# Run all unit tests
cargo test --workspace

# Lint with clippy
cargo clippy --workspace -- -D warnings

# Format code
cargo fmt --all -- --check
```

### 2.2 Flutter Android Application
```bash
cd apps/mobile
flutter pub get
flutter test --concurrency=1
flutter analyze
flutter run
```

---

## 3. Coding Standards & Guidelines

1. **Rust Safety & Cleanliness**:
   - Strictly prohibit `unsafe` blocks unless absolutely required for FFI.
   - Use `thiserror` for library error types with structured variants and context.
   - All network bytes are untrusted: validate frame boundaries, schemas, and timestamps.

2. **Flutter & Dart Architecture**:
   - Use Riverpod state management.
   - Keep business logic and network operations out of UI widgets.
   - Follow Material 3 guidelines and use the official NEXORA theme tokens (`#14243B`, `#3978F6`, `#39C6B0`).

3. **Documentation**:
   - Maintain comments on all public structs, enums, functions, and wire messages.
   - Never commit API changes without updating `docs/PROTOCOL.md` and `docs/IMPLEMENTATION_STATUS.md`.
