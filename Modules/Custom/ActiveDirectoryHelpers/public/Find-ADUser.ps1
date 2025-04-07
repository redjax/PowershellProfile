function Find-ADUser {
    <#
        .SYNOPSIS
        Search Active Directory for a user

        .PARAMETER Username
        The username to search for

        .EXAMPLE
        Find-ADUser -Username "username"
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "The username to search for. Default: `$null")]
        [string]$Username = $null
    )

    while ( $null -eq $Username ) {
        $Username = Read-Host "Please enter a domain username to search for, ommitting the domain (i.e. 'username', not 'domain\username')"
    }

    Write-Output "Searching for user '$($Username)' ..."
    try {
        $ADUsers = (Get-ADUser -Identity $Username -Properties * | Format-List)
        return $ADUsers
    }
    catch {
        Write-Error "Error searching Active Directory for username '$($Username)'. Details: $($_.Exception.Message)"
        return
    }
}