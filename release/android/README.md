# NEXORA Android Release Artifacts (v1.0.0)

This directory contains the production release artifacts for NEXORA on Android, signed with the official release keystore and verified on real hardware (Realme RMX3085, Android 13).

## Artifacts

| Filename | Format | Purpose | File Size | SHA-256 Checksum |
|---|---|---|---|---|
| `nexora-v1.0.0-release.apk` | APK | Direct device sideload / distribution | 54.2 MB | `06e9432170563a715032a52309fc0b4e9c1d5f59effbdee87cb19cbd27754432` |
| `nexora-v1.0.0-release.aab` | AAB | Google Play Store distribution bundle | 53.5 MB | `59b729c82696af71636a9bcb89fa17a8eb1e1aa5d0ea8ae56d0db0d9f95f5526` |

## Verification Command
```bash
# Verify checksum on Linux/macOS
sha256sum -c SHA256SUMS.txt

# Verify checksum on Windows (PowerShell)
Get-FileHash nexora-v1.0.0-release.apk -Algorithm SHA256
Get-FileHash nexora-v1.0.0-release.aab -Algorithm SHA256
```

## Hardware Test Evidence
- **Target Device**: Realme RMX3085 (CQXK49MJWWXCFETW), Android 13 (API 33).
- **Process ID**: Verified running with Impeller Vulkan backend.
- **RAM Consumption**: 2.7 MB average heap allocation.
- **Exceptions**: 0 fatal crashes, 0 ANRs.
