param(
    [string]$Author,
    [string]$ModuleRoot = ".\ProfileModule",
    [string]$FunctionsPath = (Join-Path $ModuleRoot "Functions"),
    [string]$AliasesFile = (Join-Path $ModuleRoot "Aliases.ps1"),
    [string]$ManifestPath = (Join-Path $ModuleRoot "MyPSProfile.psd1"),
    [string]$GUIDFilePath = (Join-Path $ModuleRoot "guid.txt"),
    [string]$AuthorFilePath = (Join-Path $ModuleRoot "author.txt"),
    [string]$VersionFilePath = (Join-Path $ModuleRoot "version.txt"),
    [switch]$Debug,
    [switch]$Verbose
)

If ( $Debug ) {
    $DebugPreference = "Continue"
}

If ( $Verbose ) {
    $VerbosePreference = "Continue"
}

Write-Verbose "Author string: $Author"
Write-Verbose "Module root: $($ModuleRoot)"
Write-Verbose "Functions path: $($FunctionsPath)"
Write-Verbose "Aliases file: $($AliasesFile)"
Write-Verbose "Manifest file path: $($ManifestPath)"
Write-Verbose "Module GUID file path: $($GUIDFilePath)"
Write-Verbose "Module author file path: $($AuthorFilePath)"
Write-Verbose "Module version file path: $($VersionFilePath)"

## Generate GUID if it doesn't exist
if ( -Not ( Test-Path -Path $GUIDFilePath ) ) {
    Write-Debug "GUID file '$($GUIDFilePath)' does not exist. Generating GUID and saving to file."
    $guid = [guid]::NewGuid().ToString()
    Set-Content -Path $GUIDFilePath -Value $guid
} else {
    Write-Debug "Loading GUID from file: $($GUIDFilePath)"
    $guid = Get-Content -Path $GUIDFilePath
}

## Save author if provided
if ( $Author ) {
    Write-Debug "Saving author '$Author' to path: $($AuthorFilePath)"
    ## Set author.txt contents to -Author param value
    Set-Content -Path $AuthorFilePath -Value $Author
} elseif ( -Not (Test-Path -Path $AuthorFilePath)) {
    Write-Error "Author not provided and author.txt does not exist."
    exit 1
} else {
    ## Load author from author.txt file
    Write-Debug "Loading author from file: $($AuthorFilePath)"
    $Author = Get-Content -Path $AuthorFilePath
}

## Set version if it doesn't exist
if ( -Not ( Test-Path -Path $VersionFilePath ) ) {
    ## Initialize version.txt contents with 0.1.0
    Write-Debug "Version file not found at path '$($VersionFilePath)'. Saving version '0.1.0' to version file."
    $version = "0.1.0"
    Set-Content -Path $VersionFilePath -Value $version
} else {
    ## Load version from version.txt file
    Write-Debug "Loading module version from file '$($VersionFilePath)'."
    $version = Get-Content -Path $VersionFilePath
}

## Import existing module manifest if it exists
if ( Test-Path -Path $ManifestPath ) {
    Write-Debug "Loading module manifest contents from path '$($ManifestPath)'"
    $manifest = Import-PowerShellDataFile -Path $ManifestPath
} else {
    Write-Debug "Did not find module manifest at path '$($ManifestPath)'. Initializing new manifest."

    $manifest = @{
        RootModule          = "$moduleRoot\MyPSProfile.psm1"
        ModuleVersion       = $version
        GUID                = $guid
        Author              = $Author
        FunctionsToExport   = @()
        AliasesToExport     = @()
        CmdletsToExport     = @()
        VariablesToExport   = @()
    }
}

function Get-FunctionsFromScript {
    <#
        .SYNOPSIS
        Helper function to extract functions from script content
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
            $Functions += $match.Groups[1].Value
        }
    }

    return $Functions
}

# Helper function to extract aliases from script content
function Get-AliasesFromScript {
    Param(
        $ScriptContent
    )

    $Aliases = @()
    $aliasRegex = [regex]'(?ms)^\s*Set-Alias\s+-Name\s+(\w+)\s+-Value\s+(\w+)'
    $SearchMatches = $aliasRegex.Matches($scriptContent)

    ForEach ($match in $SearchMatches) {
        ## Check if alias is uncommented
        if ( -Not ( $match.Value -match '^\s*#' ) ) {
            $Aliases += $match.Groups[1].Value
        }
    }

    return $Aliases
}

Write-Host "Updating Powershell module at path: $($ModuleRoot)" -ForegroundColor Green

## Update functions and aliases
$Functions = @()
$Aliases = @()

## Scan for functions
if ( Test-Path -Path $FunctionsPath -PathType Container ) {
    Write-Host "Scanning path '$($FunctionsPath)' for script files with functions." -ForegroundColor Cyan

    $scripts = Get-ChildItem -Path $FunctionsPath -Filter *.psm1
    
    If ( $Scripts ) {
        Write-Host "Extracting uncommented functions." -ForegroundColor Magenta
    }
    ForEach ($script in $scripts) {
        $scriptContent = Get-Content -Path $script.FullName -Raw
        $Functions += Get-FunctionsFromScript -scriptContent $scriptContent
    }
}

## Scan for aliases
if ( Test-Path -Path $AliasesFile -PathType Leaf ) {
    Write-Host "Scanning path '$($AliasesFile)' for aliases." -ForegroundColor Cyan

    $scriptContent = Get-Content -Path $AliasesFile -Raw
    Write-Host "Extracting uncommented aliases" -ForegroundColor Magenta
    $Aliases += Get-AliasesFromScript -scriptContent $scriptContent
}

## Add discovered functions to manifest's FunctionsToExport
$manifest.FunctionsToExport = $Functions
## Add discovered aliases to manifest's AliasesToExport
$manifest.AliasesToExport = $Aliases

Write-Host "Updating module manifest at path '$($ManifestPath)'" -ForegroundColor Cyan
try {
    ## Save the updated or new manifest
    New-ModuleManifest -Path $ManifestPath -RootModule $manifest.RootModule `
        -ModuleVersion $manifest.ModuleVersion -GUID $manifest.GUID `
        -Author $manifest.Author -FunctionsToExport $manifest.FunctionsToExport `
        -AliasesToExport $manifest.AliasesToExport -CmdletsToExport $manifest.CmdletsToExport `
        -VariablesToExport $manifest.VariablesToExport

    Write-Host "Module manifest updated successfully." -ForegroundColor Green
} catch {
    Write-Error "Error updating module manifest file. Details: $($_.Exception.Message)"
}
