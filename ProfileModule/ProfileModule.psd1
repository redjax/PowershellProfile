@{
    RootModule          = '.\ProfileModule.psm1'
    ModuleVersion       = '0.1.0'
    GUID                = '1491925f-0698-4f01-9ac3-2694563dce3f'
    Author              = 'redjax'
    FunctionsToExport   = @('Invoke-Greeting', 'uptime', 'touch', 'unzip', 'grep', 'df', 'sed', 'which', 'export', 'pkill', 'pgrep', 'Install-AzureCLI', 'Get-UTCTime', 'Set-EnvVar', 'Remove-EnvVar', 'Test-IsAdmin', 'Start-AsAdmin', 'New-PSProfile', 'Get-CommandInfo', 'Show-ApprovedVerbs', 'Write-PSVersionTable', 'Show-TermColors', 'Lock-Machine', 'Show-ProfileModuleFunctions', 'Show-ProfileModuleAliases', 'Restart-Shell', 'Show-PSProfilePaths', 'Get-OpenIPAddress', 'Get-PublicIP', 'Get-ParentPath', 'Edit-Profile', 'New-SymLink', 'Find-File', 'Update-PSModules', 'New-SelfSignedCert', 'Install-ScoopCli', 'Initialize-ScoopCli', 'Install-Winget', 'Start-WinGetUpdate')
    AliasesToExport     = @('find', 'ghu', 'lock', 'profiles', 'reload', 'su', 'sudo', 'tn', 'which')
    CmdletsToExport     = @()
    VariablesToExport   = @()
}
