; ==============================================================================
; NEXORA Windows Setup Script (Inno Setup 6+)
; Professional, Native, Production-Ready Windows Installer
; CONNECT. SHARE. ANYWHERE.
; ==============================================================================

#define MyAppName "NEXORA"
#define MyAppVersion "1.1.0"
#define MyAppPublisher "CodeByArnob"
#define MyAppURL "https://github.com/CodeByArnob/Nexora-share"
#define MyAppExeName "nexora.exe"
#define MyAppIcon "app_icon.ico"
#define MyBuildDir "..\..\apps\desktop\build\windows\x64\runner\Release"

[Setup]
; App Identity & Versioning
AppId={{5D8E8F3C-7264-463F-A2B5-F799651C81FA}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases

; Installation Folders & Privileges
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; Output Distribution Bundle
OutputDir=..\..\dist\windows
OutputBaseFilename=NEXORA-Setup-x64
SetupIconFile={#MyAppIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

; Branding & Metadata
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Secure Cross-Platform Local File Sharing
VersionInfoCopyright=Copyright (C) 2026 {#MyAppPublisher}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "autostart"; Description: "Automatically start NEXORA on Windows startup"; GroupDescription: "Preferences:"; Flags: unchecked

[Files]
Source: "{#MyBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{autoprograms}\{#MyAppName}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#MyAppName}"; ValueData: """{app}\{#MyAppExeName}"" --minimized"; Flags: uninsdeletevalue; Tasks: autostart

[Run]
; Windows Firewall Inbound Rule Configuration for Local Transfer Port (TCP 48842 + UDP Discovery)
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""NEXORA File Sharing"" dir=in action=allow program=""{app}\{#MyAppExeName}"" enable=yes"; Flags: runhidden; StatusMsg: "Configuring Windows Firewall permissions..."
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Clean up Windows Firewall Rule on Uninstall
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""NEXORA File Sharing"" program=""{app}\{#MyAppExeName}"""; Flags: runhidden
