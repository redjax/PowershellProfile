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