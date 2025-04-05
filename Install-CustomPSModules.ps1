## Path vars
$ProfileSetupModulePath = "$PSScriptRoot/scripts/setup/PowershellProfileSetup"
$RepoCustomModulesDir = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "Modules") -ChildPath "Custom"
$HostPSModulesDir = Join-Path -Path (Split-Path $PROFILE -Parent) -ChildPath "Modules"
$HostCustomModulesPath = Join-Path -Path $HostPSModulesDir -ChildPath "Custom"

Write-Verbose "`$ProfileSetupModulePath=$($ProfileSetupModulePath)"
Write-Verbose "`$RepoCustomModulesDir=$($RepoCustomModulesDir)"
Write-Verbose "`$HostPSModulesDir=$($HostPSModulesDir)"
Write-Verbose "`$HostCustomModulesPath=$($HostCustomModulesPath)"

# Helper function to prompt user for valid input
function Start-UserModuleInstallPrompt {
    param (
        [string]$ModuleName
    )

    while ($true) {
        $UserResponse = Read-Host -Prompt "Install module: $ModuleName (y/n)"
        # Normalize input to lowercase for easier comparison
        $UserResponse = $UserResponse.ToLower()

        if ($UserResponse -match '^(y|yes|n|no)$') {
            return $UserResponse
        }
        else {
            Write-Warning "Invalid response. Please enter 'y', 'yes', 'n', or 'no'."
        }
    }
}

## Ensure PowershellProfileSetup module is available
if (-not ( Test-Path $ProfileSetupModulePath ) ) {
    Write-Error "PowershellProfileSetup module not found at path: $ProfileSetupModulePath"
    exit(1)
}

## Ensure there is a .psm1 file at the module path
if ( -not ( Get-ChildItem "$PSScriptRoot/scripts/setup/PowershellProfileSetup" -Filter *.psm1 ) ) {
    Write-Error "Path is not a module directory: $PSScriptRoot/scripts/setup/PowershellProfileSetup"
    exit(1)
}

## Ensure repository custom Powershell modules are available
if ( -not ( Test-Path -Path $RepoCustomModulesDir -ErrorAction SilentlyContinue ) ) {
    Write-Error "Repository custom Powershell modules not found at path '$RepoCustomModulesDir'."
    exit(1)
}

## Test if Install-CustomModules command is available
if (-not (Get-Command Install-CustomModules -ErrorAction SilentlyContinue)) {
    Write-Debug "Install-CustomModules command is not available. Import module from path: $($ProfileSetupModulePath)"
    try {
        Import-Module $ProfileSetupModulePath -ErrorAction Stop
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

Write-Output "`n--[ Validate Environment"

## Initialize custom modules directory
try {
    Invoke-CustomModulesPathInit -RepoModulesDir $HostPSModulesDir -ErrorAction SilentlyContinue | Out-Null
    $CustomModulesDirCreatedStatus = $true
}
catch {
    Write-Error "Error initializing custom Powershell modules path. Details: $($_.Exception.Message)"
    $CustomModulesDirCreatedStatus = $false
}

if (-not $CustomModulesDirCreatedStatus) {
    Write-Error "Did not find custom modules directory at path: $HostCustomModulesPath."
    exit(1)
}

Write-Output "Found repository custom Powershell modules at path: $RepoCustomModulesDir"
Write-Output "Found host Powershell modules at path: $HostPSModulesDir"
Write-Output "Found custom Powershell modules directory at path: $HostCustomModulesPath"

Write-Output "`n--[ Pick Custom Modules to Install"

## Store list of modules to install
$InstallModules = @()

## Get list of directories in repo custom modules path
$RepoCustomModules = Get-ChildItem -Path $RepoCustomModulesDir -Directory | Where-Object {
    ## Check if .psm1 file exists directly beneath module parent directory
    Test-Path (Join-Path -Path $_.FullName -ChildPath "*.psm1")
}

## Prompt user for each module
$RepoCustomModules | ForEach-Object {
    $ModuleName = $_.BaseName
    $ModulePath = $_.FullName

    Write-Debug "Found module: $ModuleName"

    ## Prompt user for input using helper function
    $UserResponse = Start-UserModuleInstallPrompt -ModuleName $ModuleName

    ## Check if response was affirmative (y/yes)
    if ($UserResponse -match '^(y|yes)$') {
        Write-Output "+ Adding module '$($ModulePath)' to install list"
        $InstallModules += $ModulePath
    }
    else {
        Write-Output "Skipping module: $ModuleName"
    }
}

Write-Output "`n--[ Installing $($InstallModules.Count) Powershell Module(s)"

## Run Install-CustomModules
try {
    Install-CustomModules -Modules $InstallModules -HostCustomModulesPath $HostCustomModulesPath -ErrorAction Stop | Out-Null
    Write-Output "Successfully installed custom Powershell modules."
}
catch {
    Write-Error "Error installing custom Powershell modules. Details: $($_.Exception.Message)"
    exit(1)
}

## Append host's custom Powershell modules path to PSModulePath
Write-Output "`n--[ Add Custom Powershell Modules Path to `$PSModulePath"

try {
    Set-CustomPSModulesPath -CustomModulesPath $HostCustomModulesPath -ErrorAction Stop | Out-Null
    Write-Output "Successfully added custom Powershell modules path to `$PSModulePath."
    Write-Debug "Added path '$($HostCustomModulesPath)' to `$PSModulePath."
    Write-Debug "New `$PSModulePath: $env:PSModulePath"
}
catch {
    Write-Error "`nError adding custom Powershell modules path to `$PSModulePath. Details: $($_.Exception.Message)"
    exit(1)
}

Write-Output "`n⭐ Finished installing custom Powershell modules."
