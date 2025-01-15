<#
    .SYNOPSIS
    Lint and analyze scripts with PowerShell-Beautifier and PSScriptAnalyzer.

    .DESCRIPTION
    Lint/format code with Powershell-Beautifier (https://github.com/DTW-DanWard/PowerShell-Beautifier).
    Perform static type checking with PSScriptAnalyzer (https://learn.microsoft.com/en-us/powershell/module/psscriptanalyzer/?view=ps-modules).
#>
param(
    [switch]$Verbose,
    [switch]$Debug,
    [switch]$Lint,
    [switch]$Analyze
)

if ((-not $Lint) -and (-not $Analyze)) {
    Write-Output "You must pass one or both of -Lint / -Analyze."
    Write-Output "  [-Lint]: will scan scripts in the repository for formatting errors (double space instead of four, tabs instead of spaces, etc)."
    Write-Output "  [-Analyze]: will analyze script files with the PSScriptAnalyzer tool."

    exit 0
}

if ($Debug) {
    $DebugPreference = "Continue"
} else {
    $DebugPreference = "SilentlyContinue"
}

if ($Verbose) {
    $VerbosePreference = "Continue"
} else {
    $VerbosePreference = "SilentlyContinue"
}

$LintPaths = @(
    ".\scripts"
    ".\Profiles"
    # ".\Modules"
    ".\ProfileModule"
)

function Install-PowershellBeautifierModule  {
    if (-not (Get-Module -ListAvailable -Name PowerShell-Beautifier)) {
        Write-Output "PowerShell-Beautifier module is not installed. Installing now."
        try {
            Install-Module -Name PowerShell-Beautifier -Scope CurrentUser -Force -AllowClobber
            Write-Output "Installed PowerShell-Beautifier module."
        } catch {
            Write-Error "Failed to install PowerShell-Beautifier module. Details: $($_.Exception.Message)"
            exit 1
        }
    } else {
        Write-Output "PowerShell-Beautifier module is already installed. Skipping."
        return
    }
}

function Install-PSScriptAnalyzerModule  {
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-Output "PSScriptAnalyzer module is not installed. Installing now."
        try {
            Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -AllowClobber
            Write-Output "Installed PSScriptAnalyzer module."
        } catch {
            Write-Error "Failed to install PSScriptAnalyzer module. Details: $($_.Exception.Message)"
            exit 1
        }
    } else {
        Write-Output "PSScriptAnalyzer module is already installed. Skipping."
        return
    }
}

function Start-BeatifySingleScript  {
    param(
        [string]$TargetScript
    )

    if (-not ($TargetScript)) {
        Write-Error "-TargetScript must not be `$null or empty."
        return
    }

    if (-not (Test-Path "$($TargetScript)")) {
        Write-Error "Could not find file to beautify: $($TargetScript)"
        return
    }

    Write-Output "Beautifying file: $($TargetScript)"
    try {
        Edit-DTWBeautifyScript "$($TargetScript)"
        Write-Output "Finished linting file: $($TargetScript)"

        return
    } catch {
        Write-Error "Error linting file '$($TargetScript)'. Details: $($_.Exception.Message)"
        return
    }
}

function Start-BeautifyScriptsInPath  {
    param(
        [string]$ScanPath = ".\"
    )

    if (-not (Test-Path -Path $ScanPath)) {
        Write-Error "Failed to beautify scripts, could not find path: $($ScanPath)."
        return
    }

    Write-Output "[START] Beautifying script files in path: $($ScanPath)"
    try {
        Get-ChildItem -Path "$($ScanPath)" -Recurse -Include *.ps1,*.psm1 | Edit-DTWBeautifyScript -IndentType FourSpaces
        Write-Output "[FINISH] Beautified scripts in path: $($ScanPath)"
        return
    } catch {
        Write-Error "Failed to beautify scripts in path: $($ScanPath). Details: $($_.Exception.Message)"
        return
    }
}

function Start-AnalyzeScriptsInPath  {
    param(
        $ScanPath = ".\"
    )

    if (-not (Test-Path -Path $ScanPath)) {
        Write-Error "Failed to analyze scripts, could not find path: $($ScanPath)"
        return
    }

    Write-Output "[START] Analyzing scripts in path: $($ScanPath)`n"
    try {
        Invoke-ScriptAnalyzer -Recurse "$($ScanPath)"

        Write-Output "[FINISH] Analyzed scripts in path $($ScanPath)`n"
        return
    } catch {
        Write-Error "Failed to analyze scripts in path: $($ScanPath). Details: $($_.Exception.Message)"
        exit 1
    }
}

function main  {
    if ($Analyze) {
        Install-PSScriptAnalyzerModule

        $LintPaths | ForEach-Object {
            Write-Output "Linting path: $($_)"
            try {
                Start-AnalyzeScriptsInPath -ScanPath "$_"
            } catch {
                Write-Error "Failed analyzing path '$($_)'. Details: $($_.Exception.Message)"
                continue
            }
        }
    }

    if ($Lint) {
        Install-PowershellBeautifierModule

        $LintPaths | ForEach-Object {
            Write-Output "Beautifying path: $($_)"
            try {
                Start-BeautifyScriptsInPath -ScanPath "$_"
            } catch {
                Write-Error "Failed beautifying path '$($_)'. Details: $($_.Exception.Message)"
                continue
            }
        }
    }
}

main
