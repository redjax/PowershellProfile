<#
    .SYNOPSIS
    Powershell $PROFILE with Starship prompt.

    .DESCRIPTION
    Loads the _StarshipBase.ps1 base profile which includes:
    - Custom ProfileModule
    - Custom modules from CustomModules directory
    
    Then initializes Starship prompt in the background.
#>

## Uncomment to enable profile tracing
# Set-PSDebug -Trace 1

## Uncomment to enable debug logging
# $DebugPreference = "Continue"

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

## Initialize Starship prompt with caching for faster startup
if (Get-Command starship -ErrorAction SilentlyContinue) {
    $starshipCache = Join-Path $env:USERPROFILE ".starship\starship.ps1"
    $starshipConfig = Join-Path $env:USERPROFILE ".config\starship.toml"
    
    # Generate cache if it doesn't exist or is older than starship executable or config file
    $starshipExe = (Get-Command starship).Source
    $cacheNeedsUpdate = $false
    
    if (-not (Test-Path $starshipCache)) {
        $cacheNeedsUpdate = $true
    }
    elseif ((Get-Item $starshipCache).LastWriteTime -lt (Get-Item $starshipExe).LastWriteTime) {
        $cacheNeedsUpdate = $true
    }
    elseif ((Test-Path $starshipConfig) -and 
            (Get-Item $starshipCache).LastWriteTime -lt (Get-Item $starshipConfig).LastWriteTime) {
        $cacheNeedsUpdate = $true
    }
    
    if ($cacheNeedsUpdate) {
        $cacheDir = Split-Path $starshipCache -Parent
        if (-not (Test-Path $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }
        
        & starship init powershell | Out-File -FilePath $starshipCache -Encoding utf8
    }
    
    # Source the cached init script - MUCH faster than running starship init every time
    . $starshipCache
}
else {
    Write-Warning "Starship is not installed."
    Write-Host "Install with: winget install Starship.Starship" -ForegroundColor Cyan
}

if ($ClearOnInit) {
    Clear-Host
}

## End profile initialization timer
$ProfileEndTime = Get-Date
## Calculate profile init time
$ProfileInitTime = $ProfileEndTime - $ProfileStartTime
## Print initialization time
Write-Output "Profile loaded in $($ProfileInitTime.TotalSeconds) second(s)."

## Disable profile tracing
Set-PSDebug -Trace 0
