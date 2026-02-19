package models

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
)

// getScriptCommand returns the command to execute a script
func getScriptCommand(script Script) *exec.Cmd {
	var cmd *exec.Cmd

	switch script.Extension {
	case ".sh":
		cmd = exec.Command("bash", script.Path)
	case ".ps1":
		// Try pwsh first, fallback to powershell
		if _, err := exec.LookPath("pwsh"); err == nil {
			cmd = exec.Command("pwsh", "-ExecutionPolicy", "Bypass", "-File", script.Path)
		} else {
			cmd = exec.Command("powershell", "-ExecutionPolicy", "Bypass", "-File", script.Path)
		}
	case ".bat":
		if runtime.GOOS == "windows" {
			cmd = exec.Command("cmd.exe", "/c", script.Path)
		} else {
			cmd = exec.Command("cmd.exe", "/c", script.Path) // WSL scenario
		}
	default:
		// Return a command that will fail with a clear error
		cmd = exec.Command("echo", fmt.Sprintf("unsupported script extension: %s", script.Extension))
	}

	return cmd
}

// ExecuteScript executes a script and returns the exit code and error output
func ExecuteScript(script Script) (int, string) {
	var cmd *exec.Cmd

	switch script.Extension {
	case ".sh":
		cmd = exec.Command("bash", script.Path)
	case ".ps1":
		// Try pwsh first, fallback to powershell
		if _, err := exec.LookPath("pwsh"); err == nil {
			cmd = exec.Command("pwsh", "-ExecutionPolicy", "Bypass", "-File", script.Path)
		} else {
			cmd = exec.Command("powershell", "-ExecutionPolicy", "Bypass", "-File", script.Path)
		}
	case ".bat":
		if runtime.GOOS == "windows" {
			cmd = exec.Command("cmd.exe", "/c", script.Path)
		} else {
			cmd = exec.Command("cmd.exe", "/c", script.Path) // WSL scenario
		}
	default:
		return 1, fmt.Sprintf("unsupported script extension: %s", script.Extension)
	}

	// Set stdout to terminal, capture stderr
	cmd.Stdout = os.Stdout
	cmd.Stdin = os.Stdin
	
	// Capture stderr
	stderrPipe, err := cmd.StderrPipe()
	if err != nil {
		return 1, fmt.Sprintf("failed to create stderr pipe: %v", err)
	}

	// Execute
	if err := cmd.Start(); err != nil {
		return 1, fmt.Sprintf("failed to start script: %v", err)
	}
	
	// Read stderr
	stderrBytes := make([]byte, 0)
	buf := make([]byte, 1024)
	for {
		n, err := stderrPipe.Read(buf)
		if n > 0 {
			stderrBytes = append(stderrBytes, buf[:n]...)
			// Also write to terminal in real-time
			os.Stderr.Write(buf[:n])
		}
		if err != nil {
			break
		}
	}
	
	// Wait for completion
	err = cmd.Wait()
	
	exitCode := 0
	errorOutput := string(stderrBytes)
	
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		} else {
			exitCode = 1
			if errorOutput == "" {
				errorOutput = err.Error()
			}
		}
	}

	return exitCode, errorOutput
}
