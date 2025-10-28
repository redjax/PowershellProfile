<#
    .SYNOPSIS
    Shell completions for Monolith profile.

    .DESCRIPTION
    Registers argument completers for various CLI tools:
    - Starship (prompt tool)
    - Azure CLI (az)
    - Azure Developer CLI (azd)
    - Winget (Windows package manager)
#>

#####################
# Shell Completions #
#####################

## Starship completions
try {
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        # Load Starship completions
        starship completions power-shell | Out-String | Invoke-Expression
        Write-Verbose "Starship completions loaded."
    }
    else {
        Write-Verbose "Starship is not installed. Skipping completions."
    }
}
catch {
    Write-Warning "Failed to load Starship completions: $($_.Exception.Message)"
}

## Azure CLI completions
try {
    if (Get-Command az -ErrorAction SilentlyContinue) {
        # Use Azure CLI's native PowerShell completion (much faster than argcomplete)
        if (Test-Path "$env:USERPROFILE\.azure\az.completion.ps1") {
            . "$env:USERPROFILE\.azure\az.completion.ps1"
            Write-Verbose "Azure CLI completions loaded (native method)."
        }
        else {
            # Generate the completion file if it doesn't exist
            Write-Verbose "Generating Azure CLI completion file..."
            az completion --shell powershell | Out-File -FilePath "$env:USERPROFILE\.azure\az.completion.ps1" -Encoding utf8
            . "$env:USERPROFILE\.azure\az.completion.ps1"
        }
    }
    else {
        Write-Verbose "Azure CLI is not installed. Skipping completions."
    }
}
catch {
    Write-Warning "Failed to load Azure CLI completions: $($_.Exception.Message)"
}

## Azure Developer CLI completions
try {
    if (Get-Command azd -ErrorAction SilentlyContinue) {
        azd completion powershell | Out-String | Invoke-Expression
        Write-Verbose "azd CLI completions loaded."
    }
    else {
        Write-Verbose "azd CLI is not installed. Skipping completions."
    }
}
catch {
    Write-Warning "Failed to load azd CLI completions: $($_.Exception.Message)"
}

## Winget completions
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
