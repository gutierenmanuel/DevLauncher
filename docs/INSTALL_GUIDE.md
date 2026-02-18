# 📦 Guía de Instalación - DevLauncher v1.4.0

## 🚀 Instalación Rápida

### Linux / macOS

```bash
cd ~/DataProyects/Scripts_dev
./install.sh
source ~/.bashrc  # o ~/.zshrc si usas zsh
```

### Windows (PowerShell)

```powershell
cd ~\DataProyects\Scripts_dev
.\install.ps1
. $PROFILE
```

---

## ✨ Qué hace el instalador

1. **Detecta tu entorno**
   - Bash, Zsh, o PowerShell
   - Encuentra tu archivo de configuración

2. **Configura el acceso global**
   - Añade `$DEVSCRIPTS_ROOT` apuntando al proyecto
   - Agrega el directorio al `PATH`

3. **Crea comandos útiles**
   - `devlauncher` o `dl` → Launcher interactivo
   - `devscript <nombre>` → Ejecuta scripts directamente

4. **Habilita autocompletado**
   - Tab completion para nombres de scripts

---

## 🎮 Uso después de instalar

### Launcher Interactivo

```bash
# Desde cualquier directorio
dl

# O usando el nombre completo
devlauncher
```

Esto abre el launcher Go con Bubbletea mostrando:
- 🎨 Header ASCII aleatorio con degradado
- 📂 Categorías de scripts organizadas
- ⚡ Navegación con flechas, números, vim keys
- 🔧 Terminal de comandos con `:`

### Ejecutar script directamente

```bash
# Linux
devscript control_procesos.sh

# Windows
devscript init_project.ps1

# Con autocompletado
devscript <TAB>  # Lista todos los scripts disponibles
```

---

## 🔄 Reinstalación / Actualización

Si ya tenías la versión antigua instalada:

```bash
# Linux/macOS
./install.sh
# Responde "s" cuando pregunte si quieres reinstalar

# Windows
.\install.ps1
# Responde "s" cuando pregunte si quieres reinstalar
```

El instalador:
1. ✅ Detecta la instalación anterior
2. ✅ Remueve la configuración antigua
3. ✅ Instala la nueva con los binarios Go
4. ✅ Mantiene tus scripts intactos

---

## 📋 Comandos Disponibles

### `devlauncher` o `dl`

Abre el launcher interactivo con todas las categorías y scripts.

**Características:**
- Header ASCII aleatorio (8 opciones)
- Navegación con ↑↓, j/k, 1-9
- Terminal integrada con `:`
- Volver con `.`, `0`, `esc`
- Salir con `q`

**Ejemplo:**
```bash
dl
# Selecciona categoría → Selecciona script → Ejecuta
```

### `devscript <nombre>`

Ejecuta un script directamente sin abrir el launcher.

**Ventajas:**
- Más rápido para scripts conocidos
- Autocompletado con Tab
- Busca automáticamente en todas las categorías

**Ejemplos:**
```bash
# Linux
devscript dev.sh
devscript espacio_disponible.sh
devscript init_backend_project.sh

# Windows
devscript dev.ps1
devscript clean_temp.bat
```

---

## 🛠️ Estructura de Archivos

Después de la instalación:

```
~/DataProyects/Scripts_dev/
├── install.sh           → Instalador Linux/macOS
├── install.ps1          → Instalador Windows
├── launcher-linux       → Binario Go (Linux/WSL) - 4.9 MB
├── launcher.exe         → Binario Go (Windows) - 5.3 MB
├── launcher-mac         → Binario Go (macOS) - 4.7 MB
├── launcher-go/         → Código fuente Go
├── scripts/
│   ├── linux/           → Scripts Linux (.sh)
│   └── win/             → Scripts Windows (.ps1, .bat)
└── static/              → Headers ASCII (.txt)
```

**Archivos de configuración modificados:**

Linux/macOS:
- `~/.bashrc` (bash)
- `~/.zshrc` (zsh)

Windows:
- `$PROFILE` (PowerShell)

---

## 🧪 Verificar Instalación

### Test básico

```bash
# Debe mostrar la ruta del proyecto
echo $DEVSCRIPTS_ROOT  # Linux/macOS
echo $env:DEVSCRIPTS_ROOT  # Windows

# Debe abrir el launcher
dl

# Debe mostrar ayuda
devscript
```

### Test de acceso global

```bash
# Ve a otro directorio
cd ~

# Ejecuta el launcher
dl  # ✓ Debería funcionar desde cualquier lugar
```

### Test de autocompletado

```bash
# Presiona Tab después de escribir
devscript <TAB>

# Debería listar todos los scripts disponibles
```

---

## ❌ Desinstalación

Si quieres remover el launcher:

### Linux/macOS

1. Edita tu archivo de configuración:
   ```bash
   nano ~/.bashrc  # o ~/.zshrc
   ```

2. Elimina la sección:
   ```bash
   # Scripts Development Launcher
   ...
   # End Scripts Development Launcher
   ```

3. Recarga:
   ```bash
   source ~/.bashrc
   ```

### Windows

1. Edita tu perfil de PowerShell:
   ```powershell
   notepad $PROFILE
   ```

2. Elimina la sección:
   ```powershell
   # Scripts Development Launcher
   ...
   # End Scripts Development Launcher
   ```

3. Recarga:
   ```powershell
   . $PROFILE
   ```

---

## 🔧 Troubleshooting

### "command not found: dl"

**Causa:** No se recargó el perfil del shell.

**Solución:**
```bash
# Linux/macOS
source ~/.bashrc  # o ~/.zshrc

# Windows
. $PROFILE
```

### "Permission denied"

**Causa:** Binarios no tienen permisos de ejecución.

**Solución:**
```bash
cd ~/DataProyects/Scripts_dev
chmod +x launcher-linux launcher-mac
```

### Windows: "execution of scripts is disabled"

**Causa:** Política de ejecución de PowerShell restrictiva.

**Solución:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "No such file or directory: launcher-linux"

**Causa:** Los binarios no se compilaron o no existen.

**Solución:**
```bash
cd launcher-go
./build.sh
```

---

## 💡 Tips y Trucos

### Alias personalizados

Puedes agregar tus propios alias en tu `.bashrc` / `.zshrc` / `$PROFILE`:

```bash
# Launcher con categoría específica
alias dlweb="dl && echo '1'"  # Abre directamente web scripts

# Script favoritos
alias mydev="devscript my_daily_script.sh"
```

### Integración con IDE

Visual Studio Code:
1. `Ctrl+Shift+P`
2. "Tasks: Configure Task"
3. Agregar:
   ```json
   {
     "label": "Run DevLauncher",
     "type": "shell",
     "command": "dl",
     "problemMatcher": []
   }
   ```

### Script de inicio automático

Agregar al final de `.bashrc` / `.zshrc`:
```bash
# Auto-mostrar launcher al abrir terminal
# dl
```

---

## 📚 Más Información

- **README.md** - Documentación completa del launcher
- **CHANGELOG.md** - Historial de cambios
- **launcher-go/README.md** - Documentación técnica Go

---

## 🎉 ¡Listo!

Ahora tienes acceso global a todos tus scripts de desarrollo desde cualquier directorio.

**Comandos clave:**
- `dl` → Launcher interactivo
- `devscript <nombre>` → Ejecutar script directo
- `q` → Salir del launcher

¡Disfruta de tu launcher mejorado! 🚀
