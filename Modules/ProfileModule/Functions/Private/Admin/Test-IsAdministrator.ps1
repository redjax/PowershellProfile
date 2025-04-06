Function Test-IsAdministrator {
    <#
    .SYNOPSIS
    Check if the current user is an administrator.
    #>

    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}