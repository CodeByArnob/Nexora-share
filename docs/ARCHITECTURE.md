# NEXORA System Architecture

## 1. High-Level Architectural Principles

1. **Flutter Never Directly Speaks Raw Sockets**: Networking, encryption, session state machines, chunk streaming, and file integrity verification live strictly in the Rust core.
2. **Memory-Bounded Streaming**: Files are transferred in bounded chunk sizes (default 1 MiB) with flow control and backpressure. The system never loads entire multi-gigabyte files into memory.
3. **Explicit Consent & Defense-in-Depth**: No incoming file is written or executed without user approval. Path traversal sanitization, symlink escape detection, and OS reserved name prevention run on every file.
4. **Typed Bridge Boundaries**: Flutter communicates with Rust through typed, asynchronous data structures, structured error codes, and progress event streams.

---

## 2. Monorepo Crate & Package Topology

```mermaid
graph TD
    UI[Flutter UI - Material 3] --> Bridge[packages/rust_bridge]
    Bridge --> Core[crates/nexora_core]
    
    Core --> Discovery[crates/discovery]
    Core --> Identity[crates/identity]
    Core --> Pairing[crates/pairing]
    Core --> Security[crates/security]
    Core --> Protocol[crates/protocol]
    Core --> Transport[crates/transport]
    Core --> Transfer[crates/transfer]
    Core --> Resume[crates/resume]
    Core --> Verification[crates/verification]
    Core --> Storage[crates/storage]

    Transfer --> Verification
    Transfer --> Resume
    Transfer --> Security
    Pairing --> Identity
    Pairing --> Security
    Transport --> Protocol
```

---

## 3. Crate Breakdown & Responsibilities

| Crate | Package Name | Responsibility |
|---|---|---|
| `nexora_core` | `nexora-core` | High-level application orchestrator, Flutter/FFI entry point, state coordination. |
| `discovery` | `nexora-discovery` | Zero-configuration mDNS / DNS-SD announcement (`_nexora._tcp.local.`), peer browsing, and stale peer eviction. |
| `identity` | `nexora-identity` | Ed25519 keypair generation, public key SHA-256 fingerprinting, cryptographic message signing and verification. |
| `pairing` | `nexora-pairing` | QR code payload generation/parsing, 6-digit Short Authentication String (SAS), and challenge-response handshake state machine. |
| `security` | `nexora-security` | Path traversal protection, Windows reserved filename sanitization, CSPRNG nonce generation, and replay attack guards. |
| `protocol` | `nexora-protocol` | Wire frame definitions, 4-byte length prefixing, schema validation, and official error code catalogue. |
| `transport` | `nexora-transport` | Asynchronous TCP/TLS framed stream reader and writer with bounded message sizes and timeouts. |
| `transfer` | `nexora-transfer` | Bounded file streaming, 1 MiB chunk reading/writing, exponential moving average speed and ETA computation. |
| `resume` | `nexora-resume` | Chunk-level resume tracking, verified chunk bitsets, and checkpoint serialization. |
| `verification` | `nexora-verification` | Streaming SHA-256 computation and chunk hash validation. |
| `storage` | `nexora-storage` | SQLite database, schema migrations, trusted device records, and transfer history. |

---

## 4. Transfer State Machine

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> DiscoveryBrowsing : User searches peers
    DiscoveryBrowsing --> PairingInitiated : Select peer / Scan QR
    PairingInitiated --> Authenticated : SAS verified & Challenge-response confirmed
    Authenticated --> ManifestOffered : Sender submits TransferOffer
    ManifestOffered --> Rejected : Receiver declines
    ManifestOffered --> Approved : Receiver approves manifest
    Approved --> StreamingChunks : Transmission starts
    StreamingChunks --> Paused : Network drop / User pause
    Paused --> StreamingChunks : Verified chunk resume
    StreamingChunks --> Verifying : All chunks received
    Verifying --> Completed : SHA-256 matches
    Verifying --> Corrupted : Checksum mismatch
    Completed --> [*]
    Rejected --> [*]
```
