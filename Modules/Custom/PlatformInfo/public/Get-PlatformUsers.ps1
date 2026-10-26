function Get-PlatformUsers {
    <#
        .SYNOPSIS
        Returns Windows user account information.

        .DESCRIPTION
        Queries Win32_UserAccount using Get-CimInstance.

        Does not restrict the query to local accounts.

        Requires Windows.

        .EXAMPLE
        Get-PlatformUsers

        .EXAMPLE
        Get-PlatformUsers |
            Where-Object { $_.LocalAccount } |
            Select-Object Name, Disabled, SID
    #>

    [CmdletBinding()]
    param()

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'Get-PlatformUsers is supported only on Windows.'
        }

        $properties = @(
            'Domain'
            'Name'
            'Description'
            'LocalAccount'
            'Status'
            'Disabled'
            'Lockout'
            'PasswordRequired'
            'PasswordExpires'
            'PasswordChangeable'
            'SID'
            'SIDType'
            'AccountType'
        )

        Get-CimInstance `
            -ClassName Win32_UserAccount `
            -ErrorAction Stop |
        Select-Object -Property $properties
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
