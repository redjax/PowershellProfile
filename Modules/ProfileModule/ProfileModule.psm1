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
    $PrivateFunctions = Get-ChildItem -Path $PrivateFunctionsPath -Recurse -Filter *.ps1

    ## Load all private/internal Powershell functions from script files
    $PrivateFunctions | ForEach-Object {
        .$_.FullName
    }
}

$PublicFunctions | ForEach-Object {
    .$_.FullName
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
    Export-ModuleMember -Function $_
}

## Source the Aliases.ps1 file if it exists
if (Test-Path -Path $AliasesFilePath) {
    .$AliasesFilePath

    ## Export aliases after sourcing the Aliases.ps1
    $Aliases = Get-Command -CommandType Alias | Where-Object { $_.Source -eq $ModuleName }

    $Aliases | ForEach-Object {
        Export-ModuleMember -Alias $_.Name
    }
}

## Load and export aliases from the Aliases directory
if (Test-Path -Path $AliasesPath) {
    $AliasFiles = Get-ChildItem -Path $AliasesPath -Recurse -Filter *.ps1

    foreach ($AliasFile in $AliasFiles) {
        # Source each .ps1 file in the Aliases directory
        .$AliasFile.FullName
    }

    ## Get all aliases defined in the module
    $Aliases = Get-Command -CommandType Alias | Where-Object { $_.Source -eq $ModuleName }

    ## Export each alias
    $Aliases | ForEach-Object {
        Export-ModuleMember -Alias $_.Name
    }
}
