## Test if Install-CustomModules command is available
if (-not (Get-Command Install-CustomModules -ErrorAction SilentlyContinue)) {
    Write-Error "Install-CustomModules command is not available."

    Write-Output "Importing module: ./scripts/setup/PowershellProfileSetup"
    try {
        Import-Module ./scripts/setup/PowershellProfileSetup -ErrorAction Stop
    }
    catch {
        Write-Error "Error importing PowershellProfileSetup module. Details: $($_.Exception.Message)"
        exit(1)
    }
}

if (-not (Get-Command Install-CustomModules -ErrorAction SilentlyContinue)) {
    Write-Error "Install-CustomModules command is not available."
    exit(1)
}

## Run Install-CustomModules
# Install-CustomModules -RepoModulesDir C:\scripts\PowershellProfile\Modules
