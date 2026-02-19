# Script de utilidades - Información del sistema
# Muestra información detallada del sistema Windows

Clear-Host

# Colores
$Green = "`e[32m"
$Blue = "`e[34m"
$Yellow = "`e[33m"
$Purple = "`e[35m"
$Cyan = "`e[36m"
$Gray = "`e[90m"
$NC = "`e[0m"

Write-Host ""
Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${Purple}║          Información del Sistema 💻                        ║${NC}"
Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

# Sistema Operativo
Write-Host "${Cyan}═══ Sistema Operativo ═══${NC}"
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "  OS: ${Green}$($os.Caption)${NC}"
Write-Host "  Versión: ${Green}$($os.Version)${NC}"
Write-Host "  Build: ${Green}$($os.BuildNumber)${NC}"
Write-Host "  Arquitectura: ${Green}$($os.OSArchitecture)${NC}"
Write-Host ""

# CPU
Write-Host "${Cyan}═══ Procesador ═══${NC}"
$cpu = Get-CimInstance Win32_Processor
Write-Host "  CPU: ${Green}$($cpu.Name.Trim())${NC}"
Write-Host "  Núcleos: ${Green}$($cpu.NumberOfCores)${NC}"
Write-Host "  Hilos: ${Green}$($cpu.NumberOfLogicalProcessors)${NC}"
Write-Host ""

# Memoria RAM
Write-Host "${Cyan}═══ Memoria RAM ═══${NC}"
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRAM = [math]::Round($totalRAM - $freeRAM, 2)
$usagePercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)

Write-Host "  Total: ${Green}$totalRAM GB${NC}"
Write-Host "  Usado: ${Yellow}$usedRAM GB${NC} (${Yellow}$usagePercent%${NC})"
Write-Host "  Libre: ${Green}$freeRAM GB${NC}"
Write-Host ""

# Discos
Write-Host "${Cyan}═══ Discos ═══${NC}"
$disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
foreach ($disk in $disks) {
    $totalGB = [math]::Round($disk.Size / 1GB, 2)
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $usedGB = [math]::Round($totalGB - $freeGB, 2)
    $usagePercent = [math]::Round(($usedGB / $totalGB) * 100, 1)
    
    Write-Host "  ${Green}$($disk.DeviceID)${NC}"
    Write-Host "    Total: ${Green}$totalGB GB${NC}"
    Write-Host "    Usado: ${Yellow}$usedGB GB${NC} (${Yellow}$usagePercent%${NC})"
    Write-Host "    Libre: ${Green}$freeGB GB${NC}"
}
Write-Host ""

# Red
Write-Host "${Cyan}═══ Red ═══${NC}"
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($adapter in $adapters) {
    $ip = (Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    if ($ip) {
        Write-Host "  ${Green}$($adapter.Name)${NC}"
        Write-Host "    IP: ${Cyan}$ip${NC}"
        Write-Host "    MAC: ${Gray}$($adapter.MacAddress)${NC}"
    }
}
Write-Host ""

# Versiones de herramientas de desarrollo
Write-Host "${Cyan}═══ Herramientas de Desarrollo ═══${NC}"

$tools = @(
    @{Name="Node.js"; Cmd="node"; Args="--version"},
    @{Name="npm"; Cmd="npm"; Args="--version"},
    @{Name="pnpm"; Cmd="pnpm"; Args="--version"},
    @{Name="Python"; Cmd="python"; Args="--version"},
    @{Name="Git"; Cmd="git"; Args="--version"},
    @{Name="Go"; Cmd="go"; Args="version"},
    @{Name="Docker"; Cmd="docker"; Args="--version"}
)

foreach ($tool in $tools) {
    try {
        $version = & $tool.Cmd $tool.Args 2>&1
        if ($LASTEXITCODE -eq 0 -or $version) {
            $version = $version -replace '^.*?(\d+\.\d+.*?)$', '$1' -replace 'version ', ''
            Write-Host "  ${Green}✓${NC} $($tool.Name): ${Cyan}$version${NC}"
        }
    } catch {
        Write-Host "  ${Gray}✗${NC} $($tool.Name): ${Gray}No instalado${NC}"
    }
}

Write-Host ""
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host ""
Read-Host "Presiona Enter para volver al launcher..."
