package app

import (
"embed"
"os"

"github.com/charmbracelet/bubbles/progress"
"github.com/charmbracelet/bubbles/spinner"
tea "github.com/charmbracelet/bubbletea"
"github.com/charmbracelet/lipgloss"
"github.com/lucas/installer/core"
"github.com/lucas/installer/middleware"
)

// Model is the BubbleTea model for the installer TUI.
type Model struct {
phase    core.Phase
spinner  spinner.Model
progress progress.Model
width    int
height   int

installDir  string
existing    *core.ExistingInstall
embeddedVer string

totalFiles   int
doneFiles    int
currentFile  string
shellProfile string
shortcutPath string
err          error

createShortcut  bool
launchAfterDone bool
launchPath      string

assets embed.FS
}

// NewModel creates a new installer Model.
func NewModel(assets embed.FS) Model {
s := spinner.New()
s.Spinner = spinner.Dot
s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color(ColorPurple))

return Model{
phase:          core.PhaseSplash,
spinner:        s,
progress:       progress.New(progress.WithDefaultGradient()),
assets:         assets,
createShortcut: true,
}
}

func (m Model) Init() tea.Cmd { return nil }

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
switch msg := msg.(type) {
case tea.WindowSizeMsg:
m.width = msg.Width
m.height = msg.Height
m.progress.Width = msg.Width - 10
if m.progress.Width < 10 {
m.progress.Width = 10
}
return m, nil

case tea.KeyMsg:
return m.handleKey(msg)

case spinner.TickMsg:
var cmd tea.Cmd
m.spinner, cmd = m.spinner.Update(msg)
return m, cmd

case progress.FrameMsg:
pm, cmd := m.progress.Update(msg)
m.progress = pm.(progress.Model)
return m, cmd

case detectionDoneMsg:
m.installDir = msg.installDir
m.existing = msg.existing
m.embeddedVer = msg.embeddedVer
m.totalFiles = msg.totalFiles
m.phase = core.PhaseConfirm
return m, nil

case fileExtractedMsg:
m.doneFiles = msg.current
m.currentFile = msg.filename
pct := 0.0
if msg.total > 0 {
pct = float64(msg.current) / float64(msg.total)
}
cmd := m.progress.SetPercent(pct)
if msg.current >= msg.total {
return m, tea.Batch(cmd, func() tea.Msg { return extractDoneMsg{nil} })
}
return m, cmd

case extractDoneMsg:
if msg.err != nil {
m.err = msg.err
m.phase = core.PhaseError
return m, nil
}
if err := middleware.GenerateUninstaller(m.installDir); err != nil {
m.err = err
m.phase = core.PhaseError
return m, nil
}
m.phase = core.PhaseShellConfig
return m, tea.Batch(m.spinner.Tick, doShellConfig(m.installDir))

case shellDoneMsg:
if msg.err != nil {
m.err = msg.err
m.phase = core.PhaseError
return m, nil
}
m.shellProfile = msg.profile
if m.createShortcut {
m.phase = core.PhaseDesktopShortcut
return m, tea.Batch(m.spinner.Tick, doDesktopShortcut(m.installDir))
}
m.prepareLaunch()
m.phase = core.PhaseDone
return m, nil

case shortcutDoneMsg:
if msg.err != nil {
m.err = msg.err
m.phase = core.PhaseError
return m, nil
}
m.shortcutPath = msg.path
m.prepareLaunch()
m.phase = core.PhaseDone
return m, nil
}

return m, nil
}

func (m Model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
switch m.phase {
case core.PhaseSplash:
if msg.Type == tea.KeyEnter {
m.phase = core.PhaseDetecting
return m, tea.Batch(m.spinner.Tick, doDetection(m.assets))
}
if msg.Type == tea.KeyCtrlC {
return m, tea.Quit
}

case core.PhaseDetecting:
if msg.Type == tea.KeyCtrlC {
return m, tea.Quit
}

case core.PhaseConfirm:
switch msg.String() {
case "d", "D":
m.createShortcut = !m.createShortcut
return m, nil
case "y", "Y", "enter":
m.phase = core.PhaseInstalling
m.doneFiles = 0
return m, tea.Batch(m.spinner.Tick, m.startExtraction())
case "q", "n", "ctrl+c":
return m, tea.Quit
}

case core.PhaseDone, core.PhaseError:
return m, tea.Quit
}

return m, nil
}

func (m *Model) startExtraction() tea.Cmd {
return func() tea.Msg {
return m.doFullExtraction()
}
}

func (m *Model) doFullExtraction() tea.Msg {
err := middleware.ExtractAssets(m.assets, m.installDir, nil)
if err != nil {
return extractDoneMsg{err}
}
total := m.totalFiles
if total == 0 {
total = core.CountAssets(m.assets)
}
return fileExtractedMsg{current: total, total: total, filename: "done"}
}

func (m *Model) prepareLaunch() {
launcherPath := core.GetLauncherPath(m.installDir)
if _, err := os.Stat(launcherPath); err == nil {
m.launchAfterDone = true
m.launchPath = launcherPath
}
}

// ShouldLaunch indicates whether main should launch DevLauncher after installer exits.
func (m Model) ShouldLaunch() bool { return m.launchAfterDone }

// LaunchPath returns the launcher binary path to execute after successful install.
func (m Model) LaunchPath() string { return m.launchPath }
