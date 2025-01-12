<#
    .SYNOPSIS
    Lint and analyze scripts with PowerShell-Beautifier and PSScriptAnalyzer.

    .DESCRIPTION
    Lint/format code with Powershell-Beautifier (https://github.com/DTW-DanWard/PowerShell-Beautifier).
    Perform static type checking with PSScriptAnalyzer (https://learn.microsoft.com/en-us/powershell/module/psscriptanalyzer/?view=ps-modules).
#>
param(
    [switch]$Verbose,
    [switch]$Debug
)

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

function Install-PowershellBeautifierModule () {
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

function Install-PSScriptAnalyzerModule () {
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

function Start-BeatifySingleScript () {
    param(
        [string]$TargetScript
    )

    if (-not ($TargetScript)) {
        Write-Error "-TargetScript must not be `$null or empty."
        return $false
    }

    if (-not (Test-Path "$($TargetScript)")) {
        Write-Error "Could not find file to beautify: $($TargetScript)"
        return $false
    }

    Write-Output "Beautifying file: $($TargetScript)"
    try {
        Edit-DTWBeautifyScript "$($TargetScript)"
        Write-Output "Finished linting file: $($TargetScript)"

        return $true
    } catch {
        Write-Error "Error linting file '$($TargetScript)'. Details: $($_.Exception.Message)"
        return $false
    }
}

function Start-BeautifyScriptsInPath () {
    param(
        [string]$ScanPath = ".\"
    )

    if (-not (Test-Path -Path $ScanPath)) {
        Write-Error "Failed to beautify scripts, could not find path: $($ScanPath)."
        return $false
    }

    Write-Output "Beautifying script files in path: $($ScanPath)"
    try {
        Get-ChildItem -Path "$($ScanPath)" -Recurse -Include *.ps1,*.psm1 | Edit-DTWBeautifyScript -IndentType FourSpaces -NewLine LF
        Write-Output "Finished beautifying scripts in path: $($ScanPath)"
        return $true
    } catch {
        Write-Error "Failed to beautify scripts in path: $($ScanPath). Details: $($_.Exception.Message)"
        return $false
    }
}

function main () {
    Install-PSScriptAnalyzerModule
    Install-PowershellBeautifierModule

    Start-BeautifyScriptsInPath -ScanPath .\scripts
}

main
