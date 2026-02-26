# Script: Inicializa un proyecto de Data Science con uv + Python + Jupyter en Windows.

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name, [string]$InstallHint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Error "No se encontró '$Name'. $InstallHint"
        exit 1
    }
}

$projectName = if ($env:DL_PROJECT_NAME) { $env:DL_PROJECT_NAME } else { "data-project" }

Write-Host ""
Write-Host "📊 Inicializador Data Science"
Write-Host "Proyecto: $projectName"
Write-Host ""

Require-Command -Name "uv" -InstallHint "Instálalo desde https://docs.astral.sh/uv/"

if (Test-Path $projectName) {
    $ans = Read-Host "El directorio '$projectName' ya existe. ¿Eliminar y recrear? (s/N)"
    if ($ans -notmatch '^[sS]$') {
        Write-Host "Operación cancelada."
        exit 0
    }
    Remove-Item -Path $projectName -Recurse -Force
}

uv init $projectName | Out-Host
Push-Location $projectName
uv venv | Out-Host

$dirs = @(
    "src",
    "notebooks",
    "data/01_raw",
    "data/02_clean",
    "data/03_processed",
    "data/04_output",
    "models",
    "docs",
    "scripts",
    "tests"
)

foreach ($d in $dirs) {
    New-Item -Path ($d -replace '/', '\\') -ItemType Directory -Force | Out-Null
}

New-Item -Path "src\__init__.py" -ItemType File -Force | Out-Null
New-Item -Path "tests\__init__.py" -ItemType File -Force | Out-Null

@'
[project]
name = "data-project"
version = "0.1.0"
description = "Proyecto de Data Science con Jupyter, Pandas y DuckDB"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
    "pandas>=2.2.0",
    "numpy>=1.26.0",
    "jupyterlab>=4.0.0",
    "matplotlib>=3.8.0",
    "seaborn>=0.13.0",
    "plotly>=5.18.0",
    "duckdb>=0.10.0",
    "polars>=0.20.0",
    "scikit-learn>=1.4.0",
    "openpyxl>=3.1.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-cov>=4.1.0",
    "black>=24.0.0",
    "ruff>=0.3.0",
    "mypy>=1.8.0",
]
'@ | Out-File -FilePath "pyproject.toml" -Encoding UTF8

@'
"""Punto de entrada principal del proyecto de datos."""

from src.data_utils import create_sample_data, summarize_by_category


def main() -> None:
    print("📊 Proyecto Data Science inicializado")
    df = create_sample_data()
    print(f"Filas generadas: {len(df)}")
    print(summarize_by_category(df))


if __name__ == "__main__":
    main()
'@ | Out-File -FilePath "src\main.py" -Encoding UTF8

@'
"""Utilidades de datos para el proyecto."""

from __future__ import annotations

import numpy as np
import pandas as pd


def create_sample_data(rows: int = 100) -> pd.DataFrame:
    rng = np.random.default_rng(seed=42)
    return pd.DataFrame(
        {
            "id": range(1, rows + 1),
            "categoria": rng.choice(["A", "B", "C", "D"], rows),
            "valor": rng.uniform(10, 1000, rows).round(2),
        }
    )


def summarize_by_category(df: pd.DataFrame) -> pd.DataFrame:
    return (
        df.groupby("categoria", as_index=False)["valor"]
        .agg(["count", "mean"])
        .reset_index()
    )
'@ | Out-File -FilePath "src\data_utils.py" -Encoding UTF8

@'
from src.data_utils import create_sample_data


def test_create_sample_data_default() -> None:
    df = create_sample_data()
    assert len(df) == 100
    assert "categoria" in df.columns
    assert "valor" in df.columns
'@ | Out-File -FilePath "tests\test_data_utils.py" -Encoding UTF8

@'
# $projectName

Proyecto Data Science inicializado para Windows con uv, jupyterlab y stack de análisis.

## Uso rápido

```powershell
.\.venv\Scripts\Activate.ps1
uv pip install -e ".[dev]"
python -m src.main
jupyter lab
```
'@ | Out-File -FilePath "README.md" -Encoding UTF8

@'
# Python
__pycache__/
*.py[cod]

# Virtual env
.venv/
venv/

# Data outputs
data/**/*.csv
data/**/*.parquet
data/**/*.db

# Tools
.pytest_cache/
.mypy_cache/
.ruff_cache/

# IDE / OS
.idea/
.vscode/
Thumbs.db
.DS_Store
'@ | Out-File -FilePath ".gitignore" -Encoding UTF8

try {
    uv pip install -e ".[dev]" | Out-Host
} catch {
    Write-Warning 'No se pudieron instalar dependencias automáticamente. Continúa manualmente con: uv pip install -e ".[dev]"'
}

Pop-Location

Write-Host ""
Write-Host "✅ Proyecto Data creado: $projectName"
Write-Host "Siguiente paso: cd $projectName"
