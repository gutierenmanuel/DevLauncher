package tui

import (
	"fmt"
	"runtime"
	"strings"

	"github.com/charmbracelet/bubbles/progress"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/lucas/installer/installer"
)

// UninstallPhase represents a step in the uninstall flow.
type UninstallPhase int

const (
	UninstallPhaseSplash    UninstallPhase = iota
	UninstallPhaseDetecting                // spinner: find install dir
	UninstallPhaseConfirm                  // show what will be removed
	UninstallPhaseRemoving                 // progress: deleting files
	UninstallPhaseShell                    // spinner: removing shell config (optional)
	UninstallPhaseDone
	UninstallPhaseError
	UninstallPhaseNotFound // nothing installed
)

// UninstallModel is the BubbleTea model for the uninstaller TUI.
type UninstallModel struct {
	phase       UninstallPhase
	spinner     spinner.Model
	progress    progress.Model
	width       int
	height      int
	installDir  string
	existing    *installer.ExistingInstall
	removeShell bool   // whether to also clean shell config
	shellCursor int    // 0 = Yes, 1 = No (for shell removal prompt)
	shellFile   string // path modified
	err         error
}

// uninstall messages
type uninstallDetectionDoneMsg struct {
	installDir string
	existing   *installer.ExistingInstall
}
type uninstallRemovedMsg struct{ err error }
type uninstallShellDoneMsg struct {
	file string
	err  error
}

// NewUninstallModel creates a new uninstaller model.
func NewUninstallModel() UninstallModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color(ColorPurple))

	return UninstallModel{
		phase:       UninstallPhaseSplash,
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
			m.phase = UninstallPhaseNotFound
		} else {
			m.phase = UninstallPhaseConfirm
		}
		return m, nil

	case uninstallRemovedMsg:
		if msg.err != nil {
			m.err = msg.err
			m.phase = UninstallPhaseError
			return m, nil
		}
		if m.removeShell {
			m.phase = UninstallPhaseShell
			return m, tea.Batch(m.spinner.Tick, doRemoveShell())
		}
		m.phase = UninstallPhaseDone
		return m, nil

	case uninstallShellDoneMsg:
		m.shellFile = msg.file
		if msg.err != nil {
			m.err = msg.err
			m.phase = UninstallPhaseError
			return m, nil
		}
		m.phase = UninstallPhaseDone
		return m, nil
	}

	return m, nil
}

func (m UninstallModel) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch m.phase {
	case UninstallPhaseSplash:
		if msg.Type == tea.KeyEnter {
			m.phase = UninstallPhaseDetecting
			return m, tea.Batch(m.spinner.Tick, doUninstallDetection())
		}
		if msg.Type == tea.KeyCtrlC {
			return m, tea.Quit
		}

	case UninstallPhaseDetecting:
		if msg.Type == tea.KeyCtrlC {
			return m, tea.Quit
		}

	case UninstallPhaseConfirm:
		switch msg.String() {
		case "up", "k", "left":
			m.shellCursor = 0
		case "down", "j", "right":
			m.shellCursor = 1
		case "enter":
			m.removeShell = m.shellCursor == 0
			m.phase = UninstallPhaseRemoving
			cmd := m.progress.SetPercent(0)
			return m, tea.Batch(cmd, doRemoveDir(m.installDir))
		case "q", "ctrl+c":
			return m, tea.Quit
		}

	case UninstallPhaseNotFound, UninstallPhaseDone, UninstallPhaseError:
		return m, tea.Quit
	}

	return m, nil
}

// Commands

func doUninstallDetection() tea.Cmd {
	return func() tea.Msg {
		dir := installer.GetInstallDir()
		existing, _ := installer.DetectExistingInstall(dir)
		return uninstallDetectionDoneMsg{installDir: dir, existing: existing}
	}
}

func doRemoveDir(installDir string) tea.Cmd {
	return func() tea.Msg {
		err := installer.RemoveInstallDir(installDir)
		return uninstallRemovedMsg{err: err}
	}
}

func doRemoveShell() tea.Cmd {
	return func() tea.Msg {
		file, err := installer.RemoveShellConfig()
		return uninstallShellDoneMsg{file: file, err: err}
	}
}

// Views

func (m UninstallModel) View() string {
	switch m.phase {
	case UninstallPhaseSplash:
		return m.ucenter(m.viewUSplash())
	case UninstallPhaseDetecting:
		return m.ucenter(m.viewUDetecting())
	case UninstallPhaseConfirm:
		return m.ucenter(m.viewUConfirm())
	case UninstallPhaseRemoving:
		return m.ucenter(m.viewURemoving())
	case UninstallPhaseShell:
		return m.ucenter(m.viewUShell())
	case UninstallPhaseDone:
		return m.ucenter(m.viewUDone())
	case UninstallPhaseError:
		return m.ucenter(m.viewUError())
	case UninstallPhaseNotFound:
		return m.ucenter(m.viewUNotFound())
	}
	return ""
}

func (m UninstallModel) viewUSplash() string {
	title := ErrorStyle.Render("🗑  DevScripts Uninstaller")
	sub := NormalStyle.Render("Elimina la instalación de DevScripts")
	hint := DimStyle.Render("Presiona Enter para continuar")
	return BoxStyle.Render(title + "\n" + sub + "\n\n" + hint)
}

func (m UninstallModel) viewUDetecting() string {
	return TitleStyle.Render("Buscando instalación...") + "\n\n" +
		m.spinner.View() + " Detectando directorio de instalación...\n"
}

func (m UninstallModel) viewUConfirm() string {
	var sb strings.Builder
	sb.WriteString(ErrorStyle.Render("⚠  Se eliminará:") + "\n")
	sb.WriteString(NormalStyle.Render("  Directorio: "+m.installDir) + "\n")
	sb.WriteString(TitleStyle.Render("  Se conserva: scripts/") + DimStyle.Render(" (se renombra a scripts-old-<random>)") + "\n")
	sb.WriteString(SuccessStyle.Render("  Tus scripts NO se perderán") + "\n")
	if m.existing != nil && m.existing.Version != "" {
		sb.WriteString(DimStyle.Render("  Versión:     "+m.existing.Version) + "\n")
	}
	sb.WriteString("\n")

	// Shell config option
	sb.WriteString(CyanStyle.Render("¿Eliminar también la configuración del shell?") + "\n")
	sb.WriteString(DimStyle.Render("  (aliases devlauncher, dl, devscript)") + "\n\n")

	optYes := "  [ ] Sí, eliminar configuración del shell"
	optNo := "  [ ] No, conservar configuración del shell"
	if m.shellCursor == 0 {
		optYes = SuccessStyle.Render("  [●] Sí, eliminar configuración del shell")
	} else {
		optNo = SuccessStyle.Render("  [●] No, conservar configuración del shell")
	}
	sb.WriteString(optYes + "\n")
	sb.WriteString(optNo + "\n\n")

	sb.WriteString(DimStyle.Render("↑↓: seleccionar   Enter: confirmar   q: cancelar"))
	return BoxStyle.Render(sb.String())
}

func (m UninstallModel) viewURemoving() string {
	return TitleStyle.Render("Eliminando instalación...") + "\n\n" +
		m.progress.View() + "\n\n" +
		DimStyle.Render(m.installDir) + "\n"
}

func (m UninstallModel) viewUShell() string {
	return TitleStyle.Render("Limpiando configuración del shell...") + "\n\n" +
		m.spinner.View() + " Eliminando bloque DevScripts...\n"
}

func (m UninstallModel) viewUDone() string {
	sourceCmd := "source ~/.bashrc"
	if runtime.GOOS == "windows" {
		sourceCmd = ". $PROFILE"
	} else if runtime.GOOS == "darwin" {
		sourceCmd = "source ~/.zshrc"
	}

	var sb strings.Builder
	sb.WriteString(SuccessStyle.Render("✓ Desinstalación completada") + "\n\n")
	sb.WriteString(NormalStyle.Render("Eliminado: contenido de "+m.installDir) + "\n")
	sb.WriteString(TitleStyle.Render("Conservado: scripts-old-<random> (si existía scripts/)") + "\n")
	if m.removeShell && m.shellFile != "" {
		sb.WriteString(NormalStyle.Render("Config:    "+m.shellFile) + "\n")
		sb.WriteString("\n" + CyanStyle.Render("Para aplicar los cambios:") + "\n")
		sb.WriteString(PurpleStyle.Render("  "+sourceCmd) + "\n")
	}
	sb.WriteString("\n" + DimStyle.Render("Presiona cualquier tecla para salir"))
	return BoxStyle.Render(sb.String())
}

func (m UninstallModel) viewUError() string {
	msg := "Error desconocido"
	if m.err != nil {
		msg = m.err.Error()
	}
	return ErrorStyle.Render("✗ Error durante la desinstalación") + "\n\n" +
		NormalStyle.Render(msg) + "\n\n" +
		DimStyle.Render(fmt.Sprintf("Directorio afectado: %s", m.installDir)) + "\n" +
		DimStyle.Render("Presiona cualquier tecla para salir")
}

func (m UninstallModel) viewUNotFound() string {
	return BoxStyle.Render(
		CyanStyle.Render("ℹ  No se encontró ninguna instalación") + "\n\n" +
			NormalStyle.Render("Directorio buscado: "+m.installDir) + "\n\n" +
			DimStyle.Render("Presiona cualquier tecla para salir"),
	)
}

func (m UninstallModel) ucenter(s string) string {
	if m.width == 0 {
		return s
	}
	return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, s)
}
