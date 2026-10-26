function Get-PlatformNetwork {
    <#
        .SYNOPSIS
        Returns IP-enabled network adapter configurations.

        .DESCRIPTION
        Queries Win32_NetworkAdapterConfiguration using Get-CimInstance
        and returns configurations where IPEnabled is true.

        Requires Windows.

        .EXAMPLE
        Get-PlatformNetwork

        .EXAMPLE
        Get-PlatformNetwork | Format-List
    #>

    [CmdletBinding()]
    param()

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'Get-PlatformNetwork is supported only on Windows.'
        }

        $properties = @(
            'Description'
            'MACAddress'
            'IPAddress'
            'DefaultIPGateway'
            'DNSServerSearchOrder'
        )

        Get-CimInstance `
            -ClassName Win32_NetworkAdapterConfiguration `
            -ErrorAction Stop |
        Where-Object { $_.IPEnabled } |
        Select-Object -Property $properties
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
