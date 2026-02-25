// installer-go/main.go
//
// Entry point del installer de DevLauncher.
//
// ── Flujo general ────────────────────────────────────────────────────────────
//
//  1. embed.go declara assetsFS (embed.FS) con todo el contenido de assets/:
//       scripts/, static/, VERSION.txt, launcher-linux / launcher.exe, etc.
//
//  2. main() construye el modelo TUI del installer (app.NewModel) y lanza
//     BubbleTea en pantalla completa (alt-screen).
//
//  3. BubbleTea ejecuta el loop de eventos. Las fases del installer son:
//
//       PhaseSplash         → pantalla de bienvenida, espera Enter
//       PhaseDetecting      → goroutine: detecta instalación existente + cuenta archivos
//       PhaseConfirm        → muestra plan (nueva / actualización), espera y/n
//       PhaseInstalling     → goroutine: ExtractAssets() volcando assets/ al disco
//                             + GenerateUninstaller() escribe el script de desinstalación
//       PhaseShellConfig    → goroutine: escribe bloque en ~/.bashrc / ~/.zshrc / $PROFILE
//       PhaseDesktopShortcut→ goroutine: crea .desktop (Linux) o .lnk (Windows)
//       PhaseDone           → resumen de instalación, espera Enter
//       PhaseError          → muestra el error, sale al pulsar cualquier tecla
//
//  4. Cuando BubbleTea termina, main() recupera el modelo final y consulta:
//       - ShouldLaunch() → true si la instalación fue exitosa y el binario existe
//       - LaunchPath()   → ruta absoluta al launcher instalado
//
//  5. Si ShouldLaunch es true, main() reemplaza el proceso actual por el launcher
//     (exec semántico via cmd.Run con Stdin/Stdout/Stderr heredados), de modo que
//     el usuario entra directamente a DevLauncher tras instalar.
//
// ── Separación de responsabilidades ─────────────────────────────────────────
//
//   main.go       → wiring: embed FS + BubbleTea + exec post-install
//   app/          → orquestación TUI (Model, Update, View, mensajes tea.Cmd)
//   middleware/   → I/O real: filesystem, shell config, shortcuts, detección
//   core/         → lógica pura: semver, asset mapping, paths, tipos
//
// ────────────────────────────────────────────────────────────────────────────

package main

import (
	"fmt"
	"os"
	"os/exec"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/lucas/installer/app"
)

func main() {
	// Construye el modelo del installer pasándole el embed.FS con todos los
	// assets embebidos en tiempo de compilación (declarado en embed.go).
	m := app.NewModel(assetsFS)

	// Inicia BubbleTea en modo pantalla completa (alt-screen) para que el TUI
	// ocupe toda la terminal sin mezclar su output con texto previo.
	p := tea.NewProgram(&m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}

	// ── Post-install: lanzar DevLauncher automáticamente ─────────────────────
	//
	// BubbleTea puede devolver el modelo como valor o puntero dependiendo de
	// cómo se hayan aplicado las actualizaciones internas; probamos ambas formas.
	shouldLaunch := false
	launchPath := ""

	if fm, ok := finalModel.(*app.Model); ok {
		// Modelo devuelto como puntero (caso habitual con &m en NewProgram)
		shouldLaunch = fm.ShouldLaunch()
		launchPath = fm.LaunchPath()
	} else if fm, ok := finalModel.(app.Model); ok {
		// Modelo devuelto como valor (fallback defensivo)
		shouldLaunch = fm.ShouldLaunch()
		launchPath = fm.LaunchPath()
	}

	if shouldLaunch {
		// Ejecuta el launcher instalado heredando stdin/stdout/stderr del proceso
		// actual, de modo que el usuario no percibe ningún salto entre el instalador
		// y la sesión de DevLauncher.
		cmd := exec.Command(launchPath)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Fprintln(os.Stderr, "No se pudo iniciar DevLauncher:", err)
			os.Exit(1)
		}
	}
}
