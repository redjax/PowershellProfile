function Test-IsAdmin {
    ## Check if the current process is running with elevated privileges (admin rights)
    $isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    return $isAdmin
}

function Get-PowershellVersion() {
    $PowershellVersion = $PSVersionTable.PSVersion.ToString()

    Write-Host "Powershell version: $PowershellVersion"
}

## Export functions
# Export-ModuleMember -Function Test-IsAdmin
