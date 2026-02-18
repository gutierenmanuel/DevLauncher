# Script inicializador - Crear proyecto Python
# Inicializa un nuevo proyecto Python con venv y estructura básica

# Colores
$Green = "`e[32m"
$Blue = "`e[34m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Purple = "`e[35m"
$Cyan = "`e[36m"
$Gray = "`e[90m"
$NC = "`e[0m"

Write-Host ""
Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${Purple}║          Inicializar Proyecto Python 🐍                    ║${NC}"
Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

# Verificar Python
$pythonCmd = $null
if (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    $pythonCmd = "python3"
} else {
    Write-Host "${Red}✗ Python no está instalado${NC}"
    Write-Host "${Yellow}Instálalo con: ${Cyan}devscript instalar_python312.ps1${NC}"
    exit 1
}

$pythonVersion = & $pythonCmd --version
Write-Host "${Green}✓ Python disponible: $pythonVersion${NC}"
Write-Host ""

# Pedir nombre del proyecto
$projectName = Read-Host "${Cyan}Nombre del proyecto${NC}"

if (-not $projectName) {
    Write-Host "${Red}✗ Nombre de proyecto requerido${NC}"
    exit 1
}

# Verificar si el directorio ya existe
if (Test-Path $projectName) {
    Write-Host "${Red}✗ El directorio '$projectName' ya existe${NC}"
    exit 1
}

Write-Host ""
Write-Host "${Blue}→ Creando estructura del proyecto...${NC}"

# Crear directorio principal
New-Item -ItemType Directory -Path $projectName | Out-Null
Set-Location $projectName

# Crear estructura de directorios
$dirs = @("src", "tests", "docs")
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir | Out-Null
    Write-Host "${Gray}  ✓ Creado: $dir/${NC}"
}

# Crear archivos iniciales
Write-Host ""
Write-Host "${Blue}→ Creando archivos iniciales...${NC}"

# README.md
@"
# $projectName

Descripción del proyecto.

## Instalación

\`\`\`bash
# Crear entorno virtual
python -m venv .venv

# Activar entorno virtual
.venv\Scripts\Activate.ps1

# Instalar dependencias
pip install -r requirements.txt
\`\`\`

## Uso

\`\`\`bash
python src/main.py
\`\`\`

## Desarrollo

\`\`\`bash
# Instalar dependencias de desarrollo
pip install -r requirements-dev.txt

# Ejecutar tests
pytest
\`\`\`
"@ | Out-File -FilePath "README.md" -Encoding UTF8

# .gitignore
@"
# Python
__pycache__/
*.py[cod]
*`$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
.venv/
venv/
ENV/
env/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/

# OS
.DS_Store
Thumbs.db
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8

# requirements.txt
"# Dependencias del proyecto`n" | Out-File -FilePath "requirements.txt" -Encoding UTF8

# requirements-dev.txt
@"
# Dependencias de desarrollo
pytest>=7.0.0
pytest-cov>=4.0.0
black>=23.0.0
flake8>=6.0.0
mypy>=1.0.0
"@ | Out-File -FilePath "requirements-dev.txt" -Encoding UTF8

# src/main.py
@"
"""
$projectName - Archivo principal
"""

def main():
    print("¡Hola desde $projectName!")
    print("Python está funcionando correctamente.")

if __name__ == "__main__":
    main()
"@ | Out-File -FilePath "src\main.py" -Encoding UTF8

# tests/__init__.py
"" | Out-File -FilePath "tests\__init__.py" -Encoding UTF8

# tests/test_main.py
@"
"""
Tests para el módulo principal
"""
import sys
sys.path.insert(0, '../src')

def test_example():
    assert True, "Test de ejemplo"
"@ | Out-File -FilePath "tests\test_main.py" -Encoding UTF8

Write-Host "${Gray}  ✓ README.md${NC}"
Write-Host "${Gray}  ✓ .gitignore${NC}"
Write-Host "${Gray}  ✓ requirements.txt${NC}"
Write-Host "${Gray}  ✓ requirements-dev.txt${NC}"
Write-Host "${Gray}  ✓ src/main.py${NC}"
Write-Host "${Gray}  ✓ tests/__init__.py${NC}"
Write-Host "${Gray}  ✓ tests/test_main.py${NC}"

Write-Host ""
Write-Host "${Blue}→ Creando entorno virtual...${NC}"
& $pythonCmd -m venv .venv

if ($LASTEXITCODE -eq 0) {
    Write-Host "${Green}✓ Entorno virtual creado${NC}"
} else {
    Write-Host "${Yellow}⚠ No se pudo crear el entorno virtual${NC}"
}

Write-Host ""
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host "${Green}✨ ¡Proyecto creado exitosamente!${NC}"
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host ""
Write-Host "${Cyan}Próximos pasos:${NC}"
Write-Host "  ${Green}cd $projectName${NC}"
Write-Host "  ${Green}.venv\Scripts\Activate.ps1${NC}  - Activar entorno virtual"
Write-Host "  ${Green}pip install -r requirements-dev.txt${NC}  - Instalar deps"
Write-Host "  ${Green}python src\main.py${NC}  - Ejecutar el programa"
Write-Host "  ${Green}pytest${NC}  - Ejecutar tests"
Write-Host ""
Write-Host "${Yellow}💡 Tip: Usa ${Cyan}uv${NC} para instalaciones más rápidas${NC}"
Write-Host ""
