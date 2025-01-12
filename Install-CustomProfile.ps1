Param(
    [switch]$Debug,
    [switch]$Verbose,
    [string]$ModuleAuthor
)

If ( $Debug ) {
    $DebugPreference = "Continue"
}
else {
    $DebugPreference = "SilentlyContinue"
}

If ( $Verbose ) {
    $VerbosePreference = "Continue"
}
else {
    $VerbosePreference = "SilentlyContinue"
}

## Set relative path to the ProfileModule/ directory
[string]$ProfileModuleRoot = ".\ProfileModule"
## Set path to Functions/ directory
[string]$FunctionsPath = (Join-Path $ProfileModuleRoot "Functions")
## Set path to public Functions
[string]$PublicFunctionsPath = (Join-Path $FunctionsPath "Public")
## Set path to private Functions
[string]$PrivateFunctionsPath = (Join-Path $FunctionsPath "Private")
## Path to module's Aliases.ps1 file
[string]$AliasesFile = (Join-Path $ProfileModuleRoot "Aliases.ps1")
## Set path to module's manifest .psd1 file
[string]$ManifestPath = (Join-Path $ProfileModuleRoot "ProfileModule.psd1")
## Set path to module's guid.txt containing the unique ID for the module
[string]$GUIDFilePath = (Join-Path $ProfileModuleRoot "guid.txt")
## Set path to module's author.txt containing the module author name
[string]$AuthorFilePath = (Join-Path $ProfileModuleRoot "author.txt")
## Set path to module's version.txt containing the moddule's version
[string]$VersionFilePath = (Join-Path $ProfileModuleRoot "version.txt")
## Set path to machine's Modules\ path in the $PROFILE's parent directory
[string]$PSModulesPath = "$(Split-Path $PROFILE -Parent)\Modules"

Write-Verbose "ProfileModule path: $ProfileModuleRoot"
Write-Verbose "Path to module's functions: $FunctionsPath"
Write-Verbose "Path to module's Public/ functions: $PublicFunctionsPath"
Write-Verbose "Path to module's Private/ functions: $PrivateFunctionsPath"
Write-Verbose "Path to module's manifest file: $ManifestPath"
Write-Verbose "Path to module's GUID file: $GUIDFilePath"
Write-Verbose "Path to module's author file: $AuthorFilePath"
Write-Verbose "Path to module's version file: $VersionFilePath"

function Start-ModuleManifestUpdate() {
    <#
        .SYNOPSIS
        Create or update the module's .psd1 module manifest.
    #>
    Param(
        $Debug = $False,
        $Verbose = $False,
        $GUIDFilePath = $GUIDFilePath,
        $Author = $Author,
        $AuthorFilePath = $AuthorFilePath,
        $VersionFilePath = $VersionFilePath,
        $ManifestPath = $ManifestPath,
        $FunctionsPath = $FunctionsPath,
        $AliasesFile = $AliasesFile
    )

    # Explicitly set Debug and Verbose if not provided
    $Debug = $Debug -eq $True
    $Verbose = $Verbose -eq $True

    $UpdateManifestScriptPath = Join-Path -Path $PSScriptRoot -ChildPath ".\scripts\Update-ProfileModuleManifest.ps1"
    
    Write-Debug "Calling script: $UpdateManifestScriptPath"
    Write-Debug "Debug: $($Debug), Verbose: $($Verbose)"

    ## Call the script to update the module's manifest
    & $UpdateManifestScriptPath `
        -Author $Author `
        -FunctionsPath $FunctionsPath `
        -AliasesFile $AliasesFile `
        -ManifestPath $ManifestPath `
        -GUIDFilePath $GUIDFilePath `
        -AuthorFilePath $AuthorFilePath `
        -VersionFilePath $VersionFilePath `
        -Debug:$Debug `
        -Verbose:$Verbose
}

function Start-ModuleInstall() {
    <#
        .SYNOPSIS
        Install Powershell module in profile's modules/ path.
    #>
    Param(
        $Debug = $False,
        $Verbose = $False,
        $RepositoryPath = $PSScriptRoot,
        $ModuleSource = (Join-Path -Path $RepositoryPath -ChildPath "ProfileModule"),
        $ProfileModulePath = (Join-Path -Path (Split-Path -Parent $PROFILE) -ChildPath "Modules\ProfileModule")
    )

    # Explicitly set Debug and Verbose if not provided
    $Debug = $Debug -eq $True
    $Verbose = $Verbose -eq $True

    $InstallModuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath ".\scripts\Install-ProfileModule.ps1"
    
    Write-Debug "Calling script: $InstallModuleScriptPath"
    Write-Debug "Debug: $($Debug), Verbose: $($Verbose)"

    ## Call the script to update the module's manifest
    try {
        & $InstallModuleScriptPath `
            -Debug:$Debug `
            -Verbose:$Verbose `
            -RepositoryPath $RepositoryPath `
            -SourcePath $ModuleSource `
            -TargetPath $ProfileModulePath
    } catch {
        Write-Error "Error running ProfileModule install script. Details: $($_.Exception.Message)"
        exit 1
    }
}

function Start-ProfileInstall() {
    Param(
        $Debug = $False,
        $Verbose = $False,
        $ProfilePath = $PROFILE,
        $PSModulesPath = $PSModulesPath
    )

    # Explicitly set Debug and Verbose if not provided
    $Debug = $Debug -eq $True
    $Verbose = $Verbose -eq $True

    $InstallModuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath ".\scripts\Set-Profile.ps1"

    Write-Debug "Calling script: $InstallModuleScriptPath"
    Write-Debug "Debug: $($Debug), Verbose: $($Verbose)"

    try {
        ## Call the script to update the module's manifest
        & $InstallModuleScriptPath `
            -Debug:$Debug `
            -Verbose:$Verbose `
            -ProfilePath $ProfilePath `
            -PSModulesPath $PSModulesPath
    } catch {
        Write-Error "Error installing custom profile. Details: $($_.Exception.Message)"
        exit 1
    }
}

function main() {
    Write-Output "`n[ Update Powershell module's .psd1 manifest file ]" -ForegroundColor Blue

    try {
        Start-ModuleManifestUpdate `
            -GUIDFilePath $GUIDFilePath `
            -Author $Author `
            -AuthorFilePath $AuthorFilePath `
            -VersionFilePath $VersionFilePath `
            -ManifestPath $ManifestPath `
            -FunctionsPath $FunctionsPath `
            -AliasesFile $AliasesFile `
            -Verbose:$Verbose `
            -Debug:$Debug
    }
    catch {
        Write-Error "Error creating/updating module manifest. Details: $($_.Exception.Message)"
    }

    Write-Output "`n[ Install ProfileModule in path: $($PSModulesPath) ]" -ForegroundColor Blue
    try {
        Start-ModuleInstall `
            -Debug:$Debug `
            -Verbose:$Verbose
    }
    catch {
        Write-Error "Failed to install ProfileModule Powershell module. Details: $($_.Exception.Message)"
    }

    Write-Output "`n[ Install custom `$PROFILE ]" -ForegroundColor Blue

    try {
        Start-ProfileInstall `
            -Debug:$Debug `
            -Verbose:$Verbose
    } catch {
        Write-Error "Error installing custom profile. Details: $($_.Exception.Message)"
        exit 1
    }
}

main
