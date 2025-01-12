function Get-ParentPath {
    ## Return the parent directory for a given path.
    Param(
        [string]$Path
    )

    If ( -Not ( $Path ) ) {
        Write-Warning "-Path is empty."
        return
    }

    $ParentPath = Split-Path -Path $Path -Parent

    return $ParentPath
}

function Edit-Profile {
    <#
        Open current profile.ps1 in PowerShell ISE
    #>
    Param(
        [string]$Editor = "notepad"
    )
    $ProfilePath = $($PROFILE)
    Write-Debug "Editor: $Editor, Profile: $($ProfilePath)"

    If ($host.Name -match 'ise') {
        ## Edit in PowerShell ISE, if available
        $psISE.CurrentPowerShellTab.Files.Add($ProfilePath)
    }
    Else {
        ## Edit in Notepad if no PowerShell ISE found
        & $Editor $ProfilePath
    }
}
