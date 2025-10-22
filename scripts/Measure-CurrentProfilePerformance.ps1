<#
.SYNOPSIS
    Measures performance of your currently installed PowerShell profile with detailed breakdown
    
.DESCRIPTION
    Analyzes module load times and total profile initialization time
    
.EXAMPLE
    .\scripts\Measure-CurrentProfilePerformance.ps1
#>

Write-Host "`n=== Current Profile Performance Analysis ===`n" -ForegroundColor Cyan

## Check if profile exists
if (-not (Test-Path $PROFILE)) {
    Write-Host "No profile found at: $PROFILE" -ForegroundColor Red
    exit 1
}

Write-Host "Profile Location: $PROFILE" -ForegroundColor Yellow
Write-Host ""

## Measure actual profile load time in a new session
Write-Host "Analyzing profile load performance" -ForegroundColor Yellow
Write-Host ""

$testScript = @'
Write-Host "=== Profile Load Performance Analysis ===`n" -ForegroundColor Cyan

# Start timing
$profileStart = Get-Date

# Track module load times
$moduleTimes = @{}

# Measure ProfileModule
Write-Host "Loading ProfileModule" -ForegroundColor Gray
$pmStart = Get-Date
Import-Module ProfileModule -ErrorAction SilentlyContinue
$pmEnd = Get-Date
$moduleTimes['ProfileModule'] = ($pmEnd - $pmStart).TotalMilliseconds

# Measure Custom Modules individually
$customModulesPath = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath "CustomModules"
if (Test-Path $customModulesPath) {
    Write-Host "Loading Custom Modules" -ForegroundColor Gray
    $customModules = Get-ChildItem -Path $customModulesPath -Directory -ErrorAction SilentlyContinue
    
    foreach ($module in $customModules) {
        $modStart = Get-Date
        Import-Module -Name $module.FullName -Global -ErrorAction SilentlyContinue
        $modEnd = Get-Date
        $moduleTimes[$module.Name] = ($modEnd - $modStart).TotalMilliseconds
    }
}

# Measure completion scripts
Write-Host "Loading completion scripts" -ForegroundColor Gray
$completionTimes = @{}

if (Get-Module -ListAvailable -Name posh-git) {
    $pgStart = Get-Date
    Import-Module posh-git -ErrorAction SilentlyContinue
    $pgEnd = Get-Date
    $completionTimes['posh-git'] = ($pgEnd - $pgStart).TotalMilliseconds
}

if (Get-Command azd -ErrorAction SilentlyContinue) {
    $azdStart = Get-Date
    azd completion powershell | Out-String | Invoke-Expression
    $azdEnd = Get-Date
    $completionTimes['azd'] = ($azdEnd - $azdStart).TotalMilliseconds
}

if (Get-Command op -ErrorAction SilentlyContinue) {
    $opStart = Get-Date
    op completion powershell | Out-String | Invoke-Expression
    $opEnd = Get-Date
    $completionTimes['1Password (op)'] = ($opEnd - $opStart).TotalMilliseconds
}

# Calculate total time
$profileEnd = Get-Date
$totalTime = ($profileEnd - $profileStart).TotalMilliseconds

# Display results
Write-Host "`n=== Module Load Times ===" -ForegroundColor Cyan

$sortedModules = $moduleTimes.GetEnumerator() | Sort-Object -Property Value -Descending

$totalModuleTime = 0
foreach ($entry in $sortedModules) {
    $time = [Math]::Round($entry.Value)
    $totalModuleTime += $time
    
    $color = if ($time -gt 500) { 'Red' } 
             elseif ($time -gt 200) { 'Yellow' } 
             else { 'Green' }
    
    $padding = " " * (45 - $entry.Key.Length)
    Write-Host "  $($entry.Key)$padding$time ms" -ForegroundColor $color
}

Write-Host "`n  ────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Total Module Time:                              $([Math]::Round($totalModuleTime)) ms" -ForegroundColor Cyan

if ($completionTimes.Count -gt 0) {
    Write-Host "`n=== Completion Script Times ===" -ForegroundColor Cyan
    
    $totalCompletionTime = 0
    foreach ($entry in $completionTimes.GetEnumerator() | Sort-Object -Property Value -Descending) {
        $time = [Math]::Round($entry.Value)
        $totalCompletionTime += $time
        
        $color = if ($time -gt 1000) { 'Red' } 
                 elseif ($time -gt 500) { 'Yellow' } 
                 else { 'Green' }
        
        $padding = " " * (45 - $entry.Key.Length)
        Write-Host "  $($entry.Key)$padding$time ms" -ForegroundColor $color
    }
    
    Write-Host "`n  ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Total Completion Time:                          $([Math]::Round($totalCompletionTime)) ms" -ForegroundColor Cyan
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$totalColor = if ($totalTime -lt 1000) { 'Green' } elseif ($totalTime -lt 3000) { 'Yellow' } else { 'Red' }
Write-Host "  TOTAL LOAD TIME:                                $([Math]::Round($totalTime)) ms" -ForegroundColor $totalColor

# Module count
$loadedModules = Get-Module | Where-Object { 
    $_.Path -like "*CustomModules*" -or 
    $_.Name -eq "ProfileModule" -or 
    $_.Name -eq "posh-git" 
}
Write-Host "  Modules loaded:                                 $(@($loadedModules).Count)" -ForegroundColor Cyan

# Performance rating
Write-Host ""
if ($totalTime -lt 1000) {
    Write-Host "  ✅ Excellent performance! (<1 second)" -ForegroundColor Green
} elseif ($totalTime -lt 3000) {
    Write-Host "  ⚠️  Acceptable performance (1-3 seconds)" -ForegroundColor Yellow
    Write-Host "     Consider moving slow modules to background" -ForegroundColor Gray
} else {
    Write-Host "  ❌ Slow performance (>3 seconds)" -ForegroundColor Red
    Write-Host "     Strongly recommend optimizations" -ForegroundColor Gray
}

Write-Host ""
'@

# Save to temp file
$tempScript = "$env:TEMP\measure-profile-perf.ps1"
$testScript | Out-File -FilePath $tempScript -Encoding UTF8

# Run in new PowerShell session
& pwsh -NoLogo -NoProfile -File $tempScript

# Cleanup
Remove-Item $tempScript -ErrorAction SilentlyContinue

Write-Host "=== Analysis Complete ===`n" -ForegroundColor Cyan
