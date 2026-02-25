#!/bin/bash

# Script: Inicializa un repositorio Julia con Pluto, Makie y DuckDB

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# Nombre del proyecto
PROJECT_NAME="${DL_PROJECT_NAME:-julia-project}"

show_header "Inicializador de Proyecto Julia 🔮" "Pluto + Makie + DuckDB + DataFrames"

info "Proyecto: ${BOLD}$PROJECT_NAME${NC}"
info "Ubicación: $(pwd)/$PROJECT_NAME"
echo ""

# Verificar Julia
progress "Verificando dependencias..."
check_command "julia" "JULIA_NOT_FOUND" || exit 1
show_version "julia" "--version"
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
# 1. CREAR ESTRUCTURA
# ==========================================
progress "📁 Creando estructura del proyecto..."
mkdir -p "$PROJECT_NAME"/{src,notebooks,data,docs,scripts}
cd "$PROJECT_NAME"
success "Estructura de carpetas creada"
echo ""

# ==========================================
# 2. INICIALIZAR ENTORNO JULIA
# ==========================================
progress "📦 Inicializando entorno Julia e instalando paquetes..."
info "Esto puede tomar varios minutos en la primera ejecución..."
echo ""

if ! julia -e '
using Pkg
Pkg.activate(".")
Pkg.add(["Pluto", "PlutoUI", "GLMakie", "CairoMakie", "DuckDB", "DataFrames"])
println("✅ Paquetes instalados correctamente")
'; then
    handle_error "JULIA_PKG_FAILED" "Falló la instalación de paquetes Julia" \
        "Verifica tu conexión a internet y que Julia esté correctamente instalado"
    exit 1
fi

success "Entorno Julia inicializado con paquetes"
echo ""

# ==========================================
# 3. CREAR ARCHIVOS DE EJEMPLO
# ==========================================
progress "📝 Creando archivos de ejemplo..."

# Notebook de Pluto
cat > notebooks/notebook_pluto.jl << 'EOF'
### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# ╔═╡ 00000001-0000-0000-0000-000000000001
using PlutoUI

# ╔═╡ 00000002-0000-0000-0000-000000000002
md"""
# 🔮 Notebook de Pluto

Este es un notebook reactivo de Julia.
"""

# ╔═╡ 00000003-0000-0000-0000-000000000003
println("Hola desde Pluto 🚀")

# ╔═╡ Cell order:
# ╠═00000001-0000-0000-0000-000000000001
# ╠═00000002-0000-0000-0000-000000000002
# ╠═00000003-0000-0000-0000-000000000003
EOF

# Script de visualización con Makie
cat > src/makie_example.jl << 'EOF'
using GLMakie

# Ejemplo básico: gráfico de línea
fig = Figure(size = (800, 600))
ax = Axis(fig[1, 1],
    title = "Ejemplo Makie 🎨",
    xlabel = "x",
    ylabel = "f(x)"
)

x = range(0, 4π, length=200)
lines!(ax, x, sin.(x), color = :dodgerblue, linewidth = 2, label = "sin(x)")
lines!(ax, x, cos.(x), color = :tomato, linewidth = 2, label = "cos(x)")
axislegend(ax)

display(fig)

println("✅ Gráfico Makie generado")
EOF

# Script de datos con DuckDB
cat > src/duckdb_example.jl << 'EOF'
using DuckDB
using DataFrames

# Crear base de datos en memoria
db = DuckDB.DB()
con = DuckDB.connect(db)

# Crear tabla de ejemplo
DuckDB.execute(con, """
    CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY,
        nombre VARCHAR,
        edad INTEGER,
        ciudad VARCHAR
    )
""")

# Insertar datos
DuckDB.execute(con, """
    INSERT INTO usuarios VALUES
    (1, 'Ana', 28, 'Madrid'),
    (2, 'Carlos', 35, 'Barcelona'),
    (3, 'Lucía', 22, 'Valencia'),
    (4, 'Miguel', 31, 'Sevilla')
""")

# Consultar
df = DataFrame(DuckDB.execute(con, "SELECT * FROM usuarios WHERE edad > 25"))
println("📊 Usuarios mayores de 25:")
println(df)

DuckDB.disconnect(con)
DuckDB.close(db)

println("\n✅ DuckDB funcionando correctamente")
EOF

# Main
cat > src/main.jl << 'EOF'
println("🔮 ¡Hola desde Julia!")
println("Proyecto inicializado correctamente")
println()
println("Módulos disponibles:")
println("  → Pluto (notebooks reactivos)")
println("  → Makie (visualización)")
println("  → DuckDB (base de datos)")
println("  → DataFrames (manipulación de datos)")
EOF

success "Archivos de ejemplo creados"
echo ""

# ==========================================
# 4. CREAR SCRIPTS DE LANZAMIENTO
# ==========================================
progress "🚀 Creando scripts de lanzamiento..."

cat > scripts/iniciar_pluto.sh << 'LAUNCH'
#!/bin/bash
cd "$(dirname "$0")/.."
julia --project=. -e '
using Pluto
Pluto.run(notebook="notebooks/notebook_pluto.jl", auto_reload_from_file=true)
'
LAUNCH
chmod +x scripts/iniciar_pluto.sh

cat > scripts/iniciar_makie.sh << 'LAUNCH'
#!/bin/bash
cd "$(dirname "$0")/.."
julia --project=. src/makie_example.jl
LAUNCH
chmod +x scripts/iniciar_makie.sh

cat > scripts/run.sh << 'LAUNCH'
#!/bin/bash
cd "$(dirname "$0")/.."
julia --project=. src/main.jl
LAUNCH
chmod +x scripts/run.sh

success "Scripts de lanzamiento creados"
echo ""

# ==========================================
# 5. CREAR .GITIGNORE
# ==========================================
progress "🔒 Creando .gitignore..."

cat > .gitignore << 'EOF'
# Julia
.julia/
*.jl.cov
*.jl.mem
Manifest.toml

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Data
data/*.csv
data/*.parquet
data/*.db
EOF

success ".gitignore creado"
echo ""

# ==========================================
# 6. CREAR README
# ==========================================
progress "📖 Creando README..."

cat > README.md << 'EOF'
# Julia Project 🔮

Proyecto Julia inicializado con Pluto, Makie y DuckDB.

## 🚀 Inicio Rápido

### Ejecutar proyecto
```bash
./scripts/run.sh
```

### Abrir notebook Pluto
```bash
./scripts/iniciar_pluto.sh
```

### Ejecutar visualización Makie
```bash
./scripts/iniciar_makie.sh
```

## 📁 Estructura

```
julia-project/
├── src/                    # Código fuente
│   ├── main.jl
│   ├── makie_example.jl
│   └── duckdb_example.jl
├── notebooks/              # Notebooks de Pluto
│   └── notebook_pluto.jl
├── data/                   # Datos
├── docs/                   # Documentación
├── scripts/                # Scripts de lanzamiento
│   ├── run.sh
│   ├── iniciar_pluto.sh
│   └── iniciar_makie.sh
├── Project.toml
└── README.md
```

## 📦 Paquetes Incluidos

- **Pluto** + PlutoUI — Notebooks reactivos
- **GLMakie** + CairoMakie — Visualización
- **DuckDB** — Base de datos analítica
- **DataFrames** — Manipulación de datos

## 📚 Recursos

- [Julia Documentation](https://docs.julialang.org/)
- [Pluto.jl](https://plutojl.org/)
- [Makie.jl](https://docs.makie.org/)
- [DuckDB.jl](https://duckdb.org/docs/api/julia)
EOF

success "README.md creado"
echo ""

# ==========================================
# 7. INICIALIZAR GIT
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
success "✅ ¡Proyecto Julia creado exitosamente!"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

info "📁 Estructura creada:"
echo -e "  ${GREEN}./$PROJECT_NAME/src/${NC}        ← Código fuente"
echo -e "  ${GREEN}./$PROJECT_NAME/notebooks/${NC}  ← Notebooks Pluto"
echo -e "  ${GREEN}./$PROJECT_NAME/data/${NC}       ← Datos"
echo -e "  ${GREEN}./$PROJECT_NAME/scripts/${NC}    ← Scripts de lanzamiento"
echo ""

echo -e "${CYAN}${BOLD}Próximos pasos:${NC}"
echo -e "  ${GREEN}1.${NC} cd $PROJECT_NAME"
echo -e "  ${GREEN}2.${NC} ./scripts/run.sh              ${GRAY}# Ejecutar proyecto${NC}"
echo -e "  ${GREEN}3.${NC} ./scripts/iniciar_pluto.sh    ${GRAY}# Abrir Pluto${NC}"
echo -e "  ${GREEN}4.${NC} ./scripts/iniciar_makie.sh    ${GRAY}# Visualización${NC}"
echo ""

echo -e "${CYAN}${BOLD}Paquetes instalados:${NC}"
echo -e "  ${YELLOW}✓${NC} Pluto + PlutoUI  (notebooks reactivos)"
echo -e "  ${YELLOW}✓${NC} GLMakie + CairoMakie  (visualización)"
echo -e "  ${YELLOW}✓${NC} DuckDB  (base de datos analítica)"
echo -e "  ${YELLOW}✓${NC} DataFrames  (manipulación de datos)"
echo ""

success "🎉 ¡Todo listo para desarrollar en Julia!"
