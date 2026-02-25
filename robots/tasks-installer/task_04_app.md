````markdown
# Task 04 – Migrar TUI a `app/`

**Estado:** ⬜ pendiente  
**Depende de:** task_02, task_03  
**Bloquea:** task_05

## Objetivo

Mover toda la orquestación BubbleTea de `tui/` al paquete `app/`. El paquete `app/` solo orquesta: usa `core/` y `middleware/`, no contiene lógica de negocio propia.

## Movimientos por archivo

### `app/styles.go`
Mover desde `tui/styles.go`:
- Todas las constantes de color (`ColorPurple`, `ColorCyan`, `ColorYellow`, `ColorGreen`, `ColorRed`, `ColorGray`)
- Todos los estilos lipgloss (`TitleStyle`, `SuccessStyle`, `ErrorStyle`, `DimStyle`, `NormalStyle`, `BoxStyle`, `CyanStyle`, `PurpleStyle`)

Sin cambios de contenido. Solo cambia el paquete: `package tui` → `package app`.

### `app/messages.go`
Extraer desde `tui/model.go` y `tui/uninstaller.go`:

Tipos de mensajes del installer:
- `type detectionDoneMsg struct`
- `type fileExtractedMsg struct`
- `type extractDoneMsg struct`
- `type shellDoneMsg struct`
- `type shortcutDoneMsg struct`

Tipos de mensajes del uninstaller:
- `type uninstallDetectionDoneMsg struct`
- `type uninstallRemovedMsg struct`
- `type uninstallShellDoneMsg struct`

Factories (comandos Tea):
```go
func cmdDetect(installDir string, assets embed.FS) tea.Cmd
func cmdExtract(assets embed.FS, installDir string) tea.Cmd
func cmdConfigShell(installDir string) tea.Cmd
func cmdCreateShortcut(installDir string) tea.Cmd
func cmdDetectUninstall() tea.Cmd
func cmdRemoveInstall(installDir string) tea.Cmd
func cmdRemoveShell() tea.Cmd
```

Cada factory lanza una goroutine que devuelve el tipo de mensaje correspondiente.  
Usan `middleware.DetectExistingInstall`, `middleware.ExtractAssets`, `middleware.ConfigureShell`, `middleware.CreateDesktopShortcut`, `middleware.RemoveInstallDir`, `middleware.RemoveShellConfig`.

### `app/model.go`
Mover desde `tui/model.go`:
- `type Model struct` (actualizar todos los campos a tipos de `core/`)
- `func NewModel(assets embed.FS) Model`
- `func (m Model) Init() tea.Cmd`
- `func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd)`
- `func (m *Model) ShouldLaunch() bool`
- `func (m *Model) LaunchPath() string`

Cambios:
- `Phase` → `core.Phase`
- `installer.ExistingInstall` → `core.ExistingInstall`
- Llamadas a `installer.*` → llamadas a `middleware.*` y `core.*`
- Los comandos `tea.Cmd` se obtienen desde `app/messages.go` (mismo paquete)

### `app/views.go`
Extraer desde `tui/model.go` todas las funciones de render del installer:
- `func (m Model) View() string`
- `func (m Model) renderSplash() string`
- `func (m Model) renderDetecting() string`
- `func (m Model) renderConfirm() string`
- `func (m Model) renderInstalling() string`
- `func (m Model) renderShellConfig() string`
- `func (m Model) renderDesktopShortcut() string`
- `func (m Model) renderDone() string`
- `func (m Model) renderError() string`

Usar `app.BoxStyle`, `app.TitleStyle`, etc., del mismo paquete.

### `app/uninstaller.go`
Mover desde `tui/uninstaller.go`:
- `type UninstallModel struct` (actualizar tipos a `core.UninstallPhase`, `core.ExistingInstall`)
- `func NewUninstallModel() UninstallModel`
- `func (m UninstallModel) Init() tea.Cmd`
- `func (m UninstallModel) Update(msg tea.Msg) (tea.Model, tea.Cmd)`
- `func (m UninstallModel) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd)`

Cambios:
- `UninstallPhase` → `core.UninstallPhase` + constantes
- `installer.ExistingInstall` → `core.ExistingInstall`
- Llamadas a `installer.*` → `middleware.*`

### `app/uninstaller_views.go`
Extraer desde `tui/uninstaller.go` todas las funciones de render:
- `func (m UninstallModel) View() string`
- `func (m UninstallModel) renderSplash() string`
- `func (m UninstallModel) renderDetecting() string`
- `func (m UninstallModel) renderConfirm() string`
- `func (m UninstallModel) renderRemoving() string`
- `func (m UninstallModel) renderShellStep() string`
- `func (m UninstallModel) renderDone() string`
- `func (m UninstallModel) renderError() string`
- `func (m UninstallModel) renderNotFound() string`

## Criterio de éxito

```bash
cd installer-go && go build ./...
```
- Compila sin errores.
- `installer/` y `tui/` aún existen (todavía son importados por `main.go`).
- `app/` compila independientemente con `go build ./app/`.

## Reglas de capas

- `app/` **puede** importar `core/`, `middleware/`.
- `app/` **puede** importar dependencias externas: `bubbletea`, `bubbles/*`, `lipgloss`.
- `app/` **NO puede** importar `installer/` ni `tui/`.
````
