$CustomPSModulesPath = ( Join-Path -Path ( Split-Path -Path $PROFILE -Parent ) -ChildPath "CustomModules" )
if ( Test-Path -Path $CustomPSModulesPath ) {
    Write-Warning "Removing custom Powershell modules directory: $CustomPSModulesPath"

    try {
        Remove-Item -Recurse -Force $CustomPSModulesPath
    }
    catch {
        Write-Error "Error removing custom Powershell modules directory: $CustomPSModulesPath. Details: $($_.Exception.Message)"
        exit 1
    }

    Write-Host "Successfully removed custom Powershell modules directory: $CustomPSModulesPath" -ForegroundColor Green
}
