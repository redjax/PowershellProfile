function Get-PlatformMemory {
    <#
        .SYNOPSIS
        Returns physical memory information for the local Windows computer.

        .DESCRIPTION
        Queries Win32_PhysicalMemory using Get-CimInstance.

        Requires Windows.

        .EXAMPLE
        Get-PlatformMemory

        .EXAMPLE
        Get-PlatformMemory | Format-List
    #>

    [CmdletBinding()]
    param()

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'Get-PlatformMemory is supported only on Windows.'
        }

        $properties = @(
            'Capacity'
            'Speed'
            'Manufacturer'
            'PartNumber'
            'SerialNumber'
            'DeviceLocator'
            'FormFactor'
            'MemoryType'
            'ConfiguredClockSpeed'
            'BankLabel'
        )

        Get-CimInstance `
            -ClassName Win32_PhysicalMemory `
            -ErrorAction Stop |
        Select-Object -Property $properties
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
