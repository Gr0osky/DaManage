; Inno Setup script for DaManage (Frontend + Packaged Backend)
#define MyAppName "DaManage"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "DaManage"
#define MyAppExeName "usdm_gui.exe"

; Adjust these paths before building the installer
#define FrontendBuildDir "d:\passManager\DaManage\usdm_gui\build\windows\x64\runner\Release"
#define BackendDistDir  "d:\passManager\DaManage\usdm-backend\dist"

[Setup]
AppId={{2B2AB5D2-6B1E-4D8B-8F9E-2C6C4F0E8A12}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=DaManage-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "autostartbackend"; Description: "Start backend automatically at logon"; Flags: unchecked

[Files]
; Frontend EXE
Source: "{#FrontendBuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; Remaining frontend runtime files (DLLs, assets, etc.)
Source: "{#FrontendBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "{#MyAppExeName}"
; Orchestration script
Source: "d:\passManager\DaManage\Start-DaManage.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "d:\passManager\DaManage\Start-DaManage.vbs"; DestDir: "{app}"; Flags: ignoreversion
; Backend single EXE
Source: "{#BackendDistDir}\backend.exe"; DestDir: "{app}\backend"; Flags: ignoreversion

; Copy any other backend dist files (if present)
Source: "{#BackendDistDir}\*"; DestDir: "{app}\backend"; Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist; Excludes: "backend.exe"

; Ensure native sqlite binding is deployed next to backend.exe
Source: "d:\passManager\DaManage\usdm-backend\node_modules\sqlite3\build\Release\node_sqlite3.node"; DestDir: "{app}\backend"; Flags: ignoreversion
; Ensure native bcrypt binding is deployed next to backend.exe
Source: "d:\passManager\DaManage\usdm-backend\node_modules\bcrypt\lib\binding\napi-v3\bcrypt_lib.node"; DestDir: "{app}\backend"; Flags: ignoreversion
; Backend startup helpers
Source: "d:\passManager\DaManage\usdm-backend\Start-BackendExe.ps1"; DestDir: "{app}\backend"; Flags: ignoreversion
Source: "d:\passManager\DaManage\usdm-backend\Start-BackendExe.bat"; DestDir: "{app}\backend"; Flags: ignoreversion
Source: "d:\passManager\DaManage\usdm-backend\Start-BackendExe.vbs"; DestDir: "{app}\backend"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{sys}\wscript.exe"; \
  Parameters: """{app}\Start-DaManage.vbs"""; \
  WorkingDir: "{app}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{group}\Start Backend"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\backend\Start-BackendExe.vbs"""
Name: "{commondesktop}\{#MyAppName}"; Filename: "{sys}\wscript.exe"; \
  Parameters: """{app}\Start-DaManage.vbs"""; \
  WorkingDir: "{app}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: 

[Registry]
; Optional autostart of backend at user logon
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
  ValueType: string; ValueName: "DaManageBackend"; \
  ValueData: """{sys}\wscript.exe"" ""{app}\backend\Start-BackendExe.vbs"""; Tasks: autostartbackend

[Run]
; Optionally start backend after install
Filename: "{sys}\wscript.exe"; Parameters: """{app}\backend\Start-BackendExe.vbs"""; Description: "Start Backend now"; Flags: postinstall nowait skipifsilent
; Optionally launch orchestrated app after install
Filename: "{sys}\wscript.exe"; \
  Parameters: """{app}\Start-DaManage.vbs"""; \
  WorkingDir: "{app}"; Description: "Launch {#MyAppName}"; Flags: postinstall nowait skipifsilent
