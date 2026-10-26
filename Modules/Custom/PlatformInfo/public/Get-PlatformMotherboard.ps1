function Get-PlatformMotherboard {
    <#
        .SYNOPSIS
        Returns motherboard information for the local Windows computer.

        .DESCRIPTION
        Queries Win32_BaseBoard using Get-CimInstance.

        Requires Windows.

        .EXAMPLE
        Get-PlatformMotherboard

        .EXAMPLE
        Get-PlatformMotherboard | Format-List
    #>

    [CmdletBinding()]
    param()

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'Get-PlatformMotherboard is supported only on Windows.'
        }

        $properties = @(
            'Manufacturer'
            'Product'
            'SerialNumber'
            'Version'
            'Status'
            'Name'
            'Tag'
            'Description'
        )

        Get-CimInstance `
            -ClassName Win32_BaseBoard `
            -ErrorAction Stop |
        Select-Object -Property $properties
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
