# Define paths
$ModuleRoot = (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)
$FunctionsPath = Join-Path $ModuleRoot "Functions"
$AliasesFile = Join-Path $ModuleRoot "Aliases.ps1"

# Initialize arrays for functions and aliases
$FunctionsToExport = @()
$AliasesToExport = @()

# Function to extract function names from script content
function Get-FunctionsFromScript {
    param($scriptContent)
    $functionRegex = [regex]'(?ms)^function\s+([^\s{]+)\s*{'
    $searchmatches = $functionRegex.Matches($scriptContent)
    $searchmatches | ForEach-Object { $_.Groups[1].Value }
}

# Function to extract alias names from script content
function Get-AliasesFromScript {
    param($scriptContent)
    $aliasRegex = [regex]'(?ms)^\s*Set-Alias\s+-Name\s+(\w+)\s+-Value\s+(\w+)'
    $searchmatches = $aliasRegex.Matches($scriptContent)
    $searchmatches | ForEach-Object { $_.Groups[1].Value }
}

# Scan for functions in .ps1 and .psm1 scripts in Functions directory
if (Test-Path -Path $FunctionsPath -PathType Container) {
    Write-Host "Scanning path '$FunctionsPath' for script files with functions..." -ForegroundColor Cyan
    $scripts = Get-ChildItem -Path $FunctionsPath -Recurse -Include "*.psm1", "*.ps1"
    foreach ($script in $scripts) {
        Write-Host "Scanning file: $($script.FullName)" -ForegroundColor Magenta
        $scriptContent = Get-Content -Path $script.FullName -Raw
        $FunctionsToExport += Get-FunctionsFromScript -scriptContent $scriptContent
    }
}

# Scan for aliases in Aliases.ps1 file
if (Test-Path -Path $AliasesFile -PathType Leaf) {
    Write-Host "Importing aliases from '$AliasesFile'..." -ForegroundColor Cyan
    $scriptContent = Get-Content -Path $AliasesFile -Raw
    $AliasesToExport += Get-AliasesFromScript -scriptContent $scriptContent
}

# Ensure functions and aliases are available when the module is imported
Write-Host "Exporting functions: $($FunctionsToExport -join ', ')" -ForegroundColor Green
Write-Host "Exporting aliases: $($AliasesToExport -join ', ')" -ForegroundColor Green

# Create dynamic functions in the module scope and export them
foreach ($function in $FunctionsToExport) {
    $functionPath = Join-Path $FunctionsPath "$function.psm1"
    if (Test-Path $functionPath) {
        Write-Host "Loading function from file: $functionPath" -ForegroundColor Yellow
        $functionDefinition = Get-Content -Path $functionPath -Raw
        Invoke-Expression $functionDefinition
    }
    Export-ModuleMember -Function $function
}

# Create dynamic aliases and export them
foreach ($alias in $AliasesToExport) {
    Set-Alias -Name $alias -Value $alias
    Export-ModuleMember -Alias $alias
}

Write-Host "Module setup completed." -ForegroundColor Green
