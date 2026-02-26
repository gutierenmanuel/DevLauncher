# Script: Inicializa un módulo Go simple en Windows.

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name, [string]$InstallHint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Error "No se encontró '$Name'. $InstallHint"
        exit 1
    }
}

$projectName = if ($env:DL_PROJECT_NAME) { $env:DL_PROJECT_NAME } else { "module" }
$defaultModule = "github.com/$env:USERNAME/$projectName"
$moduleName = if ($env:DL_GO_MODULE) { $env:DL_GO_MODULE } else { $defaultModule }

Write-Host ""
Write-Host "🧱 Inicializador de Módulo Go"
Write-Host "Proyecto: $projectName"
Write-Host "Módulo:   $moduleName"
Write-Host "Ruta:     $(Join-Path (Get-Location) $projectName)"
Write-Host ""

Require-Command -Name "go" -InstallHint "Instálalo desde https://go.dev/dl/"

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

go mod init $moduleName | Out-Host

@'
package main

import "fmt"

func main() {
    fmt.Println("🚀 ¡Hola desde Go!")
    fmt.Println("Módulo inicializado correctamente")
}
'@ | Out-File -FilePath "main.go" -Encoding UTF8

@'
# Binarios
bin/
build/
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

Módulo Go simple inicializado automáticamente.

## Ejecutar

```powershell
go run .
```

## Compilar

```powershell
go build -o bin\app.exe .
```
"@ | Out-File -FilePath "README.md" -Encoding UTF8

@'
param([string]$Target = "windows")
$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Path "bin" -Force | Out-Null

switch ($Target.ToLowerInvariant()) {
    "windows" {
        go build -o "bin/app-windows.exe" . | Out-Host
    }
    "linux" {
        $env:GOOS = "linux"
        $env:GOARCH = "amd64"
        go build -o "bin/app-linux" . | Out-Host
        Remove-Item Env:GOOS -ErrorAction SilentlyContinue
        Remove-Item Env:GOARCH -ErrorAction SilentlyContinue
    }
    "all" {
        & $PSCommandPath windows
        & $PSCommandPath linux
    }
    default {
        Write-Error "Target inválido: $Target (windows|linux|all)"
        exit 1
    }
}

Write-Host "✅ Build completado"
'@ | Out-File -FilePath "build.ps1" -Encoding UTF8

@'
param([Parameter(ValueFromRemainingArguments = $true)] [string[]]$ArgsRest)
$ErrorActionPreference = "Stop"

go run . @ArgsRest
'@ | Out-File -FilePath "run.ps1" -Encoding UTF8

Pop-Location

Write-Host ""
Write-Host "✅ Módulo Go creado en '$projectName'"
Write-Host "Siguiente paso:"
Write-Host "  cd $projectName"
Write-Host "  .\run.ps1"
