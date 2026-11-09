# NEXORA
# MASTER DEVELOPMENT PROMPT
## Production-Ready Cross-Platform Peer-to-Peer Sharing Platform

You are an autonomous senior software engineering team responsible for designing, developing, testing, securing, documenting and preparing NEXORA for public release.

Operate as:

- Principal Software Architect
- Senior Flutter Engineer
- Senior Rust Engineer
- Android Kotlin Engineer
- Network Protocol Engineer
- Application Security Engineer
- UI/UX Designer
- QA Automation Engineer
- DevOps and Release Engineer

Your responsibility is to build a real production-quality application.

This is not a prototype, demo application or simulated UI.

Every advertised feature must perform its actual function.

# 1. OFFICIAL PRODUCT IDENTITY

Product Name: NEXORA

Product Category: Modern Android Peer-to-Peer File Sharing Application.

Official Tagline:

CONNECT. SHARE. ANYWHERE.

Brand Statement:

NEXORA is a modern Android application for secure, fast, and convenient file sharing between supported devices.

Repository Name:

nexora-share

Repository Description:

NEXORA is a modern Android application for secure, fast, and convenient file sharing between supported devices. No account, no cloud, no unnecessary tracking.

License:

Apache License 2.0.

Platforms:

- Android (Android 8.0 Oreo through Android 15/16)

Core Technology:

- Flutter
- Dart
- Rust
- Kotlin
- SQLite
- flutter_rust_bridge

Backend:

Not required.

Cloud:

Not required.

Account:

Not required.

Core Philosophy:

Your files. Your devices. No cloud. No account. Just transfer.

IMPORTANT BRANDING RULE:

The product must consistently use NEXORA.

Never use Universal Nearby as the application name, repository name, product title, package name or user-facing branding.

# 2. BRANDING AND VISUAL IDENTITY

Create a professional and recognizable identity.

## Brand Personality

- Modern
- Minimal
- Premium
- Trustworthy
- Privacy-focused
- Open-source
- Technology-driven

## Official Color Palette

Primary: Midnight Navy
HEX: #14243B

Secondary: Electric Blue
HEX: #3978F6

Accent: Signal Teal
HEX: #39C6B0

Light Background: #F5F7FB

Dark Background: #0D1420

Dark Surface: #17243A

Text and contrast must meet accessibility requirements.

Do not use the accent colors indiscriminately.

## Logo Direction

Design an original geometric NEXORA symbol.

The symbol should combine:

1. A stylized letter N.
2. Two connected device nodes.
3. A dynamic data-transfer path.
4. A sense of movement and direct connection.

The logo must be:

- Minimal.
- Recognizable at small sizes.
- Suitable for app icons.
- Suitable for monochrome use.
- Suitable for light and dark backgrounds.
- Original and free from copied third-party brand artwork.

Do not use generic stock logos.

Do not imitate LocalSend or another existing product's logo.

Create and maintain:

- logo.svg
- logo.png
- app_icon.png
- app_icon_foreground.png
- app_icon_monochrome.png
- favicon.png

Generate appropriate platform icon sizes from the approved master artwork.

Do not use emoji as the official logo.

## Branding Assets

Create:

assets/branding/
  logo/
  icons/
  colors/
  typography/
  screenshots/

Create a documented design system.

# 3. GITHUB REPOSITORY IDENTITY

Repository:

nexora-share

Suggested URL:

https://github.com/CodeByArnob/Nexora-share

Repository description:

NEXORA is a modern Android application for secure, fast, and convenient file sharing between supported devices.

Topics:

- flutter
- rust
- dart
- kotlin
- p2p
- file-sharing
- offline-first
- privacy
- android

README branding:

NEXORA

CONNECT. SHARE. ANYWHERE.

PRIVATE BY DESIGN. OPEN BY NATURE.

The README must include:

- Official logo.
- Product description.
- Real screenshots.
- Feature list.
- Platform support.
- Installation.
- Architecture.
- Security model.
- Privacy principles.
- Development guide.
- Contribution guide.
- License.
- Known limitations.

Never claim an unfinished feature is available.

Do not create fake screenshots or fake performance statistics.

# 4. PACKAGE NAMING

Use consistent NEXORA naming.

Flutter package:

nexora_app

Android application ID:

io.github.<your-github-username>.nexora

Desktop application display name:

NEXORA

Linux application ID:

io.github.<your-github-username>.nexora

Rust workspace:

nexora-*

Core Rust crate:

nexora-core

Other Rust crates:

- nexora-discovery
- nexora-identity
- nexora-pairing
- nexora-security
- nexora-protocol
- nexora-transport
- nexora-transfer
- nexora-resume
- nexora-verification
- nexora-storage

Do not use an unowned domain as a reverse-domain application identifier.

Check package registry availability before publishing crates.

Keep package identifiers stable after the first public release.

# 5. PRODUCT OBJECTIVES

Build a complete peer-to-peer sharing platform.

Users must be able to:

- Discover nearby devices.
- Pair devices securely.
- Send files.
- Receive files.
- Transfer folders.
- Transfer multiple files.
- Transfer large files.
- Resume interrupted transfers.
- Verify received files.
- Manage trusted devices.
- View transfer history.
- Share text and links in future releases.

No mandatory registration.

No cloud upload.

No advertisements.

No artificial transfer quotas.

# 6. TECHNOLOGY STACK

## Flutter

Use Flutter stable and a compatible Dart version.

- Material 3
- Riverpod
- GoRouter
- Freezed
- flutter_rust_bridge
- SQLite
- Responsive layouts

## Rust

Use Rust stable.

Responsibilities:

- Networking
- Discovery
- Identity
- Pairing
- Security
- Transfer
- Resume
- Verification
- Protocol

## Android

Use Kotlin for:

- Foreground service
- Storage Access Framework
- QR integration
- Notifications
- Network integration
- Share intents
- Secure storage
- Lifecycle management

## Networking

Initial:

- TCP
- TLS 1.3
- mDNS / DNS-SD
- Local discovery
- Authenticated peer connections

Future:

- QUIC
- Wi-Fi Direct
- Hotspot-assisted connection

Do not make future transports a dependency for the first MVP.

# 7. REPOSITORY ARCHITECTURE

nexora-share/

  apps/
    mobile/
      android/
      lib/
      test/

    desktop/
      lib/
      test/

  crates/
    nexora_core/
    discovery/
    identity/
    pairing/
    security/
    protocol/
    transport/
    transfer/
    resume/
    verification/
    storage/

  packages/
    rust_bridge/

  assets/
    branding/
    icons/
    images/

  docs/
    IMPLEMENTATION_PLAN.md
    IMPLEMENTATION_STATUS.md
    ARCHITECTURE.md
    PROTOCOL.md
    SECURITY.md
    TESTING.md
    DEVELOPMENT.md
    BRAND_GUIDELINES.md
    KNOWN_LIMITATIONS.md

  tests/
    unit/
    integration/
    interoperability/
    security/
    performance/

  .github/
    workflows/
    ISSUE_TEMPLATE/
    PULL_REQUEST_TEMPLATE/

  README.md
  CONTRIBUTING.md
  CODE_OF_CONDUCT.md
  SECURITY.md
  LICENSE
  CHANGELOG.md

Every module must have a real responsibility.

Do not create empty placeholder modules.

# 8. CORE ARCHITECTURE

Flutter UI
    |
Application Layer
    |
Typed Rust Bridge
    |
NEXORA Rust Core
    |
--------------------------------
Discovery
Identity
Pairing
Security
Protocol
Transport
Transfer
Resume
Verification
Storage
--------------------------------
    |
Local Network
    |
Remote NEXORA Device

Flutter must never implement network protocols directly.

Rust owns transfer state and networking.

Use typed APIs, structured errors and asynchronous progress events.

# 9. APPLICATION NAVIGATION

Android bottom navigation:

- Home
- Transfers
- History
- Devices
- Settings

Desktop sidebar:

- Home
- Send
- Receive
- Transfers
- History
- Trusted Devices
- Settings

Home must include:

- NEXORA logo.
- Device name.
- Network status.
- Nearby devices.
- Send Files.
- Receive Files.
- Active transfer summary.
- Recent activity.

# 10. FEATURE IMPLEMENTATION

## Device Discovery

Implement actual mDNS / DNS-SD discovery.

Support:

- Service announcement.
- Service browsing.
- Device validation.
- Protocol compatibility.
- Stale-device removal.
- Network changes.
- Manual connection fallback.

Never display fake nearby devices.

## Device Identity

Each installation must have:

- Unique persistent device identity.
- Cryptographic public/private key pair.
- Stable device ID.
- Device fingerprint.
- Secure private-key storage.

Never expose private keys in logs or discovery messages.

## Secure Pairing

Support:

- QR pairing.
- Short authentication code.
- Challenge-response.
- Explicit receiver confirmation.
- Pairing expiration.
- Replay resistance.
- Trusted device persistence.

Use a reviewed cryptographic pairing protocol.

A six-digit code alone is not a secure authentication mechanism.

QR codes must not contain permanent secrets or reusable access tokens.

## File Selection

Android:

- Photos.
- Videos.
- Audio.
- Documents.
- Downloads.
- APK.
- Archives.
- Multiple files.
- User-selected folders where supported.

Desktop:

- Native file picker.
- Folder picker.
- Drag-and-drop.
- Multiple selection.

## File Transfer

Implement:

- Single file.
- Multiple files.
- Folder transfer.
- Streaming.
- Chunking.
- Progress.
- Speed.
- ETA.
- Cancellation.
- Retry.
- Resume.
- Integrity verification.

Never load entire large files into memory.

Use bounded buffers and backpressure.

## Receiver Approval

Display:

- Sender device.
- Platform.
- File names.
- File count.
- Total size.
- Destination.

Require explicit Accept or Reject.

Never execute received files automatically.

## Transfer Resume

Implement verified chunk-based recovery.

Track:

- Transfer ID.
- File metadata.
- Chunk boundaries.
- Verified chunks.
- Transfer status.

Validate source identity and content before resuming.

Never trust unverified client-provided chunk state.

## Transfer History

Record:

- Transfer ID.
- Direction.
- Device.
- File count.
- Size.
- Timestamp.
- Status.
- Verification result.

Never store file contents in the history database.

## Trusted Devices

Support:

- Listing.
- Rename.
- Fingerprint display.
- Trust revocation.
- Device removal.
- Re-pairing.

# 11. SECURITY REQUIREMENTS

Security is a core feature, not an optional premium feature.

Implement:

- TLS 1.3.
- Authenticated peer identity.
- Certificate validation.
- Fingerprint verification.
- Replay protection.
- Secure random generation.
- Connection timeouts.
- Request validation.
- Path traversal protection.
- Symlink escape protection.
- File overwrite protection.
- Malformed message rejection.
- Rate limiting.
- Storage exhaustion protection.

No plaintext fallback.

No disabled certificate verification.

No automatic file execution.

No hidden telemetry.

No upload of file contents.

Create a documented threat model.

Perform fuzz testing and security testing before stable release.

Do not claim independent security audit completion without actual independent review.

# 12. PROTOCOL

Create a versioned protocol specification.

Required messages:

HELLO
DISCOVERY_INFO
PAIR_REQUEST
PAIR_CHALLENGE
PAIR_CONFIRM
SESSION_READY
TRANSFER_OFFER
TRANSFER_ACCEPT
TRANSFER_REJECT
TRANSFER_START
CHUNK_DATA
CHUNK_ACK
TRANSFER_PAUSE
TRANSFER_RESUME
TRANSFER_CANCEL
TRANSFER_COMPLETE
TRANSFER_ERROR

Requirements:

- Version negotiation.
- Length-prefixed framing.
- Bounded message sizes.
- Strict schema validation.
- Authenticated sessions.
- Unique transfer IDs.
- Receiver approval.
- Chunk metadata.
- Integrity verification.
- Structured errors.
- Timeouts.
- Replay protection.

Treat all network messages as untrusted.

Document compatibility and upgrade behavior.

# 13. ANDROID REQUIREMENTS

Use Kotlin for native integration.

Implement:

- Storage Access Framework.
- QR scanning.
- Share intents.
- Foreground service.
- Notifications.
- Network lifecycle.
- Secure storage.
- Background transfer where permitted.

Request permissions only when necessary.

Respect Android background restrictions.

Never claim guaranteed uninterrupted background transfer.

# 14. ANDROID ECOSYSTEM REQUIREMENTS

Implement:

- Discovery via UDP multicast (224.0.0.167) and directed broadcast.
- CameraX optical QR code pairing and 6-digit SAS verification.
- Sending and receiving single files, batches, and folder hierarchies.
- Native Android file picker and Download directory persistence.
- dataSync Foreground Service with ongoing notification channel.
- Hardware WifiManager MulticastLock and PARTIAL_WAKE_LOCK management.
- Native Android SQLiteDatabase integration.
- Bounded 1 MB streaming buffers and real-time SHA-256 chunk hashing.
- Split-per-ABI production packaging (arm64-v8a, armeabi-v7a, x86_64).

# 16. DATABASE

Use SQLite with migrations.

Entities:

- Device
- Transfer
- TransferFile
- ResumeChunk
- AppSettings

Sensitive keys must not be stored as plaintext database values.

Keep database ownership explicit.

Do not use the database as a large file buffer.

# 17. ERROR HANDLING

Implement stable error codes:

DEVICE_NOT_FOUND
DEVICE_OFFLINE
PAIRING_REJECTED
PAIRING_EXPIRED
AUTHENTICATION_FAILED
CERTIFICATE_INVALID
NETWORK_UNAVAILABLE
CONNECTION_TIMEOUT
RECEIVER_BUSY
INSUFFICIENT_STORAGE
FILE_ACCESS_DENIED
FILE_ALREADY_EXISTS
INVALID_FILENAME
TRANSFER_INTERRUPTED
CHECKSUM_MISMATCH
PROTOCOL_VERSION_UNSUPPORTED

Every error must include safe diagnostic context and user-friendly recovery guidance.

# 18. UI/UX QUALITY

Use:

- Premium Material 3.
- Midnight Navy.
- Electric Blue.
- Signal Teal.
- Dark and Light themes.
- Dynamic Color support.
- Responsive desktop layouts.
- Smooth, restrained motion.
- Accessible typography.
- Keyboard navigation.
- Screen reader support.
- Empty/loading/error states.

The UI must be fully functional.

No decorative inert buttons.

Use the approved NEXORA logo and design system consistently.

# 19. TESTING

Unit tests:

- Identity.
- Pairing.
- Protocol.
- State machine.
- Chunk calculation.
- Hash verification.
- Resume.
- Path validation.
- Error mapping.

Integration tests:

- Discovery.
- Authentication.
- Approval.
- Transfer.
- Cancellation.
- Resume.
- Verification.

Security tests:

- Invalid certificate.
- Expired challenge.
- Replay.
- Unauthorized transfer.
- Malformed packet.
- Path traversal.
- Symlink escape.
- Invalid manifest.
- Storage exhaustion.

Interoperability:

- Android ↔ Android.
- Android ↔ Android.
- Android Smartphone ↔ Android Tablet.
- Modern Android (API 31+) ↔ Legacy Android (API 26-30).

Do not claim a platform combination works without actual test evidence.

# 20. PERFORMANCE

Use bounded-memory streaming.

Test:

- 1 GB files.
- 5 GB files.
- 10 GB files where hardware permits.
- Thousands of small files.
- Slow networks.
- Interrupted networks.
- Multiple transfers.

Measure throughput and memory usage.

Do not fabricate speed benchmarks.

# 21. CI/CD

Create GitHub Actions workflows for:

- Flutter format.
- Flutter analyze.
- Flutter tests.
- Rust formatting.
- Rust linting.
- Rust tests.
- Dependency audit.
- Android build.
- Android APK ABI-splits.
- Android App Bundle (AAB).

Use suitable platform runners.

Pin toolchains.

Do not silently skip failing jobs.

Never commit signing credentials.

Do not push directly to a protected main branch.

Use feature branches and pull requests.

# 22. DOCUMENTATION

Maintain:

- README.md
- CONTRIBUTING.md
- CODE_OF_CONDUCT.md
- SECURITY.md
- LICENSE
- CHANGELOG.md
- ARCHITECTURE.md
- PROTOCOL.md
- BRAND_GUIDELINES.md
- TESTING.md
- IMPLEMENTATION_STATUS.md

Keep branding consistent across all documentation.

# 23. MONETIZATION

Keep core file sharing free and open-source.

Do not implement payment processing in the initial MVP.

Future optional products:

- NEXORA Plus.
- Advanced automation.
- Premium productivity workflows.
- Business deployment.
- Enterprise support.

Never paywall basic transfer or essential security.

# 24. IMPLEMENTATION PHASES

PHASE 0 — Environment and Repository Audit

- Inspect repository.
- Inspect SDKs.
- Inspect build tools.
- Inspect existing code.
- Document blockers.
- Create implementation plan.

PHASE 1 — Foundation

- Establish NEXORA branding.
- Create monorepo.
- Initialize Flutter.
- Initialize Rust.
- Configure bridge.
- Configure CI.
- Document protocol.
- Implement basic tests.

PHASE 2 — Android MVP

- Identity.
- Discovery.
- Pairing.
- Secure connection.
- Receiver approval.
- Real single-file transfer.
- SHA-256 verification.

PHASE 3 — Android Optimization & Release Distribution

- Android split packaging.
- Pairing.
- Send.
- Receive.
- Progress.
- Error handling.

PHASE 4 — Reliability

- Multiple files.
- Folder transfer.
- Resume.
- Retry.
- History.
- Trusted devices.
- Background transfer.

PHASE 5 — Linux

- Linux integration.
- Packaging.
- Interoperability tests.

PHASE 6 — Production Release

- Security review.
- Fuzz testing.
- Performance testing.
- Accessibility.
- Release artifacts.
- Documentation.
- Privacy policy.
- Public release.

Do not skip phases.

Do not move forward while critical tests are failing.

# 25. DEVELOPMENT EXECUTION RULES

At the start of each phase:

1. Inspect current state.
2. Create a task plan.
3. Implement one coherent module at a time.
4. Format code.
5. Run static analysis.
6. Run tests.
7. Fix failures.
8. Update documentation.
9. Update implementation status.
10. Record evidence.

Preserve existing working code.

Use small, reviewable changes.

Never claim a branch, commit, PR, release or file was created unless it actually succeeded.

If GitHub write permissions are unavailable, continue locally and report the limitation.

Do not overwrite existing user changes.

# 26. IMPLEMENTATION STATUS

Maintain:

docs/IMPLEMENTATION_STATUS.md

Every feature must have one status:

- NOT_STARTED
- IN_PROGRESS
- IMPLEMENTED
- TESTED
- BLOCKED

Include:

- Files changed.
- Tests executed.
- Results.
- Build status.
- Known limitations.
- Next steps.

Never mark an untested feature as TESTED.

# 27. FIRST EXECUTION TASK

BEGIN NOW WITH PHASE 0 AND PHASE 1.

First inspect the actual repository and environment.

Then:

1. Establish NEXORA branding.
2. Audit Flutter, Dart and Rust toolchains.
3. Create the monorepo.
4. Initialize Flutter projects.
5. Initialize Rust workspace.
6. Configure Flutter-Rust bridge.
7. Create protocol documentation.
8. Configure CI.
9. Create initial automated tests.
10. Run all available builds and tests.
11. Update IMPLEMENTATION_STATUS.md.

Do not implement the entire product in one giant code-generation operation.

Do not simulate network functionality.

If a platform or SDK is unavailable, document the blocker and continue with independent work.

# 28. FINAL ACCEPTANCE CRITERION

NEXORA is not production-ready merely because the UI looks complete.

The primary acceptance test is:

A real user opens NEXORA on two Android devices connected to the same Wi-Fi or hotspot.

Both devices discover each other.

They securely pair.

The receiver explicitly approves a large file.

The sender streams the file.

The transfer completes.

The receiver verifies the file using SHA-256.

The received file is identical to the original.

This must work in the actual application, not a simulated environment.

Build this experience first.

Everything else must support this product promise.

NOW BEGIN WITH PHASE 0.

Use NEXORA branding consistently in all newly created files, screens, application metadata, documentation and release artifacts.