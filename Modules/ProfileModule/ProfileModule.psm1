## Set directory separator character, i.e. '\' on Windows
$DirectorySeparator = [System.IO.Path]::DirectorySeparatorChar

## Set name of module from $PSScriptRoot
$ModuleName = $PSScriptRoot.Split($DirectorySeparator)[-1]

## Define paths using Join-Path (cleaner and slightly faster)
$PublicFunctionsPath = Join-Path $PSScriptRoot 'Functions' 'Public'
$PrivateFunctionsPath = Join-Path $PSScriptRoot 'Functions' 'Private'
$AliasesPath = Join-Path $PSScriptRoot 'Aliases'

## Import Unix.ps1 if it exists
$UnixPath = Join-Path $PublicFunctionsPath 'Unix.ps1'
if (Test-Path -LiteralPath $UnixPath) {
    . $UnixPath
}

## Get list of .ps1 files - use -File parameter for faster filtering
if (Test-Path -LiteralPath $PrivateFunctionsPath) {
    $PrivateFunctions = Get-ChildItem -LiteralPath $PrivateFunctionsPath -Recurse -Filter *.ps1 -File
    
    ## Load all private functions
    foreach ($file in $PrivateFunctions) {
        . $file.FullName
    }
}

## Get and load public functions
$PublicFunctions = Get-ChildItem -LiteralPath $PublicFunctionsPath -Recurse -Filter *.ps1 -File
$PublicFunctionNames = [System.Collections.Generic.List[string]]::new()

foreach ($file in $PublicFunctions) {
    . $file.FullName
    
    ## OPTIMIZATION: Extract function name from filename instead of parsing content
    ## Most files are named the same as the function (e.g., Get-Something.ps1 contains function Get-Something)
    $baseName = $file.BaseName
    $PublicFunctionNames.Add($baseName)
}

## Export public functions
foreach ($functionName in $PublicFunctionNames) {
    Export-ModuleMember -Function $functionName
}

## Load and export aliases
if (Test-Path -LiteralPath $AliasesPath) {
    ## Snapshot aliases BEFORE loading
    $AliasesBefore = @(Get-Alias -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    
    ## Source all alias files
    $AliasFiles = Get-ChildItem -LiteralPath $AliasesPath -Recurse -Filter *.ps1 -File
    
    foreach ($AliasFile in $AliasFiles) {
        try {
            . $AliasFile.FullName
        }
        catch {
            Write-Error "Error sourcing alias file: $($AliasFile.FullName). Details: $($_.Exception.Message)"
        }
    }
    
    ## OPTIMIZATION: Get NEW aliases by comparing snapshots
    $AliasesAfter = @(Get-Alias -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    $NewAliases = $AliasesAfter | Where-Object { $_ -notin $AliasesBefore }
    
    ## Export new aliases
    foreach ($AliasName in $NewAliases) {
        Export-ModuleMember -Alias $AliasName
    }
}
