function Find-ADUser {
    [CmdletBinding()]
    [Parameter(Mandatory = $false, HelpMessage = "The username to search for. Default: `$null")]
    [string]$Username = $null

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
        exit(1)
    }
}