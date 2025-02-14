function Start-ModuleManifestUpdate {
    Param(
        [string]$ModuleAuthor = $env:USERNAME,
        [string]$ModuleName = "ProfileModule",
        [string]$RepoModulesDir = "$($PSScriptRoot)\Modules",
        [string]$ModuleRoot = (Join-Path $RepoModulesDir $ModuleName),
        [string]$FunctionsPath = (Join-Path $ModuleRoot "Functions"),
        [string]$AliasesPath = (Join-Path $ModuleRoot "Aliases"),
        [string]$ManifestPath = (Join-Path $ModuleRoot "$ModuleName.psd1"),
        [string]$GUIDFilePath = (Join-Path $ModuleRoot "guid.txt"),
        [string]$AuthorFilePath = (Join-Path $ModuleRoot "author.txt"),
        [string]$VersionFilePath = (Join-Path $ModuleRoot "version.txt")
    )
    Write-Host "Updating module manifest at path: $($ManifestPath)" -ForegroundColor Cyan
    try {
        Update-ProfileModuleManifest `
            -GUIDFilePath $GUIDFilePath `
            -Author $ModuleAuthor `
            -AuthorFilePath $AuthorFilePath `
            -VersionFilePath $VersionFilePath `
            -ManifestPath $ManifestPath `
            -FunctionsPath $FunctionsPath `
            -AliasesPath $AliasesPath # `
        # -Verbose:$Verbose `
        # -Debug:$Debug
    }
    catch {
        Write-Error "Error creating/updating module manifest. Details: $($_.Exception.Message)"
    }
}