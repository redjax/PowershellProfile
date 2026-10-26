@{
    Severity     = @(
        'Error'
        'Warning'
    )

    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
        'PSUseSingularNouns'
        ## This repository targets PowerShell 7 and uses UTF-8 without BOM.
        'PSUseBOMForUnicodeEncodedFile'
        ## The profile stores a number of global vars as state and updates them on profile load.
        'PSAvoidGlobalVars'
    )
}