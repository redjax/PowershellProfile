function Get-InstalledApps {
    Param(
        [switch]$Count
    )

    [array]$Apps = @()

    Write-Debug "Adding 32 bit apps from HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    ## Add 32 bit apps
    $Apps += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

    Write-Debug "Adding 64 bit apps from HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    ## Add 64 bit apps
    $Apps += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

    if ( $Count ) {
        Write-Debug "Counted $($Apps.Count) installed app(s)."
        return $Apps.Count
    }
    else {
        return $Apps
    }
}

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

    # $Apps | ForEach-Object {
    #     [PSCustomObject]@{
    #         DisplayName    = $_.DisplayName
    #         DisplayVersion = $_.DisplayVersion
    #         Publisher      = $_.Publisher
    #         InstallDate    = if ($_.InstallDate -match '^\d{8}$') {
    #             # Convert YYYYMMDD to YYYY-MM-DD
    #             [datetime]::ParseExact($_.InstallDate, 'yyyyMMdd', $null).ToString('yyyy-MM-dd')
    #         }
    #         else {
    #             $_.InstallDate
    #         }
    #     }
    # } | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table
}