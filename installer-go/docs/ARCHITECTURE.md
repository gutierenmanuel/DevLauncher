# installer-go – Arquitectura y Flujo

## Capas de la arquitectura

```mermaid
graph TD
    subgraph entry["Entry Points"]
        MAIN["main.go\n─────────────\nEmbed assets\nLanza TUI installer\nPost-install: exec launcher"]
        UMAIN["cmd/uninstaller/main.go\n─────────────\nLanza TUI uninstaller"]
    end

    subgraph app["app/  ·  Orquestación BubbleTea"]
        MODEL["model.go\nModel struct\nInit · Update · handleKey\nShouldLaunch / LaunchPath"]
        VIEWS["views.go\nviewSplash · viewDetecting\nviewConfirm · viewInstalling\nviewShellConfig · viewDone · viewError"]
        MESSAGES["messages.go\nTea msg types\ndoDetection · doShellConfig\ndoDesktopShortcut\ndoUninstallDetection\ndoRemoveDir · doRemoveShell"]
        STYLES["styles.go\nlipgloss styles\ncolors"]
        UMODEL["uninstaller.go\nUninstallModel struct\nInit · Update · handleKey"]
        UVIEWS["uninstaller_views.go\nviewUSplash · viewUConfirm\nviewURemoving · viewUDone"]
    end

    subgraph middleware["middleware/  ·  I/O e interacción con el SO"]
        DET["detection.go\nDetectExistingInstall\nRemoveInstallDir"]
        EXT["extractor.go\nExtractAssets"]
        SHU["shell_unix.go\nConfigureShell\nRemoveShellConfig"]
        SHW["shell_windows.go\nConfigureShell\nRemoveShellConfig"]
        SCU["shortcut_unix.go\nCreateDesktopShortcut"]
        SCW["shortcut_windows.go\nCreateDesktopShortcut"]
        UNU["uninstaller_unix.go\nGenerateUninstaller"]
        UNW["uninstaller_windows.go\nGenerateUninstaller"]
    end

    subgraph core["core/  ·  Lógica pura sin efectos"]
        TYPES["types.go\nExistingInstall\nPhase · UninstallPhase"]
        VER["version.go\nParseVersion\nCompareVersions"]
        ASSETS["assets.go\nCountAssets\nMapAssetPath\nIsExecutable"]
        PATHS["paths.go\nGetInstallDir\nGetLauncherPath"]
    end

    MAIN --> MODEL
    UMAIN --> UMODEL

    MODEL --> MESSAGES
    UMODEL --> MESSAGES
    MODEL --> VIEWS
    UMODEL --> UVIEWS
    MODEL --> STYLES
    UMODEL --> STYLES

    MESSAGES --> DET
    MESSAGES --> SHU
    MESSAGES --> SHW
    MESSAGES --> SCU
    MESSAGES --> SCW
    EXT --> ASSETS

    MESSAGES --> PATHS
    MESSAGES --> VER
    DET --> VER
    EXT --> ASSETS
    SCU --> PATHS
    SCW --> PATHS

    style entry fill:#1a1a2e,stroke:#7c7cff,color:#fff
    style app fill:#16213e,stroke:#7c7cff,color:#fff
    style middleware fill:#0f3460,stroke:#00d7ff,color:#fff
    style core fill:#533483,stroke:#af87ff,color:#fff
```

---

## Flujo del Installer

```mermaid
stateDiagram-v2
    [*] --> Splash : go run installer

    Splash --> Detecting : Enter
    Splash --> [*] : Ctrl+C

    Detecting --> Confirm : detectionDoneMsg\n(installDir, embeddedVer, totalFiles)
    Detecting --> [*] : Ctrl+C

    Confirm --> Installing : y / Enter\n(crea cola de extracción)
    Confirm --> [*] : q / n
    Confirm --> Confirm : d (toggle desktop shortcut)

    Installing --> ShellConfig : extractDoneMsg OK\n+ GenerateUninstaller()
    Installing --> Error : extractDoneMsg err

    ShellConfig --> DesktopShortcut : shellDoneMsg OK\n(si createShortcut=true)
    ShellConfig --> Done : shellDoneMsg OK\n(si createShortcut=false)
    ShellConfig --> Error : shellDoneMsg err

    DesktopShortcut --> Done : shortcutDoneMsg OK
    DesktopShortcut --> Error : shortcutDoneMsg err

    Done --> [*] : Enter / q\n(si ShouldLaunch → exec launcher)
    Error --> [*] : cualquier tecla
```

---

## Flujo del Uninstaller

```mermaid
stateDiagram-v2
    [*] --> USplash : go run cmd/uninstaller

    USplash --> UDetecting : Enter
    USplash --> [*] : Ctrl+C

    UDetecting --> UConfirm : uninstallDetectionDoneMsg\n(instalación encontrada)
    UDetecting --> UNotFound : uninstallDetectionDoneMsg\n(nil existing)
    UDetecting --> [*] : Ctrl+C

    UConfirm --> URemoving : Enter\n(elige si borrar shell config)
    UConfirm --> [*] : q / Ctrl+C

    URemoving --> UShell : uninstallRemovedMsg OK\n(si removeShell=true)
    URemoving --> UDone : uninstallRemovedMsg OK\n(si removeShell=false)
    URemoving --> UError : uninstallRemovedMsg err

    UShell --> UDone : uninstallShellDoneMsg
    UShell --> UError : uninstallShellDoneMsg err

    UDone --> [*] : cualquier tecla
    UError --> [*] : cualquier tecla
    UNotFound --> [*] : cualquier tecla
```

---

## Mapa de archivos

| Capa | Archivo | Responsabilidad |
|------|---------|-----------------|
| `core/` | `types.go` | `ExistingInstall`, `Phase`, `UninstallPhase` |
| `core/` | `version.go` | `ParseVersion`, `CompareVersions` |
| `core/` | `assets.go` | `CountAssets`, `MapAssetPath`, `IsExecutable` |
| `core/` | `paths.go` | `GetInstallDir`, `GetLauncherPath` |
| `middleware/` | `detection.go` | `DetectExistingInstall`, `RemoveInstallDir` |
| `middleware/` | `extractor.go` | `ExtractAssets` |
| `middleware/` | `shell_unix.go` | `ConfigureShell`, `RemoveShellConfig` (Linux/macOS) |
| `middleware/` | `shell_windows.go` | `ConfigureShell`, `RemoveShellConfig` (Windows) |
| `middleware/` | `shortcut_unix.go` | `CreateDesktopShortcut` (Linux/macOS) |
| `middleware/` | `shortcut_windows.go` | `CreateDesktopShortcut` (Windows) |
| `middleware/` | `uninstaller_unix.go` | `GenerateUninstaller` → `uninstaller.sh` |
| `middleware/` | `uninstaller_windows.go` | `GenerateUninstaller` → `uninstaller.ps1` |
| `app/` | `model.go` | `Model`, `NewModel`, `Init`, `Update`, `handleKey` |
| `app/` | `views.go` | `View()` + renders de cada fase |
| `app/` | `messages.go` | Tipos Tea msg + cmd factories |
| `app/` | `styles.go` | Colores y estilos lipgloss |
| `app/` | `uninstaller.go` | `UninstallModel`, `NewUninstallModel`, `Update` |
| `app/` | `uninstaller_views.go` | Renders del uninstaller |
| `.` | `main.go` | Entry point installer: embed FS → TUI → exec launcher |
| `cmd/uninstaller/` | `main.go` | Entry point uninstaller: TUI |
| `.` | `embed.go` | `//go:embed assets` → `assetsFS` |

---

## Reglas de capas

```
core/        → solo stdlib sin I/O real (excepto os.UserHomeDir)
middleware/  → puede importar core/. I/O libre (os.*, embed, exec)
app/         → puede importar core/ y middleware/. BubbleTea libre
main.go      → importa solo app/ y embed
```
