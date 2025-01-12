@{
    RootModule          = '.\ProfileModule.psm1'
    ModuleVersion       = '0.1.0'
    GUID                = '1491925f-0698-4f01-9ac3-2694563dce3f'
    Author              = 'redjax'
    FunctionsToExport   = @('Test-IsAdmin', 'Greet-User')
    AliasesToExport     = @('ghu', 'tn')
    CmdletsToExport     = @()
    VariablesToExport   = @()
}
