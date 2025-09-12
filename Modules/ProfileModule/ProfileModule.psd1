@{
    RootModule          = 'ProfileModule.psm1'
    ModuleVersion       = '0.1.1'
    GUID                = '1491925f-0698-4f01-9ac3-2694563dce3f'
    Author              = 'redjax'
    FunctionsToExport   = @('Install-NerdFont', 'Start-StarshipShell', 'Test-ValidPackageManager', 'Install-Winget', 'Start-WinGetUpdate', 'Test-IsAdmin', 'Lock-Machine', 'Restart-ShellSession', 'Test-PendingReboot', 'Show-InstalledApps', 'Show-ModulesInSession', 'Show-ProfileModuleAliases', 'Show-ProfileModuleFunctions', 'Update-PSModules', 'Remove-EnvVar', 'Set-EnvVar', 'Show-EnvVars', 'Show-DiskInfo', 'Show-DiskUsage', 'Install-PoshGit', 'Start-LocalBranchPrune', 'Get-PowershellVersion', 'Install-PowerShellGet', 'New-PSProfile', 'Show-ApprovedVerbs', 'Show-PSProfilePaths', 'Show-TermColors', 'Write-PSVersionTable')
    AliasesToExport     = @('bwu', 'git-prune', 'lg', 'lock', 'profiles', 'reload', 'tn', 'wezterm')
    CmdletsToExport     = @()
    VariablesToExport   = @()
}
