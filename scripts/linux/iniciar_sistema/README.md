# Scripts de Inicialización de Sistema 🖥️

Scripts para configurar un PC nuevo o actualizar configuraciones del sistema.

## 📋 Scripts Disponibles

### 1. inject_aliases.sh

Inyecta aliases y funciones útiles en tu `.bashrc` o `.zshrc` de forma inteligente.

**Características:**
- ✅ Detección automática de shell (bash/zsh)
- ✅ Control de versiones con SHA256 hash
- ✅ Actualización automática de snippets modificados
- ✅ Backup automático antes de modificar
- ✅ No duplica snippets existentes

**Snippets incluidos:**

#### Funciones Python
- `vnv` - Activar entorno virtual (.venv)
- `mkvenv [nombre]` - Crear entorno virtual con uv

#### Funciones Git
- `gcm <mensaje>` - Add + commit rápido
- `gp [rama]` - Push rápido
- `gs` - Status limpio

#### Funciones Desarrollo
- `cdp [proyecto]` - Navegar a carpeta de proyectos
- `pyclean` - Limpiar cache de Python
- `nmclean` - Eliminar node_modules

#### Aliases Navegación
- `..` / `...` / `....` - Subir directorios
- `~` - Ir a home

#### Aliases Listado
- `ll` - Listado detallado
- `la` - Mostrar ocultos
- `l` - Listado compacto

#### Aliases Git
- `ga` / `gaa` - Git add
- `gst` - Git status
- `gco` / `gcb` - Checkout
- `gl` - Log gráfico
- `gd` / `gdc` - Diff
- `gb` / `gba` - Branches

#### Aliases Docker
- `dps` / `dpsa` - Docker ps
- `di` - Docker images
- `dex` - Docker exec
- `dlog` - Docker logs

#### Aliases Desarrollo
- `py` - Python3
- `pip` - Python3 pip
- `serve` - HTTP server simple

**Uso:**

```bash
# Desde el lanzador
dl
# → Seleccionar: iniciar_sistema → inject_aliases.sh

# O directamente
./scripts/linux/iniciar_sistema/inject_aliases.sh

# Aplicar cambios
source ~/.bashrc  # o ~/.zshrc
```

**Personalización:**

Edita el script y añade tus propios bloques:

```bash
add_chunk <<'BASH'
# Mi función personalizada
mi_funcion() {
  echo "Hola mundo"
}
BASH
```

---

### 2. setup_git_gitea.sh

Configura Git con credenciales de Gitea de forma segura.

**Características:**
- ✅ Configuración de usuario y email de Git
- ✅ Almacenamiento seguro de token (permisos 600)
- ✅ URL rewrite automático para Gitea
- ✅ Configuraciones recomendadas (colores, editor, etc.)
- ✅ Validación interactiva

**Qué configura:**

1. **Usuario y Email:**
   ```bash
   git config --global user.name "usuario"
   git config --global user.email "email@example.com"
   ```

2. **Credential Helper:**
   ```bash
   git config --global credential.helper store
   ```

3. **Token en ~/.git-credentials:**
   ```
   https://usuario:TOKEN@host.com
   ```

4. **URL Rewrite:**
   ```bash
   git config --global url."https://usuario@host/".insteadOf "https://host/"
   ```

5. **Configuraciones Adicionales:**
   - Editor por defecto (nano/vim)
   - Colores activados
   - Push simple
   - Pull sin rebase por defecto
   - Autocorrección de comandos

**Uso:**

```bash
# Desde el lanzador
dl
# → Seleccionar: iniciar_sistema → setup_git_gitea.sh

# O directamente con valores por defecto
./scripts/linux/iniciar_sistema/setup_git_gitea.sh

# Con parámetros personalizados
./scripts/linux/iniciar_sistema/setup_git_gitea.sh "mi_usuario" "email@example.com" "gitea.host.com"
```

**Parámetros:**

```bash
./setup_git_gitea.sh [USUARIO] [EMAIL] [HOST]

# Ejemplo:
./setup_git_gitea.sh "juan" "juan@empresa.com" "git.empresa.com:3000"
```

**Después de ejecutar:**

```bash
# Clonar repositorios (sin pedir credenciales)
git clone https://gitea.host.com/org/repo.git

# Verificar configuración
git config --global --list
```

---

## 🚀 Flujo Típico: PC Nuevo

### 1. Instalar herramientas básicas

```bash
dl
# → instaladores → instalar_pnpm.sh
# → instaladores → instalar_volta.sh
# → instaladores → instalar_uv.sh
# → instaladores → instalar_python312.sh
```

### 2. Configurar Git

```bash
dl
# → iniciar_sistema → setup_git_gitea.sh
```

### 3. Inyectar aliases

```bash
dl
# → iniciar_sistema → inject_aliases.sh
source ~/.bashrc
```

### 4. Clonar tus repositorios

```bash
mkdir ~/proyectos
cd ~/proyectos
git clone https://gitea.host.com/user/mi-proyecto.git
```

---

## 📁 Estructura

```
iniciar_sistema/
├── inject_aliases.sh       # Inyector de aliases
├── setup_git_gitea.sh      # Configurador de Git
└── README.md               # Esta documentación
```

---

## 💡 Tips

### Verificar aliases inyectados

```bash
# Ver todos los snippets
grep "# SNIPPET" ~/.bashrc

# Ver un snippet específico
grep -A 10 "# SNIPPET vnv" ~/.bashrc
```

### Actualizar snippets

Simplemente ejecuta `inject_aliases.sh` de nuevo. Si el contenido cambió, se actualizará automáticamente.

### Remover snippets

Edita manualmente tu `.bashrc`/`.zshrc` y elimina las líneas entre:
```bash
# SNIPPET nombre_snippet sha256:hash
...
```

### Restaurar backup

Si algo sale mal con inject_aliases.sh:

```bash
# Los backups están en:
ls -la ~/.bashrc.bak.*

# Restaurar el último
cp ~/.bashrc.bak.YYYYMMDD-HHMMSS ~/.bashrc
source ~/.bashrc
```

### Git: cambiar token

Ejecuta `setup_git_gitea.sh` de nuevo con el nuevo token. Reemplazará el anterior.

### Git: verificar token guardado

```bash
cat ~/.git-credentials
# ADVERTENCIA: El token está en texto plano (pero con permisos 600)
```

---

## 🔒 Seguridad

### inject_aliases.sh

- ✅ No ejecuta código externo
- ✅ Crea backup antes de modificar
- ✅ Solo modifica archivos de configuración del usuario

### setup_git_gitea.sh

- ⚠️ El token se guarda en `~/.git-credentials` (texto plano)
- ✅ Permisos 600 (solo lectura/escritura del usuario)
- ⚠️ Considera usar SSH keys para producción
- ✅ Git credential helper usa almacenamiento local seguro

**Recomendación:** Para mayor seguridad, usa SSH keys en lugar de tokens HTTPS.

---

## 🐛 Troubleshooting

### inject_aliases.sh: "command not found"

Los aliases solo están disponibles después de:
```bash
source ~/.bashrc  # o ~/.zshrc
```

### inject_aliases.sh: snippets duplicados

No debería pasar gracias al hash SHA256, pero si ocurre:
```bash
# Restaurar backup
cp ~/.bashrc.bak.YYYYMMDD-HHMMSS ~/.bashrc
```

### setup_git_gitea.sh: "Permission denied"

```bash
# Verificar permisos de ~/.git-credentials
chmod 600 ~/.git-credentials

# Verificar propiedad
ls -la ~/.git-credentials
```

### Git sigue pidiendo credenciales

```bash
# Verificar configuración
git config --global --list | grep credential

# Debería mostrar:
# credential.helper=store

# Verificar archivo de credenciales
cat ~/.git-credentials
```

### Git: "fatal: could not read Username"

Verifica la configuración de URL rewrite:
```bash
git config --global --list | grep url
```

---

## 📚 Recursos

- [Git Credential Helper](https://git-scm.com/docs/git-credential-store)
- [Bash Aliases](https://www.gnu.org/software/bash/manual/html_node/Aliases.html)
- [Zsh Aliases](https://zsh.sourceforge.io/Doc/Release/Shell-Grammar.html#Aliasing)
