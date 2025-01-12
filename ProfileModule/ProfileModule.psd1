@{
    RootModule          = '.\ProfileModule.psm1'
    ModuleVersion       = '0.1.0'
    GUID                = '1491925f-0698-4f01-9ac3-2694563dce3f'
    Author              = 'redjax'
    FunctionsToExport   = @('Set-EnvVar', 'Remove-EnvVar', 'Test-IsAdmin', 'Start-AsAdmin', 'Get-PowershellVersion', 'Start-StarshipShell', 'Get-CommandInfo', 'Write-PSVersionTable', 'Show-TermColors', 'Lock-Machine', 'Get-OpenIPAddress', 'Get-ParentPath', 'Edit-Profile', 'New-SymLink', 'Invoke-Greeting', 'Install-ScoopCli', 'Initialize-ScoopCli', 'uptime', 'touch($file)')
    AliasesToExport     = @('ghu', 'tn', 'lock', 'su', 'sudo', 'which')
    CmdletsToExport     = @()
    VariablesToExport   = @()
}
