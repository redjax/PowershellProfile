function Start-SystInstall {
    <#
        .SYNOPSIS
        Downloads and runs the Syst PowerShell installer.

        .DESCRIPTION
        Downloads the installer from the Syst repository and invokes it
        with -Auto.

        Skips installation if Syst is already available, unless -Reinstall
        is supplied.

        Supports -WhatIf and -Confirm.

        .PARAMETER Reinstall
        Runs the installer even when Syst is already installed.

        Does not delete the existing executable before running the installer.

        .EXAMPLE
        Start-SystInstall -WhatIf

        .EXAMPLE
        Start-SystInstall -Confirm

        .EXAMPLE
        Start-SystInstall -Reinstall -Confirm
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch] $Reinstall
    )

    $existingCommand = Get-Command `
        -Name syst `
        -CommandType Application `
        -ErrorAction SilentlyContinue |
    Select-Object -First 1

    if ($existingCommand -and -not $Reinstall) {
        Write-Warning (
            "Syst is already installed at '$($existingCommand.Path)'. " +
            'Use Start-SystUpgrade to rerun the installer.'
        )

        return
    }

    $installerUri = (
        'https://raw.githubusercontent.com/redjax/syst/' +
        'refs/heads/main/scripts/install-syst.ps1'
    )

    $action = 'Download and run the Syst installer with -Auto'

    if ($Reinstall) {
        $action += ', retaining the existing executable until the installer handles it'
    }

    if (-not $PSCmdlet.ShouldProcess('Syst installation', $action)) {
        return
    }

    $temporaryDirectory = $null

    try {
        $temporaryDirectory = Join-Path `
        ([IO.Path]::GetTempPath()) `
        ('syst-install-' + [guid]::NewGuid().ToString('N'))

        $null = New-Item `
            -Path $temporaryDirectory `
            -ItemType Directory `
            -ErrorAction Stop

        $installerPath = Join-Path $temporaryDirectory 'install-syst.ps1'

        Write-Host 'Downloading Syst installer...' -ForegroundColor Cyan

        Invoke-WebRequest `
            -Uri $installerUri `
            -OutFile $installerPath `
            -ErrorAction Stop

        $LASTEXITCODE = 0

        Write-Host 'Running Syst installer...' -ForegroundColor Cyan

        & $installerPath -Auto -ErrorAction Stop

        if ($LASTEXITCODE -ne 0) {
            throw "Syst installer returned exit code $LASTEXITCODE."
        }

        Write-Host 'Syst installer completed.' -ForegroundColor Green
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        if (
            $temporaryDirectory -and
            (Test-Path -LiteralPath $temporaryDirectory)
        ) {
            Remove-Item `
                -LiteralPath $temporaryDirectory `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}
