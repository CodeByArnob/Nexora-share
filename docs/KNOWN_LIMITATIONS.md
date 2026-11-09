# NEXORA Known Limitations & Environment Blockers

## 1. Transport & Network Limitations

### 1.1 Router Client Isolation
- On public or enterprise Wi-Fi networks where router AP (client) isolation is enabled, devices cannot discover or connect directly to each other via UDP multicast or broadcast.
- **Resolution**: NEXORA provides direct IP pairing and native CameraX QR code scanning to connect directly across client isolation boundaries.

### 1.2 Android Background Transfer
- Android aggressive battery optimization and Doze mode may restrict long-running background tasks.
- **Resolution**: Transfers utilize an active Android Foreground Service with `FOREGROUND_SERVICE_DATA_SYNC`, `MulticastLock`, and `PARTIAL_WAKE_LOCK` with persistent notifications to ensure uninterrupted transfers.

---

## 2. Scope Boundaries

- **Direct P2P Only**: No cloud relay or remote NAT traversal (direct local network and hotspot transfers only).
- **Target OS**: NEXORA is focused exclusively on the Android platform (Android 8.0 Oreo through Android 15).
