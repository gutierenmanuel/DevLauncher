# Task 04 – Migrar TUI a `app/`

**Estado:** ⬜ pendiente  
**Depende de:** task_02, task_03  
**Bloquea:** task_06

## Objetivo

Mover toda la orquestación BubbleTea de `models/app.go` y partes de `models/command.go` al paquete `app/`. El paquete `app/` solo orquesta: no contiene lógica de negocio propia, usa `core/` y `middleware/`.

## Movimientos por archivo

### `app/model.go`
Mover desde `models/app.go`:
- `type Model struct` (actualizar tipos a `core.Category`, `core.Script`, `core.ViewState`, etc.)
- `func NewModel() Model` — usar `middleware.GetStaticPath`, `middleware.GetScriptsPath`, `middleware.ReadLauncherVersion`
- `func (m *Model) Init() tea.Cmd`
- `func (m *Model) Update(msg tea.Msg) (tea.Model, tea.Cmd)`
- `func (m *Model) View() string`

### `app/messages.go`
Mover desde `models/app.go`:
- `type categoriesLoadedMsg struct`
- `type scriptsLoadedMsg struct`
- `type scriptExecutedMsg struct`
- `type errorMsg struct`
- `func loadCategories(rootDir string) tea.Cmd` — usa `middleware.ScanCategories`
- `func loadScripts(categoryPath string) tea.Cmd` — usa `middleware.ScanScripts`
- `func executeScript(script core.Script, workingDir string) tea.Cmd` — usa `middleware.BuildScriptCommand` y `middleware.ExecuteScript`

### `app/views.go`
Mover desde `models/app.go`:
- `func (m Model) renderCategoryView() string`
- `func (m Model) renderScriptView() string`
- `func (m Model) renderExecutingView() string`
- `func (m Model) renderResultView() string`
- `func (m Model) renderCategoriesWithNumbers() string`
- `func (m Model) renderScriptsWithNumbers() string`
- `func formatCategoryCounts(dirCount, scriptCount int) string`
- `func decorateHeaderWithVersion(header, version string) string`

Mover desde `models/app.go`:
- `func ListAllScripts()` — usa `middleware.ScanCategories`, `middleware.ScanScripts`

### `app/lists.go`
Mover desde `models/app.go`:
- `type categoryItem struct` + métodos BubbleTea list
- `type scriptItem struct` + métodos BubbleTea list
- `func (m Model) createCategoryList() list.Model`
- `func (m Model) createScriptList() list.Model`

### `app/command_mode.go`
Mover desde `models/command.go`:
- `type CommandMode struct`
- `func NewCommandMode() CommandMode`
- `func (c *CommandMode) SetSize(width, height int)`
- `func (c *CommandMode) AutoComplete(m *Model)` — usa `core.longestCommonPrefix`, `core.commandSuggestions`
- `func (c *CommandMode) HandleCommand(cmd string, m *Model) tea.Cmd`
- `func (c *CommandMode) HandleMouse(msg tea.MouseMsg) tea.Cmd`
- `func (c *CommandMode) View() string`
- `func (c *CommandMode) syncViewport()`

## Criterio de éxito

```bash
cd launcher-go && go build ./...
```
- Compila sin errores.
- `models/` aún existe (no se ha eliminado).
- `main.go` sigue apuntando a `models.NewModel()` y `models.ListAllScripts()` **hasta task_07**.

## Notas

- `app/` puede importar `core/`, `middleware/`, `ui/` (para estilos) pero NO `models/` ni `utils/`.
- El `Model` en `app/` es el que `main.go` usará finalmente.
- `CommandMode` en `app/command_mode.go` usa tipos del mismo paquete `app/` (Model), lo cual está bien.
