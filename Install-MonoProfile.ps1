<#
    .SYNOPSIS
    Install the Monolith PowerShell profile and its component files.

    .DESCRIPTION
    Installs the Monolith.ps1 profile and ProfileComponents directory to the $PROFILE directory.
    
    The ProfileComponents directory contains:
    - namespaces.ps1: Type shortcuts
    - psreadline-handlers.ps1: Advanced key bindings
    - prompt.ps1: Starship prompt initialization
    - shell-completions.ps1: CLI tool completions
    - aliases.ps1: Unix-like aliases and functions
    - software-init.ps1: Third-party tool initialization

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
$MonolithSourceDir = Join-Path $ScriptRoot "Profiles\Monolith"
$ComponentsSourceDir = Join-Path $MonolithSourceDir "ProfileComponents"
$MonolithProfilePath = Join-Path $MonolithSourceDir "Monolith.ps1"
$DestinationPath = $PROFILE
$DestinationDir = Split-Path $DestinationPath -Parent
$ComponentsDestDir = Join-Path $DestinationDir "ProfileComponents"

Write-Host "`n=== Monolith Profile Installer ===" -ForegroundColor Cyan
Write-Host "Source Directory: $MonolithSourceDir" -ForegroundColor Gray
Write-Host "Destination: $DestinationPath" -ForegroundColor Gray
Write-Host ""

## Check if source directory exists
if (-not (Test-Path $MonolithSourceDir)) {
    Write-Error "Monolith directory not found at: $MonolithSourceDir"
    exit 1
}

## Check if ProfileComponents directory exists
if (-not (Test-Path $ComponentsSourceDir)) {
    Write-Error "ProfileComponents directory not found at: $ComponentsSourceDir"
    exit 1
}

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
        Write-Host "Profile directory created" -ForegroundColor Green
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
        $backupResponse = Read-Host "Do you want to create a backup before installing? (Y/N)"
        
        if ($backupResponse -eq 'Y' -or $backupResponse -eq 'y') {
            ## Backup existing profile
            $BackupPath = "$DestinationPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Write-Host "Backing up existing profile to: $BackupPath" -ForegroundColor Yellow
            try {
                Copy-Item -Path $DestinationPath -Destination $BackupPath -Force
                Write-Host "  Backup created successfully" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to backup existing profile: $($_.Exception.Message)"
                exit 1
            }
        }
        else {
            Write-Host "Skipping backup - profile will be overwritten" -ForegroundColor Yellow
        }
    }
    else {
        ## Force flag is set - create backup automatically without prompting
        $BackupPath = "$DestinationPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Write-Host "Force flag set - backing up existing profile to: $BackupPath" -ForegroundColor Yellow
        try {
            Copy-Item -Path $DestinationPath -Destination $BackupPath -Force
            Write-Host "  Backup created successfully" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to backup existing profile: $($_.Exception.Message)"
            Write-Host "  Continuing with installation..." -ForegroundColor Yellow
        }
    }
}

## Install the Monolith profile
Write-Host "Installing Monolith profile" -ForegroundColor Cyan
try {
    Copy-Item -Path $MonolithProfilePath -Destination $DestinationPath -Force
    Write-Host "  Monolith.ps1 copied" -ForegroundColor Green
}
catch {
    Write-Error "Failed to install profile: $($_.Exception.Message)"
    exit 1
}

## Install ProfileComponents directory
Write-Host "Installing ProfileComponents directory" -ForegroundColor Cyan
try {
    # Create ProfileComponents directory if it doesn't exist
    if (-not (Test-Path $ComponentsDestDir)) {
        New-Item -Path $ComponentsDestDir -ItemType Directory -Force | Out-Null
        Write-Host "  Created ProfileComponents directory" -ForegroundColor Green
    }
    
    # Copy all component files (root level)
    $componentFiles = Get-ChildItem -Path $ComponentsSourceDir -File
    $installedCount = 0
    $failedCount = 0
    
    foreach ($file in $componentFiles) {
        try {
            Copy-Item -Path $file.FullName -Destination $ComponentsDestDir -Force
            Write-Host "  $($file.Name)" -ForegroundColor Green
            $installedCount++
        }
        catch {
            Write-Warning "  Failed to copy $($file.Name): $($_.Exception.Message)"
            $failedCount++
        }
    }
    
    # Copy subdirectories (like functions/)
    $componentDirs = Get-ChildItem -Path $ComponentsSourceDir -Directory
    foreach ($dir in $componentDirs) {
        try {
            $destSubDir = Join-Path $ComponentsDestDir $dir.Name
            # Create the destination subdirectory if it doesn't exist
            if (-not (Test-Path $destSubDir)) {
                New-Item -Path $destSubDir -ItemType Directory -Force | Out-Null
            }
            # Copy contents of the directory, not the directory itself
            Copy-Item -Path "$($dir.FullName)\*" -Destination $destSubDir -Recurse -Force
            Write-Host "  $($dir.Name)/ directory" -ForegroundColor Green
            $installedCount++
        }
        catch {
            Write-Warning "  Failed to copy $($dir.Name)/ directory: $($_.Exception.Message)"
            $failedCount++
        }
    }
    
    if ($failedCount -gt 0) {
        Write-Warning "`nSome component files failed to install. The profile may not work correctly."
    }
    
    Write-Host "`nInstalled: $installedCount component files/directories" -ForegroundColor Cyan
    if ($failedCount -gt 0) {
        Write-Host "Failed: $failedCount component files/directories" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Failed to install ProfileComponents: $($_.Exception.Message)"
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
