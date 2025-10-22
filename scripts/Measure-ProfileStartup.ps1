<#
.SYNOPSIS
    Detailed profiling of PowerShell profile with granular timing
    
.DESCRIPTION
    Instruments and profiles your PowerShell profile to identify performance bottlenecks.
    Shows timing for every command, module import, and function call.
    
.PARAMETER OutputPath
    Path to save detailed profiling results (optional)
    
.EXAMPLE
    .\scripts\Profile-Detailed.ps1
    
.EXAMPLE
    .\scripts\Profile-Detailed.ps1 -OutputPath "profile-analysis.txt"
#>

param(
    [string]$OutputPath
)

Write-Host "`n=== Detailed Profile Profiling ===`n" -ForegroundColor Cyan

if (-not (Test-Path $PROFILE)) {
    Write-Host "No profile found at: $PROFILE" -ForegroundColor Red
    exit 1
}

Write-Host "Profile: $PROFILE" -ForegroundColor Yellow
Write-Host "Starting instrumented profile analysis...`n" -ForegroundColor Yellow

# Create profiling script
$profilingScript = @"
# Enable strict mode and debugging
`$ErrorActionPreference = 'Continue'
`$VerbosePreference = 'Continue'

# Initialize the ManualResetEvent objects that the profile expects
`$Global:ProfileModuleImported = New-Object System.Threading.ManualResetEvent `$false
`$Global:CustomModulesImported = New-Object System.Threading.ManualResetEvent `$false

# Profiling data collection
`$Global:ProfileTimings = @()
`$Global:CurrentSection = 'Profile Start'
`$Global:SectionStart = Get-Date

function Record-Timing {
    param([string]`$Section)
    
    `$now = Get-Date
    `$duration = (`$now - `$Global:SectionStart).TotalMilliseconds
    
    `$Global:ProfileTimings += [PSCustomObject]@{
        Section = `$Global:CurrentSection
        Duration = `$duration
        Timestamp = `$now
    }
    
    `$Global:CurrentSection = `$Section
    `$Global:SectionStart = `$now
}

# Override Import-Module to track each import
`$OriginalImportModule = Get-Command Import-Module -CommandType Cmdlet
function Import-Module {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=`$true)]
        [string]`$Name,
        [switch]`$Global,
        [switch]`$Force
    )
    
    Record-Timing "Before Import: `$Name"
    
    try {
        `$params = @{
            Name = `$Name
            Global = `$Global
            Force = `$Force
            ErrorAction = `$ErrorActionPreference
        }
        & `$OriginalImportModule @params
    } catch {
        Write-Warning "Failed to import `$(`$Name): `$(`$_.Exception.Message)"
    }
    
    Record-Timing "After Import: `$Name"
}

# Trace profile execution
Write-Host "Executing profile with instrumentation..." -ForegroundColor Gray

try {
    # Source the actual profile
    . '$($PROFILE.Replace("'", "''"))'
    
    Record-Timing "Profile Execution Complete"
    
    # Wait for background tasks
    Start-Sleep -Milliseconds 500
    
    # Try to trigger OnIdle events
    `$idleEvents = Get-EventSubscriber | Where-Object { `$_.SourceIdentifier -eq 'PowerShell.OnIdle' }
    if (`$idleEvents) {
        Record-Timing "Before OnIdle Events"
        foreach (`$event in `$idleEvents) {
            if (`$event.Action) {
                try {
                    # Get the script block from the action
                    `$scriptBlock = `$event.Action.Command
                    if (`$scriptBlock -is [scriptblock]) {
                        & `$scriptBlock
                    } else {
                        # If it's a string, convert to scriptblock
                        `$scriptBlock = [scriptblock]::Create(`$scriptBlock)
                        & `$scriptBlock
                    }
                } catch {
                    Write-Warning "OnIdle event failed: `$(`$_.Exception.Message)"
                }
            }
        }
        Record-Timing "After OnIdle Events"
    }
    
    Start-Sleep -Milliseconds 1000
    Record-Timing "Analysis Complete"
    
} catch {
    Write-Error "Profile execution failed: `$(`$_.Exception.Message)"
}

# Display results
Write-Host "`n=== Timing Analysis ===`n" -ForegroundColor Cyan

`$sortedTimings = `$Global:ProfileTimings | Sort-Object -Property Duration -Descending

foreach (`$timing in `$sortedTimings) {
    `$ms = [Math]::Round(`$timing.Duration, 2)
    
    `$color = if (`$ms -gt 1000) { 'Red' } 
             elseif (`$ms -gt 500) { 'Yellow' } 
             elseif (`$ms -gt 100) { 'Cyan' }
             else { 'Green' }
    
    `$paddedSection = `$timing.Section.PadRight(60)
    Write-Host "  `$paddedSection" -NoNewline
    Write-Host "`$ms ms" -ForegroundColor `$color
}

# Summary
`$totalTime = (`$Global:ProfileTimings | Measure-Object -Property Duration -Sum).Sum
Write-Host "`n  " -NoNewline
Write-Host ("=" * 70) -ForegroundColor DarkGray
Write-Host "  Total Time:".PadRight(60) -NoNewline
Write-Host "`$([Math]::Round(`$totalTime, 2)) ms" -ForegroundColor Cyan

# Top slowest operations
Write-Host "`n=== Top 10 Slowest Operations ===`n" -ForegroundColor Cyan
`$slowest = `$Global:ProfileTimings | Sort-Object -Property Duration -Descending | Select-Object -First 10

foreach (`$item in `$slowest) {
    `$ms = [Math]::Round(`$item.Duration, 2)
    `$color = if (`$ms -gt 1000) { 'Red' } elseif (`$ms -gt 500) { 'Yellow' } else { 'Cyan' }
    Write-Host "  `$(`$item.Section)" -NoNewline
    Write-Host " - " -NoNewline -ForegroundColor DarkGray
    Write-Host "`$ms ms" -ForegroundColor `$color
}

# Module analysis
Write-Host "`n=== Loaded Modules ===`n" -ForegroundColor Cyan
`$modules = Get-Module | Where-Object { 
    `$_.Path -like "*CustomModules*" -or 
    `$_.Name -eq "ProfileModule" -or
    `$_.Name -eq "posh-git"
}

if (`$modules) {
    foreach (`$mod in `$modules | Sort-Object Name) {
        Write-Host "  ✓ " -NoNewline -ForegroundColor Green
        Write-Host `$mod.Name -NoNewline
        if (`$mod.Path -like "*CustomModules*") {
            Write-Host " [Custom]" -ForegroundColor DarkGray
        } else {
            Write-Host ""
        }
    }
    Write-Host "`n  Total modules loaded: " -NoNewline
    Write-Host `$modules.Count -ForegroundColor Cyan
} else {
    Write-Host "  No profile modules detected" -ForegroundColor Yellow
}

# Export results if requested
if ('$OutputPath') {
    `$Global:ProfileTimings | Export-Csv -Path '$OutputPath' -NoTypeInformation
    Write-Host "`n✓ Detailed results saved to: $OutputPath" -ForegroundColor Green
}

Write-Host ""

# ========================================
# FINAL SUMMARY REPORT
# ========================================
Write-Host "`n" -NoNewline
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "                          PROFILE PERFORMANCE SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# Calculate key metrics
`$totalTime = (`$Global:ProfileTimings | Measure-Object -Property Duration -Sum).Sum
`$totalSeconds = [Math]::Round(`$totalTime / 1000, 2)

# Find key operations
`$profileModuleTime = (`$Global:ProfileTimings | Where-Object { `$_.Section -like "*ProfileModule*" } | Measure-Object -Property Duration -Sum).Sum
`$customModulesTime = (`$Global:ProfileTimings | Where-Object { `$_.Section -like "*Custom*" -or `$_.Section -like "*OnIdle*" } | Measure-Object -Property Duration -Sum).Sum
`$psReadLineTime = (`$Global:ProfileTimings | Where-Object { `$_.Section -like "*PSReadLine*" } | Measure-Object -Property Duration -Sum).Sum

Write-Host "`n📊 OVERALL PERFORMANCE" -ForegroundColor Yellow
Write-Host "  Total Load Time:        " -NoNewline
`$timeColor = if (`$totalTime -lt 2000) { 'Green' } elseif (`$totalTime -lt 5000) { 'Yellow' } else { 'Red' }
Write-Host "`$totalSeconds seconds (`$([Math]::Round(`$totalTime))ms)" -ForegroundColor `$timeColor

if (`$totalTime -lt 2000) {
    Write-Host "  Performance Rating:     " -NoNewline
    Write-Host "⭐⭐⭐⭐⭐ Excellent" -ForegroundColor Green
} elseif (`$totalTime -lt 5000) {
    Write-Host "  Performance Rating:     " -NoNewline
    Write-Host "⭐⭐⭐ Acceptable" -ForegroundColor Yellow
} else {
    Write-Host "  Performance Rating:     " -NoNewline
    Write-Host "⭐⭐ Needs Optimization" -ForegroundColor Red
}

Write-Host "`n🔍 BREAKDOWN BY COMPONENT" -ForegroundColor Yellow

if (`$profileModuleTime -gt 0) {
    `$pct = [Math]::Round((`$profileModuleTime / `$totalTime) * 100, 1)
    Write-Host "  ProfileModule:          " -NoNewline
    `$color = if (`$profileModuleTime -gt 2000) { 'Red' } elseif (`$profileModuleTime -gt 1000) { 'Yellow' } else { 'Green' }
    Write-Host "`$([Math]::Round(`$profileModuleTime))ms (`$pct%)" -ForegroundColor `$color
}

if (`$psReadLineTime -gt 0) {
    `$pct = [Math]::Round((`$psReadLineTime / `$totalTime) * 100, 1)
    Write-Host "  PSReadLine:             " -NoNewline
    `$color = if (`$psReadLineTime -gt 1000) { 'Red' } elseif (`$psReadLineTime -gt 500) { 'Yellow' } else { 'Green' }
    Write-Host "`$([Math]::Round(`$psReadLineTime))ms (`$pct%)" -ForegroundColor `$color
}

if (`$customModulesTime -gt 0) {
    `$pct = [Math]::Round((`$customModulesTime / `$totalTime) * 100, 1)
    Write-Host "  Background Tasks:       " -NoNewline
    `$color = if (`$customModulesTime -gt 2000) { 'Red' } elseif (`$customModulesTime -gt 1000) { 'Yellow' } else { 'Green' }
    Write-Host "`$([Math]::Round(`$customModulesTime))ms (`$pct%)" -ForegroundColor `$color
}

Write-Host "`n🎯 TOP 3 BOTTLENECKS" -ForegroundColor Yellow
`$top3 = `$Global:ProfileTimings | Sort-Object -Property Duration -Descending | Select-Object -First 3
`$rank = 1
foreach (`$item in `$top3) {
    `$ms = [Math]::Round(`$item.Duration, 2)
    `$pct = [Math]::Round((`$ms / `$totalTime) * 100, 1)
    `$color = if (`$ms -gt 1000) { 'Red' } elseif (`$ms -gt 500) { 'Yellow' } else { 'Cyan' }
    Write-Host "  `$rank. " -NoNewline
    Write-Host `$item.Section.PadRight(35) -NoNewline
    Write-Host "`$ms ms (`$pct%)" -ForegroundColor `$color
    `$rank++
}

Write-Host "`n📦 MODULES LOADED" -ForegroundColor Yellow
`$modules = Get-Module | Where-Object { 
    `$_.Path -like "*CustomModules*" -or 
    `$_.Name -eq "ProfileModule" -or
    `$_.Name -eq "posh-git"
}

if (`$modules) {
    `$customCount = (@(`$modules | Where-Object { `$_.Path -like "*CustomModules*" })).Count
    `$profileModuleCount = if (`$modules.Name -contains "ProfileModule") { 1 } else { 0 }
    `$poshGitCount = if (`$modules.Name -contains "posh-git") { 1 } else { 0 }
    
    Write-Host "  ProfileModule:          " -NoNewline
    if (`$profileModuleCount -gt 0) {
        Write-Host "✓ Loaded" -ForegroundColor Green
    } else {
        Write-Host "✗ Not loaded" -ForegroundColor Red
    }
    
    Write-Host "  Custom Modules:         " -NoNewline
    Write-Host "`$customCount loaded" -ForegroundColor Cyan
    
    Write-Host "  posh-git:               " -NoNewline
    if (`$poshGitCount -gt 0) {
        Write-Host "✓ Loaded" -ForegroundColor Green
    } else {
        Write-Host "- Not loaded" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  No profile modules detected" -ForegroundColor Red
}

Write-Host "`n💡 RECOMMENDATIONS" -ForegroundColor Yellow

if (`$profileModuleTime -gt 2000) {
    Write-Host "  ⚠️  ProfileModule is very slow (>`$([Math]::Round(`$profileModuleTime))ms)" -ForegroundColor Red
    Write-Host "     Consider analyzing what's inside ProfileModule" -ForegroundColor Gray
}

if (`$totalTime -gt 5000) {
    Write-Host "  ⚠️  Total load time exceeds 5 seconds" -ForegroundColor Red
    Write-Host "     Consider moving more operations to background tasks" -ForegroundColor Gray
}

if (`$psReadLineTime -gt 1000) {
    Write-Host "  ⚠️  PSReadLine is taking >`$([Math]::Round(`$psReadLineTime))ms" -ForegroundColor Yellow
    Write-Host "     Already using InlineView mode (fastest option)" -ForegroundColor Gray
}

if (`$totalTime -lt 3000) {
    Write-Host "  ✓ Performance is good! Profile loads quickly" -ForegroundColor Green
}

Write-Host "`n" -NoNewline
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""
"@

# Save and execute profiling script
$tempScript = "$env:TEMP\profile-detailed-analysis.ps1"
$profilingScript | Out-File -FilePath $tempScript -Encoding UTF8

# Run in new session
& pwsh -NoLogo -NoProfile -File $tempScript

# Cleanup
Remove-Item $tempScript -ErrorAction SilentlyContinue

Write-Host "=== Profiling Complete ===`n" -ForegroundColor Cyan
