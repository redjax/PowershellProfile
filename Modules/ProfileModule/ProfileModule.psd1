@{
    RootModule          = 'ProfileModule.psm1'
    ModuleVersion       = '0.1.1'
    GUID                = '1491925f-0698-4f01-9ac3-2694563dce3f'
    Author              = 'redjax'
    FunctionsToExport   = @('Test-IsAdmin', 'Lock-Machine', 'Restart-ShellSession', 'Test-PendingReboot', 'Show-InstalledApps', 'Show-DiskInfo', 'Show-DiskUsage', 'Remove-EnvVar', 'Set-EnvVar', 'Show-EnvVars', 'Get-PowershellVersion', 'Install-PoshGit','Install-PowerShellGet', 'New-PSProfile', 'Show-ApprovedVerbs', 'Show-PSProfilePaths', 'Show-TermColors', 'Write-PSVersionTable', 'Show-ModulesInSession', 'Show-ProfileModuleAliases', 'Show-ProfileModuleFunctions', 'Update-PSModules', 'Test-ValidPackageManager', 'Install-Winget', 'Start-WinGetUpdate', 'Install-NerdFont', 'Start-StarshipShell')
    AliasesToExport     = @('bwu', 'lg', 'lock', 'profiles', 'reload', 'tn')
    CmdletsToExport     = @()
    VariablesToExport   = @()
}
