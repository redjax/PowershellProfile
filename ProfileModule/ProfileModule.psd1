@{
    RootModule          = '.\ProfileModule.psm1'
    ModuleVersion       = '0.1.0'
    GUID                = '1491925f-0698-4f01-9ac3-2694563dce3f'
    Author              = 'redjax'
    FunctionsToExport   = @('Invoke-Greeting', 'uptime', 'touch', 'Install-AzureCLI', 'Set-EnvVar', 'Remove-EnvVar', 'Test-IsAdmin', 'Start-AsAdmin', 'Get-CommandInfo', 'Show-ApprovedVerbs', 'Write-PSVersionTable', 'Show-TermColors', 'Lock-Machine', 'Show-ProfileModuleFunctions', 'Show-ProfileModuleAliases', 'Get-OpenIPAddress', 'Get-ParentPath', 'Edit-Profile', 'New-SymLink', 'Install-ScoopCli', 'Initialize-ScoopCli', 'Install-Winget')
    AliasesToExport     = @('ghu', 'lock', 'su', 'sudo', 'tn', 'which')
    CmdletsToExport     = @()
    VariablesToExport   = @()
}
