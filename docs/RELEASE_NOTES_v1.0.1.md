# NEXORA v1.0.1 Release Notes

**Release Tag**: `v1.0.1`  
**Build Number**: `101`  
**Date**: November 8, 2026  
**License**: Apache License 2.0  
**Status**: Production Verified  

---

## 🚀 Key Improvements & Bug Fixes

### 1. File Transfer Completion Handshake
- Implemented explicit two-way completion protocol (`TransferComplete` ↔ `TransferCompleteAck`).
- Resolves transfer status stuck at 100% on receiver devices.
- Ensures immediate clean closure and resource disposal for completed TCP streams.

### 2. Live Transfer State Machine Management
- Completed transfers are immediately promoted to history and demoted from active transfers.
- Live transfer speed resets to `0 B/s` and ETA clears upon receipt of completion acknowledgement.
- Added comprehensive unit and widget tests for file transfer completion state transitions.

### 3. Background Transfer Execution Continuity
- Reinforced Android foreground service persistence (`FOREGROUND_SERVICE_DATA_SYNC`).
- Maintained active Wi-Fi `MulticastLock` and `WakeLock` across device sleep and app backgrounding.

---

## 📦 Verified Release Artifacts

| Asset | Format | Size | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| **`nexora-v1.0.1-release.apk`** | Universal Android APK | 54.7 MB (57,355,992 bytes) | `097e5a764e34843007dddac4991dd5d99bd2761d1b0267d58b137eb2e6537e50` |
| **`nexora-v1.0.1-release.aab`** | Google Play App Bundle | 53.9 MB (56,499,306 bytes) | `c52eb46677eeb74af44813a17fc5cb861176ff1aa6576f5d6c23f98f5c9723ea` |
| **`SHA256SUMS.txt`** | Checksum Ledger | 184 bytes | Cryptographic integrity ledger |

---

## 📱 Compatibility & Requirements

- **Supported Platforms**: Android (Mobile)
- **Minimum Android Version**: Android 8.0 Oreo (API level 26) or higher
- **Target Android Version**: Android 15 (API level 35)
- **Supported ABIs**: `arm64-v8a`, `armeabi-v7a`, `x86_64`
- **Network**: Wi-Fi, Local LAN, or Mobile Hotspot (Zero Internet/cloud required)

---

**Developer**: [CodeByArnob](https://github.com/CodeByArnob)  
**Repository**: [CodeByArnob/Nexora-share](https://github.com/CodeByArnob/Nexora-share)  
**License**: Apache License 2.0
