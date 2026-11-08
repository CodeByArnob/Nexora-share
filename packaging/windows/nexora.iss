#define AppName "NEXORA"
#ifndef AppVersion
  #define AppVersion "1.1.0"
#endif
#define AppPublisher "CodeByArnob"
#define AppExeName "nexora.exe"

[Setup]
AppId={{B9C4A72E-4A1C-4F6B-9A31-7C0A8F1D2E65}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://github.com/CodeByArnob/Nexora-share
AppSupportURL=https://github.com/CodeByArnob/Nexora-share/issues
AppUpdatesURL=https://github.com/CodeByArnob/Nexora-share/releases
DefaultDirName={autopf}\NEXORA
DefaultGroupName=NEXORA
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=lowest
OutputDir=..\..\dist\windows
OutputBaseFilename=NEXORA-Setup-x64
SetupIconFile=..\..\apps\desktop\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
VersionInfoVersion={#AppVersion}.0
VersionInfoProductName=NEXORA
VersionInfoCompany=CodeByArnob
VersionInfoDescription=NEXORA peer-to-peer file sharing

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "..\..\apps\desktop\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\NEXORA"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\NEXORA"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""NEXORA File Sharing"" dir=in action=allow program=""{app}\{#AppExeName}"" enable=yes"; Flags: runhidden; StatusMsg: "Configuring Windows Firewall permissions..."
Filename: "{app}\{#AppExeName}"; Description: "Launch NEXORA"; Flags: postinstall nowait skipifsilent

[UninstallRun]
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""NEXORA File Sharing"" program=""{app}\{#AppExeName}"""; Flags: runhidden
