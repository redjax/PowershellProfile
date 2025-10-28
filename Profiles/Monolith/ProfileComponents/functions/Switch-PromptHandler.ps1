<#
    .SYNOPSIS
    Switch prompt handler on the fly.

    .DESCRIPTION
    Allows you to change between Starship, Oh-My-Posh, and default prompt
    without restarting your PowerShell session.

    .PARAMETER Handler
    The prompt handler to use: "starship", "oh-my-posh", "default"

    .EXAMPLE
    Switch-PromptHandler -Handler starship
    Switches to Starship prompt.

    .EXAMPLE
    Switch-PromptHandler -Handler oh-my-posh
    Switches to Oh-My-Posh prompt.

    .EXAMPLE
    Switch-PromptHandler -Handler default
    Switches to custom default prompt.
#>
function Switch-PromptHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("starship", "oh-my-posh", "default")]
        [string]$Handler
    )

    # Update the global variable
    $global:PromptHandler = $Handler
    
    # Reload the prompt component
    $ProfileDir = Split-Path -Path $PROFILE -Parent
    $ComponentsDir = Join-Path $ProfileDir "ProfileComponents"
    $PromptComponentPath = Join-Path $ComponentsDir "prompt.ps1"
    
    if (Test-Path $PromptComponentPath) {
        Write-Host "Switching to $Handler prompt..." -ForegroundColor Cyan
        try {
            . $PromptComponentPath
            Write-Host "Prompt switched successfully!" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to switch prompt: $($_.Exception.Message)"
        }
    }
    else {
        Write-Error "Prompt component not found at: $PromptComponentPath"
    }
}

# Alias for convenience
Set-Alias -Name "prompt-switch" -Value "Switch-PromptHandler"
