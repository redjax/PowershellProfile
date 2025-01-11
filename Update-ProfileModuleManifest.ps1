Param(
    [switch]$Verbose,
    [switch]$Debug,
    [string]$Author = "redjax",
    [string]$RepositoryPath = $PSScriptRoot,
    [string]$PSModulePath = (Join-Path -Path $RepositoryPath -ChildPath "ProfileModule"),
    [string]$PSModuleManifestFilename = "MyPSProfile.psd1",
    [string]$PSModuleManifestPath = "$($PSModulePath)\$($PSModuleManifestFilename)"
)

If ( $Verbose ) {
    $VerbosePreference = "Continue"
}

If ( $Debug ) {
    $DebugPreference = "Continue"
}

## Automatically update the manifest file (MyPSProfile.psd1)
Write-Debug "MyPSProfile module manifest path: $($PSModuleManifestPath)"
If ( -Not ( Test-Path -Path $PSModuleManifestPath ) ) {
    Write-Error "[ERROR] Could not find manifest file at path: $($PSModuleManifestPath)"
} else {
    Write-Host "Updating MyPSProfile module manifest."
}

## Scan for functions in the module, excluding commented lines
$Functions = Get-ChildItem -Path $PSModulePath -Recurse -Filter "*.psm1" | ForEach-Object {
    ## Extract functions from each .psm1 file, ignoring commented lines
    (Select-String -Path $_.FullName -Pattern "^\s*function\s+([a-zA-Z0-9\-]+)" | ForEach-Object { 
        # Ignore lines that are comments (starting with #)
        if ($_.Line -notmatch '^\s*#') {
            $_.Matches.Groups[1].Value
        }
    })
} | Sort-Object -Unique

If ( $Functions ) {
    Write-Debug "Discovered functions:"
    $Functions | ForEach-Object {
        Write-Debug "$($_)"
    }
} else {
    Write-Host "No functions found."
}

## Scan for aliases in the module (from Aliases.ps1 file)
$Aliases = Get-ChildItem -Path $PSModulePath -Recurse -Filter "*.ps1" | ForEach-Object {
    ## Extract aliases from each .ps1 file, excluding commented lines
    (Select-String -Path $_.FullName -Pattern "^\s*Set-Alias\s+-Name\s+([a-zA-Z0-9\-]+)" | ForEach-Object { 
        # Ignore lines that are comments (starting with #)
        if ($_.Line -notmatch '^\s*#') {
            $_.Matches.Groups[1].Value
        }
    }) 
} | Sort-Object -Unique

If ( $Aliases ) {
    Write-Debug "Discovered aliases:"
    $Aliases | ForEach-Object {
        Write-Debug "$($_)"
    }
} else {
    Write-Host "No aliases found."
}

## Create the manifest hashtable
$Manifest = @{
    ModuleVersion   = '1.0.0'
    GUID            = [guid]::NewGuid().ToString()
    Author          = "'$($Author)'"
    Description     = 'My custom PowerShell Profile Module'
    RootModule      = 'ProfileModule.psm1'
    FunctionsToExport = $Functions
    CmdletsToExport  = @()
    AliasesToExport  = $Aliases
    PrivateData      = @{
        PSData = @{
            Tags        = @('Profile', 'Customization')
            LicenseUri  = ''
            ProjectUri  = ''
        }
    }
}

## Build the .psd1 formatted string
$ManifestString = ""

ForEach ($key in $Manifest.Keys) {
    $value = $Manifest[$key]
    
    # Handle nested hashtables
    if ($value -is [Hashtable]) {
        $valueString = "{"
        ForEach ($subKey in $value.Keys) {
            $subValue = $value[$subKey]
            $valueString += "`n$subKey = '$subValue'"
        }
        $valueString += "`n}"
        $value = $valueString
    }
    
    $ManifestString += "$key = $value`n"
}

Write-Verbose "Manifest file contents: `n$ManifestString"

## Write the formatted manifest string to the .psd1 file
try {
    $ManifestString | Out-File -FilePath $PSModuleManifestPath
    Write-Host "[SUCCESS] Manifest file updated at: $PSModuleManifestPath"
    exit 0
} catch {
    Write-Error "Failed to update manifest file at path '$($PSModuleManifestPath)'. Details: $($_.Exception.Message)"
    exit 1
}