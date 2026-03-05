<#
.SYNOPSIS
    Measure and profile PowerShell Monolith profile startup performance.

.DESCRIPTION
    Accurately profiles the Monolith PowerShell profile by measuring each component
    with high-resolution Stopwatch timers. Profiles both synchronous startup and
    deferred OnIdle background tasks separately.

    Measures:
    - Configuration loading (PSModulePath, prompt-config)
    - Each synchronous component (namespaces, prompt, aliases, software-init)
    - Function cache / individual function file loading
    - OnIdle event registrations
    - Deferred background tasks (PSReadLine, shell-completions, posh-git, tool aliases)
    - Import-Module calls (transparently wrapped)

.PARAMETER IncludeDeferred
    Also execute and time deferred OnIdle tasks (adds several seconds).
    Without this flag, only synchronous startup time is measured.

.PARAMETER Iterations
    Number of times to run the profile for averaging (default: 1).
    Use higher values to reduce noise from background system activity.

.PARAMETER OutputPath
    Path to save detailed profiling results as CSV (optional).

.EXAMPLE
    .\scripts\Measure-ProfileStartup.ps1
    Measure synchronous startup only.

.EXAMPLE
    .\scripts\Measure-ProfileStartup.ps1 -IncludeDeferred
    Measure startup plus all deferred OnIdle tasks.

.EXAMPLE
    .\scripts\Measure-ProfileStartup.ps1 -Iterations 3
    Average profile startup over 3 runs.

.EXAMPLE
    .\scripts\Measure-ProfileStartup.ps1 -OutputPath "profile-timing.csv"
    Measure startup and export results to CSV.
#>

[CmdletBinding()]
param(
    [switch]$IncludeDeferred,

    [ValidateRange(1, 20)]
    [int]$Iterations = 1,

    [string]$OutputPath
)

# Build the profiling script as a here-string.
# It runs inside a fresh pwsh -NoProfile session so nothing is pre-loaded.
$profilingScript = @"
`$ErrorActionPreference = 'Continue'

# ── High-resolution timer helpers ──────────────────────────────────────────────
`$Global:_Timings = [System.Collections.Generic.List[psobject]]::new()

function Add-Timing {
    param([string]`$Name, [double]`$Ms, [string]`$Category = 'Startup')
    `$Global:_Timings.Add([pscustomobject]@{
        Name     = `$Name
        Ms       = [Math]::Round(`$Ms, 2)
        Category = `$Category
    })
}

function Measure-Block {
    param([string]`$Name, [scriptblock]`$Block, [string]`$Category = 'Startup')
    `$sw = [System.Diagnostics.Stopwatch]::StartNew()
    try { & `$Block } catch { Write-Warning "`$Name failed: `$(`$_.Exception.Message)" }
    `$sw.Stop()
    Add-Timing -Name `$Name -Ms `$sw.Elapsed.TotalMilliseconds -Category `$Category
}

# ── Wrap Import-Module to capture timing ───────────────────────────────────────
`$script:_OrigImportModule = Get-Command Import-Module -CommandType Cmdlet

function Import-Module {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]`$Name,
        [Parameter()] [switch]`$Global,
        [Parameter()] [switch]`$Force,
        [Parameter()] [switch]`$PassThru,
        [Parameter()] [switch]`$DisableNameChecking,
        [Parameter()] [string]`$Prefix
    )
    `$sw = [System.Diagnostics.Stopwatch]::StartNew()
    `$params = @{}
    foreach (`$key in `$PSBoundParameters.Keys) { `$params[`$key] = `$PSBoundParameters[`$key] }
    try { & `$script:_OrigImportModule @params }
    catch { Write-Warning "Import-Module `$(`$Name -join ', ') failed: `$(`$_.Exception.Message)" }
    `$sw.Stop()
    Add-Timing -Name "Import-Module: `$(`$Name -join ', ')" -Ms `$sw.Elapsed.TotalMilliseconds -Category 'Module'
}

# ── Resolve profile paths ─────────────────────────────────────────────────────
`$ProfilePath = '$($PROFILE.Replace("'", "''"))'
`$ProfileDir  = Split-Path -Path `$ProfilePath -Parent
`$ComponentsDir = Join-Path `$ProfileDir 'ProfileComponents'

if (-not (Test-Path `$ProfilePath)) {
    Write-Host "Profile not found at: `$ProfilePath" -ForegroundColor Red
    exit 1
}

# ── Overall timer ─────────────────────────────────────────────────────────────
`$overallSw = [System.Diagnostics.Stopwatch]::StartNew()

# ── 1. Configuration ──────────────────────────────────────────────────────────
Measure-Block 'PSModulePath setup' {
    `$CustomModulesPath = Join-Path `$ProfileDir 'Modules\Custom'
    if (Test-Path `$CustomModulesPath) {
        `$env:PSModulePath = "`$CustomModulesPath;`$env:PSModulePath"
    }
}

Measure-Block 'prompt-config.ps1' {
    `$PromptConfigPath = Join-Path `$ProfileDir 'prompt-config.ps1'
    if (Test-Path `$PromptConfigPath) { . `$PromptConfigPath }
}

# ── 2. Synchronous components ────────────────────────────────────────────────
`$components = @('namespaces.ps1', 'prompt.ps1', 'aliases.ps1', 'software-init.ps1')
foreach (`$comp in `$components) {
    `$compPath = Join-Path `$ComponentsDir `$comp
    if (Test-Path `$compPath) {
        Measure-Block `$comp { . `$compPath }
    }
}

# ── 3. Function loading ──────────────────────────────────────────────────────
`$FunctionsCacheFile = Join-Path `$ComponentsDir '.functions-cache.ps1'
`$FunctionsDir = Join-Path `$ComponentsDir 'functions'

if (Test-Path `$FunctionsCacheFile) {
    Measure-Block '.functions-cache.ps1' { . `$FunctionsCacheFile }
} elseif (Test-Path `$FunctionsDir) {
    Measure-Block 'functions/ (individual files)' {
        `$files = Get-ChildItem -Path `$FunctionsDir -Filter '*.ps1' -File -Recurse
        foreach (`$f in `$files) { . `$f.FullName }
    }
}

# ── 4. OnIdle registrations (just measuring the Register-EngineEvent calls) ──
Measure-Block 'OnIdle registrations' {
    `$psReadLineHandlersPath = Join-Path `$ComponentsDir 'psreadline-handlers.ps1'
    if (Test-Path `$psReadLineHandlersPath) {
        `$null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action ([scriptblock]::Create(""))
    }
    `$shellCompletionsPath = Join-Path `$ComponentsDir 'shell-completions.ps1'
    if (Test-Path `$shellCompletionsPath) {
        `$null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action ([scriptblock]::Create(""))
    }
    `$null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {}
}

`$overallSw.Stop()
`$startupMs = `$overallSw.Elapsed.TotalMilliseconds
Add-Timing -Name '=== Synchronous Startup Total ===' -Ms `$startupMs -Category 'Total'

# ── 5. Deferred tasks (optional) ─────────────────────────────────────────────
`$includeDeferred = [bool]::Parse('$($IncludeDeferred.ToString())')

if (`$includeDeferred) {
    # Unregister the dummy events we just registered
    Get-EventSubscriber | Where-Object { `$_.SourceIdentifier -eq 'PowerShell.OnIdle' } |
        Unregister-Event -ErrorAction SilentlyContinue

    `$psrlPath = Join-Path `$ComponentsDir 'psreadline-handlers.ps1'
    if (Test-Path `$psrlPath) {
        Measure-Block 'Deferred: psreadline-handlers.ps1' { . `$psrlPath } 'Deferred'
    }

    `$scPath = Join-Path `$ComponentsDir 'shell-completions.ps1'
    if (Test-Path `$scPath) {
        Measure-Block 'Deferred: shell-completions.ps1' { . `$scPath } 'Deferred'
    }

    Measure-Block 'Deferred: posh-git check + import' {
        if (Get-Module -ListAvailable -Name posh-git) {
            & `$script:_OrigImportModule posh-git -ErrorAction SilentlyContinue
        }
    } 'Deferred'

    `$deferredMs = (`$Global:_Timings | Where-Object { `$_.Category -eq 'Deferred' } |
        Measure-Object -Property Ms -Sum).Sum
    if (`$null -eq `$deferredMs) { `$deferredMs = 0 }
    Add-Timing -Name '=== Deferred Tasks Total ===' -Ms `$deferredMs -Category 'Total'
}

# ── Restore Import-Module ────────────────────────────────────────────────────
Remove-Item Function:\Import-Module -ErrorAction SilentlyContinue

# ══════════════════════════════════════════════════════════════════════════════
# OUTPUT
# ══════════════════════════════════════════════════════════════════════════════

function Write-Bar {
    param([double]`$Ms, [double]`$MaxMs)
    `$width = 30
    `$filled = if (`$MaxMs -gt 0) { [Math]::Max(1, [Math]::Round((`$Ms / `$MaxMs) * `$width)) } else { 1 }
    `$filled = [Math]::Min(`$filled, `$width)
    `$color = if (`$Ms -gt 1000) { 'Red' } elseif (`$Ms -gt 500) { 'Yellow' } elseif (`$Ms -gt 100) { 'Cyan' } else { 'Green' }
    Write-Host ([string][char]0x2588 * `$filled) -ForegroundColor `$color -NoNewline
    Write-Host (' ' * (`$width - `$filled)) -NoNewline
}

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "                    MONOLITH PROFILE STARTUP ANALYSIS" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# -- Synchronous breakdown --
Write-Host "`n  SYNCHRONOUS STARTUP" -ForegroundColor Yellow
Write-Host ("  " + "-" * 76) -ForegroundColor DarkGray

`$syncTimings = `$Global:_Timings | Where-Object { `$_.Category -eq 'Startup' -or `$_.Category -eq 'Module' }
`$maxMs = (`$syncTimings | Measure-Object -Property Ms -Maximum).Maximum
if (`$null -eq `$maxMs -or `$maxMs -eq 0) { `$maxMs = 1 }

foreach (`$t in `$syncTimings | Sort-Object Ms -Descending) {
    `$pct = if (`$startupMs -gt 0) { [Math]::Round((`$t.Ms / `$startupMs) * 100, 1) } else { 0 }
    Write-Host "  " -NoNewline
    Write-Bar -Ms `$t.Ms -MaxMs `$maxMs
    `$label = `$t.Name.PadRight(38)
    Write-Host " `$label" -NoNewline
    `$msStr = "`$(`$t.Ms)ms".PadLeft(10)
    `$color = if (`$t.Ms -gt 1000) { 'Red' } elseif (`$t.Ms -gt 500) { 'Yellow' } elseif (`$t.Ms -gt 100) { 'Cyan' } else { 'Green' }
    Write-Host `$msStr -ForegroundColor `$color -NoNewline
    Write-Host " (`$pct%)" -ForegroundColor DarkGray
}

Write-Host ("  " + "-" * 76) -ForegroundColor DarkGray
`$totalColor = if (`$startupMs -lt 500) { 'Green' } elseif (`$startupMs -lt 1500) { 'Cyan' } elseif (`$startupMs -lt 3000) { 'Yellow' } else { 'Red' }
Write-Host "  TOTAL (to first prompt):".PadRight(70) -NoNewline
Write-Host "`$([Math]::Round(`$startupMs))ms" -ForegroundColor `$totalColor

# -- Deferred breakdown --
if (`$includeDeferred) {
    `$deferredTimings = `$Global:_Timings | Where-Object { `$_.Category -eq 'Deferred' }
    if (`$deferredTimings) {
        Write-Host "`n  DEFERRED (OnIdle) TASKS" -ForegroundColor Yellow
        Write-Host ("  " + "-" * 76) -ForegroundColor DarkGray

        `$maxDef = (`$deferredTimings | Measure-Object -Property Ms -Maximum).Maximum
        if (`$null -eq `$maxDef -or `$maxDef -eq 0) { `$maxDef = 1 }

        foreach (`$t in `$deferredTimings | Sort-Object Ms -Descending) {
            Write-Host "  " -NoNewline
            Write-Bar -Ms `$t.Ms -MaxMs `$maxDef
            `$label = `$t.Name.PadRight(38)
            Write-Host " `$label" -NoNewline
            `$msStr = "`$(`$t.Ms)ms".PadLeft(10)
            `$color = if (`$t.Ms -gt 1000) { 'Red' } elseif (`$t.Ms -gt 500) { 'Yellow' } elseif (`$t.Ms -gt 100) { 'Cyan' } else { 'Green' }
            Write-Host `$msStr -ForegroundColor `$color
        }

        Write-Host ("  " + "-" * 76) -ForegroundColor DarkGray
        Write-Host "  TOTAL (deferred):".PadRight(70) -NoNewline
        Write-Host "`$([Math]::Round(`$deferredMs))ms" -ForegroundColor Cyan
    }
}

# -- Modules loaded by profile --
Write-Host "`n  MODULES LOADED" -ForegroundColor Yellow
Write-Host ("  " + "-" * 76) -ForegroundColor DarkGray
`$moduleTimings = `$Global:_Timings | Where-Object { `$_.Category -eq 'Module' }
if (`$moduleTimings) {
    foreach (`$m in `$moduleTimings | Sort-Object Ms -Descending) {
        Write-Host "  + " -NoNewline -ForegroundColor Green
        Write-Host "`$(`$m.Name.PadRight(50))" -NoNewline
        `$color = if (`$m.Ms -gt 500) { 'Yellow' } else { 'Green' }
        Write-Host "`$(`$m.Ms)ms" -ForegroundColor `$color
    }
} else {
    Write-Host "  (no explicit Import-Module calls during startup)" -ForegroundColor DarkGray
}

# -- Performance rating --
Write-Host "`n  PERFORMANCE RATING" -ForegroundColor Yellow
Write-Host ("  " + "-" * 76) -ForegroundColor DarkGray
Write-Host "  Startup time: " -NoNewline
if (`$startupMs -lt 500) {
    Write-Host "Excellent (<500ms)" -ForegroundColor Green
} elseif (`$startupMs -lt 1000) {
    Write-Host "Good (<1s)" -ForegroundColor Green
} elseif (`$startupMs -lt 2000) {
    Write-Host "Acceptable (<2s)" -ForegroundColor Cyan
} elseif (`$startupMs -lt 3000) {
    Write-Host "Slow (<3s)" -ForegroundColor Yellow
} else {
    Write-Host "Very Slow (>`$([Math]::Round(`$startupMs / 1000, 1))s) - needs optimization" -ForegroundColor Red
}

# -- Recommendations --
`$recs = [System.Collections.Generic.List[string]]::new()

`$slowest = `$syncTimings | Sort-Object Ms -Descending | Select-Object -First 1
if (`$slowest -and `$slowest.Ms -gt 500) {
    `$recs.Add("Bottleneck: '`$(`$slowest.Name)' takes `$(`$slowest.Ms)ms. Investigate or defer it.")
}

`$cacheFile = Join-Path `$ComponentsDir '.functions-cache.ps1'
if (-not (Test-Path `$cacheFile)) {
    `$recs.Add("Function cache missing. Run Update-FunctionCache or reinstall with Install-MonoProfile.ps1.")
}

`$pathCount = (`$env:PATH -split ';' | Where-Object { `$_ }).Count
if (`$pathCount -gt 50) {
    `$recs.Add("PATH has `$pathCount entries. Avoid synchronous Get-Command lookups (each scans all `$pathCount dirs).")
}

`$dupes = `$env:PATH -split ';' | Where-Object { `$_ } | Group-Object | Where-Object { `$_.Count -gt 1 }
if (`$dupes) {
    `$dupeNames = (`$dupes | ForEach-Object { "`$(`$_.Name) (x`$(`$_.Count))" }) -join ', '
    `$recs.Add("Duplicate PATH entries: `$dupeNames")
}

if (`$recs.Count -gt 0) {
    Write-Host "`n  RECOMMENDATIONS" -ForegroundColor Yellow
    Write-Host ("  " + "-" * 76) -ForegroundColor DarkGray
    foreach (`$r in `$recs) {
        Write-Host "  * `$r" -ForegroundColor Gray
    }
}

# -- Export --
`$outputCsv = '$($OutputPath -replace "'", "''")'
if (`$outputCsv) {
    `$Global:_Timings | Export-Csv -Path `$outputCsv -NoTypeInformation
    Write-Host "`n  Results saved to: `$outputCsv" -ForegroundColor Green
}

Write-Host "`n" -NoNewline
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""
"@

## Run inside a clean pwsh -NoProfile session
Write-Host "`n=== Monolith Profile Startup Profiler ===`n" -ForegroundColor Cyan
Write-Host "Profile:    $PROFILE" -ForegroundColor Gray
Write-Host "Iterations: $Iterations" -ForegroundColor Gray
Write-Host "Deferred:   $IncludeDeferred`n" -ForegroundColor Gray

for ($i = 1; $i -le $Iterations; $i++) {
    if ($Iterations -gt 1) {
        Write-Host "--- Run $i of $Iterations ---`n" -ForegroundColor DarkCyan
    }

    $tempScript = Join-Path $env:TEMP "monolith-profile-measure-$([guid]::NewGuid().ToString('N').Substring(0,8)).ps1"
    try {
        [System.IO.File]::WriteAllText($tempScript, $profilingScript)
        & pwsh -NoLogo -NoProfile -File $tempScript
    }
    finally {
        Remove-Item $tempScript -ErrorAction SilentlyContinue
    }
}

Write-Host "=== Profiling Complete ===`n" -ForegroundColor Cyan
