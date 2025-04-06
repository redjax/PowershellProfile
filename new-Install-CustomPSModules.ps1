Param(
    [Parameter(mandatory = $false, HelpMessage = "The path to the JSON config file to use for script execution.")]
    [string]$ConfigFile = "config.json"
)

[string]$RepoModulesDir = "$($PSScriptRoot)\Modules"
[string]$RepoCustomModulesDir = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "Modules") -ChildPath "Custom"
[string]$HostCustomPSModulesDir = Join-Path -Path (Split-Path $PROFILE -Parent) -ChildPath "CustomModules"

[string]$SetupModuleFilename = "PowershellProfileSetup"
[string]$SetupModulePath = Join-Path -Path $RepoModulesDir -ChildPath "/setup/$($SetupModuleFilename)"

Write-Verbose "`$RepoCustomModulesDir=$($RepoCustomModulesDir)"
Write-Verbose "`$HostCustomPSModulesDir=$($HostCustomPSModulesDir)"

## Import setup module
Write-Host "Importing PowershellProfileSetup module from: $SetupModulePath" -ForegroundColor Cyan
try {
    Import-Module $SetupModulePath -Force -Scope Global
    Write-Host "Imported $($SetupModuleFilename) module" -ForegroundColor Green
}
catch {
    Write-Error "Error importing PowershellProfileSetup module. Details: $($_.Exception.Message)"
    exit 1
}

## Read repo configuration from config.json (or another file passed with -ConfigFile)
Write-Host "Reading config from '$($ConfigFile)'" -ForegroundColor Cyan
try {
    $ProfileConfig = Get-ProfileConfig -ConfigFile "config.json"
    Write-Host "Loaded configuration" -ForegroundColor Green
}
catch {
    Write-Error "Error importing profile configuration from file: $($ConfigFile). Details: $($_.Exception.Message)"
    exit 1
}

$ProfileConfig.custom_modules | ForEach-Object {
    $ModuleName = $_
    $ModulePath = Join-Path -Path $RepoCustomModulesDir -ChildPath "$($ModuleName).psm1"

    Write-Host "Module: $ModuleName, Path: $ModulePath" -ForegroundColor Cyan
}