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
    
    ## For files with multiple functions (like Helpers.ps1), parse the content
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $functionMatches = [regex]::Matches($content, '(?m)^function\s+([\w-]+)')
    
    if ($functionMatches.Count -gt 1) {
        ## Multi-function file: extract all function names
        foreach ($match in $functionMatches) {
            $PublicFunctionNames.Add($match.Groups[1].Value)
        }
    }
    elseif ($functionMatches.Count -eq 1) {
        ## Single function file: use parsed name (more reliable than filename)
        $PublicFunctionNames.Add($functionMatches[0].Groups[1].Value)
    }
    else {
        ## No functions found, skip (might be a script or utility file)
        Write-Warning "No functions found in file: $($file.Name)"
    }
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
