function Initialize-ScoopCli {
    <#
        .SYNOPSIS
        Installs Scoop prerequisites and configures additional buckets.

        .DESCRIPTION
        Installs Scoop if necessary, then installs Git and aria2,
        configures aria2, and adds the requested buckets.

        Requires Windows and the Install-ScoopCli helper when Scoop
        is not already installed.

        Supports -WhatIf and -Confirm.

        .PARAMETER ScoopBuckets
        Scoop buckets to add.

        .EXAMPLE
        Initialize-ScoopCli -ScoopBuckets extras, nerd-fonts -WhatIf

        .EXAMPLE
        Initialize-ScoopCli -ScoopBuckets extras, nerd-fonts -Confirm
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateNotNullOrEmpty()]
        [string[]] $ScoopBuckets = @(
            'extras'
            'nerd-fonts'
        )
    )

    function Invoke-ScoopCommand {
        param(
            [Parameter(Mandatory = $true)]
            [string[]] $Arguments
        )

        $LASTEXITCODE = 0

        & scoop @Arguments

        if (-not $?) {
            throw "Scoop command failed: scoop $($Arguments -join ' ')"
        }

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Scoop command failed with exit code ${LASTEXITCODE}: " +
                "scoop $($Arguments -join ' ')"
            )
        }
    }

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'Initialize-ScoopCli is supported only on Windows.'
        }

        foreach ($bucket in $ScoopBuckets) {
            if ([string]::IsNullOrWhiteSpace($bucket)) {
                throw 'Scoop bucket names cannot be empty or whitespace.'
            }
        }

        $action = (
            'Install Scoop if missing, install Git and aria2, ' +
            'enable aria2, disable aria2 warnings, and add buckets: ' +
            ($ScoopBuckets -join ', ')
        )

        if (-not $PSCmdlet.ShouldProcess('Current-user Scoop installation', $action)) {
            return
        }

        if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
            if (-not (
                    Get-Command Install-ScoopCli -ErrorAction SilentlyContinue
                )) {
                throw (
                    'Scoop is missing and the Install-ScoopCli helper ' +
                    'is unavailable.'
                )
            }

            Write-Host 'Installing Scoop...' -ForegroundColor Cyan

            Install-ScoopCli -ErrorAction Stop

            if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                throw (
                    'Scoop is not available in this session after installation. ' +
                    'Open a new PowerShell session and retry.'
                )
            }
        }

        Write-Host 'Installing Git...' -ForegroundColor Cyan
        Invoke-ScoopCommand -Arguments @('install', 'git')

        Write-Host 'Installing aria2...' -ForegroundColor Cyan
        Invoke-ScoopCommand -Arguments @('install', 'aria2')

        Write-Host 'Enabling aria2 downloads...' -ForegroundColor Cyan
        Invoke-ScoopCommand -Arguments @(
            'config', 'aria2-enabled', 'true'
        )

        Write-Host 'Disabling aria2 warnings...' -ForegroundColor Cyan
        Invoke-ScoopCommand -Arguments @(
            'config', 'aria2-warning-enabled', 'false'
        )

        foreach ($bucket in ($ScoopBuckets | Select-Object -Unique)) {
            Write-Host "Adding Scoop bucket: $bucket" -ForegroundColor Cyan

            Invoke-ScoopCommand -Arguments @(
                'bucket', 'add', $bucket
            )
        }

        Write-Host 'Scoop initialization completed.' -ForegroundColor Green
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
