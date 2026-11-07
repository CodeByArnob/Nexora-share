# NEXORA Known Limitations & Environment Blockers

## 1. Environment & Build Toolchain Constraints

### 1.1 Windows Host Linker & Desktop Runner
- **Status**: Documented environment finding (Phase 0 Audit).
- **Details**: The local host Windows environment has Rust MSVC target installed (`x86_64-pc-windows-msvc`), but lacks Visual Studio 2022 C++ Build Tools (`link.exe` / `msvcrt.lib`). Installing the C++ workload via winget requires interactive administrative UAC elevation.
- **Impact**: Native Windows desktop execution via `flutter run -d windows` and host compilation of Rust proc-macro build scripts require the MSVC C++ Build Tools or LLVM `lld-link` to be linked.
- **Workaround / Resolution**:
  - Android NDK cross-compilation (`cargo ndk`) is fully functional.
  - Rust crates are validated for Android, Linux, and Windows targets.
  - Users on Windows developer machines can install Visual Studio 2022 with "Desktop development with C++" workload to compile the native Windows runner.

---

## 2. Transport & Network Limitations

### 2.1 Router Client Isolation
- On public or enterprise Wi-Fi networks where router AP (client) isolation is enabled, devices cannot discover or connect directly to each other via mDNS or local IP.
- **Resolution**: Future phases will implement hotspot-assisted connection or Wi-Fi Direct.

### 2.2 Android Background Transfer
- Android aggressive battery optimization and Doze mode may restrict long-running background tasks.
- **Resolution**: Transfers utilize an active Android Foreground Service with persistent notification to prevent premature task termination.

---

## 3. Scope Boundaries (MVP)

- No cloud relay or NAT traversal in initial release (direct local network transfers only).
- No payment processing or telemetry SDKs.
