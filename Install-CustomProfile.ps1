Param(
    [switch]$Debug,
    [switch]$Verbose,
    [string]$ModuleAuthor
)

If ( $Debug ) {
    $DebugPreference = "Continue"
}

If ( $Verbose ) {
    $VerbosePreference = "Continue"
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

Write-Verbose "ProfileModule path: $ProfileModuleRoot"
Write-Verbose "Path to module's functions: $FunctionsPath"
Write-Verbose "Path to module's Public/ functions: $PublicFunctionsPath"
Write-Verbose "Path to module's Private/ functions: $PrivateFunctionsPath"
Write-Verbose "Path to module's manifest file: $ManifestPath"
Write-Verbose "Path to module's GUID file: $GUIDFilePath"
Write-Verbose "Path to module's author file: $AuthorFilePath"
Write-Verbose "Path to module's version file: $VersionFilePath"

#################################
# CREATE/UPDATE MODULE MANIFEST #
#################################

function Get-FunctionsFromScript {
    <#
        .SYNOPSIS
        Scan .ps1 script for function definitions.
    #>
    Param(
        $scriptContent
    )

    $Functions = @()
    $functionRegex = [regex]'(?ms)^function\s+([^\s{]+)\s*{'
    $SearchMatches = $functionRegex.Matches($scriptContent)
    
    ForEach ($match in $SearchMatches) {
        ## Check if function is uncommented
        if ( -Not ( $match.Value -match '^\s*#' ) ) {
            # $Functions += $match.Groups[1].Value

            # Remove any parentheses from the function name
            $functionName = $match.Groups[1].Value -replace '\(\)', ''
            $Functions += $functionName
        }
    }

    return $Functions
}

function Get-AliasesFromScript {
    <#
        .SYNOPSIS
        Scan a .ps1 file for alias definitions.
    #>
    Param(
        $ScriptContent
    )

    $Aliases = @()
    $aliasRegex = [regex]'(?ms)^\s*Set-Alias\s+-Name\s+(\w+)\s+-Value\s+(\w+)'
    $SearchMatches = $aliasRegex.Matches($ScriptContent)

    ForEach ($match in $SearchMatches) {
        ## Check if alias is uncommented
        if ( -Not ( $match.Value -match '^\s*#' ) ) {
            $Aliases += $match.Groups[1].Value
        }
    }

    return $Aliases
}

function Start-ModuleManifestUpdate() {
    <#
        .SYNOPSIS
        Create or update the module's .psd1 module manifest.
    #>
    Param(
        $GUIDFilePath = $GUIDFilePath,
        $Author = $Author,
        $AuthorFilePath = $AuthorFilePath,
        $VersionFilePath = $VersionFilePath,
        $ManifestPath = $ManifestPath,
        $FunctionsPath = $FunctionsPath,
        $AliasesFile = $AliasesFile
    )

    Write-Host "Creating/updating module manifest .psd1 file."

    ## Generate GUID if it doesn't exist
    if ( -Not ( Test-Path -Path $GUIDFilePath ) ) {
        Write-Debug "GUID file '$($GUIDFilePath)' does not exist. Generating GUID and saving to file."
        $guid = [guid]::NewGuid().ToString()
    
        ## Write GUID to file
        Set-Content -Path $GUIDFilePath -Value $guid
    }
    else {
        Write-Debug "Loading GUID from file: $($GUIDFilePath)"
        $guid = Get-Content -Path $GUIDFilePath
    }

    ## Save author if provided
    if ( $Author ) {
        Write-Debug "Saving author '$Author' to path: $($AuthorFilePath)"
        Set-Content -Path $AuthorFilePath -Value $Author
    }
    elseif ( -Not (Test-Path -Path $AuthorFilePath)) {
        Write-Error "Author not provided and author.txt does not exist."
        exit 1
    }
    else {
        Write-Debug "Loading author from file: $($AuthorFilePath)"
        $Author = Get-Content -Path $AuthorFilePath
    }

    ## Set version if it doesn't exist
    if ( -Not ( Test-Path -Path $VersionFilePath ) ) {
        Write-Debug "Version file not found at path '$($VersionFilePath)'. Saving version '0.1.0' to version file."
        $version = "0.1.0"
        Set-Content -Path $VersionFilePath -Value $version
    }
    else {
        Write-Debug "Loading module version from file '$($VersionFilePath)'."
        $version = Get-Content -Path $VersionFilePath
    }

    ## Import existing module manifest if it exists
    if ( Test-Path -Path $ManifestPath ) {
        Write-Debug "Loading module manifest contents from path '$($ManifestPath)'"
        $manifest = Import-PowerShellDataFile -Path $ManifestPath
    }
    else {
        Write-Debug "Did not find module manifest at path '$($ManifestPath)'. Initializing new manifest."
        $manifest = @{
            RootModule        = ".\ProfileModule.psm1"
            ModuleVersion     = $version
            GUID              = $guid
            Author            = $Author
            FunctionsToExport = @()
            AliasesToExport   = @()
            CmdletsToExport   = @()
            VariablesToExport = @()
        }
    }

    Write-Host "Updating Powershell module at path: $($ProfileModuleRoot)" -ForegroundColor Green

    ## Create arrays to store functions & aliases to export
    $Functions = @()
    $Aliases = @()

    ## Scan for functions in Public/ directory only
    $PublicFunctionsPath = Join-Path $FunctionsPath "Public"
    if ( Test-Path -Path $PublicFunctionsPath -PathType Container ) {
        Write-Host "Scanning path '$($PublicFunctionsPath)' for script files with functions." -ForegroundColor Cyan

        $publicScripts = Get-ChildItem -Path $PublicFunctionsPath -Filter *.ps1

        If ( $publicScripts ) {
            Write-Host "Extracting uncommented functions from public scripts." -ForegroundColor Magenta
        }

        ForEach ($script in $publicScripts) {
            Write-Debug "Loading scripts in: $script"
            $scriptContent = Get-Content -Path $script.FullName -Raw
            $Functions += Get-FunctionsFromScript -scriptContent $scriptContent
        }
    }
    Write-Debug "Discovered functions: $($Functions)"

    Write-Debug "Aliases path: $AliasesFile"
    ## Scan for aliases
    if ( Test-Path -Path $AliasesFile -PathType Leaf ) {
        Write-Host "Scanning path '$($AliasesFile)' for aliases." -ForegroundColor Cyan

        $scriptContent = Get-Content -Path $AliasesFile -Raw
        Write-Host "Extracting uncommented aliases" -ForegroundColor Magenta
        $Aliases += Get-AliasesFromScript -scriptContent $scriptContent
    }

    # Ensure these are actual arrays of strings
    $FunctionsArray = @($Functions | ForEach-Object { "'$_'" })
    $AliasesArray = @($Aliases | ForEach-Object { "'$_'" })

    ## Add discovered functions to manifest's FunctionsToExport
    $manifest.FunctionsToExport = $FunctionsArray
    ## Add discovered aliases to manifest's AliasesToExport
    $manifest.AliasesToExport = $AliasesArray

    # Make sure that the RootModule, ModuleVersion, GUID, and Author are populated
    $manifest.RootModule = ".\ProfileModule.psm1"  # You can change this if necessary
    $manifest.ModuleVersion = $version
    $manifest.GUID = $guid
    $manifest.Author = $Author

    Write-Host "Updating module manifest at path '$($ManifestPath)'" -ForegroundColor Cyan
    try {
        ## Save the updated or new manifest
        $manifestContent = @"
@{
    RootModule          = '$($manifest.RootModule)'
    ModuleVersion       = '$($manifest.ModuleVersion)'
    GUID                = '$($manifest.GUID)'
    Author              = '$($manifest.Author)'
    FunctionsToExport   = @($($FunctionsArray -join ', '))
    AliasesToExport     = @($($AliasesArray -join ', '))
    CmdletsToExport     = @()
    VariablesToExport   = @()
}
"@
        Set-Content -Path $ManifestPath -Value $manifestContent

        Write-Host "Module manifest updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Error updating module manifest file. Details: $($_.Exception.Message)"
    }
}

function main() {
    try {
        Start-ModuleManifestUpdate `
            -GUIDFilePath $GUIDFilePath `
            -Author $Author `
            -AuthorFilePath $AuthorFilePath `
            -VersionFilePath $VersionFilePath `
            -ManifestPath $ManifestPath `
            -FunctionsPath $FunctionsPath `
            -AliasesFile $AliasesFile
    } catch {
        Write-Error "Error creating/updating module manifest. Details: $($_.Exception.Message)"
    }
}

main
