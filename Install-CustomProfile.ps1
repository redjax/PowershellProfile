Param(
    [Parameter(mandatory = $false, HelpMessage = "The path to the JSON config file to use for script execution.")]
    [string]$ConfigFile = (Join-Path -Path $PSScriptRoot -ChildPath "config.json"),
    [Parameter(mandatory = $false, HelpMessage = "Name of module")]
    [string]$ModuleName = "ProfileModule",
    [Parameter(mandatory = $false, HelpMessage = "Path to repo modules directory")]
    [string]$RepoModulesDir = "$($PSScriptRoot)\Modules",
    [Parameter(mandatory = $false, HelpMessage = "Path to repo Profiles directory")]
    [string]$ProfilesDir = "$($PSScriptRoot)\Profiles"
)

## Vars
[string]$SetupModuleFilename = "PowershellProfileSetup"
[string]$SetupModulePath = Join-Path -Path $RepoModulesDir -ChildPath "/setup/$($SetupModuleFilename)"
# $ModuleInstallScriptPath = Join-Path -Path "scripts" -Childpath "Install-CustomPSModules.ps1"
[string]$HostCustomPSModulesDir = Join-Path -Path (Split-Path $PROFILE -Parent) -ChildPath "CustomModules"

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
    
    Write-Host "Updated '$($ModuleName)' module's manifest" -ForegroundColor Green
}
catch {
    Write-Error "Error updating module manifest file. Details: $($_.Exception.Message)"
    exit 1
}

## Install Base $PROFILE
Write-Host "Installing base profile" -ForegroundColor Cyan
try {
    Invoke-BaseProfileInstall -ProfileBase "$($ProfilesDir)/Bases/$($ProfileConfig.repo.profile_base)"
    Write-Host "Installed base profile to: $(Split-Path $PROFILE -Parent)\_Base.ps1" -ForegroundColor Green
}
catch {
    Write-Error "Error installing base profile. Details: $($_.Exception.Message)"
    exit 1
}

## Install ProfileModule
Write-Host "Installing custom profile module" -ForegroundColor Cyan
try {
    Install-ProfileModule -RepositoryPath $PSScriptRoot
    Write-Host "Installed $($ModuleName) module" -ForegroundColor Green
}
catch {
    Write-Error "Error installing module. Details: $($_.Exception.Message)"
    exit 1
}

## Install modules
Write-Host "Installing custom Powershell modules" -ForegroundColor Cyan
try {
    Install-CustomModules `
        -ConfigFile $ConfigFile `
        -RepoCustomModulesDir (Join-Path -Path $RepoModulesDir -ChildPath "Custom") `
        -HostCustomPSModulesDir $HostCustomPSModulesDir `
        -SetupModulePath $SetupModulePath `
        -ErrorAction Stop `
    | Out-Null
    Write-Host "Installed custom modules" -ForegroundColor Green
}
catch {
    Write-Error "Error installing custom modules. Details: $($_.Exception.Message)"
    exit 1
}

## Install profile
Write-Host "Installing custom Powershell profile" -ForegroundColor Cyan
try {
    ## Call the Set-PowershellProfile function
    Set-PowershellProfile `
        -RepoProfilesDir $ProfilesDir `
        -ProfilePath $PROFILE `
        -ProfileName $ProfileConfig.profile.name

    Write-Host "Installed custom Powershell profile" -ForegroundColor Green
}
catch {
    Write-Error "Error installing custom Powershell profile. Details: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nPowershell profile installed. Restart your terminal for changes to take effect." -ForegroundColor Green
exit $LASTEXITCODE
