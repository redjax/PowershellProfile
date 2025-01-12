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
    $SearchMatches = $functionRegex.Matches($scriptContent)
    $SearchMatches | ForEach-Object { $_.Groups[1].Value }
}

# Function to extract alias names from script content
function Get-AliasesFromScript {
    param($scriptContent)
    $aliasRegex = [regex]'(?ms)^\s*Set-Alias\s+-Name\s+(\w+)\s+-Value\s+(\w+)'
    $SearchMatches = $aliasRegex.Matches($scriptContent)
    $SearchMatches | ForEach-Object { $_.Groups[1].Value }
}

# Scan for functions in .ps1 and .psm1 scripts in Functions directory
if (Test-Path -Path $FunctionsPath -PathType Container) {
    Write-Host "Scanning path '$FunctionsPath' for script files with functions..." -ForegroundColor Cyan
    $scripts = Get-ChildItem -Path $FunctionsPath -Filter "*.psm1,*.ps1" -Recurse
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
    if (-not (Get-Command $function -ErrorAction SilentlyContinue)) {
        $functionDefinition = Get-Content -Path (Join-Path $FunctionsPath "$function.psm1") -Raw
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
