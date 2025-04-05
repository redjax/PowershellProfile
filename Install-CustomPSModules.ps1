$ProfileSetupModulePath = "$PSScriptRoot/scripts/setup/PowershellProfileSetup"

if (-not (Test-Path $ProfileSetupModulePath)) {
    Write-Error "PowershellProfileSetup module not found at path: $ProfileSetupModulePath"
    exit(1)
}

## Ensure there is a .psm1 file at the module path
if ( -not ( Get-ChildItem "$PSScriptRoot/scripts/setup/PowershellProfileSetup" -Filter *.psm1 ) ) {
    Write-Error "Path is not a module directory: $PSScriptRoot/scripts/setup/PowershellProfileSetup"
    exit(1)
}

## Test if Install-CustomModules command is available
if (-not (Get-Command Install-CustomModules -ErrorAction SilentlyContinue)) {
    Write-Debug "⚠️ Install-CustomModules command is not available. Import module from path: $($ProfileSetupModulePath)"
    try {
        Import-Module $ProfileSetupModulePath -ErrorAction Stop
    }
    catch {
        Write-Error "❌ Error importing PowershellProfileSetup module. Details: $($_.Exception.Message)"
        exit(1)
    }
}

if (-not (Get-Command Install-CustomModules -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Install-CustomModules command is not available after importing module."
    exit(1)
}
else {
    Write-Output "✅ Install-CustomModules command is available after importing module."
}

Write-Output "--[ Installing custom Powershell modules"
## Run Install-CustomModules
try {
    Install-CustomModules -RepoModulesDir C:\scripts\PowershellProfile\Modules | Out-Null
}
catch {
    Write-Error "❌ Error installing custom Powershell modules. Details: $($_.Exception.Message)"
    exit(1)
}
