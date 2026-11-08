# NEXORA Android APK Size Analysis Report
Generated: 2026-11-08 20:43:29
Baseline Universal APK Size: 54.7 MB (57,355,992 bytes)

| Artifact | Architecture | File Size | Baseline Comparison | SHA-256 Checksum |
| :--- | :--- | :--- | :--- | :--- |
| **app-arm64-v8a-release.apk** | ARM64-v8a | 17.74 MB | -67.6% reduced | 75ca5b248ef7838a7c0d83fdf640c7bb2009dd1ea1042360d60d52002d33504f |
| **app-armeabi-v7a-release.apk** | ARMv7 | 15.3 MB | -72% reduced | fe93265e23cde23500acfe0d63397bf2cf09d63438afbe0b6eef393257ebe350 |
| **app-release.aab** | Play Bundle (All) | 53.88 MB | -1.5% reduced | c52eb46677eeb74af44813a17fc5cb861176ff1aa6576f5d6c23f98f5c9723ea |
| **app-release.apk** | Universal | 50.6 MB | -7.5% reduced | 354a3b7d56ffe5fe4d10f9379cc35d3798142cf36d77547eaf49b3e8f0663f36 |
| **app-x86_64-release.apk** | x86_64 | 19.13 MB | -65% reduced | d831da74b5cb328cab384bee311353ed3d73b395a125060bd1cc011fbd0b2d03 |

### Size Optimization Summary
- **ABI Slicing (--split-per-abi)**: Strips multi-architecture fat binaries, saving ~60-70% bandwidth for end-user device architectures (ARM64-v8a: ~18 MB vs 54.7 MB).
- **R8 Proguard & Resource Shrinking**: Unused class files, debug attributes, and unused resources stripped.
- **SQLite FFI Native Separation**: Android runtime utilizes native Android platform SQLite, eliminating redundant desktop C binaries.
