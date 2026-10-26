function Get-PlatformCPU {
    <#
        .SYNOPSIS
        Returns CPU information for the local Windows computer.

        .DESCRIPTION
        Queries Win32_Processor using Get-CimInstance.

        Returns one object per processor instance.

        Requires Windows.

        .EXAMPLE
        Get-PlatformCPU

        .EXAMPLE
        Get-PlatformCPU | Format-List
    #>

    [CmdletBinding()]
    param()

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'Get-PlatformCPU is supported only on Windows.'
        }

        $properties = @(
            'Name'
            'NumberOfCores'
            'NumberOfLogicalProcessors'
            'MaxClockSpeed'
            'CurrentClockSpeed'
            'L2CacheSize'
            'L3CacheSize'
        )

        Get-CimInstance `
            -ClassName Win32_Processor `
            -ErrorAction Stop |
        Select-Object -Property $properties
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
