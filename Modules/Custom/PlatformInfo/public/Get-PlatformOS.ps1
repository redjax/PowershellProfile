function Get-PlatformOS {
    <#
        .SYNOPSIS
        Returns operating system information for the local Windows computer.

        .DESCRIPTION
        Queries Win32_OperatingSystem using Get-CimInstance.

        Requires Windows.

        .EXAMPLE
        Get-PlatformOS

        .EXAMPLE
        Get-PlatformOS | Format-List
    #>

    [CmdletBinding()]
    param()

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'Get-PlatformOS is supported only on Windows.'
        }

        $properties = @(
            'Caption'
            'Version'
            'BuildNumber'
            'OSArchitecture'
            'SerialNumber'
            'LastBootUpTime'
            'InstallDate'
            'RegisteredUser'
            'SystemDrive'
            'SystemDirectory'
            'WindowsDirectory'
            'TotalVisibleMemorySize'
            'FreePhysicalMemory'
            'SizeStoredInPagingFiles'
            'FreeVirtualMemory'
            'FreeSpaceInPagingFiles'
        )

        Get-CimInstance `
            -ClassName Win32_OperatingSystem `
            -ErrorAction Stop |
        Select-Object -Property $properties
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
