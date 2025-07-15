function Install-PoshGit {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [string]$Version = "1.1.0"
    )

    $ModuleName    = "posh-git"
    $GalleryURL    = "https://www.powershellgallery.com/api/v2/package/$ModuleName/$Version"
    $TempPath      = Join-Path $env:TEMP "$ModuleName.nupkg"
    $ExtractPath   = Join-Path $env:TEMP "$ModuleName-extracted"
    $TargetPath    = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\$ModuleName"

    ## Clean up old paths
    Remove-Item -Path $TempPath -ErrorAction SilentlyContinue -Force
    Remove-Item -Path $ExtractPath -Recurse -ErrorAction SilentlyContinue -Force
    Remove-Item -Path $TargetPath -Recurse -ErrorAction SilentlyContinue -Force

    try {
        Write-Host "Downloading $ModuleName v$Version from PowerShell Gallery..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $GalleryURL -OutFile $TempPath -UseBasicParsing -ErrorAction Stop

        Write-Host "Extracting package..." -ForegroundColor Cyan
        Expand-Archive -Path $TempPath -DestinationPath $ExtractPath -Force

        ## Confirm the psd1 file exists at the extracted root
        $ModuleRoot = $ExtractPath
        if (-not (Test-Path (Join-Path $ModuleRoot "$ModuleName.psd1"))) {
            throw "Could not find $ModuleName.psd1 in extracted root folder: $ModuleRoot"
        }

        Write-Host "Installing module to: $TargetPath" -ForegroundColor Cyan
        New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$ModuleRoot\*" -Destination $TargetPath -Recurse -Force

        Write-Host "`n$ModuleName v$Version installed successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        return $false
    }
    finally {
        ## Remove files created by script
        Remove-Item -Path $TempPath -ErrorAction SilentlyContinue -Force
        Remove-Item -Path $ExtractPath -Recurse -ErrorAction SilentlyContinue -Force
    }
}
