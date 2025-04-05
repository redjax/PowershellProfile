$ProfileSetupModulePath = "$PSScriptRoot/scripts/setup/PowershellProfileSetup"
$RepoCustomModulesDir = Join-Path -Path $PSScriptRoot -ChildPath "Modules" -AdditionalChildPath "Custom"
$HostPSModulesDir = Join-Path -Path (Split-Path $PROFILE -Parent) -ChildPath "Modules"
$HostCustomModulesPath = Join-Path -Path $HostPSModulesDir -ChildPath "Custom"

if (-not ( Test-Path $ProfileSetupModulePath ) ) {
    Write-Error "❌ PowershellProfileSetup module not found at path: $ProfileSetupModulePath"
    exit(1)
}

## Ensure there is a .psm1 file at the module path
if ( -not ( Get-ChildItem "$PSScriptRoot/scripts/setup/PowershellProfileSetup" -Filter *.psm1 ) ) {
    Write-Error "❌ Path is not a module directory: $PSScriptRoot/scripts/setup/PowershellProfileSetup"
    exit(1)
}

if ( -not ( Test-Path -Path $RepoCustomModulesDir -ErrorAction SilentlyContinue ) ) {
    Write-Error "❌ Repository custom Powershell modules not found at path '$RepoCustomModulesDir'."
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
    Write-Debug "✅ Install-CustomModules command is available after importing module."
}

Write-Output "`n--[ Validate Environment"

## Run Install-CustomModules
try {
    Install-CustomModules -RepoModulesDir $HostPSModulesDir -ErrorAction SilentlyContinue | Out-Null
    $CustomModulesDirCreatedStatus = $true
}
catch {
    Write-Error "❌ Error installing custom Powershell modules. Details: $($_.Exception.Message)"
    $CustomModulesDirCreatedStatus = $false
}

if ( -not $CustomModulesDirCreatedStatus ) {
    Write-Error "❌ Did not find custom modules directory at path: $HostCustomModulesPath."
    exit(1)
}

Write-Output "✅ Found repository custom Powershell modules at path: $RepoCustomModulesDir"
Write-Output "✅ Found host Powershell modules at path: $HostPSModulesDir"
Write-Output "✅ Found custom Powershell modules directory at path: $HostCustomModulesPath"

Write-Output "`n--[ Install custom Powershell modules"
