<#
    .SYNOPSIS
    Powershell $PROFILE with Oh My Posh prompt.

    .DESCRIPTION
    Loads the base profile and initializes Oh My Posh with a custom theme.
    Theme configuration is installed to $HOME/.config/ohmyposh/theme.omp.json
    and is independent of the repository after installation.
#>

## Uncomment to enable profile tracing
# Set-PSDebug -Trace 1

## Manually set this to $false to keep profile outputs on-screen after initializing
$ClearOnInit = $true

## Start profile initialization timer
$ProfileStartTime = Get-Date

$ScriptRoot = Split-Path -Path $PROFILE -Parent
$BaseProfile = Join-Path -Path $ScriptRoot -ChildPath "_Base.ps1"

if (-not (Test-Path -Path "$($BaseProfile)")) {
    Write-Warning "Could not find base profile '$($BaseProfile)'."
}
else {
    . "$($BaseProfile)"
}

## Initialize Oh My Posh prompt
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    ## Path to Oh My Posh theme configuration (installed in user's config directory)
    $OhMyPoshTheme = Join-Path -Path $HOME -ChildPath ".config\ohmyposh\theme.omp.json"
    
    ## Check if custom theme exists
    if (Test-Path -Path $OhMyPoshTheme) {
        oh-my-posh init pwsh --config $OhMyPoshTheme | Invoke-Expression
    }
    else {
        Write-Warning "Oh My Posh theme not found at: $OhMyPoshTheme"
        Write-Host "Run the installation script to set up Oh My Posh: .\Install-CustomProfile.ps1" -ForegroundColor Yellow
        Write-Host "Or manually run: Invoke-OhMyPoshSetup -RepositoryPath <path-to-repo>" -ForegroundColor Yellow
    }
}
else {
    Write-Warning "Oh My Posh is not installed."
    Write-Host "Install with: winget install JanDeDobbeleer.OhMyPosh" -ForegroundColor Cyan
}

## Load posh-git for Oh My Posh git integration in background
@(
    {
        try {
            if (Get-Module -ListAvailable -Name posh-git) {
                Import-Module posh-git -ErrorAction Stop
                Write-Verbose "posh-git module loaded."
            }
            else {
                Write-Verbose "posh-git not installed. Skipping import."
            }
        }
        catch {
            Write-Warning "Failed to import posh-git: $($_.Exception.Message)"
        }
    }
) | ForEach-Object {
    Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $_
} | Out-Null

if ($ClearOnInit) {
    Clear-Host
}

## End profile initialization timer
$ProfileEndTime = Get-Date
## Calculate profile init time
$ProfileInitTime = $ProfileEndTime - $ProfileStartTime
## Print initialization time
Write-Output "Profile loaded in $($ProfileInitTime.TotalSeconds) second(s)."
Write-Output "Some commands may be unavailable for 1-3 seconds while background imports finish."

## Disable profile tracing
Set-PSDebug -Trace 0
