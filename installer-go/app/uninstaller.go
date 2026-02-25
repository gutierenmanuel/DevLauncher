package app

import (
"github.com/charmbracelet/bubbles/progress"
"github.com/charmbracelet/bubbles/spinner"
tea "github.com/charmbracelet/bubbletea"
"github.com/charmbracelet/lipgloss"
"github.com/lucas/installer/core"
)

// UninstallModel is the BubbleTea model for the uninstaller TUI.
type UninstallModel struct {
phase       core.UninstallPhase
spinner     spinner.Model
progress    progress.Model
width       int
height      int
installDir  string
existing    *core.ExistingInstall
removeShell bool
shellCursor int
shellFile   string
err         error
}

// NewUninstallModel creates a new uninstaller model.
func NewUninstallModel() UninstallModel {
s := spinner.New()
s.Spinner = spinner.Dot
s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color(ColorPurple))

return UninstallModel{
phase:       core.UninstallPhaseSplash,
spinner:     s,
progress:    progress.New(progress.WithDefaultGradient()),
removeShell: true,
shellCursor: 0,
}
}

func (m UninstallModel) Init() tea.Cmd { return nil }

func (m UninstallModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
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

case uninstallDetectionDoneMsg:
m.installDir = msg.installDir
m.existing = msg.existing
if msg.existing == nil {
m.phase = core.UninstallPhaseNotFound
} else {
m.phase = core.UninstallPhaseConfirm
}
return m, nil

case uninstallRemovedMsg:
if msg.err != nil {
m.err = msg.err
m.phase = core.UninstallPhaseError
return m, nil
}
if m.removeShell {
m.phase = core.UninstallPhaseShell
return m, tea.Batch(m.spinner.Tick, doRemoveShell())
}
m.phase = core.UninstallPhaseDone
return m, nil

case uninstallShellDoneMsg:
m.shellFile = msg.file
if msg.err != nil {
m.err = msg.err
m.phase = core.UninstallPhaseError
return m, nil
}
m.phase = core.UninstallPhaseDone
return m, nil
}

return m, nil
}

func (m UninstallModel) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
switch m.phase {
case core.UninstallPhaseSplash:
if msg.Type == tea.KeyEnter {
m.phase = core.UninstallPhaseDetecting
return m, tea.Batch(m.spinner.Tick, doUninstallDetection())
}
if msg.Type == tea.KeyCtrlC {
return m, tea.Quit
}

case core.UninstallPhaseDetecting:
if msg.Type == tea.KeyCtrlC {
return m, tea.Quit
}

case core.UninstallPhaseConfirm:
switch msg.String() {
case "up", "k", "left":
m.shellCursor = 0
case "down", "j", "right":
m.shellCursor = 1
case "enter":
m.removeShell = m.shellCursor == 0
m.phase = core.UninstallPhaseRemoving
cmd := m.progress.SetPercent(0)
return m, tea.Batch(cmd, doRemoveDir(m.installDir))
case "q", "ctrl+c":
return m, tea.Quit
}

case core.UninstallPhaseNotFound, core.UninstallPhaseDone, core.UninstallPhaseError:
return m, tea.Quit
}

return m, nil
}
