package tui

import (
	"embed"
	"fmt"
	"os"
	"runtime"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/progress"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/lucas/installer/installer"
)

// Phase represents the current installer phase.
type Phase int

const (
	PhaseSplash     Phase = iota // Welcome screen, press Enter
	PhaseDetecting               // Spinner while detecting
	PhaseConfirm                 // Show plan, press y/n
	PhaseInstalling              // Progress bar extracting files
	PhaseShellConfig             // Spinner configuring shell
	PhaseDesktopShortcut         // Optional: create desktop shortcut
	PhaseDone                    // Success
	PhaseError                   // Error
)

// Model is the BubbleTea model for the installer TUI.
type Model struct {
	phase    Phase
	spinner  spinner.Model
	progress progress.Model
	width    int
	height   int

	// detection
	installDir  string
	existing    *installer.ExistingInstall
	embeddedVer string

	// install state
	totalFiles   int
	doneFiles    int
	currentFile  string
	shellProfile string
	shortcutPath string
	err          error

	createShortcut  bool
	launchAfterDone bool
	launchPath      string

	// embed fs (passed from main)
	assets embed.FS

	// extraction state
	extractQueue []extractTask
}

type extractTask struct {
	path string
	data []byte
	perm uint32
}

// Messages
type detectionDoneMsg struct {
	installDir  string
	existing    *installer.ExistingInstall
	embeddedVer string
	totalFiles  int
}

type fileExtractedMsg struct {
	current  int
	total    int
	filename string
}

type extractDoneMsg struct{ err error }

type shellDoneMsg struct {
	profile string
	err     error
}

type shortcutDoneMsg struct {
	path string
	err  error
}

type autoQuitMsg struct{}

// NewModel creates a new installer Model.
func NewModel(assets embed.FS) Model {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color(ColorPurple))

	p := progress.New(progress.WithDefaultGradient())

	return Model{
		phase:          PhaseSplash,
		spinner:        s,
		progress:       p,
		assets:         assets,
		createShortcut: true,
	}
}

func (m Model) Init() tea.Cmd {
	return nil
}

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
		m.phase = PhaseConfirm
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
		return m, tea.Batch(cmd, m.extractNextFile())

	case extractDoneMsg:
		if msg.err != nil {
			m.err = msg.err
			m.phase = PhaseError
			return m, nil
		}
		m.phase = PhaseShellConfig
		return m, tea.Batch(m.spinner.Tick, doShellConfig(m.installDir))

	case shellDoneMsg:
		if msg.err != nil {
			m.err = msg.err
			m.phase = PhaseError
			return m, nil
		}
		m.shellProfile = msg.profile
		if m.createShortcut {
			m.phase = PhaseDesktopShortcut
			return m, tea.Batch(m.spinner.Tick, doDesktopShortcut(m.installDir))
		}
		m.prepareLaunch()
		m.phase = PhaseDone
		return m, tea.Tick(700*time.Millisecond, func(time.Time) tea.Msg { return autoQuitMsg{} })

	case shortcutDoneMsg:
		if msg.err != nil {
			m.err = msg.err
			m.phase = PhaseError
			return m, nil
		}
		m.shortcutPath = msg.path
		m.prepareLaunch()
		m.phase = PhaseDone
		return m, tea.Tick(700*time.Millisecond, func(time.Time) tea.Msg { return autoQuitMsg{} })

	case autoQuitMsg:
		if m.phase == PhaseDone {
			return m, tea.Quit
		}
		return m, nil
	}

	return m, nil
}

func (m Model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch m.phase {
	case PhaseSplash:
		if msg.Type == tea.KeyEnter {
			m.phase = PhaseDetecting
			return m, tea.Batch(m.spinner.Tick, doDetection(m.assets))
		}
		if msg.Type == tea.KeyCtrlC {
			return m, tea.Quit
		}

	case PhaseDetecting:
		if msg.Type == tea.KeyCtrlC {
			return m, tea.Quit
		}

	case PhaseConfirm:
		switch msg.String() {
		case "d", "D":
			m.createShortcut = !m.createShortcut
			return m, nil
		case "y", "Y", "enter":
			m.phase = PhaseInstalling
			m.doneFiles = 0
			return m, tea.Batch(m.spinner.Tick, m.startExtraction())
		case "q", "n", "ctrl+c":
			return m, tea.Quit
		}

	case PhaseDone, PhaseError:
		return m, tea.Quit
	}

	return m, nil
}

// doDetection runs detection in background and returns detectionDoneMsg.
func doDetection(assets embed.FS) tea.Cmd {
	return func() tea.Msg {
		installDir := installer.GetInstallDir()
		existing, _ := installer.DetectExistingInstall(installDir)

		// Read embedded VERSION.txt
		embeddedVer := ""
		if data, err := assets.ReadFile("assets/VERSION.txt"); err == nil {
			embeddedVer = installer.ParseVersion(string(data))
		}

		totalFiles := installer.CountAssets(assets)

		return detectionDoneMsg{
			installDir:  installDir,
			existing:    existing,
			embeddedVer: embeddedVer,
			totalFiles:  totalFiles,
		}
	}
}

// extractState holds mutable extraction state shared by chained commands.
type extractState struct {
	files   []assetFile
	index   int
	destDir string
	total   int
}

type assetFile struct {
	embPath  string
	destPath string
	data     []byte
	perm     uint32
}

func (m *Model) startExtraction() tea.Cmd {
	// Collect all files first, then extract one by one
	return func() tea.Msg {
		// We'll use ExtractAssets but adapt it to send progress messages.
		// Instead, manually enumerate files.
		return m.doFullExtraction()
	}
}

func (m *Model) doFullExtraction() tea.Msg {
	// Extract all files and send first fileExtractedMsg
	err := installer.ExtractAssets(m.assets, m.installDir, nil)
	if err != nil {
		return extractDoneMsg{err}
	}
	total := m.totalFiles
	if total == 0 {
		total = installer.CountAssets(m.assets)
	}
	return fileExtractedMsg{current: total, total: total, filename: "done"}
}

func (m Model) extractNextFile() tea.Cmd {
	// This is a no-op because we do full extraction in one shot above.
	return nil
}

// doShellConfig configures the shell profile.
func doShellConfig(installDir string) tea.Cmd {
	return func() tea.Msg {
		profile, err := installer.ConfigureShell(installDir)
		return shellDoneMsg{profile: profile, err: err}
	}
}

func doDesktopShortcut(installDir string) tea.Cmd {
	return func() tea.Msg {
		path, err := installer.CreateDesktopShortcut(installDir)
		return shortcutDoneMsg{path: path, err: err}
	}
}

func (m *Model) prepareLaunch() {
	launcherPath := installer.GetLauncherPath(m.installDir)
	if _, err := os.Stat(launcherPath); err == nil {
		m.launchAfterDone = true
		m.launchPath = launcherPath
	}
}

func (m Model) View() string {
	switch m.phase {
	case PhaseSplash:
		return m.viewSplash()
	case PhaseDetecting:
		return m.viewDetecting()
	case PhaseConfirm:
		return m.viewConfirm()
	case PhaseInstalling:
		return m.viewInstalling()
	case PhaseShellConfig:
		return m.viewShellConfig()
	case PhaseDesktopShortcut:
		return m.viewDesktopShortcut()
	case PhaseDone:
		return m.viewDone()
	case PhaseError:
		return m.viewError()
	}
	return ""
}

func (m Model) viewSplash() string {
	title := TitleStyle.Render("🚀 DevScripts Installer")
	ver := ""
	if m.embeddedVer != "" {
		ver = " " + DimStyle.Render(m.embeddedVer)
	}
	sub := NormalStyle.Render("Sistema de scripts para desarrollo")
	hint := DimStyle.Render("Presiona Enter para comenzar")

	inner := title + ver + "\n" + sub + "\n\n" + hint
	return m.center(BoxStyle.Render(inner))
}

func (m Model) viewDetecting() string {
	var sb strings.Builder
	sb.WriteString(TitleStyle.Render("Detectando sistema...") + "\n\n")
	sb.WriteString(m.spinner.View() + " Buscando instalación existente...\n")
	return m.center(sb.String())
}

func (m Model) viewConfirm() string {
	var sb strings.Builder

	if m.existing == nil {
		sb.WriteString(SuccessStyle.Render("✨ Nueva instalación") + "\n")
		sb.WriteString(NormalStyle.Render("Directorio: "+m.installDir) + "\n")
		if m.embeddedVer != "" {
			sb.WriteString(CyanStyle.Render("Versión:    "+m.embeddedVer) + "\n")
		}
	} else {
		cmp := installer.CompareVersions(m.embeddedVer, m.existing.Version)
		if cmp == 0 {
			sb.WriteString(SuccessStyle.Render("✓ Ya tienes la última versión") + "\n")
			sb.WriteString(NormalStyle.Render("Directorio: "+m.installDir) + "\n")
			sb.WriteString(DimStyle.Render("Versión instalada: "+m.existing.Version) + "\n")
		} else if cmp > 0 {
			sb.WriteString(CyanStyle.Render(fmt.Sprintf("↑ Actualización disponible: %s → %s", m.existing.Version, m.embeddedVer)) + "\n")
			sb.WriteString(NormalStyle.Render("Directorio: "+m.installDir) + "\n")
		} else {
			sb.WriteString(TitleStyle.Render(fmt.Sprintf("⚠ Versión incrustada %s < instalada %s", m.embeddedVer, m.existing.Version)) + "\n")
			sb.WriteString(NormalStyle.Render("Directorio: "+m.installDir) + "\n")
		}
	}

	sb.WriteString("\n")
	sb.WriteString(NormalStyle.Render(fmt.Sprintf("Archivos a instalar: %d", m.totalFiles)) + "\n\n")
	if m.createShortcut {
		sb.WriteString(CyanStyle.Render("Acceso directo escritorio: activado") + DimStyle.Render("  (pulsa d para desactivar)") + "\n\n")
	} else {
		sb.WriteString(DimStyle.Render("Acceso directo escritorio: desactivado  (pulsa d para activar)") + "\n\n")
	}
	sb.WriteString(SuccessStyle.Render("[y] Instalar") + "  " + ErrorStyle.Render("[q] Cancelar"))

	return m.center(BoxStyle.Render(sb.String()))
}

func (m Model) viewInstalling() string {
	var sb strings.Builder
	sb.WriteString(TitleStyle.Render("Instalando archivos...") + "\n\n")
	sb.WriteString(m.progress.View() + "\n\n")
	sb.WriteString(NormalStyle.Render(fmt.Sprintf("%d/%d archivos", m.doneFiles, m.totalFiles)) + "\n")
	if m.currentFile != "" {
		sb.WriteString(DimStyle.Render("→ "+m.currentFile) + "\n")
	}
	return m.center(sb.String())
}

func (m Model) viewShellConfig() string {
	var sb strings.Builder
	sb.WriteString(TitleStyle.Render("Configurando perfil de shell...") + "\n\n")
	sb.WriteString(m.spinner.View() + " Escribiendo configuración...\n")
	return m.center(sb.String())
}

func (m Model) viewDesktopShortcut() string {
	var sb strings.Builder
	sb.WriteString(TitleStyle.Render("Creando acceso directo en escritorio...") + "\n\n")
	sb.WriteString(m.spinner.View() + " Generando acceso directo...\n")
	return m.center(sb.String())
}

func (m Model) viewDone() string {
	sourceCmd := "source ~/.bashrc"
	if runtime.GOOS == "windows" {
		sourceCmd = ". $PROFILE"
	} else if runtime.GOOS == "darwin" {
		sourceCmd = "source ~/.zshrc"
	}

	var sb strings.Builder
	sb.WriteString(SuccessStyle.Render("✨ ¡Instalación completada!") + "\n\n")
	sb.WriteString(NormalStyle.Render("Directorio: "+m.installDir) + "\n")
	if m.shellProfile != "" {
		sb.WriteString(NormalStyle.Render("Perfil:     "+m.shellProfile) + "\n")
	}
	if m.shortcutPath != "" {
		sb.WriteString(NormalStyle.Render("Acceso directo: "+m.shortcutPath) + "\n")
	}
	sb.WriteString("\n")
	sb.WriteString(CyanStyle.Render("Para activar, ejecuta:") + "\n")
	sb.WriteString(PurpleStyle.Render("  "+sourceCmd) + "\n\n")
	sb.WriteString(CyanStyle.Render("Comandos disponibles:") + "\n")
	sb.WriteString(NormalStyle.Render("  devlauncher / dl  →  Lanzador interactivo") + "\n")
	sb.WriteString(NormalStyle.Render("  devscript <nom>   →  Ejecutar script directo") + "\n\n")
	if m.launchAfterDone {
		sb.WriteString(CyanStyle.Render("Iniciando DevLauncher...") + "\n")
		sb.WriteString(DimStyle.Render("Se abrirá en esta misma terminal."))
	} else {
		sb.WriteString(DimStyle.Render("Presiona cualquier tecla para salir"))
	}

	return m.center(BoxStyle.Render(sb.String()))
}

func (m Model) viewError() string {
	msg := "Error desconocido"
	if m.err != nil {
		msg = m.err.Error()
	}
	inner := ErrorStyle.Render("✗ Error durante la instalación") + "\n\n" +
		NormalStyle.Render(msg) + "\n\n" +
		DimStyle.Render("Presiona cualquier tecla para salir")
	return m.center(BoxStyle.Render(inner))
}

func (m Model) center(s string) string {
	if m.width == 0 {
		return s
	}
	return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, s)
}

// ShouldLaunch indicates whether main should launch DevLauncher after installer exits.
func (m Model) ShouldLaunch() bool {
	return m.launchAfterDone
}

// LaunchPath returns the launcher binary path to execute after successful install.
func (m Model) LaunchPath() string {
	return m.launchPath
}
