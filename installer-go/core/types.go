package core

// ExistingInstall represents a previously installed DevLauncher installation.
type ExistingInstall struct {
Dir     string
Version string
}

// Phase represents the current installer phase.
type Phase int

const (
PhaseSplash          Phase = iota // Welcome screen, press Enter
PhaseDetecting                    // Spinner while detecting
PhaseConfirm                      // Show plan, press y/n
PhaseInstalling                   // Progress bar extracting files
PhaseShellConfig                  // Spinner configuring shell
PhaseDesktopShortcut              // Optional: create desktop shortcut
PhaseDone                         // Success
PhaseError                        // Error
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
