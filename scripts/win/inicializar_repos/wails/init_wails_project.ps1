# Script: Inicializa un proyecto Wails en Windows (frontend + backend + wails-app).

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name, [string]$InstallHint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Error "No se encontró '$Name'. $InstallHint"
        exit 1
    }
}

$projectName = if ($env:DL_PROJECT_NAME) { $env:DL_PROJECT_NAME } else { "wails-project" }

Write-Host ""
Write-Host "🚀 Inicializador Wails"
Write-Host "Proyecto: $projectName"
Write-Host "Estructura: frontend + backend + wails-app"
Write-Host ""

Require-Command -Name "go" -InstallHint "Instálalo desde https://go.dev/dl/"
Require-Command -Name "wails" -InstallHint "Instálalo con: go install github.com/wailsapp/wails/v2/cmd/wails@latest"
Require-Command -Name "pnpm" -InstallHint "Instálalo desde https://pnpm.io/"

if (Test-Path $projectName) {
    $ans = Read-Host "El directorio '$projectName' ya existe. ¿Eliminar y recrear? (s/N)"
    if ($ans -notmatch '^[sS]$') {
        Write-Host "Operación cancelada."
        exit 0
    }
    Remove-Item -Path $projectName -Recurse -Force
}

New-Item -Path $projectName -ItemType Directory | Out-Null
Push-Location $projectName

# 1) Frontend
$frontendInitScript = Join-Path $PSScriptRoot "..\frontend\init_frontend_project.ps1"
if (-not (Test-Path $frontendInitScript)) {
    Write-Error "No se encontró init_frontend_project.ps1 para crear el frontend."
    exit 1
}

& $frontendInitScript

# 2) Backend
New-Item -Path "backend" -ItemType Directory | Out-Null
Push-Location "backend"
go mod init "github.com/$env:USERNAME/backend" | Out-Host

@'
package backend

import (
    "context"
    "fmt"
)

type App struct {
    ctx context.Context
}

func NewApp() *App {
    return &App{}
}

func (a *App) Startup(ctx context.Context) {
    a.ctx = ctx
}

func (a *App) Greet(name string) string {
    return fmt.Sprintf("¡Hola %s! 🚀", name)
}

func (a *App) GetMessage() string {
    return "¡Backend de Wails funcionando correctamente!"
}
'@ | Out-File -FilePath "app.go" -Encoding UTF8
Pop-Location

# 3) Wails app
New-Item -Path "wails-app" -ItemType Directory | Out-Null
Push-Location "wails-app"
go mod init "github.com/$env:USERNAME/wails-app" | Out-Host

@'
package main

import (
    "embed"
    "log"

    "github.com/wailsapp/wails/v2"
    "github.com/wailsapp/wails/v2/pkg/options"
    "github.com/wailsapp/wails/v2/pkg/options/assetserver"
)

//go:embed all:frontend/dist
var assets embed.FS

func main() {
    app := NewApp()

    err := wails.Run(&options.App{
        Title:  "Wails App",
        Width:  1024,
        Height: 768,
        AssetServer: &assetserver.Options{
            Assets: assets,
        },
        OnStartup: app.startup,
        Bind: []interface{}{
            app,
        },
    })

    if err != nil {
        log.Fatal(err)
    }
}
'@ | Out-File -FilePath "main.go" -Encoding UTF8

@'
package main

import "context"

type App struct {
    ctx context.Context
}

func NewApp() *App {
    return &App{}
}

func (a *App) startup(ctx context.Context) {
    a.ctx = ctx
}

func (a *App) Greet(name string) string {
    return "¡Hola " + name + " desde Wails! 🚀"
}
'@ | Out-File -FilePath "app.go" -Encoding UTF8

@'
{
  "$schema": "https://wails.io/schemas/config.v2.json",
  "name": "wails-app",
  "outputfilename": "wails-app",
  "frontend:install": "pnpm install",
  "frontend:build": "pnpm build",
  "frontend:dev:watcher": "pnpm dev",
  "frontend:dev:serverUrl": "auto"
}
'@ | Out-File -FilePath "wails.json" -Encoding UTF8
Pop-Location

@'
$ErrorActionPreference = "Stop"

Write-Host "▶ Frontend"
Set-Location (Join-Path $PSScriptRoot "frontend")
pnpm dev
'@ | Out-File -FilePath "dev-frontend.ps1" -Encoding UTF8

@'
$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "wails-app")
wails dev
'@ | Out-File -FilePath "dev-wails.ps1" -Encoding UTF8

@'
$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "wails-app")
wails build
'@ | Out-File -FilePath "build.ps1" -Encoding UTF8

@"
# $projectName

Proyecto Wails inicializado con:

- `frontend/` (React + Vite)
- `backend/` (módulo Go)
- `wails-app/` (app de escritorio)

## Uso rápido

```powershell
.\dev-frontend.ps1
.\dev-wails.ps1
.\build.ps1
```
"@ | Out-File -FilePath "README.md" -Encoding UTF8

Pop-Location

Write-Host ""
Write-Host "✅ Proyecto Wails creado: $projectName"
