function Get-PlatformOS {
    <#
        .SYNOPSIS
        Return operating system information.
    #>
    try {
        $OSInfo = Get-WmiObject Win32_OperatingSystem | Select-Object -Property `
            Caption, `
            Version, `
            BuildNumber, `
            OSArchitecture, `
            LastBootUpTime, `
            InstallDate, `
            RegisteredUser
    }
    catch {
        Write-Error "Error getting platform OS info. Details: $($_.Exception.Message)"
        exit(1)
    }

    $OSInfo
}
