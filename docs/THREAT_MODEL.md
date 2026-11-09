# NEXORA Threat Model & Security Architecture

**Version**: 1.1.0  
**Methodology**: STRIDE Threat Model & OWASP Mobile Security Verification  
**Target Platform**: Android (API 26+)  
**Scope**: Discovery, Handshake, Transport, Storage, and UI Orchestration

---

## 1. Security Architecture Principles

1. **Zero Cloud Attack Surface**: No remote auth servers, NAT traversal relays, central registries, or telemetry ingest endpoints.
2. **Cryptographic Identity**: Every device is anchored to a locally generated Ed25519 keypair.
3. **Defense-in-Depth Framing**: Hard memory ceilings (5 MB maximum frame length) and bounded 1 MiB chunk streaming buffers.
4. **Strict Path Sanitization**: Zero directory traversal tolerance (`PathSanitizer`).
5. **Verified Integrity**: Chunk-level and file-level SHA-256 validation.

---

## 2. Trust Boundaries & Data Flow

```
[ Local File System ]
         |
    (Boundary 1) Local Storage / Permissions
         |
[ NEXORA Android Application (Flutter UI + Kotlin + Rust Engine) ]
         |
    (Boundary 2) Process Isolation / Android IPC
         |
[ TCP / UDP Sockets (Port 48842 / 48843) ]
         |
    (Boundary 3) Untrusted Local Network (LAN / Hotspot)
         |
[ Remote Peer Node (Android Device) ]
```

### Trust Assumptions:
1. **The Local Host OS is Trusted**: The kernel, memory isolation, and local storage access controls of the Android operating system are assumed not to be maliciously subverted.
2. **The Local Network (LAN) is Untrusted**: Anyone on the local Wi-Fi / LAN may observe UDP broadcast / multicast discovery beacons, attempt rogue TCP connections, send malformed packets, or spoof device metadata.
3. **All Received Payloads are Untrusted**: Any incoming frame, manifest, relative file path, chunk boundary, and hash must be strictly validated before disk access.

---

## 3. STRIDE Threat Analysis & Implemented Mitigations

### 3.1 Spoofing (Identity & Discovery)
- **Threat**: A rogue device on the LAN broadcasts spoofed discovery packets impersonating trusted peers or announces fraudulent device IDs.
- **Mitigation**:
  - Each installation generates a unique, persistent Ed25519 cryptographic keypair and derived SHA-256 fingerprint (`crates/identity`).
  - Device pairing requires explicit receiver approval and cryptographic challenge verification.
  - Discovery presence is transient and cached with a 10-second sliding eviction window.

### 3.2 Tampering (Data in Transit & on Disk)
- **Threat**: A malicious network adversary attempts to inject corrupted bytes into streaming chunks or tamper with files mid-transfer.
- **Mitigation**:
  - Every transmitted chunk (up to 1 MiB) carries an individual SHA-256 digest (`chunk_sha256`).
  - The receiver computes streaming SHA-256 hashes in real time before writing to disk; any mismatch triggers an immediate socket termination and `CHECKSUM_MISMATCH` alert.
  - Final whole-file SHA-256 digest is verified against sender-declared manifest hash upon stream completion.

### 3.3 Repudiation
- **Threat**: A peer denies having offered or received files.
- **Mitigation**:
  - Local SQLite transfer ledger records signed session IDs, remote peer fingerprint, byte counts, and completion timestamps.
  - Transfers require explicit manual "Accept" on the receiver UI before socket streaming begins.

### 3.4 Information Disclosure
- **Threat**: Eavesdropping on file metadata, contents, or permanent device secrets.
- **Mitigation**:
  - Zero permanent secret tokens or private keys are ever serialized into discovery broadcasts or wire packets.
  - Private Ed25519 keys are stored in secure native platform storage (Android Keystore).
  - No analytics, telemetry, crash reporters, or external cloud endpoints exist in the codebase.

### 3.5 Denial of Service (DoS & Resource Exhaustion)
- **Threat**: Adversary attempts to exhaust receiver memory by sending giant length-prefixed headers (`0x7FFFFFFF` / 2 GB), endless chunk streams, or flooding the filesystem.
- **Mitigation**:
  - **Hard Frame Ceiling**: 4-byte big-endian framing enforces `maxFrameSize = 5 MB`. Any packet header claiming `> 5 MB` drops the TCP socket immediately without memory allocation.
  - **Bounded Memory Streaming**: Streaming uses fixed 1 MiB buffers with backpressure (`ChunkAck`). Whole files are never buffered in RAM.
  - **Disk Capacity Verification**: Receiver checks free storage before accepting transfers exceeding available disk space.

### 3.6 Elevation of Privilege & Directory Traversal
- **Threat**: Adversary crafts a manifest containing directory traversal attacks (`../../../../etc/passwd`, `/system/bin`, or reserved system device names `CON`, `PRN`, `AUX`, `NUL`) to overwrite system binaries or escape the designated download directory.
- **Mitigation**:
  - `PathSanitizer.resolveSafePath` strictly decomposes all relative paths into canonical segments.
  - Strips all `..`, `.`, and absolute root slashes (`/`).
  - Escapes reserved device names (`CON` -> `_CON.txt`).
  - Forces all writes strictly inside the Android device `Downloads/NEXORA` directory.
  - Rejects execution of received files.

---

## 4. Fuzzing & Security Verification Status

Automated security verification systematically tests:
1. `Oversized Frame Ceiling`: Verifies 50 MB length-prefix claims result in zero RAM allocation and immediate socket termination.
2. `Randomized Byte Fuzzing`: Fuzz storms of random byte streams handled without server crash or hang.
3. `Malformed Schemas`: Corrupt UTF-8, truncated JSON, and boundary anomalies rejected cleanly.
4. `Path Traversal Injection`: 15 distinct injection patterns neutralized and sandboxed.
