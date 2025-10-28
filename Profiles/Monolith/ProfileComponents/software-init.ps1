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
if (Get-Command intelli-shell.exe -ErrorAction SilentlyContinue) {
    intelli-shell.exe init powershell | Out-String | Invoke-Expression
}

