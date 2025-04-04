Param(
    [Parameter(mandatory = $false, HelpMessage = "The path to the JSON config file to use for script execution.")]
    [string]$ConfigFile = "config.json",
    [Parameter(mandatory = $false, HelpMessage = "Name of module")]
    [string]$ModuleName = "ProfileModule",
    [Parameter(mandatory = $false, HelpMessage = "Path to repo modules directory")]
    [string]$RepoModulesDir = "$($PSScriptRoot)\..\Modules",
    [Parameter(mandatory = $false, HelpMessage = "Path to repo Profiles directory")]
    [string]$ProfilesDir = "$($PSScriptRoot)\Profiles"
)

## Vars
$SetupModuleFilename = "PowershellProfileSetup"
$SetupModulePath = Join-Path -Path $PSScriptRoot "setup/$($SetupModuleFilename)"

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

## Debug print module info
#  Get-Module -Name PowershellProfileSetup

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

## Debug print configuration object
Write-Debug ($ProfileConfig | ConvertTo-Json -Depth 10)

try {
    Invoke-ModuleManifestUpdate `
        -ModuleAuthor $ProfileConfig.repo.author `
        -ModuleName $ModuleName `
        -RepoModulesDir $RepoModulesDir
}
catch {
    Write-Error "Error updating module manifest file. Details: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nUpdated module manifest for module: $($ModuleName)" -ForegroundColor Green
exit $LASTEXITCODE
