<#
.SYNOPSIS
    Third-party software initializations for PowerShell profile
    
.DESCRIPTION
    Centralized location for software that needs to inject code into the profile.
    This is sourced by the main profile during initialization.
#>

## IntelliShell
if (Get-Command intelli-shell.exe -ErrorAction SilentlyContinue) {
    $intelliStart = Get-Date
    
    $env:INTELLI_HOME = "C:\Users\jkenyon\AppData\Roaming\IntelliShell\Intelli-Shell\data"
    # $env:INTELLI_SEARCH_HOTKEY = 'Ctrl+Spacebar'
    # $env:INTELLI_VARIABLE_HOTKEY = 'Ctrl+l'
    # $env:INTELLI_BOOKMARK_HOTKEY = 'Ctrl+b'
    # $env:INTELLI_FIX_HOTKEY = 'Ctrl+x'
    # Set-Alias -Name 'is' -Value 'intelli-shell'
    
    try {
        intelli-shell.exe init powershell | Out-String | Invoke-Expression
    }
    catch {
        Write-Warning "Failed to initialize IntelliShell: $($_.Exception.Message)"
    }
    
    $intelliEnd = Get-Date
    $intelliTime = ($intelliEnd - $intelliStart).TotalMilliseconds
    Write-Debug "IntelliShell initialized in $([Math]::Round($intelliTime))ms"
}
