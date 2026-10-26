function Get-PlatformDisk {
    <#
        .SYNOPSIS
        Returns disk drive information for the local Windows computer.

        .DESCRIPTION
        Queries Win32_DiskDrive using Get-CimInstance.

        Requires Windows.

        .EXAMPLE
        Get-PlatformDisk

        .EXAMPLE
        Get-PlatformDisk | Format-List
    #>

    [CmdletBinding()]
    param()

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'Get-PlatformDisk is supported only on Windows.'
        }

        $properties = @(
            'Model'
            'InterfaceType'
            'MediaType'
            'Size'
            'Partitions'
            'SerialNumber'
            'DeviceID'
            'Status'
            'Name'
        )

        Get-CimInstance `
            -ClassName Win32_DiskDrive `
            -ErrorAction Stop |
        Select-Object -Property $properties
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
