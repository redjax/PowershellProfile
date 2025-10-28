<#
    .SYNOPSIS
    Prompt initialization for Monolith profile.

    .DESCRIPTION
    Initializes the Starship prompt if available.
    Uses cached initialization script for faster loading.
#>

## Starship prompt initialization with caching
try {
    if ($global:CommandCache['starship']) {
        $starshipCache = Join-Path $env:USERPROFILE ".starship\starship.ps1"
        
        # Generate cache if it doesn't exist or is older than starship executable
        $starshipExe = (Get-Command starship).Source
        if (-not (Test-Path $starshipCache) -or 
            (Get-Item $starshipCache).LastWriteTime -lt (Get-Item $starshipExe).LastWriteTime) {
            
            $cacheDir = Split-Path $starshipCache -Parent
            if (-not (Test-Path $cacheDir)) {
                New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
            }
            
            & starship init powershell | Out-File -FilePath $starshipCache -Encoding utf8
            Write-Verbose "Starship cache regenerated at: $starshipCache"
        }
        
        # Source the cached init script
        . $starshipCache
        Write-Verbose "Starship prompt initialized from cache."
    }
    else {
        Write-Verbose "Starship is not installed. Using default prompt."
    }
}
catch {
    Write-Warning "Failed to initialize Starship: $($_.Exception.Message)"
}
