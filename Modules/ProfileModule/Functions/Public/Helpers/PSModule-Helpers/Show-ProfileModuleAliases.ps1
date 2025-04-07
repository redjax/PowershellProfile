function Show-ProfileModuleAliases {
    try {
        $Aliases = Get-Command -Module ProfileModule -CommandType Alias
        if ($Aliases) {
            $Aliases | Format-Table Name, Definition, Source
        }
        else {
            Write-Warning "No aliases found for ProfileModule."
        }
    }
    catch {
        Write-Error "Unable to show ProfileModule aliases. Details: $($_.Exception.Message)"
        exit 1
    }
}