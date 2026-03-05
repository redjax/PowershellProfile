<#
    .SYNOPSIS
    Build a release .zip archive of the Monolith PowerShell profile.

    .DESCRIPTION
    Packages the Monolith profile, custom modules, prompt theme configs, and the
    installer into a versioned .zip file ready for distribution.

    Uses calendar versioning (CalVer): yyyyMMdd.HHmmss
    In a CI pipeline, pass -Version with the git tag value (e.g. 20260305.143022).
    When run locally without -Version, the current date/time is used with a "-dev" suffix.

    Included in the archive:
      - Install-MonoProfile.ps1 (installer)
      - Profiles/Monolith/       (profile + ProfileComponents)
      - Modules/Custom/          (auto-discovered modules)
      - config/                  (starship & ohmyposh themes)

    .PARAMETER OutputDir
    Directory to write the .zip file to. Default: ./release

    .PARAMETER Name
    Base name for the archive. Default: PowershellProfile-Monolith

    .PARAMETER Version
    Explicit version string (CalVer), typically passed from a CI pipeline using the git tag.
    When omitted, the current timestamp is used with a "-dev" suffix.

    .PARAMETER ExcludeTests
    Exclude test directories from custom modules.

    .EXAMPLE
    .\scripts\Build-Release.ps1
    Dev build: release/PowershellProfile-Monolith-20260305.143022-dev.zip

    .EXAMPLE
    .\scripts\Build-Release.ps1 -Version 20260305.143022
    Pipeline build: release/PowershellProfile-Monolith-20260305.143022.zip
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\dist"),

    [Parameter(Mandatory = $false)]
    [string]$Name = "PowershellProfile-Monolith",

    [Parameter(Mandatory = $false)]
    [string]$Version,

    [Parameter(Mandatory = $false)]
    [switch]$ExcludeTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

## ---------------------------------------------------------------------------
## Version string (CalVer: yyyyMMdd.HHmmss)
## ---------------------------------------------------------------------------
$IsDev = $false

if ($Version) {
    ## Pipeline mode: use the version as-is
}
else {
    ## Local/dev mode: generate CalVer from current timestamp
    $IsDev = $true
    $Version = "$(Get-Date -Format 'yyyyMMdd.HHmmss')-dev"
}

$ArchiveName = "$Name-$Version.zip"

Write-Host "`n=== Build Release ===" -ForegroundColor Cyan
Write-Host "Version : $Version$(if ($IsDev) { '  (dev build)' })" -ForegroundColor Gray
Write-Host "Archive : $ArchiveName" -ForegroundColor Gray

## ---------------------------------------------------------------------------
## Staging area
## ---------------------------------------------------------------------------
$StagingDir = Join-Path ([System.IO.Path]::GetTempPath()) "ps-profile-release-$Version"

if (Test-Path $StagingDir) {
    Remove-Item -Path $StagingDir -Recurse -Force
}
New-Item -Path $StagingDir -ItemType Directory -Force | Out-Null

Write-Host "`nStaging files..." -ForegroundColor Cyan

## ---------------------------------------------------------------------------
## Copy: Install-MonoProfile.ps1
## ---------------------------------------------------------------------------
$installerSrc = Join-Path $RepoRoot "Install-MonoProfile.ps1"
if (-not (Test-Path $installerSrc)) {
    Write-Error "Install-MonoProfile.ps1 not found at: $installerSrc"
    exit 1
}
Copy-Item -Path $installerSrc -Destination $StagingDir -Force
Write-Host "  Install-MonoProfile.ps1" -ForegroundColor Green

## ---------------------------------------------------------------------------
## Copy: Profiles/Monolith/
## ---------------------------------------------------------------------------
$monolithSrc = Join-Path $RepoRoot "Profiles\Monolith"
if (-not (Test-Path $monolithSrc)) {
    Write-Error "Profiles\Monolith directory not found at: $monolithSrc"
    exit 1
}
$monolithDest = Join-Path $StagingDir "Profiles\Monolith"
Copy-Item -Path $monolithSrc -Destination $monolithDest -Recurse -Force
Write-Host "  Profiles/Monolith/" -ForegroundColor Green

## ---------------------------------------------------------------------------
## Copy: Modules/Custom/
## ---------------------------------------------------------------------------
$modulesSrc = Join-Path $RepoRoot "Modules\Custom"
if (Test-Path $modulesSrc) {
    $modulesDest = Join-Path $StagingDir "Modules\Custom"
    New-Item -Path $modulesDest -ItemType Directory -Force | Out-Null

    ## Copy each module directory, optionally excluding tests
    $excludeDirs = @()
    if ($ExcludeTests) {
        $excludeDirs = @("tests")
    }

    Get-ChildItem -Path $modulesSrc -Directory | ForEach-Object {
        $moduleDest = Join-Path $modulesDest $_.Name
        Copy-Item -Path $_.FullName -Destination $moduleDest -Recurse -Force

        if ($ExcludeTests) {
            ## Remove test directories after copy
            Get-ChildItem -Path $moduleDest -Directory -Recurse |
                Where-Object { $excludeDirs -contains $_.Name } |
                ForEach-Object { Remove-Item -Path $_.FullName -Recurse -Force }
        }
    }

    $moduleCount = (Get-ChildItem -Path $modulesDest -Directory).Count
    Write-Host "  Modules/Custom/ ($moduleCount modules)" -ForegroundColor Green
}
else {
    Write-Warning "Modules/Custom directory not found — skipping"
}

## ---------------------------------------------------------------------------
## Copy: config/ (prompt themes)
## ---------------------------------------------------------------------------
$configSrc = Join-Path $RepoRoot "config"
if (Test-Path $configSrc) {
    $configDest = Join-Path $StagingDir "config"
    Copy-Item -Path $configSrc -Destination $configDest -Recurse -Force
    Write-Host "  config/" -ForegroundColor Green
}
else {
    Write-Warning "config directory not found — skipping"
}

## ---------------------------------------------------------------------------
## Write version file into the archive
## ---------------------------------------------------------------------------
$versionContent = @"
Version: $Version
Built:   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Dev:     $IsDev
"@
$versionContent | Out-File -FilePath (Join-Path $StagingDir "VERSION.txt") -Encoding utf8
Write-Host "  VERSION.txt" -ForegroundColor Green

## ---------------------------------------------------------------------------
## Create the .zip
## ---------------------------------------------------------------------------
$OutputDir = (Resolve-Path -Path $OutputDir -ErrorAction SilentlyContinue)?.Path
if (-not $OutputDir) {
    $OutputDir = Join-Path $RepoRoot "dist"
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

$ArchivePath = Join-Path $OutputDir $ArchiveName

Write-Host "`nCompressing archive..." -ForegroundColor Cyan

Compress-Archive -Path "$StagingDir\*" -DestinationPath $ArchivePath -Force

$archiveSize = (Get-Item $ArchivePath).Length
$archiveSizeMB = [math]::Round($archiveSize / 1MB, 2)

Write-Host "  Created: $ArchivePath" -ForegroundColor Green
Write-Host "  Size:    $archiveSizeMB MB" -ForegroundColor Gray

## ---------------------------------------------------------------------------
## Cleanup staging
## ---------------------------------------------------------------------------
Remove-Item -Path $StagingDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n=== Release build complete ===" -ForegroundColor Green
Write-Host "Archive: $ArchivePath" -ForegroundColor Cyan
Write-Host ""

## Return the path for pipeline consumption
$ArchivePath
