function Show-InstalledApps {
    <#
        .SYNOPSIS
        Lists all installed applications as a table.

        .DESCRIPTION
        Lists all installed applications as a table, converting the InstallDate to a datetime. Optionally, count the number of apps.
    #>

    $Apps = (Get-InstalledApps)
    Write-Debug "Found $($Apps.Count) installed app(s)."

    if ( ( $Apps.Count -eq 0) ) {
        Write-Warning "Did not find any installed apps. Try again as an administrator."
        return
    }

    $Apps | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table
}