function Get-PlatformGPU {
    <#
        .SYNOPSIS
        Returns graphics controller information for the local Windows computer.

        .DESCRIPTION
        Queries Win32_VideoController using Get-CimInstance.

        Requires Windows.

        .EXAMPLE
        Get-PlatformGPU

        .EXAMPLE
        Get-PlatformGPU | Format-List
    #>

    [CmdletBinding()]
    param()

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'Get-PlatformGPU is supported only on Windows.'
        }

        $properties = @(
            'Name'
            'VideoProcessor'
            'DriverVersion'
            'AdapterRAM'
            'CurrentRefreshRate'
            'CurrentHorizontalResolution'
            'CurrentVerticalResolution'
            'CurrentBitsPerPixel'
            'MaxRefreshRate'
            'DeviceID'
            'PNPDeviceID'
            'Status'
            'Description'
        )

        Get-CimInstance `
            -ClassName Win32_VideoController `
            -ErrorAction Stop |
        Select-Object -Property $properties
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
