#!/bin/bash

# Script: Inicializa un proyecto de Data Science con uv + Python + Jupyter + Pandas

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# Nombre del proyecto
PROJECT_NAME="${DL_PROJECT_NAME:-data-project}"

show_header "Inicializador de Proyecto Data Science 📊" "uv + Python + Jupyter + Pandas + DuckDB"

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

mkdir -p {src,notebooks,data/{01_raw,02_clean,03_processed,04_output},models,docs,scripts,tests}

touch src/__init__.py
touch tests/__init__.py

success "Estructura de carpetas creada"
echo ""

# ==========================================
# 4. CONFIGURAR PYPROJECT.TOML
# ==========================================
progress "⚙️  Configurando pyproject.toml..."

cat > pyproject.toml << 'EOF'
[project]
name = "data-project"
version = "0.1.0"
description = "Proyecto de Data Science con Jupyter, Pandas y DuckDB"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
    "pandas>=2.2.0",
    "numpy>=1.26.0",
    "jupyter>=1.0.0",
    "jupyterlab>=4.0.0",
    "notebook>=7.0.0",
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
    "nbstripout>=0.7.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = ["--verbose"]

[tool.black]
line-length = 100
target-version = ['py312']

[tool.ruff]
line-length = 100
target-version = "py312"
select = ["E", "F", "I", "N", "W"]
EOF

success "pyproject.toml configurado"
echo ""

# ==========================================
# 5. INSTALAR DEPENDENCIAS
# ==========================================
progress "📥 Instalando dependencias (esto puede tomar un momento)..."

source .venv/bin/activate

if ! uv pip install -e ".[dev]"; then
    handle_error "PIP_INSTALL_FAILED" "Falló la instalación de dependencias" \
        "Verifica tu conexión a internet"
    exit 1
fi

success "Dependencias instaladas"
echo ""

# ==========================================
# 6. CREAR ARCHIVOS DE EJEMPLO
# ==========================================
progress "📝 Creando archivos de ejemplo..."

# Módulo de utilidades de datos
cat > src/data_utils.py << 'PYEOF'
"""
Utilidades para carga y transformación de datos.
"""
import pandas as pd
import duckdb
from pathlib import Path


DATA_DIR = Path(__file__).parent.parent / "data"
RAW_DIR = DATA_DIR / "01_raw"
CLEAN_DIR = DATA_DIR / "02_clean"
PROCESSED_DIR = DATA_DIR / "03_processed"
OUTPUT_DIR = DATA_DIR / "04_output"


def load_csv(filename: str, subdir: str = "01_raw") -> pd.DataFrame:
    """Carga un CSV desde la carpeta de datos."""
    path = DATA_DIR / subdir / filename
    return pd.read_csv(path)


def save_csv(df: pd.DataFrame, filename: str, subdir: str = "04_output") -> Path:
    """Guarda un DataFrame como CSV."""
    path = DATA_DIR / subdir / filename
    df.to_csv(path, index=False)
    return path


def query_duckdb(sql: str, **kwargs) -> pd.DataFrame:
    """Ejecuta una consulta SQL con DuckDB y retorna un DataFrame."""
    return duckdb.sql(sql).df()


def create_sample_data() -> pd.DataFrame:
    """Crea un DataFrame de ejemplo para pruebas."""
    import numpy as np
    
    np.random.seed(42)
    n = 100
    
    return pd.DataFrame({
        "id": range(1, n + 1),
        "nombre": [f"item_{i}" for i in range(1, n + 1)],
        "valor": np.random.uniform(10, 1000, n).round(2),
        "categoria": np.random.choice(["A", "B", "C", "D"], n),
        "fecha": pd.date_range("2024-01-01", periods=n, freq="D"),
    })
PYEOF

# Main
cat > src/main.py << 'PYEOF'
"""
Punto de entrada principal del proyecto de datos.
"""
from src.data_utils import create_sample_data, query_duckdb


def main():
    print("📊 Proyecto Data Science inicializado")
    print()
    
    # Crear datos de ejemplo
    df = create_sample_data()
    print(f"✅ DataFrame creado: {df.shape[0]} filas × {df.shape[1]} columnas")
    print()
    
    # Ejemplo con DuckDB
    result = query_duckdb("""
        SELECT categoria, 
               COUNT(*) as cantidad,
               ROUND(AVG(valor), 2) as promedio
        FROM df 
        GROUP BY categoria 
        ORDER BY promedio DESC
    """)
    
    print("📈 Resumen por categoría (DuckDB):")
    print(result.to_string(index=False))
    print()
    print("✨ Todo funcionando correctamente")


if __name__ == "__main__":
    main()
PYEOF

# Test
cat > tests/test_data_utils.py << 'PYEOF'
"""
Tests para utilidades de datos.
"""
import pandas as pd
from src.data_utils import create_sample_data


def test_create_sample_data():
    """Test de creación de datos de ejemplo."""
    df = create_sample_data()
    assert isinstance(df, pd.DataFrame)
    assert len(df) == 100
    assert "id" in df.columns
    assert "valor" in df.columns
    assert "categoria" in df.columns


def test_sample_data_categories():
    """Test de categorías en datos de ejemplo."""
    df = create_sample_data()
    categories = set(df["categoria"].unique())
    assert categories == {"A", "B", "C", "D"}


def test_sample_data_values():
    """Test de rango de valores."""
    df = create_sample_data()
    assert df["valor"].min() >= 10
    assert df["valor"].max() <= 1000
PYEOF

# Notebook de ejemplo
cat > notebooks/01_exploracion.py << 'PYEOF'
# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .py
#       format_name: percent
# ---

# %% [markdown]
# # 📊 Exploración de Datos
# Notebook inicial para exploración y análisis.

# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import duckdb

# Configuración
pd.set_option("display.max_columns", None)
sns.set_theme(style="whitegrid")

# %%
# Crear datos de ejemplo
np.random.seed(42)
n = 200

df = pd.DataFrame({
    "fecha": pd.date_range("2024-01-01", periods=n, freq="D"),
    "ventas": np.random.uniform(100, 5000, n).round(2),
    "categoria": np.random.choice(["Tech", "Salud", "Educación", "Finanzas"], n),
    "region": np.random.choice(["Norte", "Sur", "Este", "Oeste"], n),
})

print(f"Shape: {df.shape}")
df.head()

# %%
# Análisis con DuckDB
resultado = duckdb.sql("""
    SELECT 
        categoria,
        region,
        COUNT(*) as registros,
        ROUND(AVG(ventas), 2) as promedio_ventas,
        ROUND(SUM(ventas), 2) as total_ventas
    FROM df
    GROUP BY categoria, region
    ORDER BY total_ventas DESC
""").df()

resultado

# %%
# Visualización
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Ventas por categoría
df.groupby("categoria")["ventas"].mean().plot(kind="bar", ax=axes[0], color="steelblue")
axes[0].set_title("Promedio de Ventas por Categoría")
axes[0].set_ylabel("Ventas ($)")

# Serie temporal
df.set_index("fecha")["ventas"].rolling(7).mean().plot(ax=axes[1], color="coral")
axes[1].set_title("Ventas - Media Móvil 7 días")
axes[1].set_ylabel("Ventas ($)")

plt.tight_layout()
plt.savefig("../data/04_output/exploracion.png", dpi=150)
plt.show()

print("✅ Exploración completada")
PYEOF

success "Archivos de ejemplo creados"
echo ""

# ==========================================
# 7. CREAR .GITIGNORE
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

# Distribution
build/
dist/
*.egg-info/

# Jupyter
.ipynb_checkpoints/
*.ipynb

# Testing
.pytest_cache/
.coverage
htmlcov/

# IDEs
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Data (no trackear datos pesados)
data/01_raw/*.csv
data/01_raw/*.parquet
data/01_raw/*.xlsx
data/02_clean/*
data/03_processed/*
data/04_output/*
!data/**/.gitkeep
models/*.pkl
models/*.joblib

# Type checking
.mypy_cache/
.ruff_cache/
EOF

# Crear .gitkeep para mantener estructura de data/
touch data/01_raw/.gitkeep
touch data/02_clean/.gitkeep
touch data/03_processed/.gitkeep
touch data/04_output/.gitkeep
touch models/.gitkeep

success ".gitignore creado"
echo ""

# ==========================================
# 8. CREAR SCRIPTS DE DESARROLLO
# ==========================================
progress "🚀 Creando scripts de desarrollo..."

cd ..

# Script para lanzar Jupyter
cat > jupyter.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/$PROJECT_DIR"
source .venv/bin/activate
echo "🚀 Iniciando JupyterLab..."
jupyter lab --notebook-dir=notebooks
EOF
sed -i "s|\$PROJECT_DIR|$PROJECT_NAME|" jupyter.sh
chmod +x jupyter.sh

# Script dev.sh
cat > dev.sh << 'EOF'
#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Data Science Runner 📊                                   ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

cd "$(dirname "$0")/$PROJECT_DIR"
source .venv/bin/activate

echo -e "${GREEN}✓ Entorno virtual activado${NC}"
echo -e "${BLUE}  Python: $(python --version)${NC}"
echo ""

python -m src.main "$@"
EOF
sed -i "s|\$PROJECT_DIR|$PROJECT_NAME|" dev.sh
chmod +x dev.sh

success "Scripts de desarrollo creados"
echo ""

# ==========================================
# 9. CREAR README
# ==========================================
cd "$PROJECT_NAME"

progress "📖 Creando README..."

cat > README.md << 'EOF'
# Data Science Project 📊

Proyecto de Data Science con Python, Jupyter, Pandas y DuckDB.

## 🚀 Inicio Rápido

### Activar entorno
```bash
source .venv/bin/activate
```

### Ejecutar análisis
```bash
python -m src.main
```

### Abrir JupyterLab
```bash
cd .. && ./jupyter.sh
```

## 📁 Estructura

```
data-project/
├── src/                        # Código fuente
│   ├── __init__.py
│   ├── main.py
│   └── data_utils.py
├── notebooks/                  # Notebooks Jupyter
│   └── 01_exploracion.py
├── data/
│   ├── 01_raw/                 # Datos crudos
│   ├── 02_clean/               # Datos limpios
│   ├── 03_processed/           # Datos procesados
│   └── 04_output/              # Resultados
├── models/                     # Modelos entrenados
├── tests/                      # Tests
├── docs/                       # Documentación
├── scripts/                    # Scripts auxiliares
├── pyproject.toml
└── README.md
```

## 📦 Stack Incluido

| Paquete | Uso |
|---------|-----|
| **pandas** | Manipulación de datos |
| **numpy** | Computación numérica |
| **jupyter** + **jupyterlab** | Notebooks interactivos |
| **matplotlib** + **seaborn** | Visualización estática |
| **plotly** | Visualización interactiva |
| **duckdb** | SQL analítico en memoria |
| **polars** | DataFrames de alto rendimiento |
| **scikit-learn** | Machine Learning |

## 🧪 Testing

```bash
pytest
pytest --cov=src
```

## 📚 Recursos

- [Pandas](https://pandas.pydata.org/docs/)
- [DuckDB](https://duckdb.org/docs/)
- [JupyterLab](https://jupyterlab.readthedocs.io/)
- [Polars](https://pola.rs/)
- [Scikit-learn](https://scikit-learn.org/)
EOF

success "README.md creado"
echo ""

# ==========================================
# 10. INICIALIZAR GIT
# ==========================================
progress "🔗 Inicializando repositorio git..."
git init >/dev/null 2>&1
git add .
success "Repositorio git inicializado"
echo ""

# ==========================================
# FINALIZACIÓN
# ==========================================

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
success "✅ ¡Proyecto Data Science creado exitosamente!"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

info "📁 Estructura creada:"
echo -e "  ${GREEN}./$PROJECT_NAME/src/${NC}         ← Código fuente"
echo -e "  ${GREEN}./$PROJECT_NAME/notebooks/${NC}   ← Notebooks Jupyter"
echo -e "  ${GREEN}./$PROJECT_NAME/data/${NC}        ← Pipeline de datos (raw → output)"
echo -e "  ${GREEN}./$PROJECT_NAME/models/${NC}      ← Modelos entrenados"
echo -e "  ${GREEN}./jupyter.sh${NC}                ← Lanzar JupyterLab"
echo -e "  ${GREEN}./dev.sh${NC}                    ← Ejecutar análisis"
echo ""

echo -e "${CYAN}${BOLD}Próximos pasos:${NC}"
echo -e "  ${GREEN}1.${NC} cd $PROJECT_NAME && source .venv/bin/activate"
echo -e "  ${GREEN}2.${NC} python -m src.main                ${GRAY}# Ejecutar análisis${NC}"
echo -e "  ${GREEN}3.${NC} cd .. && ./jupyter.sh             ${GRAY}# Abrir JupyterLab${NC}"
echo ""

echo -e "${CYAN}${BOLD}Paquetes instalados:${NC}"
echo -e "  ${YELLOW}✓${NC} pandas + numpy     (datos)"
echo -e "  ${YELLOW}✓${NC} jupyter + lab      (notebooks)"
echo -e "  ${YELLOW}✓${NC} matplotlib + seaborn + plotly  (visualización)"
echo -e "  ${YELLOW}✓${NC} duckdb + polars    (SQL + alto rendimiento)"
echo -e "  ${YELLOW}✓${NC} scikit-learn       (machine learning)"
echo ""

success "🎉 ¡Todo listo para hacer Data Science!"
