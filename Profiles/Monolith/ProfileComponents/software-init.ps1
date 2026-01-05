<#
    .SYNOPSIS
    Third-party software initialization for Monolith profile.

    .DESCRIPTION
    Initializes third-party software integrations:
    - IntelliShell (AI-powered shell assistance)
#>

###########################
# Software Initialization #
###########################

## Mise
if (Get-Command mise -ErrorAction SilentlyContinue) {
    ## Initialize variables that mise checks for to avoid "variable not set" errors
    if (-not (Get-Variable -Name __mise_pwsh_chpwd -Scope Global -ErrorAction SilentlyContinue)) {
        $Global:__mise_pwsh_chpwd = $null
    }

    if (-not (Get-Variable -Name __mise_pwsh_previous_prompt_function -Scope Global -ErrorAction SilentlyContinue)) {
        $Global:__mise_pwsh_previous_prompt_function = $null
    }

    if (-not (Get-Variable -Name __mise_pwsh_command_not_found -Scope Global -ErrorAction SilentlyContinue)) {
        $Global:__mise_pwsh_command_not_found = $null
    }

    if (-not (Get-Variable -Name __mise_original_pwsh_chpwd_function -Scope Global -ErrorAction SilentlyContinue)) {
        $Global:__mise_original_pwsh_chpwd_function = $null
    }
    
    ## Activate Mise
    mise activate pwsh | Out-String | Invoke-Expression

    try {
        $miseShim = "$env:LOCALAPPDATA\mise\shims"
        if (Test-Path $miseShim) {
            $env:PATH = "$miseShim;$env:PATH"
        }
    } catch {
        Write-Warning "Failed to add Mise shims to PATH: $($_.Exception.Message)"
    }
}
