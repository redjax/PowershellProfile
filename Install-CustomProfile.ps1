Param(
    [Parameter(mandatory = $false, HelpMessage = "The path to the JSON config file to use for script execution.")]
    [string]$ConfigFile = (Join-Path -Path $PSScriptRoot -ChildPath "config.json"),
    [Parameter(mandatory = $false, HelpMessage = "Name of module")]
    [string]$ModuleName = "ProfileModule",
    [Parameter(mandatory = $false, HelpMessage = "Path to repo modules directory")]
    [string]$RepoModulesDir = "$($PSScriptRoot)\Modules",
    [Parameter(mandatory = $false, HelpMessage = "Path to repo Profiles directory")]
    [string]$ProfilesDir = "$($PSScriptRoot)\Profiles",
    [Parameter(Mandatory = $false, HelpMessage = "Force a clean reinstall by removing all custom modules & reimporting only the ones specified in config.json")]
    [switch]$Clean,
    [Parameter(Mandatory = $false, HelpMessage = "Install custom modules from Modules/Custom to enable auto-discovery")]
    [switch]$CustomModules
)

## Vars
[string]$SetupModuleFilename = "PowershellProfileSetup"
[string]$SetupModulePath = Join-Path -Path $RepoModulesDir -ChildPath "/setup/$($SetupModuleFilename)"
# $ModuleInstallScriptPath = Join-Path -Path "scripts" -Childpath "Install-CustomPSModules.ps1"
[string]$HostProfileDir = Split-Path $PROFILE -Parent
[string]$HostCustomPSModulesDir = Join-Path -Path $HostProfileDir -ChildPath "Modules\Custom"

Write-Host "`n--[ Setup Installation Environment" -ForegroundColor Magenta

## Import setup module
Write-Host "Importing PowershellProfileSetup module from: $SetupModulePath" -ForegroundColor Cyan
try {
    Import-Module $SetupModulePath -Force -Scope Global
    Write-Debug "Imported $($SetupModuleFilename) module"
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
    $ProfileConfig = Get-ProfileConfig -ConfigFile $ConfigFile
    Write-Debug "Loaded configuration"
}
catch {
    Write-Error "Error importing profile configuration from file: $($ConfigFile). Details: $($_.Exception.Message)"
    exit 1
}

## Debug print configuration object
Write-Debug ($ProfileConfig | ConvertTo-Json -Depth 10)

## Update ProfileModule manifest
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

Write-Host "`n--[ Install ProfileModule" -ForegroundColor Magenta

## Install ProfileModule
try {
    Install-ProfileModule -RepositoryPath $PSScriptRoot
    Write-Host "Installed $($ModuleName) module" -ForegroundColor Green
}
catch {
    Write-Error "Error installing module. Details: $($_.Exception.Message)"
    exit 1
}

Write-Host "`n--[ Install Custom Powershell Profile" -ForegroundColor Magenta

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

## Install software_inits.ps1
Write-Host "Installing software initializations file" -ForegroundColor Cyan
$SoftwareInitsSource = Join-Path $ProfilesDir "software_inits.ps1"
$SoftwareInitsDest = Join-Path (Split-Path $PROFILE -Parent) "software_inits.ps1"

if (Test-Path $SoftwareInitsSource) {
    try {
        Copy-Item -Path $SoftwareInitsSource -Destination $SoftwareInitsDest -Force
        Write-Host "Installed software_inits.ps1 to: $SoftwareInitsDest" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to install software_inits.ps1: $($_.Exception.Message)"
    }
}
else {
    Write-Debug "No software_inits.ps1 file found at $SoftwareInitsSource"
}

## Install custom modules if -CustomModules switch is provided
if ($CustomModules) {
    Write-Host "`n--[ Install Custom Modules for Auto-Discovery" -ForegroundColor Magenta
    
    $CustomModulesSource = Join-Path $PSScriptRoot "Modules\Custom"
    
    if (Test-Path $CustomModulesSource) {
        # Remove existing custom modules directory if it exists for clean installation
        if (Test-Path $HostCustomPSModulesDir) {
            Write-Host "  Removing existing custom modules directory..." -ForegroundColor Yellow
            Remove-Item -Path $HostCustomPSModulesDir -Recurse -Force
            Write-Host "  Existing custom modules removed" -ForegroundColor Gray
        }
        
        # Create the Modules/Custom directory
        New-Item -Path $HostCustomPSModulesDir -ItemType Directory -Force | Out-Null
        Write-Host "Installing custom modules to: $HostCustomPSModulesDir" -ForegroundColor Cyan
        
        # Copy all modules from Modules/Custom
        $moduleCount = 0
        Get-ChildItem -Path $CustomModulesSource -Directory | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination (Join-Path $HostCustomPSModulesDir $_.Name) -Recurse -Force
            Write-Host "  $($_.Name)" -ForegroundColor Gray
            $moduleCount++
        }
        
        Write-Host "Installed $moduleCount custom modules for auto-discovery" -ForegroundColor Green
    }
    else {
        Write-Warning "Custom modules source directory not found at: $CustomModulesSource"
    }
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

## Handle Oh My Posh setup if OhMyPosh profile is selected
if ($ProfileConfig.profile.name -eq "OhMyPosh") {
    Write-Host ""
    try {
        Invoke-OhMyPoshSetup `
            -RepositoryPath $PSScriptRoot `
            -PromptForInstall `
            -CreateDefaultTheme
    }
    catch {
        Write-Warning "Oh My Posh setup encountered an error: $($_.Exception.Message)"
        Write-Host "You can set up Oh My Posh manually later with: Invoke-OhMyPoshSetup -RepositoryPath `"$PSScriptRoot`"" -ForegroundColor Yellow
    }
}

## Handle Starship setup if Starship profile is selected
if ($ProfileConfig.profile.name -eq "Starship") {
    Write-Host ""
    try {
        Invoke-StarshipSetup -RepositoryPath $PSScriptRoot -PromptForInstall -ConfigFile $ConfigFile -ConfigName $ProfileConfig.starship.config
    }
    catch {
        Write-Warning "Starship setup encountered an error: $($_.Exception.Message)"
        Write-Host "You can set up Starship manually later with: Invoke-StarshipSetup -RepositoryPath `"$PSScriptRoot`" -ConfigFile `"$ConfigFile`"" -ForegroundColor Yellow
    }
}

Write-Host "`n--[ Finished" -ForegroundColor Magenta
Write-Host "Powershell profile installed. Restart your terminal for changes to take effect." -ForegroundColor Green
exit $LASTEXITCODE
