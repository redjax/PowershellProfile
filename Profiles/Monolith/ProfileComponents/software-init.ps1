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

## IntelliShell
$env:INTELLI_HOME = "$env:APPDATA\IntelliShell\Intelli-Shell\data"
# $env:INTELLI_SEARCH_HOTKEY = 'Ctrl+Spacebar'
# $env:INTELLI_VARIABLE_HOTKEY = 'Ctrl+l'
# $env:INTELLI_BOOKMARK_HOTKEY = 'Ctrl+b'
# $env:INTELLI_FIX_HOTKEY = 'Ctrl+x'
# Set-Alias -Name 'is' -Value 'intelli-shell'
try {
    if (Get-Command intelli-shell.exe -ErrorAction SilentlyContinue) {
        intelli-shell.exe init powershell | Out-String | Invoke-Expression
        Write-Verbose "IntelliShell initialized."
    }
    else {
        Write-Verbose "IntelliShell is not installed."
    }
}
catch {
    Write-Warning "Failed to initialize IntelliShell: $($_.Exception.Message)"
}
