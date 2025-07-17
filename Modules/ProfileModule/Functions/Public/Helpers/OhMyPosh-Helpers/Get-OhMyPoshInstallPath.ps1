function Get-OhMyPoshInstallPath {
    if ( -Not ( Get-Command oh-my-posh -ErrorAction SilentlyContinue ) ) {
        Write-Error "Oh-My-Posh is not installed."
        return
    }

    ## Get the source of the oh-my-posh command
    try {
        $OhMyPoshPath = (Get-Command oh-my-posh).Source
        return $OhMyPoshPath
    }
    catch {
        Write-Error "Unable to get Oh-My-Posh install path. Details: $($_.Exception.Message)"
        return
    }
}