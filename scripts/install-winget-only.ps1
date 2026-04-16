Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$wingetApps = @(
    @{ Id = "Microsoft.VisualStudioCode" },
    @{ Id = "Git.Git" },
    @{ Id = "GitHub.cli" },
    @{ Id = "GnuPG.GnuPG" },
    @{ Id = "sharkdp.bat" },
    @{ Id = "ajeetdsouza.zoxide" },
    @{ Id = "OpenJS.NodeJS" },
    @{ Id = "Oracle.JDK.26" },
    @{ Id = "Python.Python.3.12" },
    @{ Id = "Google.Chrome" },
    @{ Id = "VideoLAN.VLC" },
    @{ Id = "JanDeDobbeleer.OhMyPosh" },
    @{ Id = "Google.GoogleDrive" },
    @{ Id = "Guru3D.Afterburner" },
    @{ Id = "Valve.Steam" },
    @{ Id = "EpicGames.EpicGamesLauncher" },
    @{ Id = "ElectronicArts.EADesktop" },
    @{ Id = "9PFHDD62MXS1"; Source = "msstore" } # Apple Music
)

foreach ($app in $wingetApps) {
    $appId = [string]$app.Id
    if ([string]::IsNullOrWhiteSpace($appId)) {
        continue
    }

    if ($app.ContainsKey("Source")) {
        $source = [string]$app.Source
        Write-Host "[STEP] Installing $appId from source $source" -ForegroundColor Yellow
        winget install -e --id $appId --source $source --accept-source-agreements --accept-package-agreements --disable-interactivity
    }
    else {
        Write-Host "[STEP] Installing $appId" -ForegroundColor Yellow
        winget install -e --id $appId --accept-source-agreements --accept-package-agreements --disable-interactivity
    }
}

Write-Host "[OK] Winget-only install pass complete." -ForegroundColor Green
