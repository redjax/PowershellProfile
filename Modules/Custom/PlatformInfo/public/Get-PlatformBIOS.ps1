function Get-PlatformBIOS {
    <#
        .SYNOPSIS
        Returns BIOS and firmware information for the local Windows computer.

        .DESCRIPTION
        Queries Win32_BIOS using Get-CimInstance and returns selected
        BIOS and firmware properties.

        This function requires Windows.

        .EXAMPLE
        Get-PlatformBIOS

        .EXAMPLE
        Get-PlatformBIOS | Format-List

        .EXAMPLE
        Get-PlatformBIOS | Select-Object Manufacturer, SerialNumber
    #>

    [CmdletBinding()]
    param()

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'Get-PlatformBIOS is supported only on Windows.'
        }

        $properties = @(
            'Manufacturer'
            'Name'
            'Version'
            'SerialNumber'
            'ReleaseDate'
            'Status'
            'PrimaryBIOS'
            'SMBIOSPresent'
            'SMBIOSBIOSVersion'
            'SMBIOSMajorVersion'
            'SMBIOSMinorVersion'
            'Description'
            'CurrentLanguage'
        )

        Get-CimInstance `
            -ClassName Win32_BIOS `
            -ErrorAction Stop |
        Select-Object -Property $properties
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
