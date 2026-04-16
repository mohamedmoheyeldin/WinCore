Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDirectory = Split-Path -Parent $PSCommandPath
$projectRoot = Split-Path -Parent $scriptDirectory
. (Join-Path $scriptDirectory "helpers.ps1")

try {
    Write-Step "Checking PSWindowsUpdate module."
    Write-Step "Ensuring NuGet provider is available."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null

    Write-Step "Ensuring PSGallery repository is trusted."
    $psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if (-not $psGallery) {
        Register-PSRepository -Default -ErrorAction Stop
    }
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop

    $moduleAvailable = Get-Module -ListAvailable -Name PSWindowsUpdate
    if (-not $moduleAvailable) {
        Write-Step "PSWindowsUpdate not found. Installing module..."
        Install-Module -Name PSWindowsUpdate -Scope CurrentUser -Force -AllowClobber -Repository PSGallery
        Write-Success "PSWindowsUpdate module installed."
    }
    else {
        Write-Step "PSWindowsUpdate module already present."
    }

    Import-Module PSWindowsUpdate -Force
    Write-Step "Searching and installing Windows updates (no forced reboot)."
    Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot
    Write-Success "Windows update pass completed."
}
catch {
    Write-Error "Windows update step failed: $($_.Exception.Message)"
    throw
}
