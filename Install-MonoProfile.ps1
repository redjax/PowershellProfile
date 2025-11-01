<#
    .SYNOPSIS
    Install the Monolith PowerShell profile and its component files.

    .DESCRIPTION
    Installs the Monolith.ps1 profile and ProfileComponents directory to the $PROFILE directory.
    Configures prompt handler and copies theme files to standard locations.
    
    .PARAMETER Force
    Overwrite existing profile without prompting for confirmation.
    
    .PARAMETER Prompt
    Prompt handler to use: "default", "starship", or "oh-my-posh". Default: "starship"
    
    .PARAMETER StarshipTheme
    Starship theme name (maps to config/starship/*.toml). Default: "default"
    
    .PARAMETER OhMyPoshTheme
    Oh-My-Posh theme name (maps to config/ohmyposh/*.omp.json). Default: "default"
    
    .PARAMETER CustomModules
    Install custom modules from Modules/Custom to the profile's Modules/Custom directory.

    .EXAMPLE
    .\Install-MonoProfile.ps1
    Installs with Starship prompt and default theme.

    .EXAMPLE
    .\Install-MonoProfile.ps1 -Prompt oh-my-posh -OhMyPoshTheme minimal
    Installs with Oh-My-Posh prompt using minimal theme.
    
    .EXAMPLE
    .\Install-MonoProfile.ps1 -Force -Prompt default
    Installs with custom default prompt, overwriting without prompting.
    
    .EXAMPLE
    .\Install-MonoProfile.ps1 -CustomModules
    Installs profile and copies custom modules to profile directory.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false, HelpMessage = "Overwrite existing profile without prompting")]
    [switch]$Force,
    
    [Parameter(Mandatory = $false, HelpMessage = "Prompt handler to use")]
    [ValidateSet("default", "starship", "oh-my-posh")]
    [string]$Prompt = "default",
    
    [Parameter(Mandatory = $false, HelpMessage = "Starship theme name")]
    [string]$StarshipTheme = "default",
    
    [Parameter(Mandatory = $false, HelpMessage = "Oh-My-Posh theme name")]
    [string]$OhMyPoshTheme = "default",
    
    [Parameter(Mandatory = $false, HelpMessage = "Install custom modules")]
    [switch]$CustomModules
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

# Remove existing ProfileComponents directory if it exists
if (Test-Path $ComponentsDestDir) {
    Write-Host "  Removing existing ProfileComponents directory..." -ForegroundColor Yellow
    try {
        Remove-Item -Path $ComponentsDestDir -Recurse -Force
        Write-Host "  Existing ProfileComponents removed" -ForegroundColor Green
    }
    catch {
        Write-Warning "  Failed to remove existing ProfileComponents: $($_.Exception.Message)"
        Write-Host "  Attempting to overwrite files..." -ForegroundColor Yellow
    }
}

try {
    # Create fresh ProfileComponents directory
    New-Item -Path $ComponentsDestDir -ItemType Directory -Force | Out-Null
    Write-Host "  Created ProfileComponents directory" -ForegroundColor Green
    
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

## Configure prompt handler
Write-Host "`nConfiguring prompt handler: $Prompt" -ForegroundColor Cyan

# Write prompt configuration file
$PromptConfigPath = Join-Path $DestinationDir "prompt-config.ps1"
$promptConfigContent = @"
# Monolith Profile - Prompt Configuration
# Generated by Install-MonoProfile.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Do not edit manually - regenerate by running Install-MonoProfile.ps1

`$PromptHandler = "$Prompt"
"@

try {
    $promptConfigContent | Out-File -FilePath $PromptConfigPath -Encoding utf8 -Force
    Write-Host "  Prompt handler set to: $Prompt" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to write prompt configuration: $($_.Exception.Message)"
}

## Install Starship theme (if Starship prompt is selected)
if ($Prompt -eq "starship") {
    $StarshipConfigSourceDir = Join-Path $ScriptRoot "config\starship"
    $StarshipThemeSource = Join-Path $StarshipConfigSourceDir "$StarshipTheme.toml"
    $StarshipConfigDest = Join-Path $env:USERPROFILE ".config\starship.toml"
    
    if (Test-Path $StarshipThemeSource) {
        Write-Host "`nInstalling Starship theme: $StarshipTheme" -ForegroundColor Cyan
        try {
            $starshipConfigDir = Split-Path $StarshipConfigDest -Parent
            if (-not (Test-Path $starshipConfigDir)) {
                New-Item -Path $starshipConfigDir -ItemType Directory -Force | Out-Null
            }
            
            Copy-Item -Path $StarshipThemeSource -Destination $StarshipConfigDest -Force
            Write-Host "  Theme installed to: $StarshipConfigDest" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to install Starship theme: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Starship theme '$StarshipTheme' not found at: $StarshipThemeSource"
    }
}

## Install Oh-My-Posh theme (if Oh-My-Posh prompt is selected)
if ($Prompt -eq "oh-my-posh") {
    $OmpConfigSourceDir = Join-Path $ScriptRoot "config\ohmyposh"
    $OmpThemeSource = Join-Path $OmpConfigSourceDir "$OhMyPoshTheme.omp.json"
    $OmpConfigDest = Join-Path $env:USERPROFILE ".config\ohmyposh\theme.omp.json"
    
    if (Test-Path $OmpThemeSource) {
        Write-Host "`nInstalling Oh-My-Posh theme: $OhMyPoshTheme" -ForegroundColor Cyan
        try {
            $ompConfigDir = Split-Path $OmpConfigDest -Parent
            if (-not (Test-Path $ompConfigDir)) {
                New-Item -Path $ompConfigDir -ItemType Directory -Force | Out-Null
            }
            
            Copy-Item -Path $OmpThemeSource -Destination $OmpConfigDest -Force
            Write-Host "  Theme installed to: $OmpConfigDest" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to install Oh-My-Posh theme: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Oh-My-Posh theme '$OhMyPoshTheme' not found at: $OmpThemeSource"
    }
}

## Install Custom Modules (if -CustomModules flag is set)
if ($CustomModules) {
    $CustomModulesSource = Join-Path $ScriptRoot "Modules\Custom"
    $CustomModulesDest = Join-Path (Split-Path $DestinationPath -Parent) "Modules\Custom"
    
    if (Test-Path $CustomModulesSource) {
        Write-Host "`nInstalling custom modules..." -ForegroundColor Cyan
        try {
            # Remove existing Modules/Custom directory if it exists (clean install)
            if (Test-Path $CustomModulesDest) {
                Write-Host "  Removing existing custom modules directory..." -ForegroundColor Yellow
                Remove-Item -Path $CustomModulesDest -Recurse -Force
                Write-Host "  Existing custom modules removed" -ForegroundColor Gray
            }
            
            # Create Modules/Custom directory
            New-Item -Path $CustomModulesDest -ItemType Directory -Force | Out-Null
            
            # Copy all modules from source to destination
            $moduleCount = 0
            Get-ChildItem -Path $CustomModulesSource -Directory | ForEach-Object {
                $moduleName = $_.Name
                $moduleSource = $_.FullName
                $moduleDest = Join-Path $CustomModulesDest $moduleName
                
                Copy-Item -Path $moduleSource -Destination $moduleDest -Recurse -Force
                Write-Host "  $moduleName" -ForegroundColor Gray
                $moduleCount++
            }
            
            Write-Host "`nInstalled $moduleCount custom module(s) to: $CustomModulesDest" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to install custom modules: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Custom modules directory not found at: $CustomModulesSource"
    }
}

## Summary
Write-Host "`n=== Installation Complete ===" -ForegroundColor Green
Write-Host "Profile location: $DestinationPath" -ForegroundColor Gray
Write-Host "`nTo activate the new profile:" -ForegroundColor Cyan
Write-Host "  1. Restart your PowerShell session, or" -ForegroundColor Gray
Write-Host "  2. Run: . `$PROFILE" -ForegroundColor Gray
Write-Host ""

exit 0
