# NEXORA Release Notes — v1.0.0 (Build 100)

**Release Date**: November 7, 2026  
**License**: Apache License 2.0  
**Developer**: CodeByArnob ([GitHub](https://github.com/CodeByArnob))  
**Repository**: [https://github.com/CodeByArnob/Nexora-share](https://github.com/CodeByArnob/Nexora-share)

---

## Highlights

NEXORA is a lightweight, privacy-first peer-to-peer file sharing platform engineered for Android, Windows, and Linux. It delivers verified file transfers across your local Wi-Fi or subnet with no account, zero cloud storage, and no tracking.

> **CONNECT. SHARE. ANYWHERE.**  
> *PRIVATE BY DESIGN. OPEN BY NATURE.*

---

## What's New in Version 1.0.0

### 1. Production Release Architecture
* **Signed Android Release APK**: 54.2 MB release binary optimized with R8 shrinking, ProGuard rules, and private keystore signing.
* **Google Play App Bundle (AAB)**: 53.5 MB AAB ready for Google Play Store publishing.
* **Windows PC Executable**: Native x64 Windows binary target (`nexora.exe`) with consistent iconography and metadata.
* **Linux Desktop Support**: Native Linux executable target (`nexora`) with Desktop Entry, AppStream metainfo, and Debian packaging scripts.

### 2. High-Performance Bounded-Memory Streaming
* **Bounded RAM Consumption**: Streams multi-gigabyte files (1GB, 5GB, 10GB+) using fixed 1MB chunk slicing without memory inflation (~2.7MB heap on real devices).
* **Chunk SHA-256 Integrity**: Real-time per-chunk cryptographic hashing and whole-file verification.
* **Checkpoint Resumption**: Interrupted transfers automatically resume from the last verified chunk instead of restarting.
* **Exponential Backoff**: Adaptive reconnection policy with jitter to recover from momentary network drops.

### 3. Background Transfer Execution
* **Android Foreground Service**: Compliant with Android 13/14+ background execution limits via `FOREGROUND_SERVICE_DATA_SYNC` and persistent notification channel.
* **Screen Lock & Multitasking**: Transfers continue seamlessly when the device is locked or the user switches apps.

### 4. Senior-Level Brand Identity & Motion Design
* **Geometric "N" Monogram**: Custom vector icon combining two interconnected nodes and an accelerated data transfer path.
* **Theme System**: Material 3 theme with Midnight Navy (`#14243B`), Electric Blue (`#3978F6`), and Signal Teal (`#39C6B0`).
* **GPU-Accelerated Motion**: Lightweight radar pulse discovery rings, smooth progress bar tweening, and animated success badges that respect reduced-motion accessibility.

### 5. Multi-File Batches & Folder Hierarchy
* Send and receive entire directories while preserving nested folder hierarchy on all target operating systems.

### 6. Developer & Project Credits
* Detailed About NEXORA section in Settings displaying developer profile (`CodeByArnob`), repository links, version number, build code, and technology acknowledgements.

---

## Artifact Checksums

```
06e9432170563a715032a52309fc0b4e9c1d5f59effbdee87cb19cbd27754432  nexora-v1.0.0-release.apk
59b729c82696af71636a9bcb89fa17a8eb1e1aa5d0ea8ae56d0db0d9f95f5526  nexora-v1.0.0-release.aab
```
