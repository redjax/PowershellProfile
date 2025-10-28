<#
    .SYNOPSIS
    Install the Monolith PowerShell profile.

    .DESCRIPTION
    Installs the self-contained Monolith.ps1 profile to $PROFILE.
    This profile does not require any modules or additional files.

    .PARAMETER Force
    Overwrite existing profile without prompting for confirmation.

    .EXAMPLE
    .\Install-MonoProfile.ps1
    Installs the Monolith profile, prompting for confirmation if profile exists.

    .EXAMPLE
    .\Install-MonoProfile.ps1 -Force
    Installs the Monolith profile, overwriting existing profile without prompting.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false, HelpMessage = "Overwrite existing profile without prompting")]
    [switch]$Force
)

## Variables
$ScriptRoot = $PSScriptRoot
$MonolithProfilePath = Join-Path $ScriptRoot "Profiles\Monolith.ps1"
$DestinationPath = $PROFILE

Write-Host "`n=== Monolith Profile Installer ===" -ForegroundColor Cyan
Write-Host "Source: $MonolithProfilePath" -ForegroundColor Gray
Write-Host "Destination: $DestinationPath" -ForegroundColor Gray
Write-Host ""

## Check if source profile exists
if (-not (Test-Path $MonolithProfilePath)) {
    Write-Error "Monolith.ps1 not found at: $MonolithProfilePath"
    exit 1
}

## Ensure destination directory exists
$ProfileDirectory = Split-Path $DestinationPath -Parent
if (-not (Test-Path $ProfileDirectory)) {
    Write-Host "Creating profile directory: $ProfileDirectory" -ForegroundColor Yellow
    try {
        New-Item -Path $ProfileDirectory -ItemType Directory -Force | Out-Null
        Write-Host "✓ Profile directory created" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create profile directory: $($_.Exception.Message)"
        exit 1
    }
}

## Check if profile already exists
if (Test-Path $DestinationPath) {
    if (-not $Force) {
        Write-Warning "A profile already exists at: $DestinationPath"
        $response = Read-Host "Do you want to back up and overwrite it? (Y/N)"
        if ($response -ne 'Y' -and $response -ne 'y') {
            Write-Host "Installation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    
    ## Backup existing profile
    $BackupPath = "$DestinationPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "Backing up existing profile to: $BackupPath" -ForegroundColor Yellow
    try {
        Copy-Item -Path $DestinationPath -Destination $BackupPath -Force
        Write-Host "✓ Backup created" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to backup existing profile: $($_.Exception.Message)"
        exit 1
    }
}

## Install the Monolith profile
Write-Host "Installing Monolith profile..." -ForegroundColor Cyan
try {
    Copy-Item -Path $MonolithProfilePath -Destination $DestinationPath -Force
    Write-Host "✓ Monolith profile installed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to install profile: $($_.Exception.Message)"
    exit 1
}

## Summary
Write-Host "`n=== Installation Complete ===" -ForegroundColor Green
Write-Host "Profile location: $DestinationPath" -ForegroundColor Gray
Write-Host "`nTo activate the new profile:" -ForegroundColor Cyan
Write-Host "  1. Restart your PowerShell session, or" -ForegroundColor Gray
Write-Host "  2. Run: . `$PROFILE" -ForegroundColor Gray
Write-Host ""

exit 0
