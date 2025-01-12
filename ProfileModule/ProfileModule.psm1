## Set directory separator character, i.e. '\' on Windows
$DirectorySeparator = [System.IO.Path]::DirectorySeparatorChar

## Set name of module from $PSScriptRoot
$ModuleName = $PSScriptRoot.Split($DirectorySeparator)[-1]

## Define paths to public and private function directories
$PublicFunctionsPath = $PSScriptRoot + $DirectorySeparator + 'Functions' + $DirectorySeparator + 'Public' + $DirectorySeparator
$PrivateFunctionsPath = $PSScriptRoot + $DirectorySeparator + 'Functions' + $DirectorySeparator + 'Private' + $DirectorySeparator

## Regular expression to match function definitions
$functionRegex = 'function\s+([^\s{]+)\s*\{'

## Get list of .ps1 files in Public/ recursively
$PublicFunctions = Get-ChildItem -Path $PublicFunctionsPath -Recurse -Filter *.ps1

## Get list of .ps1 files in Private/ recursively
$PrivateFunctions = Get-ChildItem -Path $PrivateFunctionsPath -Recurse -Filter *.ps1

## Load all PowerShell functions from script files
$PrivateFunctions | ForEach-Object { 
    # Write-Host "Sourcing private function from: $($_.FullName)"
    . $_.FullName 
}  # Load private functions first

$PublicFunctions | ForEach-Object { 
    # Write-Host "Sourcing public function from: $($_.FullName)"
    . $_.FullName 
}   # Load public functions after

## Gather function names from each script in the Public folder
$PublicFunctionNames = @()

foreach ($script in $PublicFunctions) {
    $scriptContent = Get-Content -Path $script.FullName -Raw
    $SearchMatches = [regex]::Matches($scriptContent, $functionRegex)
    
    foreach ($match in $SearchMatches) {
        $functionName = $match.Groups[1].Value
        $PublicFunctionNames += $functionName
    }
}

## Debugging: Output the function names
# Write-Host "Public functions to export: $PublicFunctionNames"

## Export each public function individually
$PublicFunctionNames | ForEach-Object {
    Export-ModuleMember -Function $_
}

# Write-Host "Module loaded and functions exported."
