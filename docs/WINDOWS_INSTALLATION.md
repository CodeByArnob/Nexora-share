# NEXORA for Windows

## Install from GitHub Releases

Download `NEXORA-Setup-x64.exe` from the [latest NEXORA release](https://github.com/CodeByArnob/Nexora-share/releases/latest). Run the installer and follow the setup wizard. The installer supports per-user installation and an optional desktop shortcut.

## Build locally

Requirements: Windows 10/11 x64, Flutter stable 3.44.4, Visual Studio 2022 with the Desktop development with C++ workload, and Inno Setup 6.

```powershell
cd apps/desktop
flutter pub get
flutter build windows --release
cd ../..
& 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' '/DAppVersion=1.0.0' packaging/windows/nexora.iss
```

The installer is written to `dist/windows/NEXORA-Setup-x64.exe`.

## Notes

The initial installer is an unsigned x64 installer. Windows SmartScreen may show an unknown-publisher warning. Verify the SHA-256 checksum published alongside the installer. Code signing can be added later with a securely managed certificate.
