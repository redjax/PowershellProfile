<#
.SYNOPSIS
Runs PowerShell linting and formatting checks locally.

.DESCRIPTION
Uses PSScriptAnalyzer for both static analysis and formatting.

Checks tracked .ps1, .psm1, and .psd1 files using repository-owned
configuration files.

Formatting is check-only unless -Fix is supplied.

.EXAMPLE
./scripts/lint.ps1

Run linting and formatting checks.

.EXAMPLE
./scripts/lint.ps1 -Mode Lint

Run linting only.

.EXAMPLE
./scripts/lint.ps1 -Mode Format -Fix

Apply formatting changes.

.EXAMPLE
./scripts/lint.ps1 -WarnOnly

Report quality findings without returning a failing exit code.
Execution failures still fail.
#>

#requires -Version 7.2

[CmdletBinding()]
param(
    [ValidateSet('Lint', 'Format', 'Both')]
    [string] $Mode = 'Both',

    [switch] $Fix,

    [switch] $WarnOnly,

    [string[]] $Paths = @('.'),

    [string[]] $ExcludePaths = @(),

    [string] $LintSettingsFile = 'config/PSScriptAnalyzerSettings.psd1',

    [string] $FormatSettingsFile = 'config/FormatterSettings.psd1',

    [ValidateSet('Error', 'Warning', 'Information')]
    [string[]] $Severity = @('Error', 'Warning'),

    # Keep this aligned with the version selected by CI.
    # renovate: datasource=powershell depName=PSScriptAnalyzer
    [string] $PSScriptAnalyzerVersion = '1.24.0'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Git diff returns 1 when differences exist.
# Handle native exit codes explicitly rather than treating those
# differences as PowerShell execution failures.
$PSNativeCommandUseErrorActionPreference = $false

function Resolve-SettingsFile {
    param(
        [string] $Root,
        [string] $RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        throw 'A settings file path is required.'
    }

    if ([IO.Path]::IsPathRooted($RelativePath)) {
        throw "Settings paths must be repository-relative: $RelativePath"
    }

    $absolutePath = [IO.Path]::GetFullPath(
        (Join-Path $Root $RelativePath)
    )

    $relative = [IO.Path]::GetRelativePath($Root, $absolutePath)

    if (
        $relative -eq '..' -or
        $relative.StartsWith('../') -or
        $relative.StartsWith('..\')
    ) {
        throw "Settings file must remain inside the repository: $RelativePath"
    }

    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        throw "Settings file not found: $absolutePath"
    }

    $null = Import-PowerShellDataFile -LiteralPath $absolutePath

    return $absolutePath
}

function Read-ScriptText {
    param(
        [string] $Path
    )

    $defaultEncoding = [Text.UTF8Encoding]::new($false, $true)

    $reader = [IO.StreamReader]::new(
        $Path,
        $defaultEncoding,
        $true
    )

    try {
        $text = $reader.ReadToEnd()
        $encoding = $reader.CurrentEncoding
    }
    finally {
        $reader.Dispose()
    }

    $newline = "`n"

    if ($text.Contains("`r`n")) {
        $newline = "`r`n"
    }

    return @{
        Text     = $text
        Encoding = $encoding
        Newline  = $newline
    }
}

function Assert-ValidSyntax {
    param(
        [string] $Text,
        [string] $Name
    )

    $tokens = $null
    $parseErrors = $null

    $null = [Management.Automation.Language.Parser]::ParseInput(
        $Text,
        [ref] $tokens,
        [ref] $parseErrors
    )

    if (@($parseErrors).Count -gt 0) {
        $messages = $parseErrors | ForEach-Object {
            "line $($_.Extent.StartLineNumber): $($_.Message)"
        }

        throw "Cannot format ${Name}: $($messages -join '; ')"
    }
}

function Get-FormattedText {
    param(
        [string] $Text,
        [string] $Settings,
        [string] $Newline
    )

    $formatted = Invoke-Formatter `
        -ScriptDefinition $Text `
        -Settings $Settings `
        -ErrorAction Stop

    return [regex]::Replace(
        $formatted,
        "\r\n|\r|\n",
        $Newline
    )
}

function Show-FormattingDiff {
    param(
        [string] $OriginalPath,
        [string] $FormattedText,
        [Text.Encoding] $Encoding,
        [string] $RelativePath
    )

    $temporaryFile = [IO.Path]::GetTempFileName()

    try {
        [IO.File]::WriteAllText(
            $temporaryFile,
            $FormattedText,
            $Encoding
        )

        Write-Host "`nFormatting diff: $RelativePath"

        & git --no-pager diff `
            --no-index `
            --no-ext-diff `
            --no-color `
            -- $OriginalPath $temporaryFile |
        ForEach-Object {
            Write-Host $_
        }

        $diffExitCode = $LASTEXITCODE

        if ($diffExitCode -notin @(0, 1)) {
            throw "git diff failed with exit code $diffExitCode."
        }
    }
    finally {
        Remove-Item -LiteralPath $temporaryFile `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

try {
    if ($Fix -and $Mode -eq 'Lint') {
        throw '-Fix requires -Mode Format or -Mode Both.'
    }

    $null = Get-Command git -CommandType Application -ErrorAction Stop

    # Locate the repository from the script, not the terminal's
    # current working directory.
    $rootOutput = @(
        & git -C $PSScriptRoot rev-parse --show-toplevel
    )

    if ($LASTEXITCODE -ne 0 -or $rootOutput.Count -ne 1) {
        throw 'Could not determine the Git repository containing this script.'
    }

    $repositoryRoot = (
        Resolve-Path -LiteralPath $rootOutput[0]
    ).Path

    $runLint = $Mode -in @('Lint', 'Both')
    $runFormat = $Mode -in @('Format', 'Both')

    $lintSettings = $null
    $formatSettings = $null

    if ($runLint) {
        $lintSettings = Resolve-SettingsFile `
            -Root $repositoryRoot `
            -RelativePath $LintSettingsFile
    }

    if ($runFormat) {
        $formatSettings = Resolve-SettingsFile `
            -Root $repositoryRoot `
            -RelativePath $FormatSettingsFile
    }

    $availableVersion = @(
        Get-Module -ListAvailable -Name PSScriptAnalyzer |
        Where-Object {
            $_.Version -eq [version] $PSScriptAnalyzerVersion
        }
    )

    if ($availableVersion.Count -eq 0) {
        Write-Host (
            "Installing PSScriptAnalyzer $PSScriptAnalyzerVersion..."
        )

        Install-Module `
            -Name PSScriptAnalyzer `
            -RequiredVersion $PSScriptAnalyzerVersion `
            -Repository PSGallery `
            -Scope CurrentUser `
            -Force `
            -AllowClobber `
            -ErrorAction Stop
    }

    # Avoid silently using a different version already loaded in
    # this PowerShell process.
    $loadedModule = Get-Module -Name PSScriptAnalyzer

    if ($loadedModule) {
        Remove-Module -Name PSScriptAnalyzer -Force -ErrorAction Stop
    }

    Import-Module PSScriptAnalyzer `
        -RequiredVersion $PSScriptAnalyzerVersion `
        -ErrorAction Stop

    $Paths = @(
        $Paths | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        }
    )

    if ($Paths.Count -eq 0) {
        $Paths = @('.')
    }

    Push-Location $repositoryRoot

    try {
        $trackedFiles = @(
            & git -c core.quotepath=false ls-files -- @Paths
        )

        if ($LASTEXITCODE -ne 0) {
            throw "git ls-files failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }

    $files = @(
        foreach ($relativePath in $trackedFiles) {
            if (
                [IO.Path]::GetExtension($relativePath) -notin @(
                    '.ps1'
                    '.psm1'
                    '.psd1'
                )
            ) {
                continue
            }

            $excluded = $false

            foreach ($pattern in $ExcludePaths) {
                if (
                    -not [string]::IsNullOrWhiteSpace($pattern) -and
                    $relativePath -like $pattern
                ) {
                    $excluded = $true
                    break
                }
            }

            $absolutePath = Join-Path $repositoryRoot $relativePath

            if (
                -not $excluded -and
                (Test-Path -LiteralPath $absolutePath -PathType Leaf)
            ) {
                $relativePath
            }
        }
    ) | Sort-Object -Unique

    $files = @($files)

    Write-Host "Repository: $repositoryRoot"
    Write-Host "PSScriptAnalyzer: $PSScriptAnalyzerVersion"
    Write-Host "Mode: $Mode"
    Write-Host "Selected files: $($files.Count)"
    Write-Host "Fix formatting: $($Fix.IsPresent)"
    Write-Host "Warning-only findings: $($WarnOnly.IsPresent)"

    if ($runLint) {
        Write-Host "Lint settings: $lintSettings"
    }

    if ($runFormat) {
        Write-Host "Formatter settings: $formatSettings"
    }

    if ($files.Count -eq 0) {
        Write-Host 'No matching tracked PowerShell files.'
        exit 0
    }

    $lintFindingCount = 0
    $formattingFindingCount = 0
    $fixedFileCount = 0
    $executionFailureCount = 0

    if ($runLint) {
        Write-Host "`n=== PowerShell lint ==="

        foreach ($relativePath in $files) {
            $absolutePath = Join-Path $repositoryRoot $relativePath

            try {
                Write-Host "Analyzing: $relativePath"

                $findings = @(
                    Invoke-ScriptAnalyzer `
                        -Path $absolutePath `
                        -Settings $lintSettings `
                        -Severity $Severity `
                        -ErrorAction Stop
                )

                foreach ($finding in $findings) {
                    $lintFindingCount++

                    $line = [Math]::Max(1, [int] $finding.Line)
                    $column = 1

                    if ($null -ne $finding.Extent) {
                        $column = [Math]::Max(
                            1,
                            [int] $finding.Extent.StartColumnNumber
                        )
                    }

                    $message = (
                        '{0}:{1}:{2}: [{3}] {4}: {5}' -f
                        $relativePath,
                        $line,
                        $column,
                        $finding.Severity,
                        $finding.RuleName,
                        $finding.Message
                    )

                    Write-Host $message
                }
            }
            catch {
                $executionFailureCount++

                Write-Warning (
                    "Lint execution failed for ${relativePath}: " +
                    $_.Exception.Message
                )
            }
        }
    }

    if ($runFormat) {
        Write-Host "`n=== PowerShell formatting ==="

        foreach ($relativePath in $files) {
            $absolutePath = Join-Path $repositoryRoot $relativePath

            try {
                $source = Read-ScriptText -Path $absolutePath

                Assert-ValidSyntax `
                    -Text $source.Text `
                    -Name $relativePath

                $formatted = Get-FormattedText `
                    -Text $source.Text `
                    -Settings $formatSettings `
                    -Newline $source.Newline

                if ($source.Text -ceq $formatted) {
                    Write-Host "Formatted correctly: $relativePath"
                    continue
                }

                $formattingFindingCount++

                Show-FormattingDiff `
                    -OriginalPath $absolutePath `
                    -FormattedText $formatted `
                    -Encoding $source.Encoding `
                    -RelativePath $relativePath

                if ($Fix) {
                    Assert-ValidSyntax `
                        -Text $formatted `
                        -Name $relativePath

                    $secondPass = Get-FormattedText `
                        -Text $formatted `
                        -Settings $formatSettings `
                        -Newline $source.Newline

                    if ($formatted -cne $secondPass) {
                        throw (
                            'Formatter did not produce stable output for ' +
                            $relativePath
                        )
                    }

                    [IO.File]::WriteAllText(
                        $absolutePath,
                        $formatted,
                        $source.Encoding
                    )

                    $fixedFileCount++

                    Write-Host "Fixed: $relativePath"
                }
            }
            catch {
                $executionFailureCount++

                Write-Warning (
                    "Formatting execution failed for ${relativePath}: " +
                    $_.Exception.Message
                )
            }
        }
    }

    Write-Host "`n=== Summary ==="
    Write-Host "Selected files: $($files.Count)"

    if ($runLint) {
        Write-Host "Lint findings: $lintFindingCount"
    }

    if ($runFormat) {
        Write-Host "Files requiring formatting: $formattingFindingCount"
        Write-Host "Files formatted: $fixedFileCount"
    }

    Write-Host "Execution failures: $executionFailureCount"

    if ($executionFailureCount -gt 0) {
        exit 2
    }

    $hasUnfixedFormatting = (
        $formattingFindingCount -gt 0 -and
        -not $Fix
    )

    if (
        -not $WarnOnly -and
        ($lintFindingCount -gt 0 -or $hasUnfixedFormatting)
    ) {
        exit 1
    }

    exit 0
}
catch {
    Write-Error $_ -ErrorAction Continue
    exit 2
}
