Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDirectory = Split-Path -Parent $PSCommandPath
. (Join-Path $scriptDirectory "helpers.ps1")

try {
    $wingetCommand = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCommand) {
        Write-Step "winget is already installed."
        Write-Success "winget check completed."
        return
    }

    Write-Step "winget not detected. Launching App Installer source URL."
    Start-Process -FilePath "explorer.exe" -ArgumentList "ms-appinstaller:?source=https://aka.ms/getwinget"

    Write-Step "Waiting for winget installation to become available..."
    $maxAttempts = 30
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        Start-Sleep -Seconds 5
        $wingetCommand = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCommand) {
            Write-Success "winget detected after installation trigger."
            return
        }
    }

    throw "winget was not detected after waiting. Complete installation manually, then rerun setup."
}
catch {
    Write-Error "winget setup failed: $($_.Exception.Message)"
    throw
}
