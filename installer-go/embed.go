// embed.go — Este archivo está intencionalmente vacío.
//
// La declaración de assetsFS se hace por plataforma en:
//
//	embed_linux.go   (//go:build linux)   → assets/launcher-linux + assets/uninstaller-linux
//	embed_windows.go (//go:build windows) → assets/launcher.exe   + assets/uninstaller.exe
//	embed_darwin.go  (//go:build darwin)  → assets/launcher-mac
//
// Cada archivo embebe únicamente los binarios necesarios para su OS objetivo,
// evitando que un installer arrastre los launchers de las otras plataformas.
package main
