# WinCore

## Project Overview
WinCore is a production-ready Windows bootstrap automation system built with PowerShell and winget. It supports repeatable workstation provisioning using profile-based application sets, modular scripts, and structured logging.

## Features
- Administrator auto-elevation at startup
- Transcript-based logging to `logs\`
- Windows update execution via `PSWindowsUpdate`
- Automatic winget detection and install trigger
- Single master app list (`apps-all.json`)
- Interactive app selection with per-app Y/N prompts
- Idempotent install flow with installed-app checks
- Retry logic for transient install failures
- Final full-system package upgrade using winget
- Clean sectioned console output with color

## Folder Structure
```text
WinCore/
|
|-- setup.ps1
|-- README.md
|-- .gitignore
|
|-- apps/
|   |-- apps-all.json
|
|-- scripts/
    |-- helpers.ps1
    |-- install-winget.ps1
    |-- windows-update.ps1
    |-- install-apps.ps1
```

## Usage
Run from `D:\projects\WinCore` in PowerShell:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\setup.ps1
```

`setup.ps1` uses `apps/apps-all.json` and prompts you to choose each app.

## Example commands
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\setup.ps1
.\setup.ps1 -Profile apps/apps-all.json
.\setup.ps1 -Profile apps/apps-all.json -InteractiveSelection
```
