function Get-PowershellVersion {
    Param(
        [switch]$Major,
        [switch]$Minor
    )

    if ( ($Major -and $Minor) -or ( ( -not $Major ) -and ( -not $Minor ) ) ) {
        ## Both flags passed, or neither passed, print full string
        $PowershellVersion = $PSVersionTable.PSVersion.ToString()
        Write-Debug "Powershell version: $($PowershellVersion)"

        return $PowershellVersion

    }
    elseif ( $Major ) {
        ## Return major version
        $PowershellVersion = $PSVersionTable.PSVersion.Major.ToString()
        Write-Debug "Powershell version: $($PowershellVersion)"

        return $PowershellVersion

    }
    else {
        ## Return minor version
        $PowershellVersion = $PSVersionTable.PSVersion.Minor.ToString()
        Write-Debug "Powershell version: $($PowershellVersion)"

        return $PowershellVersion

    }
}