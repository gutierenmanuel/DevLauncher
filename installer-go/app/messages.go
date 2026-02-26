package app

import (
	"embed"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/lucas/installer/core"
	"github.com/lucas/installer/middleware"
)

// ── Installer messages ──────────────────────────────────────────────────────

type detectionDoneMsg struct {
	installDir  string
	existing    *core.ExistingInstall
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

// ── Uninstaller messages ────────────────────────────────────────────────────

type uninstallDetectionDoneMsg struct {
	installDir string
	existing   *core.ExistingInstall
}

type uninstallRemovedMsg struct{ err error }

type uninstallShellDoneMsg struct {
	file string
	err  error
}

// ── Installer command factories ─────────────────────────────────────────────

func doDetection(assets embed.FS) tea.Cmd {
	return func() tea.Msg {
		installDir := middleware.GetInstallDir()
		existing, _ := middleware.DetectExistingInstall(installDir)

		embeddedVer := ""
		if data, err := assets.ReadFile("assets/VERSION.txt"); err == nil {
			embeddedVer = core.ParseVersion(string(data))
		}

		totalFiles := core.CountAssets(assets)
		return detectionDoneMsg{
			installDir:  installDir,
			existing:    existing,
			embeddedVer: embeddedVer,
			totalFiles:  totalFiles,
		}
	}
}

func doShellConfig(installDir string) tea.Cmd {
	return func() tea.Msg {
		profile, err := middleware.ConfigureShell(installDir)
		return shellDoneMsg{profile: profile, err: err}
	}
}

func doDesktopShortcut(installDir string) tea.Cmd {
	return func() tea.Msg {
		path, err := middleware.CreateDesktopShortcut(installDir)
		return shortcutDoneMsg{path: path, err: err}
	}
}

// ── Uninstaller command factories ───────────────────────────────────────────

func doUninstallDetection() tea.Cmd {
	return func() tea.Msg {
		dir := middleware.GetInstallDir()
		existing, _ := middleware.DetectExistingInstall(dir)
		return uninstallDetectionDoneMsg{installDir: dir, existing: existing}
	}
}

func doRemoveDir(installDir string) tea.Cmd {
	return func() tea.Msg {
		err := middleware.RemoveInstallDir(installDir)
		return uninstallRemovedMsg{err: err}
	}
}

func doRemoveShell() tea.Cmd {
	return func() tea.Msg {
		file, err := middleware.RemoveShellConfig()
		return uninstallShellDoneMsg{file: file, err: err}
	}
}
