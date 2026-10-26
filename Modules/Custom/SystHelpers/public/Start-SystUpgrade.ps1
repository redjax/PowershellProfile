function Start-SystUpgrade {
    <#
        .SYNOPSIS
        Reruns the Syst installer to update the installation.

        .DESCRIPTION
        Calls Start-SystInstall -Reinstall.

        Does not delete the existing Syst executable before downloading
        and running the installer.

        Actual replacement behavior is controlled by the Syst installer.

        Supports -WhatIf and -Confirm.

        .EXAMPLE
        Start-SystUpgrade -WhatIf

        .EXAMPLE
        Start-SystUpgrade -Confirm
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $existingCommand = Get-Command `
        -Name syst `
        -CommandType Application `
        -ErrorAction SilentlyContinue |
    Select-Object -First 1

    $target = 'Syst installation'

    if ($existingCommand) {
        $target = $existingCommand.Path
    }

    if (-not $PSCmdlet.ShouldProcess(
            $target,
            'Rerun the Syst installer to install the current release'
        )) {
        return
    }

    try {
        ## The outer function has already requested approval.
        #  Keep the inner guard active, but avoid a second confirmation.
        Start-SystInstall `
            -Reinstall `
            -Confirm:$false `
            -ErrorAction Stop
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
