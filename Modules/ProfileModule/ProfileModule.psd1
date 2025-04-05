@{
    RootModule          = 'ProfileModule.psm1'
    ModuleVersion       = '0.1.1'
    GUID                = '1491925f-0698-4f01-9ac3-2694563dce3f'
    Author              = 'redjax'
    FunctionsToExport   = @('Get-InstalledApps', 'Show-InstalledApps', 'Get-DiskUsage', 'Set-EnvVar', 'Remove-EnvVar', 'Test-IsAdmin', 'New-PSProfile', 'Get-PowershellVersion', 'Start-StarshipShell', 'Get-CommandInfo', 'Show-ApprovedVerbs', 'Write-PSVersionTable', 'Show-TermColors', 'Lock-Machine', 'Show-ProfileModuleFunctions', 'Show-ProfileModuleAliases', 'Restart-ShellSession', 'Show-PSProfilePaths', 'Update-PSModules', 'Show-ModulesInSession', 'Install-ScoopCli', 'Initialize-ScoopCli', 'Install-Winget', 'Start-WinGetUpdate', 'y', 'Open-YaziHelp')
    AliasesToExport     = @('bwu', 'lg', 'lock', 'profiles', 'reload', 'tn')
    CmdletsToExport     = @()
    VariablesToExport   = @()
}
