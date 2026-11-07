# NEXORA Privacy Policy

*Last Updated: November 7, 2026*  
*Product: NEXORA (`io.github.codebyarnob.nexora`)*  
*License: Apache 2.0*  
*Repository: https://github.com/CodeByArnob/Nexora-share*

---

### CONNECT. SHARE. ANYWHERE.
### PRIVATE BY DESIGN. OPEN BY NATURE.

At NEXORA, your privacy is not a setting or a secondary consideration—it is the foundational architecture of the entire platform. This Privacy Policy outlines our commitment to zero-telemetry, zero-cloud, and strictly localized peer-to-peer data handling.

---

## 1. Zero Cloud Architecture

NEXORA does **NOT** operate any central servers, cloud storage, relay proxies, signaling brokers, or user account databases:
- **No User Accounts**: NEXORA requires no registration, phone numbers, email addresses, or account authentication.
- **No Cloud File Storage**: Your files are never uploaded to any remote server or third-party cloud infrastructure. All data flows directly from sender to receiver over your local Wi-Fi or local area network (LAN).
- **No Third-Party Mediators**: Transfers are completely direct (device-to-device) over local TCP and UDP sockets.

---

## 2. Zero Telemetry & Zero Tracking

NEXORA is free from surveillance software:
- **No Analytics**: We do not collect metrics, usage patterns, transfer frequencies, or session lengths.
- **No Tracking SDKs**: The application contains no advertising SDKs, tracking pixels, or user behavior profiling tools.
- **No Crash Reporting Uploads**: Crash diagnostics remain solely on your local device. We do not automatically send stack traces or device fingerprints to any external servers.

---

## 3. Local Data & Cryptographic Keys

All application state is stored strictly on your local device:
- **Device Cryptographic Identity**: Each NEXORA installation creates a local cryptographic Ed25519 keypair and SHA-256 fingerprint. Private keys never leave your device's native secure keystore.
- **Transfer History**: The history of sent and received transfers is maintained exclusively in a local SQLite database (`nexora.db`) on your device. File contents are never stored in the database.
- **Trusted Device List**: Fingerprints and display names of paired devices are stored locally and can be cleared or revoked at any time in the Settings menu.

---

## 4. Platform Permissions & Justification

NEXORA requests only permissions strictly necessary for local network operation:
- **Local Network / Wi-Fi Access**: Required to announce device presence on the local subnet via UDP multicast (`224.0.0.167:48843`) and stream files via TCP (`48842`).
- **Foreground Service (Android)**: Required to sustain active large-file transfers when the screen is locked or the application is placed in the background.
- **Storage / File Access**: Required solely to read user-selected files for transmission and write approved received files to your designated Downloads directory (`~/Downloads/NEXORA`).

---

## 5. Explicit Receiver Consent

NEXORA enforces strict user consent:
- No file is ever accepted or written to your disk automatically.
- Every incoming transfer offer prompts the receiver with explicit sender identity, file names, file count, and total size before any data transmission begins.

---

## 6. Open Source Verification

NEXORA is fully open source under the Apache 2.0 License. The entire source code is publicly accessible and auditable at:
`https://github.com/CodeByArnob/Nexora-share`

You are encouraged to inspect our network implementations, build configurations, and cryptographic primitives directly.
