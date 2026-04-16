param(
    [Parameter(Mandatory = $true)]
    [string]$ProfilePath,
    [int]$MaxRetries = 3,
    [int]$RetryDelaySeconds = 8,
    [switch]$InteractiveSelection
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDirectory = Split-Path -Parent $PSCommandPath
$projectRoot = Split-Path -Parent $scriptDirectory
$downloadDirectory = Join-Path $projectRoot "downloads"
. (Join-Path $scriptDirectory "helpers.ps1")

function Get-AppDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$AppEntry
    )

    if ($AppEntry -is [string]) {
        return [PSCustomObject]@{
            Type                 = "winget"
            Name                 = $AppEntry
            Id                   = $AppEntry
            Source               = $null
            Url                  = $null
            SourceUrl            = $null
            SourceUrls           = @()
            UrlPattern           = $null
            UrlPatterns          = @()
            AllowedDomains       = @()
            ResolveLatest        = $false
            FileName             = $null
            Arguments            = $null
            WaitForExit          = $false
            InstalledCheckWinget = $null
            InstalledCheckPath   = $null
        }
    }

    if ($AppEntry.PSObject.Properties.Name -contains "id") {
        $name = if ($AppEntry.PSObject.Properties.Name -contains "name" -and -not [string]::IsNullOrWhiteSpace([string]$AppEntry.name)) {
            [string]$AppEntry.name
        }
        else {
            [string]$AppEntry.id
        }

        return [PSCustomObject]@{
            Type                 = "winget"
            Name                 = $name
            Id                   = [string]$AppEntry.id
            Source               = $(if ($AppEntry.PSObject.Properties.Name -contains "source") { [string]$AppEntry.source } else { $null })
            Url                  = $null
            SourceUrl            = $null
            SourceUrls           = @()
            UrlPattern           = $null
            UrlPatterns          = @()
            AllowedDomains       = @()
            ResolveLatest        = $false
            FileName             = $null
            Arguments            = $null
            WaitForExit          = $false
            InstalledCheckWinget = $null
            InstalledCheckPath   = $null
        }
    }

    $hasType = $AppEntry.PSObject.Properties.Name -contains "type"
    $hasUrl = $AppEntry.PSObject.Properties.Name -contains "url"
    if ($hasType -and $hasUrl -and [string]$AppEntry.type -eq "download-run") {
        $displayName = if ($AppEntry.PSObject.Properties.Name -contains "name" -and -not [string]::IsNullOrWhiteSpace([string]$AppEntry.name)) {
            [string]$AppEntry.name
        }
        else {
            [string]$AppEntry.url
        }

        $waitForExit = $true
        if ($AppEntry.PSObject.Properties.Name -contains "waitForExit") {
            $waitForExit = [bool]$AppEntry.waitForExit
        }

        $fileName = $null
        if ($AppEntry.PSObject.Properties.Name -contains "fileName" -and -not [string]::IsNullOrWhiteSpace([string]$AppEntry.fileName)) {
            $fileName = [string]$AppEntry.fileName
        }

        $arguments = $null
        if ($AppEntry.PSObject.Properties.Name -contains "arguments" -and -not [string]::IsNullOrWhiteSpace([string]$AppEntry.arguments)) {
            $arguments = [string]$AppEntry.arguments
        }

        $installedCheckWinget = $null
        if ($AppEntry.PSObject.Properties.Name -contains "installedCheckWingetId" -and -not [string]::IsNullOrWhiteSpace([string]$AppEntry.installedCheckWingetId)) {
            $installedCheckWinget = [string]$AppEntry.installedCheckWingetId
        }

        $installedCheckPath = $null
        if ($AppEntry.PSObject.Properties.Name -contains "installedCheckPath" -and -not [string]::IsNullOrWhiteSpace([string]$AppEntry.installedCheckPath)) {
            $installedCheckPath = [string]$AppEntry.installedCheckPath
        }

        $sourceUrl = $null
        if ($AppEntry.PSObject.Properties.Name -contains "sourceUrl" -and -not [string]::IsNullOrWhiteSpace([string]$AppEntry.sourceUrl)) {
            $sourceUrl = [string]$AppEntry.sourceUrl
        }

        $urlPattern = $null
        if ($AppEntry.PSObject.Properties.Name -contains "urlPattern" -and -not [string]::IsNullOrWhiteSpace([string]$AppEntry.urlPattern)) {
            $urlPattern = [string]$AppEntry.urlPattern
        }

        $resolveLatest = $false
        if ($AppEntry.PSObject.Properties.Name -contains "resolveLatest") {
            $resolveLatest = [bool]$AppEntry.resolveLatest
        }

        $sourceUrls = New-Object System.Collections.Generic.List[string]
        if (-not [string]::IsNullOrWhiteSpace($sourceUrl)) {
            $sourceUrls.Add($sourceUrl)
        }
        if ($AppEntry.PSObject.Properties.Name -contains "sourceUrls" -and $AppEntry.sourceUrls) {
            foreach ($item in @($AppEntry.sourceUrls)) {
                $value = [string]$item
                if (-not [string]::IsNullOrWhiteSpace($value) -and -not $sourceUrls.Contains($value)) {
                    $sourceUrls.Add($value)
                }
            }
        }

        $urlPatterns = New-Object System.Collections.Generic.List[string]
        if (-not [string]::IsNullOrWhiteSpace($urlPattern)) {
            $urlPatterns.Add($urlPattern)
        }
        if ($AppEntry.PSObject.Properties.Name -contains "urlPatterns" -and $AppEntry.urlPatterns) {
            foreach ($item in @($AppEntry.urlPatterns)) {
                $value = [string]$item
                if (-not [string]::IsNullOrWhiteSpace($value) -and -not $urlPatterns.Contains($value)) {
                    $urlPatterns.Add($value)
                }
            }
        }

        $allowedDomains = New-Object System.Collections.Generic.List[string]
        if ($AppEntry.PSObject.Properties.Name -contains "allowedDomains" -and $AppEntry.allowedDomains) {
            foreach ($item in @($AppEntry.allowedDomains)) {
                $value = [string]$item
                if (-not [string]::IsNullOrWhiteSpace($value) -and -not $allowedDomains.Contains($value)) {
                    $allowedDomains.Add($value.ToLowerInvariant())
                }
            }
        }

        return [PSCustomObject]@{
            Type                 = "download-run"
            Name                 = $displayName
            Id                   = $null
            Source               = $null
            Url                  = [string]$AppEntry.url
            SourceUrl            = $sourceUrl
            SourceUrls           = $sourceUrls.ToArray()
            UrlPattern           = $urlPattern
            UrlPatterns          = $urlPatterns.ToArray()
            AllowedDomains       = $allowedDomains.ToArray()
            ResolveLatest        = $resolveLatest
            FileName             = $fileName
            Arguments            = $arguments
            WaitForExit          = $waitForExit
            InstalledCheckWinget = $installedCheckWinget
            InstalledCheckPath   = $installedCheckPath
        }
    }

    throw "Invalid app entry format. Use {'id':'<winget-id>'} or {'type':'download-run','url':'<installer-url>'}."
}

function Get-AppDisplayName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$AppDefinition
    )

    if ($AppDefinition.Type -eq "winget") {
        return $AppDefinition.Id
    }

    return $AppDefinition.Name
}

function Test-WingetAppInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppId
    )

    $result = winget list --id $AppId -e 2>$null | Out-String
    if ($result -match "No installed package found") {
        return $false
    }

    return ($result -match [Regex]::Escape($AppId))
}

function Test-AppDefinitionInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$AppDefinition
    )

    if ($AppDefinition.Type -eq "winget") {
        return (Test-WingetAppInstalled -AppId $AppDefinition.Id)
    }

    if (-not [string]::IsNullOrWhiteSpace($AppDefinition.InstalledCheckWinget)) {
        return (Test-WingetAppInstalled -AppId $AppDefinition.InstalledCheckWinget)
    }

    if (-not [string]::IsNullOrWhiteSpace($AppDefinition.InstalledCheckPath)) {
        return (Test-Path -LiteralPath $AppDefinition.InstalledCheckPath)
    }

    return $false
}

function Install-WingetAppWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppId,
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [int]$Retries,
        [Parameter(Mandatory = $true)]
        [int]$DelaySeconds
    )

    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            Write-Step "Installing $AppId (attempt $attempt/$Retries)..."
            if (-not [string]::IsNullOrWhiteSpace($Source)) {
                winget install -e --id $AppId --source $Source --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
            }
            else {
                winget install -e --id $AppId --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
            }
            Write-Success "$AppId installed successfully."
            return $true
        }
        catch {
            if ($attempt -lt $Retries) {
                Write-Error ("Install failed for {0} on attempt {1}: {2}" -f $AppId, $attempt, $_.Exception.Message)
                Write-Step "Retrying in $DelaySeconds seconds..."
                Start-Sleep -Seconds $DelaySeconds
            }
            else {
                Write-Error "Install failed for $AppId after $Retries attempts."
                return $false
            }
        }
    }

    return $false
}

function Resolve-InstallerFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$AppDefinition
    )

    if (-not [string]::IsNullOrWhiteSpace($AppDefinition.FileName)) {
        return $AppDefinition.FileName
    }

    try {
        $uri = [Uri]$AppDefinition.Url
        $leaf = Split-Path -Leaf $uri.AbsolutePath
        if (-not [string]::IsNullOrWhiteSpace($leaf)) {
            if ($leaf.Contains(".")) {
                return $leaf
            }

            return "$leaf.exe"
        }
    }
    catch {
        # No-op: fallback file name below.
    }

    $safeName = ($AppDefinition.Name -replace "[^a-zA-Z0-9\-_.]", "-")
    if ([string]::IsNullOrWhiteSpace($safeName)) {
        $safeName = "installer"
    }

    return "$safeName.exe"
}

function Convert-ToAbsoluteUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RawUrl,
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl
    )

    if ([string]::IsNullOrWhiteSpace($RawUrl)) {
        return $null
    }

    $trimmed = $RawUrl.Trim()
    if ($trimmed.StartsWith("//")) {
        return "https:$trimmed"
    }

    try {
        $uri = [Uri]$trimmed
        if ($uri.IsAbsoluteUri) {
            return $uri.AbsoluteUri
        }
    }
    catch {
        # Continue with base URL resolution.
    }

    try {
        $baseUri = [Uri]$BaseUrl
        return ([Uri]::new($baseUri, $trimmed)).AbsoluteUri
    }
    catch {
        return $null
    }
}

function Get-VersionFromUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    $match = [regex]::Match($Url, "([0-9]+(?:\.[0-9]+){1,})")
    if ($match.Success) {
        try {
            return [version]$match.Groups[1].Value
        }
        catch {
            return [version]"0.0.0.0"
        }
    }

    return [version]"0.0.0.0"
}

function Get-AllowedDomainMap {
    [CmdletBinding()]
    param(
        [string[]]$AllowedDomains
    )

    $map = @{}
    foreach ($domain in @($AllowedDomains)) {
        if (-not [string]::IsNullOrWhiteSpace($domain)) {
            $map[$domain.ToLowerInvariant()] = $true
        }
    }

    return $map
}

function Test-UrlDomainAllowed {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [hashtable]$AllowedDomainMap
    )

    if ($AllowedDomainMap.Count -eq 0) {
        return $true
    }

    try {
        $host = ([Uri]$Url).Host.ToLowerInvariant()
    }
    catch {
        return $false
    }

    foreach ($domain in $AllowedDomainMap.Keys) {
        if ($host -eq $domain -or $host.EndsWith(".$domain")) {
            return $true
        }
    }

    return $false
}

function Resolve-LatestInstallerUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$AppDefinition
    )

    $sourceUrls = @($AppDefinition.SourceUrls)
    if (($sourceUrls.Count -eq 0) -and -not [string]::IsNullOrWhiteSpace($AppDefinition.SourceUrl)) {
        $sourceUrls = @($AppDefinition.SourceUrl)
    }

    $urlPatterns = @($AppDefinition.UrlPatterns)
    if (($urlPatterns.Count -eq 0) -and -not [string]::IsNullOrWhiteSpace($AppDefinition.UrlPattern)) {
        $urlPatterns = @($AppDefinition.UrlPattern)
    }

    if ($sourceUrls.Count -eq 0 -or $urlPatterns.Count -eq 0) {
        throw "resolveLatest requires at least one source URL and one URL pattern."
    }

    $allowedDomainMap = Get-AllowedDomainMap -AllowedDomains $AppDefinition.AllowedDomains
    $candidateMap = @{}

    foreach ($sourceUrl in $sourceUrls) {
        try {
            Write-Step "Resolving latest from source: $sourceUrl"
            $response = Invoke-WebRequest -Uri $sourceUrl
            $content = $response.Content

            foreach ($pattern in $urlPatterns) {
                foreach ($match in [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                    $absoluteUrl = Convert-ToAbsoluteUrl -RawUrl $match.Value -BaseUrl $sourceUrl
                    if (-not [string]::IsNullOrWhiteSpace($absoluteUrl) -and (Test-UrlDomainAllowed -Url $absoluteUrl -AllowedDomainMap $allowedDomainMap)) {
                        $candidateMap[$absoluteUrl] = $true
                    }
                }
            }

            # Fallback scan: parse all href/src links and keep only .exe from allowed domains.
            foreach ($token in [regex]::Matches($content, "(?i)(?:href|src)\\s*=\\s*['""]([^'""]+)['""]")) {
                $rawUrl = $token.Groups[1].Value
                $absoluteUrl = Convert-ToAbsoluteUrl -RawUrl $rawUrl -BaseUrl $sourceUrl
                if ([string]::IsNullOrWhiteSpace($absoluteUrl)) {
                    continue
                }

                if ($absoluteUrl -notmatch "(?i)\\.exe(?:\\?|$)") {
                    continue
                }

                if (Test-UrlDomainAllowed -Url $absoluteUrl -AllowedDomainMap $allowedDomainMap) {
                    $candidateMap[$absoluteUrl] = $true
                }
            }
        }
        catch {
            Write-Error ("Failed to query source {0}: {1}" -f $sourceUrl, $_.Exception.Message)
        }
    }

    if ($candidateMap.Count -eq 0) {
        throw "Could not resolve a candidate installer URL from any source."
    }

    $best = (
        $candidateMap.Keys |
        ForEach-Object {
            [PSCustomObject]@{
                Url     = $_
                Version = Get-VersionFromUrl -Url $_
            }
        } |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1
    )

    return $best.Url
}

function Install-DownloadedInstallerWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$AppDefinition,
        [Parameter(Mandatory = $true)]
        [int]$Retries,
        [Parameter(Mandatory = $true)]
        [int]$DelaySeconds
    )

    if (-not (Test-Path -LiteralPath $downloadDirectory)) {
        New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null
    }

    $fileName = Resolve-InstallerFileName -AppDefinition $AppDefinition
    $appName = Get-AppDisplayName -AppDefinition $AppDefinition

    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            $effectiveUrl = $AppDefinition.Url
            if ($AppDefinition.ResolveLatest) {
                $effectiveUrl = Resolve-LatestInstallerUrl -AppDefinition $AppDefinition
                Write-Step "Resolved latest URL: $effectiveUrl"
            }

            $effectiveDefinition = [PSCustomObject]@{
                Type                 = $AppDefinition.Type
                Name                 = $AppDefinition.Name
                Id                   = $AppDefinition.Id
                Url                  = $effectiveUrl
                SourceUrl            = $AppDefinition.SourceUrl
                SourceUrls           = $AppDefinition.SourceUrls
                UrlPattern           = $AppDefinition.UrlPattern
                UrlPatterns          = $AppDefinition.UrlPatterns
                AllowedDomains       = $AppDefinition.AllowedDomains
                ResolveLatest        = $AppDefinition.ResolveLatest
                FileName             = $AppDefinition.FileName
                Arguments            = $AppDefinition.Arguments
                WaitForExit          = $AppDefinition.WaitForExit
                InstalledCheckWinget = $AppDefinition.InstalledCheckWinget
                InstalledCheckPath   = $AppDefinition.InstalledCheckPath
            }

            $effectiveFileName = Resolve-InstallerFileName -AppDefinition $effectiveDefinition
            $downloadPath = Join-Path $downloadDirectory $effectiveFileName

            Write-Step "Downloading $appName (attempt $attempt/$Retries)..."
            Invoke-WebRequest -Uri $effectiveUrl -OutFile $downloadPath

            Write-Step "Launching installer: $downloadPath"
            $startProcessArgs = @{
                FilePath = $downloadPath
                PassThru = $true
            }

            if (-not [string]::IsNullOrWhiteSpace($AppDefinition.Arguments)) {
                $startProcessArgs["ArgumentList"] = $AppDefinition.Arguments
            }

            if ($AppDefinition.WaitForExit) {
                $startProcessArgs["Wait"] = $true
            }

            $process = Start-Process @startProcessArgs

            if ($AppDefinition.WaitForExit -and $process.ExitCode -ne 0) {
                throw "Installer exited with code $($process.ExitCode)."
            }

            Write-Success "$appName installer started successfully."
            return $true
        }
        catch {
            if ($attempt -lt $Retries) {
                Write-Error ("Download/install failed for {0} on attempt {1}: {2}" -f $appName, $attempt, $_.Exception.Message)
                Write-Step "Retrying in $DelaySeconds seconds..."
                Start-Sleep -Seconds $DelaySeconds
            }
            else {
                Write-Error "Download/install failed for $appName after $Retries attempts."
                return $false
            }
        }
    }

    return $false
}

function Remove-OtherJavaPackages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PreferredJavaId
    )

    $javaPackageIds = @(
        "EclipseAdoptium.Temurin.8.JDK",
        "EclipseAdoptium.Temurin.11.JDK",
        "EclipseAdoptium.Temurin.17.JDK",
        "EclipseAdoptium.Temurin.21.JDK",
        "EclipseAdoptium.Temurin.22.JDK",
        "Microsoft.OpenJDK.11",
        "Microsoft.OpenJDK.17",
        "Microsoft.OpenJDK.21",
        "Oracle.JDK.17",
        "Oracle.JDK.21",
        "Oracle.JDK.22",
        "Oracle.JDK.23",
        "Oracle.JDK.24",
        "Oracle.JDK.25",
        "Oracle.JDK.26",
        "Oracle.JavaRuntimeEnvironment",
        "BellSoft.LibericaJDK.17",
        "BellSoft.LibericaJDK.21"
    )

    foreach ($javaId in $javaPackageIds) {
        if ($javaId -eq $PreferredJavaId) {
            continue
        }

        if (Test-WingetAppInstalled -AppId $javaId) {
            Write-Step "Removing non-target Java package: $javaId"
            winget uninstall -e --id $javaId --accept-source-agreements --disable-interactivity
            Write-Success "Removed $javaId"
        }
    }
}

function Select-AppsInteractively {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$AppDefinitions
    )

    $selectedApps = New-Object System.Collections.Generic.List[object]
    $totalApps = $AppDefinitions.Count

    Write-Section "Interactive App Selection"
    Write-Step "Choose Y or N for each app. Default is N."

    for ($index = 0; $index -lt $totalApps; $index++) {
        $definition = $AppDefinitions[$index]
        $displayName = Get-AppDisplayName -AppDefinition $definition
        $counter = "[{0}/{1}]" -f ($index + 1), $totalApps

        $response = ""
        while ($true) {
            $response = Read-Host ("{0} Install {1}? (Y/N)" -f $counter, $displayName)
            if ([string]::IsNullOrWhiteSpace($response)) {
                $response = "N"
            }

            $normalized = $response.Trim().ToUpperInvariant()
            if ($normalized -in @("Y", "YES", "N", "NO")) {
                if ($normalized -in @("Y", "YES")) {
                    $selectedApps.Add($definition)
                    Write-Success "$counter Selected $displayName"
                }
                else {
                    Write-Step "$counter Skipped $displayName"
                }

                break
            }

            Write-Error "Invalid input. Enter Y or N."
        }
    }

    Write-Step ("Selected {0} out of {1} apps." -f $selectedApps.Count, $totalApps)
    return $selectedApps.ToArray()
}

try {
    if (-not (Test-Path -LiteralPath $ProfilePath)) {
        throw "Profile file not found: $ProfilePath"
    }

    Write-Step "Loading app profile: $ProfilePath"
    $profileData = Get-Content -LiteralPath $ProfilePath -Raw | ConvertFrom-Json
    $appEntries = if ($profileData -is [System.Array]) { $profileData } else { $profileData.apps }
    $appEntries = @($appEntries)

    if (-not $appEntries -or $appEntries.Count -eq 0) {
        throw "No applications found in profile."
    }

    $appDefinitions = @(
        foreach ($entry in $appEntries) {
            Get-AppDefinition -AppEntry $entry
        }
    )

    if ($InteractiveSelection.IsPresent) {
        $appDefinitions = Select-AppsInteractively -AppDefinitions $appDefinitions
    }

    if (-not $appDefinitions -or $appDefinitions.Count -eq 0) {
        Write-Step "No applications selected. Nothing to install."
        return
    }

    $failedApps = New-Object System.Collections.Generic.List[string]
    $total = $appDefinitions.Count

    for ($index = 0; $index -lt $total; $index++) {
        $definition = $appDefinitions[$index]
        $displayName = Get-AppDisplayName -AppDefinition $definition
        $counter = "[{0}/{1}]" -f ($index + 1), $total
        Write-Step "$counter Processing $displayName"

            if ($definition.Type -eq "winget" -and $definition.Id -eq "Oracle.JDK.26") {
            Write-Step "$counter Enforcing Oracle.JDK.26 as the only Java package."
            Remove-OtherJavaPackages -PreferredJavaId "Oracle.JDK.26"
        }

        if (Test-AppDefinitionInstalled -AppDefinition $definition) {
            Write-Step "$counter $displayName already installed. Skipping."
            continue
        }

        $installed = $false
        if ($definition.Type -eq "winget") {
            $installed = Install-WingetAppWithRetry -AppId $definition.Id -Source $definition.Source -Retries $MaxRetries -DelaySeconds $RetryDelaySeconds
        }
        elseif ($definition.Type -eq "download-run") {
            $installed = Install-DownloadedInstallerWithRetry -AppDefinition $definition -Retries $MaxRetries -DelaySeconds $RetryDelaySeconds
        }
        else {
            throw "Unsupported app type: $($definition.Type)"
        }

        if (-not $installed) {
            $failedApps.Add($displayName)
        }
    }

    if ($failedApps.Count -gt 0) {
        $failedList = $failedApps -join ", "
        throw "Some applications failed to install: $failedList"
    }

    Write-Success "All selected applications processed successfully."
}
catch {
    Write-Error "Application install step failed: $($_.Exception.Message)"
    throw
}
