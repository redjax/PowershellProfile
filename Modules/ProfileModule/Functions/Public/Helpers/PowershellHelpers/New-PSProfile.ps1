function New-PSProfile {
    if (!(Test-Path -Path $PROFILE)) {
        Write-Warning "A Powershell profile was not found at path '$($PROFILE)'. Initializing new `$PROFILE."
        try {
            New-Item -ItemType File -Path $PROFILE -Force
            Write-Output "Profile initialized at path: $($PROFILE)"
            return
        }
        catch {
            Write-Error "Failed to initialize Powershell profile at path '$($PROFILE)'. Details: $($_.Exception.Message)"
            return $_.Exception
        }
    }
    else {
        Write-Output "A `$PROFILE .ps1 file already exists at path '$($PROFILE)'."
        return
    }
}