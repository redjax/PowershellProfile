## Set directory separator character, i.e. '\' on Windows
$DirectorySeparator = [System.IO.Path]::DirectorySeparatorChar

## Set name of module from $PSScriptRoot
$ModuleName = $PSScriptRoot.Split($DirectorySeparator)[-1]

## Define paths to public and private function directories
$PublicFunctionsPath = $PSScriptRoot + $DirectorySeparator + 'Functions' + $DirectorySeparator + 'Public' + $DirectorySeparator
$PrivateFunctionsPath = $PSScriptRoot + $DirectorySeparator + 'Functions' + $DirectorySeparator + 'Private' + $DirectorySeparator

## Path to Aliases.ps1
$AliasesFilePath = $PSScriptRoot + $DirectorySeparator + 'Aliases.ps1'
$AliasesPath = $PSScriptRoot + $DirectorySeparator + "Aliases"

## Regular expression to match function definitions
$functionRegex = 'function\s+([^\s{]+)\s*\{'

## Import Unix.ps1 if it exists
if (Test-Path -Path "$($PublicFunctionsPath)Unix.ps1") {
    . $PublicFunctionsPath"Unix.ps1"
}

## Get list of .ps1 files in Public/ recursively
$PublicFunctions = Get-ChildItem -Path $PublicFunctionsPath -Recurse -Filter *.ps1

## Get list of .ps1 files in Private/ recursively
if (Test-Path "$($PrivateFunctionsPath)") {
    $PrivateFunctions = ( Get-ChildItem -Path $PrivateFunctionsPath -Recurse -Filter *.ps1 )

    ## Load all private/internal Powershell functions from script files
    $PrivateFunctions | ForEach-Object {
        Write-Debug "Sourcing private function: $($_.FullName)"

        . "$($_.FullName)"
    }
}

$PublicFunctions | ForEach-Object {
    Write-Debug "Sourcing public function: $($_.FullName)"
    . $_.FullName
}

## Gather function names from each script in the Public folder
$PublicFunctionNames = @()

foreach ($script in $PublicFunctions) {
    $scriptContent = Get-Content -Path $script.FullName -Raw
    # $ScriptContent = [System.IO.File]::ReadAllText($script.FullName)
    $SearchMatches = [regex]::Matches($scriptContent, $functionRegex)

    foreach ($match in $SearchMatches) {
        $functionName = $match.Groups[1].Value
        $PublicFunctionNames += $functionName
    }
}

## Export each public function individually
$PublicFunctionNames | ForEach-Object {
    Write-Debug "Exporting public function: $($_)"
    Export-ModuleMember -Function $_
}

## Load and export aliases from the Aliases directory
if (Test-Path -Path $AliasesPath) {
    $AliasFiles = Get-ChildItem -Path $AliasesPath -Recurse -Filter *.ps1
    
    # Source all alias files first
    foreach ($AliasFile in $AliasFiles) {
        Write-Debug "Sourcing alias file: $($AliasFile.FullName)"
        try {
            . $AliasFile.FullName
        }
        catch {
            Write-Error "Error sourcing alias file: $($AliasFile.FullName). Details: $($_.Exception.Message)"
            continue
        }
    }

    # Gather all aliases that were created during module loading
    # Get a snapshot of aliases before and after loading to identify new ones
    $AllCurrentAliases = Get-Command -CommandType Alias
    
    # Get aliases that are likely defined by this module by checking against known patterns
    # or by getting all aliases and filtering out system ones
    $ModuleAliases = @()
    
    # Get aliases from the alias files we just loaded
    foreach ($AliasFile in $AliasFiles) {
        $AliasFileContent = Get-Content -Path $AliasFile.FullName -Raw
        # Look for Set-Alias commands to identify aliases defined in this module
        $SetAliasMatches = [regex]::Matches($AliasFileContent, 'Set-Alias\s+(?:-Name\s+)?([^\s]+)')
        foreach ($Match in $SetAliasMatches) {
            $AliasName = $Match.Groups[1].Value.Trim('"''')
            $ModuleAliases += $AliasName
        }
    }

    # Track already exported aliases to avoid double-exporting
    $ExportedAliases = @()

    ## Export each alias only if it hasn't been exported yet
    if ( $ModuleAliases ) {
        foreach ( $AliasName in $ModuleAliases ) {
            # Check if the alias actually exists and hasn't been exported yet
            $AliasCommand = Get-Command -Name $AliasName -CommandType Alias -ErrorAction SilentlyContinue
            if ( $AliasCommand -and $ExportedAliases -notcontains $AliasName ) {
                Write-Debug "Exporting alias: $($AliasName)"
                Export-ModuleMember -Alias $AliasName

                ## Add alias to the list of exported aliases
                $ExportedAliases += $AliasName
            }
            elseif ( -not $AliasCommand ) {
                Write-Debug "Alias not found or not available: $($AliasName)"
            }
            else {
                Write-Debug "Skipping duplicate export for alias: $($AliasName)"
            }
        }
    }
    else {
        Write-Warning "No aliases found to export."
    }
}
