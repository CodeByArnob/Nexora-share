# NEXORA v1.0.1 — High-Speed Streaming & Motion Release

> **CONNECT. SHARE. ANYWHERE.**  
> *PRIVATE BY DESIGN. OPEN BY NATURE.*

---

### 🚀 Primary Download Link
👉 **[Download NEXORA for Android](https://github.com/CodeByArnob/Nexora-share/releases/download/v1.0.1/nexora-v1.0.1-release.apk)** *(Direct APK Download, 54.7 MB)*

---

## 🌟 What's New in v1.0.1

### ⏹️ Interactive Transfer Pause, Resume & Instant Cancellation
- **Instant Cancel**: Wired up the cancel (`X`) button across `TransfersScreen`, `TransferClient`, and `TransferServer`. Users can instantly abort an in-flight transfer with clean socket termination, safe file handle cleanup, and graceful SQLite state transition.
- **Bi-directional Remote Cancel Protocol**: Added `TransferCancel` wire message frame. When one device aborts, the peer immediately ceases streaming and cleans up active resources.
- **Pause & Resumption**: Added dynamic pause/resume toggling. Transfer sessions flush verified checkpoints and can be resumed with zero data corruption.

### ⚡ Line-Rate Transfer Speed Acceleration (50–100+ MB/s)
- **Zero-Copy Binary Chunk Framing**: Replaced CPU-heavy JSON integer array serialization with a raw binary frame layout (`0xAA` magic marker + 4-byte length prefix). Completely eliminated JSON AST parsing and Base64 conversion overhead.
- **Sliding-Window Flow Control**: Implemented 4MB pipelining over TCP sockets with `TCP_NODELAY` enabled. Bypassed lockstep stop-and-wait roundtrip delays.
- **Throttled SQLite Checkpointing**: Checkpoint transactions are buffered to 5MB intervals, eliminating flash memory I/O bottlenecks.

### 🖼️ Android MediaStore & Auto-Gallery Indexing
- **Public Downloads Integration**: Received files now default to `/storage/emulated/0/Download/Nexora` instead of app-internal sandboxes.
- **Instant Gallery Scanning**: Added `MediaScannerConnection.scanFile` and `ACTION_MEDIA_SCANNER_SCAN_FILE` broadcast integration in `MainActivity.kt`. All incoming photos (`.jpg`, `.png`, `.webp`) and videos (`.mp4`, `.mkv`, etc.) appear immediately in Google Photos and device Gallery apps.

### 🎨 Premium Motion Graphics & UI Polish
- **Dynamic Breathing Glow**: Active transfer cards feature real-time pulsing neon gradient borders (`#3978F6` & `#39C6B0`) with GPU-accelerated micro-interactions.
- **Shimmer Progress Bar**: Fluid animated gradient progress bar with moving light streak and live speed badge (`MB/s`).
- **P2P Radar Wave Empty State**: Smooth concentric circular pulse waves when idle.

---

## 📦 Verified Release Artifacts

| Asset | Format | Size | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| **`nexora-v1.0.1-release.apk`** | Universal Android APK | 54.7 MB (57,355,992 bytes) | `097e5a764e34843007dddac4991dd5d99bd2761d1b0267d58b137eb2e6537e50` |
| **`nexora-v1.0.1-release.aab`** | Google Play App Bundle | 53.9 MB (56,499,306 bytes) | `c52eb46677eeb74af44813a17fc5cb861176ff1aa6576f5d6c23f98f5c9723ea` |
| **`SHA256SUMS.txt`** | Checksum Ledger | 184 bytes | Cryptographic integrity ledger |

---

## 📱 Compatibility & Requirements

- **Supported Platforms**: Android (Mobile), Windows (Desktop), Linux (Desktop)
- **Minimum Android Version**: Android 8.0 Oreo (API level 26) or higher
- **Target Android Version**: Android 15 (API level 35)
- **Supported ABIs**: `arm64-v8a`, `armeabi-v7a`, `x86_64`
- **Network**: Wi-Fi, Local LAN, or Mobile Hotspot (Zero Internet/cloud required)

---

**Developer**: [CodeByArnob](https://github.com/CodeByArnob)  
**Repository**: [CodeByArnob/Nexora-share](https://github.com/CodeByArnob/Nexora-share)  
**License**: Apache License 2.0
