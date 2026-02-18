# 🎨 Mejoras v1.3.0 - Headers Dinámicos

## 📊 CAMBIOS IMPLEMENTADOS

### ✅ 1. Selección Aleatoria de Headers
- **Múltiples ASCII arts**: El launcher ahora busca todos los `.txt` en `static/`
- **Selección aleatoria**: Cada vez que ejecutas el launcher, muestra un header diferente
- **Fácil de extender**: Solo agrega más archivos `.txt` a la carpeta `static/`

### ✅ 2. Degradado de Color
- **Gradiente automático**: Purple → Blue → Cyan → Pink
- **Suave y profesional**: Colores que van cambiando por línea
- **8 colores**: Paleta definida para mejor visual
  - #9b59b6 (Purple)
  - #8e44ad (Dark Purple)
  - #3498db (Blue)
  - #2980b9 (Dark Blue)
  - #1abc9c (Cyan)
  - #16a085 (Dark Cyan)
  - #e74c3c (Pink/Red)
  - #c0392b (Dark Red)

### ✅ 3. Mejor Espaciado
- **Espacio después del header**: Línea en blanco automática
- **Separación clara**: Header → Espacio → Menú
- **Más legible**: Interfaz menos saturada

## 🎨 Headers Disponibles

Ahora tienes **4 ASCII arts diferentes**:

### 1. asciiart.txt (Original)
```
Diseño original con caracteres Unicode complejos
22 líneas de arte ASCII detallado
```

### 2. asciiart2.txt (Texto simple)
```
    ____             __                           __             
   / __ \___  __  __/ /   ____ ___  ______  _____/ /_  ___  _____
  / / / / _ \/ / / / /   / __ `/ / / / __ \/ ___/ __ \/ _ \/ ___/
 ...
🚀 LAUNCHER UNIVERSAL DE SCRIPTS 🚀
```

### 3. asciiart3.txt (Box Unicode)
```
 ██████╗ ███████╗██╗   ██╗    ██╗      █████╗ ██╗   ██╗███╗   ██╗ ██████╗██╗  ██╗███████╗██████╗ 
 ██╔══██╗██╔════╝██║   ██║    ██║     ██╔══██╗██║   ██║████╗  ██║██╔════╝██║  ██║██╔════╝██╔══██╗
 ...
Script Management System
```

### 4. asciiart4.txt (Retro)
```
   ___  ____  __  __   __   ____  _  _  _  _  ___  _  _  ____  ____ 
  / __)( ___)( \/ ) / _\ (  _ \( \/ )( \/ )/ __)( )( )(  __)(  _ \
  ...
🔧 Development Script Manager 🔧
```

## 🎯 Cómo Funciona

### 1. Escaneo de Headers
```go
// Busca todos los .txt en static/
files, _ := ioutil.ReadDir(staticPath)
txtFiles := filter(files, "*.txt")
```

### 2. Selección Aleatoria
```go
// Seed con timestamp para aleatoriedad
rand.Seed(time.Now().UnixNano())
selectedFile := txtFiles[rand.Intn(len(txtFiles))]
```

### 3. Aplicación de Gradiente
```go
// Gradiente basado en posición de línea
colorIndex := (lineNumber * totalColors) / totalLines
color := gradientColors[colorIndex]
```

## 🎨 Personalizar Headers

### Agregar tu propio header:

1. **Crear archivo**:
```bash
cd static/
nano asciiart5.txt
```

2. **Pegar tu ASCII art**:
```
Tu diseño aquí...
Puede ser cualquier texto
Emojis, Unicode, etc.
```

3. **¡Listo!** El launcher lo detectará automáticamente

### Herramientas para crear ASCII art:

- **Online**: 
  - https://patorjk.com/software/taag/
  - https://www.ascii-art-generator.org/
- **CLI**: 
  - `figlet "DevLauncher"`
  - `toilet -f big "Launcher"`

## 🌈 Paleta de Gradiente

El gradiente actual usa estos colores en orden:

```
Línea 0-12%:   Purple  #9b59b6  █████
Línea 13-25%:  Purple  #8e44ad  █████
Línea 26-37%:  Blue    #3498db  █████
Línea 38-50%:  Blue    #2980b9  █████
Línea 51-62%:  Cyan    #1abc9c  █████
Línea 63-75%:  Cyan    #16a085  █████
Línea 76-87%:  Pink    #e74c3c  █████
Línea 88-100%: Red     #c0392b  █████
```

## 💡 Ejemplos Visuales

### Antes (v1.2.0):
```
[Header en 1 color fijo]

📂 /ruta/proyecto
┌─ Inicio
Menú...
```

### Ahora (v1.3.0):
```
[Header con degradado de colores]
[Gradiente Purple→Blue→Cyan→Pink]

📂 /ruta/proyecto
┌─ Inicio
Menú...
```

## 🎲 Aleatoriedad en Acción

Cada ejecución muestra un header diferente:

```bash
# Primera ejecución
./launcher-linux
# → Muestra asciiart2.txt con degradado

# Segunda ejecución
./launcher-linux
# → Muestra asciiart4.txt con degradado

# Tercera ejecución
./launcher-linux
# → Muestra asciiart.txt con degradado
```

## 🔧 Configuración Técnica

### Archivo: `ui/views.go`

**Función LoadASCIIArt():**
```go
// 1. Escanea static/ para archivos .txt
// 2. Selecciona uno aleatorio
// 3. Lee todas las líneas
// 4. Aplica gradiente
// 5. Añade espacio al final
```

**Función ApplyGradient():**
```go
// 1. Calcula total de líneas
// 2. Define paleta de colores
// 3. Asigna color según posición
// 4. Renderiza con Lipgloss
```

## 📦 Archivos Modificados

```
launcher-go/ui/views.go
  • LoadASCIIArt() - Selección aleatoria
  • ApplyGradient() - Degradado de color
  • Spacing mejorado

static/
  • asciiart.txt  (Original)
  • asciiart2.txt (Nuevo - Simple)
  • asciiart3.txt (Nuevo - Box)
  • asciiart4.txt (Nuevo - Retro)
```

## 🎯 Beneficios

### Para Usuarios
- ✅ **Variedad visual** - No aburrido
- ✅ **Sorpresa** - Cada ejecución es diferente
- ✅ **Estético** - Gradientes profesionales
- ✅ **Legibilidad** - Mejor espaciado

### Para Desarrolladores
- ✅ **Extensible** - Fácil agregar headers
- ✅ **Modular** - Sin hardcoding
- ✅ **Automático** - Detecta nuevos archivos
- ✅ **Configurable** - Paleta modificable

## 🚀 Testing

### Probar headers aleatorios:
```bash
# Ejecutar varias veces
for i in {1..5}; do
  echo "=== Ejecución $i ==="
  ./launcher-linux --list | head -30
  echo ""
  sleep 1
done
```

### Ver todos los headers:
```bash
ls -1 static/*.txt
# asciiart.txt
# asciiart2.txt
# asciiart3.txt
# asciiart4.txt
```

## 📝 Roadmap de Headers

Posibles mejoras futuras:

- [ ] **Temas estacionales** (Navidad, Halloween, etc.)
- [ ] **Headers animados** (con frames)
- [ ] **Configuración de favoritos** (:setheader N)
- [ ] **Headers por contexto** (mañana/tarde/noche)
- [ ] **Generador online** de headers personalizados

## 🎨 Ideas de Headers

### Minimalista
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    DEV LAUNCHER v1.3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Emoji
```
🚀 🔧 💻 📦 🎯
  LAUNCHER
🚀 🔧 💻 📦 🎯
```

### Banner
```
╔══════════════════════════════╗
║   DEVELOPMENT LAUNCHER       ║
║   v1.3.0                     ║
╚══════════════════════════════╝
```

## ✅ Checklist v1.3.0

- [x] Selección aleatoria de headers
- [x] Degradado de 8 colores
- [x] 4 ASCII arts incluidos
- [x] Espaciado mejorado
- [x] Detección automática de .txt
- [x] Seed con timestamp
- [x] Fallback si no hay archivos
- [x] Compatible con todos los headers

---

**Versión:** 1.3.0  
**Feature:** Headers dinámicos con degradado  
**Archivos:** 4 ASCII arts incluidos  
**Colores:** 8 en degradado  
**Fecha:** 2026-02-18

🎨 **¡Ahora cada ejecución es visualmente única!**
