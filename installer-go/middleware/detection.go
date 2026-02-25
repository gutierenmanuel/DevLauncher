package middleware

import (
"os"
"path/filepath"

"github.com/lucas/installer/core"
)

// DetectExistingInstall checks if an installation already exists at installDir.
func DetectExistingInstall(installDir string) (*core.ExistingInstall, error) {
versionFile := filepath.Join(installDir, "VERSION.txt")
data, err := os.ReadFile(versionFile)
if os.IsNotExist(err) {
return nil, nil
}
if err != nil {
return nil, err
}
return &core.ExistingInstall{
Dir:     installDir,
Version: core.ParseVersion(string(data)),
}, nil
}

// RemoveInstallDir deletes the entire installation directory.
func RemoveInstallDir(installDir string) error {
return os.RemoveAll(installDir)
}
