; Programme d'installation Windows de l'app Caisse (Inno Setup 6).
; Compilé par la mise en ligne automatique :
;   ISCC /DAppVersion=2.0.0.15 /DSourceDir=...\Release /DOutDir=...\out installer\alerte-caisse.iss
; Installation pour l'utilisateur courant : pas besoin du mot de passe administrateur.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\build\windows\x64\runner\Release"
#endif
#ifndef OutDir
  #define OutDir "..\out"
#endif

#define AppName "Alerte Caisse"
#define AppExe "alerte_caisse.exe"

[Setup]
AppId={{F32102A4-12BE-4B50-AE05-E65AAEDBF136}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Genius Labs
AppPublisherURL=https://alerte-caisse.web.app
AppSupportURL=https://alerte-caisse.web.app
VersionInfoVersion={#AppVersion}
VersionInfoDescription=Installation de {#AppName}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
DisableDirPage=yes
DisableReadyPage=yes
ShowLanguageDialog=no
; Toujours pour l'utilisateur courant : aucune question, aucun mot de passe administrateur.
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutDir}
OutputBaseFilename=AlerteCaisse-Installation
SetupIconFile=..\assets\icon\caisse.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Mise à jour : ferme l'app si elle tourne, puis la relance.
CloseApplications=force
RestartApplications=no

[Languages]
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
fr.DesktopIcon=Créer une icône sur le Bureau
en.DesktopIcon=Create a desktop shortcut
fr.StartWithWindows=Démarrer automatiquement avec Windows
en.StartWithWindows=Start automatically with Windows
fr.LaunchNow=Lancer Alerte Caisse
en.LaunchNow=Launch Alerte Caisse

[Tasks]
Name: "desktopicon"; Description: "{cm:DesktopIcon}"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
; Même nom que celui utilisé par l'app elle-même (launch_at_startup) : pas de doublon.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#AppName}"; ValueData: """{app}\{#AppExe}"""; Flags: uninsdeletevalue

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchNow}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{cmd}"; Parameters: "/C taskkill /IM {#AppExe} /F"; Flags: runhidden; RunOnceId: "StopApp"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
// Mise à jour : l'ancienne version est fermée avant de remplacer ses fichiers
// (sinon Windows refuse d'écraser un programme en cours d'exécution).
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  R: Integer;
begin
  Exec(ExpandConstant('{cmd}'), '/C taskkill /IM {#AppExe} /F', '', SW_HIDE, ewWaitUntilTerminated, R);
  Sleep(600);
  Result := '';
end;
