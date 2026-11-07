# NEXORA Testing Strategy & Verification Guide

## 1. Testing Philosophy

In NEXORA, testing is not an afterthought:
- Every advertised feature must be verified with automated test evidence.
- Untested code must never be marked as `TESTED` in status logs.
- Fuzz testing and boundary verification are enforced before any release.

---

## 2. Test Pyramid & Categories

```
          / \
         /   \      Interoperability Tests (Android ↔ Windows ↔ Linux)
        /     \     Security & Penetration Tests (Fuzzing, Traversal)
       /       \    Integration Tests (Discovery, Transfer, Resume)
      /_________\   Unit Tests (Crates: Protocol, Crypto, Math, Chunks)
```

### 2.1 Unit Tests (Rust Crates)
- **`nexora-protocol`**: Frame encoding/decoding, round-trip serialization, max frame boundary drops.
- **`nexora-identity`**: Ed25519 keypair generation, public key SHA-256 fingerprinting, message signing and verification.
- **`nexora-security`**: Path traversal attacks (`../`, `..\`), reserved Windows names (`CON`, `NUL`), replay window validation.
- **`nexora-verification`**: Known SHA-256 vector verification, streaming hasher chunk verification.
- **`nexora-resume`**: Chunk bitmap progress, missing chunk discovery, out-of-bounds rejection, checkpoint serialization.
- **`nexora-pairing`**: 6-digit SAS generation, QR payload serialization, challenge-response verification.
- **`nexora-storage`**: SQLite schema migrations, in-memory DB operations, trusted devices upsert/retrieval, transfer logs.
- **`nexora-transport`**: Asynchronous duplex stream read/write framing, socket timeout drops.
- **`nexora-transfer`**: 1 MiB chunk reading/writing, progress estimation, manifest calculation.

### 2.2 Security Tests
- Path traversal injection: Sending manifests with `../../etc/passwd` or `..\Windows\System32`.
- Duplicate nonce replay: Replaying a valid signed challenge outside the 60-second window.
- Malformed packets: Sending frame headers declaring 200 MB lengths or invalid JSON payloads.
- Corrupted chunks: Modifying chunk bytes in flight and verifying that the receiver drops the chunk with `ChecksumMismatch`.

### 2.3 Interoperability Tests
- Android (ARM64) ↔ Android (ARM64)
- Android (ARM64) ↔ Windows (x64)
- Windows (x64) ↔ Android (ARM64)
- Android (ARM64) ↔ Linux (x64)
- Linux (x64) ↔ Windows (x64)

---

## 3. Running Automated Tests

```bash
# Run all crate unit tests
cargo test --workspace

# Run Flutter mobile unit and widget tests
cd apps/mobile && flutter test

# Run Flutter desktop unit and widget tests
cd apps/desktop && flutter test
```
