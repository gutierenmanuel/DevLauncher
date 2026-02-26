# Script: Inicializa un repositorio Go completo en Windows.

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name, [string]$InstallHint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Error "No se encontró '$Name'. $InstallHint"
        exit 1
    }
}

$defaultProject = if ($env:DL_PROJECT_NAME) { $env:DL_PROJECT_NAME } else { "go-project" }
$projectNameInput = Read-Host "Nombre del proyecto [$defaultProject]"
$projectName = if ([string]::IsNullOrWhiteSpace($projectNameInput)) { $defaultProject } else { $projectNameInput }

$defaultModule = if ($env:DL_GO_MODULE) { $env:DL_GO_MODULE } else { "github.com/$env:USERNAME/$projectName" }
$moduleInput = Read-Host "Módulo Go (go.mod) [$defaultModule]"
$moduleName = if ([string]::IsNullOrWhiteSpace($moduleInput)) { $defaultModule } else { $moduleInput }

Write-Host ""
Write-Host "🧱 Inicializador de Repo Go"
Write-Host "Proyecto: $projectName"
Write-Host "Módulo:   $moduleName"
Write-Host ""

Require-Command -Name "go" -InstallHint "Instálalo desde https://go.dev/dl/"

if (Test-Path $projectName) {
    $force = $env:DL_FORCE_OVERWRITE -eq "1"
    if (-not $force) {
        $ans = Read-Host "El directorio '$projectName' ya existe. ¿Eliminar y recrear? (s/N)"
        if ($ans -notmatch '^[sS]$') {
            Write-Host "Operación cancelada."
            exit 0
        }
    }
    Remove-Item -Path $projectName -Recurse -Force
}

$dirs = @(
    "cmd/app",
    "internal/config",
    "internal/service",
    "pkg/version",
    "scripts",
    "bin"
)

foreach ($d in $dirs) {
    New-Item -Path (Join-Path $projectName ($d -replace '/', '\\')) -ItemType Directory -Force | Out-Null
}

Push-Location $projectName

go mod init $moduleName | Out-Host

@'
package main

import (
    "fmt"

    "REPLACE_MODULE/internal/config"
    "REPLACE_MODULE/internal/service"
    "REPLACE_MODULE/pkg/version"
)

func main() {
    cfg := config.Load()
    msg := service.BuildStartupMessage(cfg.AppName, version.Current())
    fmt.Println(msg)
}
'@ -replace 'REPLACE_MODULE', $moduleName | Out-File -FilePath "cmd/app/main.go" -Encoding UTF8

@'
package config

import "os"

type AppConfig struct {
    AppName string
}

func Load() AppConfig {
    appName := os.Getenv("APP_NAME")
    if appName == "" {
        appName = "Go Project"
    }

    return AppConfig{AppName: appName}
}
'@ | Out-File -FilePath "internal/config/config.go" -Encoding UTF8

@'
package service

import "fmt"

func BuildStartupMessage(appName, appVersion string) string {
    return fmt.Sprintf("🚀 %s iniciado correctamente (version %s)", appName, appVersion)
}
'@ | Out-File -FilePath "internal/service/message.go" -Encoding UTF8

@'
package service

import "testing"

func TestBuildStartupMessage(t *testing.T) {
    result := BuildStartupMessage("DevLauncher", "0.1.0")
    want := "🚀 DevLauncher iniciado correctamente (version 0.1.0)"

    if result != want {
        t.Fatalf("resultado inesperado: want=%s got=%s", want, result)
    }
}
'@ | Out-File -FilePath "internal/service/message_test.go" -Encoding UTF8

@'
package version

var value = "0.1.0"

func Current() string {
    return value
}
'@ | Out-File -FilePath "pkg/version/version.go" -Encoding UTF8

@'
# Binarios
bin/
*.exe
*.dll
*.so
*.dylib

# Test / cobertura
*.test
*.out
coverage.out

# IDE / editor
.idea/
.vscode/

# OS
.DS_Store
Thumbs.db
'@ | Out-File -FilePath ".gitignore" -Encoding UTF8

@"
# $projectName

Repositorio Go inicializado automáticamente con estructura completa.

## Uso rápido

```powershell
.\scripts\run.ps1
.\scripts\test.ps1
.\scripts\build.ps1
.\scripts\build-all.ps1
```
"@ | Out-File -FilePath "README.md" -Encoding UTF8

@'
$ErrorActionPreference = "Stop"
go run ./cmd/app
'@ | Out-File -FilePath "scripts/run.ps1" -Encoding UTF8

@'
$ErrorActionPreference = "Stop"
go test ./...
'@ | Out-File -FilePath "scripts/test.ps1" -Encoding UTF8

@'
$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Path "bin" -Force | Out-Null
go build -o ./bin/app.exe ./cmd/app
Write-Host "✅ Binario generado: ./bin/app.exe"
'@ | Out-File -FilePath "scripts/build.ps1" -Encoding UTF8

@'
$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Path "bin" -Force | Out-Null

go build -o ./bin/app-windows-amd64.exe ./cmd/app

$env:GOOS = "linux"
$env:GOARCH = "amd64"
go build -o ./bin/app-linux-amd64 ./cmd/app
Remove-Item Env:GOOS -ErrorAction SilentlyContinue
Remove-Item Env:GOARCH -ErrorAction SilentlyContinue

$env:GOOS = "darwin"
$env:GOARCH = "amd64"
go build -o ./bin/app-darwin-amd64 ./cmd/app
Remove-Item Env:GOOS -ErrorAction SilentlyContinue
Remove-Item Env:GOARCH -ErrorAction SilentlyContinue

Write-Host "✅ Builds generados en ./bin"
'@ | Out-File -FilePath "scripts/build-all.ps1" -Encoding UTF8

go mod tidy | Out-Host

if (Get-Command git -ErrorAction SilentlyContinue) {
    git init | Out-Null
    git add . | Out-Null
}

Pop-Location

Write-Host ""
Write-Host "✅ Repo Go creado: $projectName"
Write-Host "Próximos pasos:"
Write-Host "  cd $projectName"
Write-Host "  .\scripts\run.ps1"
