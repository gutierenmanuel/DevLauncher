#!/bin/bash

# Script para inicializar un proyecto Python con uv
# Crea estructura simple con uv + venv

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# Nombre del proyecto
PROJECT_NAME="python-project"

show_header "Inicializador de Proyecto Python 🐍" "uv + venv + estructura simple"

info "Proyecto: ${BOLD}$PROJECT_NAME${NC}"
info "Ubicación: $(pwd)/$PROJECT_NAME"
echo ""

# Verificar uv
progress "Verificando dependencias..."
check_command "uv" "UV_NOT_FOUND" || exit 1
success "uv instalado"
echo ""

# Verificar si ya existe
if [ -d "$PROJECT_NAME" ]; then
    warning "El directorio '$PROJECT_NAME' ya existe"
    echo ""
    
    if ! confirm "¿Deseas eliminarlo y crear uno nuevo?" "n"; then
        info "Instalación cancelada"
        exit 0
    fi
    
    progress "Eliminando directorio existente..."
    rm -rf "$PROJECT_NAME"
    success "Directorio eliminado"
    echo ""
fi

# ==========================================
# 1. INICIALIZAR PROYECTO CON UV
# ==========================================
progress "📦 Inicializando proyecto con uv..."

if ! uv init "$PROJECT_NAME"; then
    handle_error "UV_INIT_FAILED" "Falló la inicialización con uv" \
        "Verifica que uv esté correctamente instalado"
    exit 1
fi

cd "$PROJECT_NAME"
success "Proyecto inicializado con uv"
echo ""

# ==========================================
# 2. CREAR ENTORNO VIRTUAL
# ==========================================
progress "🔧 Creando entorno virtual..."

if ! uv venv; then
    handle_error "VENV_CREATE_FAILED" "Falló la creación del entorno virtual" \
        "Verifica que Python esté instalado"
    exit 1
fi

success "Entorno virtual creado en .venv/"
echo ""

# ==========================================
# 3. CREAR ESTRUCTURA DE CARPETAS
# ==========================================
progress "📁 Creando estructura del proyecto..."

mkdir -p src tests docs

# Crear __init__.py en src
touch src/__init__.py

# Crear main.py de ejemplo
cat > src/main.py << 'EOF'
"""
Módulo principal del proyecto.
"""


def greet(name: str = "Mundo") -> str:
    """
    Retorna un saludo personalizado.
    
    Args:
        name: Nombre a saludar (default: "Mundo")
        
    Returns:
        Mensaje de saludo
    """
    return f"🐍 ¡Hola {name} desde Python!"


def main():
    """Punto de entrada principal."""
    message = greet()
    print(message)
    print("✨ Proyecto Python inicializado correctamente")


if __name__ == "__main__":
    main()
EOF

# Crear test de ejemplo
cat > tests/test_main.py << 'EOF'
"""
Tests para el módulo main.
"""
import pytest
from src.main import greet


def test_greet_default():
    """Test del saludo con nombre por defecto."""
    result = greet()
    assert "Mundo" in result
    assert "🐍" in result


def test_greet_custom_name():
    """Test del saludo con nombre personalizado."""
    result = greet("Python")
    assert "Python" in result


def test_greet_return_type():
    """Test que verifica el tipo de retorno."""
    result = greet()
    assert isinstance(result, str)
EOF

touch tests/__init__.py

success "Estructura de carpetas creada"
echo ""

# ==========================================
# 4. CREAR PYPROJECT.TOML MEJORADO
# ==========================================
progress "⚙️  Configurando pyproject.toml..."

cat > pyproject.toml << 'EOF'
[project]
name = "python-project"
version = "0.1.0"
description = "Proyecto Python inicializado con uv"
readme = "README.md"
requires-python = ">=3.12"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-cov>=4.1.0",
    "black>=24.0.0",
    "ruff>=0.3.0",
    "mypy>=1.8.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--verbose",
    "--cov=src",
    "--cov-report=term-missing",
]

[tool.black]
line-length = 100
target-version = ['py312']
include = '\.pyi?$'

[tool.ruff]
line-length = 100
target-version = "py312"
select = ["E", "F", "I", "N", "W"]
ignore = []

[tool.mypy]
python_version = "3.12"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
EOF

success "pyproject.toml configurado"
echo ""

# ==========================================
# 5. CREAR .GITIGNORE
# ==========================================
progress "🔒 Creando .gitignore..."

cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python

# Virtual environments
.venv/
venv/
ENV/
env/

# Distribution / packaging
build/
dist/
*.egg-info/
.eggs/

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Type checking
.mypy_cache/
.dmypy.json
dmypy.json

# Ruff
.ruff_cache/
EOF

success ".gitignore creado"
echo ""

# ==========================================
# 6. CREAR README
# ==========================================
progress "📖 Creando README..."

cat > README.md << 'EOF'
# Python Project

Proyecto Python moderno inicializado con **uv**.

## 🚀 Inicio Rápido

### Activar entorno virtual

```bash
source .venv/bin/activate
```

### Instalar dependencias de desarrollo

```bash
uv pip install -e ".[dev]"
```

### Ejecutar el proyecto

```bash
python src/main.py
```

## 📁 Estructura

```
python-project/
├── src/                # Código fuente
│   ├── __init__.py
│   └── main.py
├── tests/              # Tests
│   ├── __init__.py
│   └── test_main.py
├── docs/               # Documentación
├── .venv/              # Entorno virtual
├── pyproject.toml      # Configuración del proyecto
├── .gitignore
└── README.md
```

## 🧪 Testing

### Ejecutar tests

```bash
pytest
```

### Con cobertura

```bash
pytest --cov=src --cov-report=html
```

### Ver reporte de cobertura

```bash
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

## 🛠️ Herramientas de Desarrollo

### Formatear código (Black)

```bash
black src tests
```

### Linting (Ruff)

```bash
ruff check src tests
ruff check --fix src tests  # Auto-fix
```

### Type checking (mypy)

```bash
mypy src
```

## 📦 Gestión de Dependencias

### Agregar dependencia

```bash
uv pip install <paquete>
```

### Agregar dependencia de desarrollo

```bash
uv pip install --dev <paquete>
```

### Actualizar dependencias

```bash
uv pip install --upgrade <paquete>
```

### Listar dependencias instaladas

```bash
uv pip list
```

### Congelar dependencias

```bash
uv pip freeze > requirements.txt
```

## 🎯 Scripts Útiles

Crea un `Makefile` o usa estos comandos:

```bash
# Tests
pytest

# Formatear + Lint
black src tests && ruff check src tests

# Type check
mypy src

# Todo junto
black src tests && ruff check src tests && mypy src && pytest
```

## 📚 Recursos

- [uv Documentation](https://github.com/astral-sh/uv)
- [Python Documentation](https://docs.python.org/3/)
- [pytest Documentation](https://docs.pytest.org/)
- [Black](https://black.readthedocs.io/)
- [Ruff](https://docs.astral.sh/ruff/)
- [mypy](https://mypy.readthedocs.io/)

## 💡 Tips

### Usar uv para todo

```bash
# En lugar de pip install
uv pip install <paquete>

# Más rápido y mejor caché
```

### Activar entorno automáticamente

Agrega a tu `.bashrc` o `.zshrc`:

```bash
alias venv="source .venv/bin/activate"
```

### Pre-commit hooks

```bash
uv pip install pre-commit
pre-commit install
```

Crea `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 24.1.1
    hooks:
      - id: black

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.3.0
    hooks:
      - id: ruff
        args: [--fix]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy
```
EOF

success "README.md creado"
echo ""

# ==========================================
# 7. CREAR SCRIPTS DE DESARROLLO
# ==========================================
cd ..

# Script dev.sh
progress "🚀 Creando dev.sh..."

cat > dev.sh << 'EOF'
#!/bin/bash

# Script de desarrollo para proyecto Python
# Activa venv y ejecuta el proyecto

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Python Development Runner 🐍                             ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar estructura
if [ ! -d "python-project" ]; then
    echo -e "${RED}✗ No se encuentra el directorio 'python-project'${NC}"
    echo -e "${YELLOW}  Ejecuta este script desde la raíz del proyecto${NC}"
    exit 1
fi

cd python-project

# Verificar entorno virtual
if [ ! -d ".venv" ]; then
    echo -e "${RED}✗ No se encuentra el entorno virtual${NC}"
    echo -e "${YELLOW}  Ejecuta: uv venv${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Entorno virtual encontrado${NC}"
echo ""

# Activar entorno virtual
echo -e "${BLUE}→ Activando entorno virtual...${NC}"
source .venv/bin/activate

echo -e "${GREEN}✓ Entorno virtual activado${NC}"
echo -e "${BLUE}  Python: $(python --version)${NC}"
echo ""

# Verificar dependencias
if ! python -c "import pytest" 2>/dev/null; then
    echo -e "${YELLOW}→ Instalando dependencias de desarrollo...${NC}"
    uv pip install -e ".[dev]"
    echo ""
fi

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Ejecutando aplicación...${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Ejecutar
python src/main.py "$@"

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Ejecución completada${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo -e "  ${GREEN}source python-project/.venv/bin/activate${NC}  # Activar venv"
echo -e "  ${GREEN}pytest${NC}                                     # Ejecutar tests"
echo -e "  ${GREEN}black src tests${NC}                           # Formatear código"
echo ""
EOF

chmod +x dev.sh
success "dev.sh creado"
echo ""

# Script test.sh
progress "🧪 Creando test.sh..."

cat > test.sh << 'EOF'
#!/bin/bash

# Script para ejecutar tests del proyecto Python

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Python Test Runner 🧪                                    ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

cd python-project

# Activar entorno virtual
if [ ! -d ".venv" ]; then
    echo -e "${RED}✗ No se encuentra el entorno virtual${NC}"
    exit 1
fi

source .venv/bin/activate

echo -e "${GREEN}✓ Entorno virtual activado${NC}"
echo ""

# Verificar pytest
if ! command -v pytest &> /dev/null; then
    echo -e "${YELLOW}→ Instalando pytest...${NC}"
    uv pip install -e ".[dev]"
    echo ""
fi

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Ejecutando tests...${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Ejecutar tests
pytest "$@"

echo ""
EOF

chmod +x test.sh
success "test.sh creado"
echo ""

# ==========================================
# FINALIZACIÓN
# ==========================================

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
success "✅ ¡Proyecto Python creado exitosamente!"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

info "📁 Estructura creada:"
echo -e "  ${GREEN}./python-project/${NC}     ← Código del proyecto"
echo -e "  ${GREEN}./python-project/.venv/${NC}  ← Entorno virtual"
echo -e "  ${GREEN}./dev.sh${NC}              ← Ejecutar aplicación"
echo -e "  ${GREEN}./test.sh${NC}             ← Ejecutar tests"
echo ""

echo -e "${CYAN}${BOLD}Próximos pasos:${NC}"
echo -e "  ${GREEN}1.${NC} cd python-project && source .venv/bin/activate  ${GRAY}# Activar venv${NC}"
echo -e "  ${GREEN}2.${NC} uv pip install -e \".[dev]\"                      ${GRAY}# Instalar deps${NC}"
echo -e "  ${GREEN}3.${NC} python src/main.py                              ${GRAY}# Ejecutar${NC}"
echo ""

echo -e "${CYAN}${BOLD}O usar los scripts:${NC}"
echo -e "  ${GREEN}→${NC} ./dev.sh      ${GRAY}# Activa venv y ejecuta${NC}"
echo -e "  ${GREEN}→${NC} ./test.sh     ${GRAY}# Ejecuta tests con cobertura${NC}"
echo ""

echo -e "${CYAN}${BOLD}Herramientas incluidas:${NC}"
echo -e "  ${YELLOW}✓${NC} pytest      (testing)"
echo -e "  ${YELLOW}✓${NC} black       (formateo)"
echo -e "  ${YELLOW}✓${NC} ruff        (linting)"
echo -e "  ${YELLOW}✓${NC} mypy        (type checking)"
echo -e "  ${YELLOW}✓${NC} pytest-cov  (cobertura)"
echo ""

success "🎉 ¡Todo listo para desarrollar en Python con uv!"
