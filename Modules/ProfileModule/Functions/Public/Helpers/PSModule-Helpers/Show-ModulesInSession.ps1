function Show-ModulesInSession {
    (Get-Command).Module.Name | Sort-Object -Unique
}