function Show-EnvVars {
    <#
        .SYNOPSIS
        Displays all environment variables in the current session.

        .DESCRIPTION
        This function retrieves and displays all environment variables available in the current PowerShell session.
    #>
    $EnvVars = (Get-ChildItem env:* | sort-object name)

    $EnvVars
}