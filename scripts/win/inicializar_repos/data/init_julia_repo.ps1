# Script: Inicializa un repositorio Julia en Windows con Pluto, Makie y DuckDB.

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name, [string]$InstallHint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Error "No se encontró '$Name'. $InstallHint"
        exit 1
    }
}

$projectName = if ($env:DL_PROJECT_NAME) { $env:DL_PROJECT_NAME } else { "julia-project" }

Write-Host ""
Write-Host "🔮 Inicializador Julia"
Write-Host "Proyecto: $projectName"
Write-Host ""

Require-Command -Name "julia" -InstallHint "Instálalo desde https://julialang.org/downloads/"

if (Test-Path $projectName) {
    $ans = Read-Host "El directorio '$projectName' ya existe. ¿Eliminar y recrear? (s/N)"
    if ($ans -notmatch '^[sS]$') {
        Write-Host "Operación cancelada."
        exit 0
    }
    Remove-Item -Path $projectName -Recurse -Force
}

$dirs = @("src", "notebooks", "data", "docs", "scripts")
foreach ($d in $dirs) {
    New-Item -Path (Join-Path $projectName $d) -ItemType Directory -Force | Out-Null
}

Push-Location $projectName

julia -e 'using Pkg; Pkg.activate("."); Pkg.add(["Pluto", "PlutoUI", "GLMakie", "CairoMakie", "DuckDB", "DataFrames"])' | Out-Host

@'
println("🔮 ¡Hola desde Julia!")
println("Proyecto inicializado correctamente")
'@ | Out-File -FilePath "src\main.jl" -Encoding UTF8

@'
using GLMakie

fig = Figure(size = (800, 600))
ax = Axis(fig[1, 1], title = "Ejemplo Makie", xlabel = "x", ylabel = "f(x)")
x = range(0, 4π, length = 200)
lines!(ax, x, sin.(x), color = :dodgerblue, linewidth = 2, label = "sin(x)")
lines!(ax, x, cos.(x), color = :tomato, linewidth = 2, label = "cos(x)")
axislegend(ax)
display(fig)
'@ | Out-File -FilePath "src\makie_example.jl" -Encoding UTF8

@'
### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils
using PlutoUI

md"""
# 🔮 Notebook de Pluto
"""

println("Hola desde Pluto 🚀")
'@ | Out-File -FilePath "notebooks\notebook_pluto.jl" -Encoding UTF8

@'
using DuckDB
using DataFrames

db = DuckDB.DB()
con = DuckDB.connect(db)

DuckDB.execute(con, "CREATE TABLE usuarios (id INTEGER, nombre VARCHAR, edad INTEGER)")
DuckDB.execute(con, "INSERT INTO usuarios VALUES (1, 'Ana', 28), (2, 'Carlos', 35)")

df = DataFrame(DuckDB.execute(con, "SELECT * FROM usuarios WHERE edad > 25"))
println(df)

DuckDB.disconnect(con)
DuckDB.close(db)
'@ | Out-File -FilePath "src\duckdb_example.jl" -Encoding UTF8

@'
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
julia --project=. src/main.jl
'@ | Out-File -FilePath "scripts\run.ps1" -Encoding UTF8

@'
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
julia --project=. src/makie_example.jl
'@ | Out-File -FilePath "scripts\iniciar_makie.ps1" -Encoding UTF8

@'
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
julia --project=. -e "using Pluto; Pluto.run(notebook=\"notebooks/notebook_pluto.jl\", auto_reload_from_file=true)"
'@ | Out-File -FilePath "scripts\iniciar_pluto.ps1" -Encoding UTF8

@"
# $projectName

Proyecto Julia inicializado con Pluto, Makie y DuckDB.

## Uso rápido

```powershell
.\scripts\run.ps1
.\scripts\iniciar_makie.ps1
.\scripts\iniciar_pluto.ps1
```
"@ | Out-File -FilePath "README.md" -Encoding UTF8

@'
# Julia
.julia/
Manifest.toml

# IDE / OS
.idea/
.vscode/
Thumbs.db
.DS_Store
'@ | Out-File -FilePath ".gitignore" -Encoding UTF8

Pop-Location

Write-Host ""
Write-Host "✅ Proyecto Julia creado: $projectName"
