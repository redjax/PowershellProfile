<#
    .SYNOPSIS
    Prompt initialization for Monolith profile.

    .DESCRIPTION
    Initializes the Starship prompt if available.
#>

## Starship prompt initialization
try {
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        # Initialize Starship prompt
        Invoke-Expression (&starship init powershell)
        Write-Verbose "Starship prompt initialized."
    }
    else {
        Write-Verbose "Starship is not installed. Using default prompt."
    }
}
catch {
    Write-Warning "Failed to initialize Starship: $($_.Exception.Message)"
}
