param(
    [string]$Profile = "apps/apps-all.json",
    [switch]$InteractiveSelection
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$rootPath = Split-Path -Parent $PSCommandPath
$helpersPath = Join-Path $rootPath "scripts\helpers.ps1"
. $helpersPath

$argumentList = @(
    "-NoProfile"
    "-ExecutionPolicy"
    "Bypass"
    "-File"
    "`"$PSCommandPath`""
    "-Profile"
    "`"$Profile`""
    $(if ($InteractiveSelection.IsPresent) { "-InteractiveSelection" })
) -join " "

Ensure-Admin -ScriptPath $PSCommandPath -ArgumentList $argumentList

$resolvedProfilePath = if ([System.IO.Path]::IsPathRooted($Profile)) {
    $Profile
}
else {
    Join-Path $rootPath $Profile
}

if (-not (Test-Path -LiteralPath $resolvedProfilePath)) {
    Write-Error "Profile file not found: $resolvedProfilePath"
    exit 1
}

$isInteractiveSelection = $true
if ($InteractiveSelection.IsPresent) {
    $isInteractiveSelection = $true
}

$null = Start-SetupLog -RootPath $rootPath

try {
    Write-Section "WinCore Bootstrap Started"
    Write-Step "Using profile: $resolvedProfilePath"

    $windowsUpdateScript = Join-Path $rootPath "scripts\windows-update.ps1"
    $installWingetScript = Join-Path $rootPath "scripts\install-winget.ps1"
    $installAppsScript = Join-Path $rootPath "scripts\install-apps.ps1"

    Write-Section "Step 1 of 4: Windows Update"
    & $windowsUpdateScript

    Write-Section "Step 2 of 4: Ensure Winget"
    & $installWingetScript

    Write-Section "Step 3 of 4: Install Profile Apps"
    & $installAppsScript -ProfilePath $resolvedProfilePath -InteractiveSelection:$isInteractiveSelection

    Write-Section "Step 4 of 4: Upgrade Installed Packages"
    Write-Step "Running: winget upgrade --all"
    winget upgrade --all --accept-package-agreements --accept-source-agreements --disable-interactivity
    Write-Success "Package upgrade pass completed."

    Write-Section "Setup Completed"
    Write-Success "WinCore bootstrap finished successfully."
}
catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    throw
}
finally {
    Stop-Transcript | Out-Null
}
