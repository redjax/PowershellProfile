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

Write-Host "`n--[ Script Setup" -ForegroundColor Magenta

## Ensure PowershellProfileSetup module is available
if (-not ( Test-Path $SetupModulePath ) ) {
    Write-Error "PowershellProfileSetup module not found at path: $SetupModulePath"
    exit(1)
}

## Ensure there is a .psm1 file at the module path
if ( -not ( Get-ChildItem "$SetupModulePath" -Filter *.psm1 ) ) {
    Write-Error "Path is not a module directory: $SetupModulePath"
    exit(1)
}

## Ensure repository custom Powershell modules are available
if ( -not ( Test-Path -Path $RepoCustomModulesDir -ErrorAction SilentlyContinue ) ) {
    Write-Error "Repository custom Powershell modules not found at path '$RepoCustomModulesDir'."
    exit(1)
}

## Test if Install-CustomModules command is available
if (-not (Get-Command Install-CustomModules -ErrorAction SilentlyContinue)) {
    Write-Debug "Install-CustomModules command is not available. Import module from path: $($SetupModulePath)"
    try {
        Import-Module $SetupModulePath -ErrorAction Stop
    }
    catch {
        Write-Error "Error importing PowershellProfileSetup module. Details: $($_.Exception.Message)"
        exit(1)
    }
}

## Check if Install-CustomModules is available after importing ProfileSetup module
if (-not (Get-Command Install-CustomModules -ErrorAction SilentlyContinue)) {
    Write-Error "Install-CustomModules command is not available after importing module."
    exit(1)
}
else {
    Write-Debug "Install-CustomModules command is available after importing module."
}

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

Write-Host "`n--[ Validate Environment" -ForegroundColor Magenta

## Initialize custom modules directory
try {
    Invoke-CustomModulesPathInit -RepoModulesDir $HostCustomPSModulesDir -ErrorAction SilentlyContinue | Out-Null
    $CustomModulesDirCreatedStatus = $true
}
catch {
    Write-Error "Error initializing custom Powershell modules path. Details: $($_.Exception.Message)"
    $CustomModulesDirCreatedStatus = $false
}

if (-not $CustomModulesDirCreatedStatus) {
    Write-Error "Did not find custom modules directory at path: $HostCustomPSModulesDir."
    exit(1)
}

Write-Host "Initialized custom modules directory at path: $HostCustomPSModulesDir" -ForegroundColor Green

Write-Host "`n--[ Get Config" -ForegroundColor Magenta

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

Write-Host "`n--[ Prepare Modules for Installation" -ForegroundColor Magenta

## Array to store module PSCustomObjects loaded from config file
[PSCustomObject[]]$ConfigInstallModules = @()
## Array to store paths to modules for installation operation
[string[]]$ModuleInstallPaths = @()

## Iterate over custom_modules list from config
$ProfileConfig.custom_modules | ForEach-Object {
    ## Extract module name
    $ModuleName = $_
    ## Build module install path
    $ModuleFile = Join-Path -Path $RepoCustomModulesDir -ChildPath "$($ModuleName).psm1"
    ## Get path to module's parent dir
    $ModuleParentDir = Split-Path -Path $ModuleFile -Parent

    ## Build module PSCustomObject
    [PSCustomObject]$ModuleObj = [PSCustomObject]@{
        Name = $ModuleName
        File = $ModuleFile
        Path = $ModuleParentDir
    }

    Write-Debug "Module: $($ModuleObj.Name), Path: $($ModuleObj.Path)"

    ## Append full object to array
    $ConfigInstallModules += $ModuleObj
    ## Append module path to array
    $ModuleInstallPaths += $ModuleObj.Path
}

Write-Host "Found $($ConfigInstallModules.Count) custom Powershell modules to install" -ForegroundColor Cyan

Write-Debug "Module install paths: $($ModuleInstallPaths -join ', ')"

Write-Host "`n--[ Install Modules" -ForegroundColor Magenta

## Run Install-CustomModules
try {
    Install-CustomModules -Modules $ModuleInstallPaths -HostCustomModulesPath $HostCustomPSModulesDir -ErrorAction Stop | Out-Null
}
catch {
    Write-Error "Error installing custom Powershell modules. Details: $($_.Exception.Message)"
    exit(1)
}

Write-Host "`n--[ Finished" -ForegroundColor Magenta
Write-Host "Successfully installed custom Powershell modules." -ForegroundColor Green
