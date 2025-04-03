@{
    RootModule          = 'ProfileModule.psm1'
    ModuleVersion       = '0.1.0'
    GUID                = '1491925f-0698-4f01-9ac3-2694563dce3f'
    Author              = 'redjax'
    FunctionsToExport   = @('Invoke-Greeting', 'Find-ADUser', 'Install-AzureCLI', 'Get-InstalledApps', 'Show-InstalledApps', 'Get-UTCTime', 'Get-DiskUsage', 'Set-EnvVar', 'Remove-EnvVar', 'Test-IsAdmin', 'Start-AsAdmin', 'New-PSProfile', 'Get-PowershellVersion', 'Start-StarshipShell', 'Get-CommandInfo', 'Show-ApprovedVerbs', 'Write-PSVersionTable', 'Show-TermColors', 'Lock-Machine', 'Show-ProfileModuleFunctions', 'Show-ProfileModuleAliases', 'Restart-ShellSession', 'Show-PSProfilePaths', 'Get-RandomUAString', 'Show-ModulesInSession', 'Get-OpenIPAddress', 'Get-PublicIP', 'Get-HTTPSiteAvailable', 'Get-ParentPath', 'Get-ProfileDir', 'Switch-ToProfilePath', 'Edit-Profile', 'New-SymLink', 'Find-File', 'Unlock-DownloadedFile', 'Update-PSModules', 'New-SelfSignedCert', 'Convert-ToLowercase', 'Convert-ToUppercase', 'Convert-ToTitlecase', 'Install-ScoopCli', 'Initialize-ScoopCli', 'Install-Winget', 'Start-WinGetUpdate', 'y', 'Open-YaziHelp', 'Get-Weather', 'uptime', 'touch', 'unzip', 'grep', 'df', 'sed', 'which', 'export', 'pkill', 'pgrep')
    AliasesToExport     = @('ghu', 'lg', 'lock', 'profiles', 'reload', 'su', 'sudo', 'tn', 'which')
    CmdletsToExport     = @()
    VariablesToExport   = @()
}
