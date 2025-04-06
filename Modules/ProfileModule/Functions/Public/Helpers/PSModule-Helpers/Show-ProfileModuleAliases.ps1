function Show-ProfileModuleAliases {
    try {
        Get-Command -Module ProfileModule -CommandType Alias
    }
    catch {
        Write-Error "Unable to show ProfileModule aliases. Details: $($_.Exception.Message)"
        exit 1
    }
}