function Install-DotnetAspire {
    <#
        .SYNOPSIS
        Installs the Aspire CLI.

        .DESCRIPTION
        Downloads the Aspire PowerShell installer to a temporary directory and invokes it with the selected parameters.

        Supports -WhatIf and -Confirm.

        .PARAMETER InstallPath
        Optional installation directory. When omitted, the Aspire installer selects its default directory.

        .PARAMETER VerboseOutput
        Enables verbose output from the installer.

        .PARAMETER Version
        Optional Aspire CLI version to install.

        .PARAMETER Quality
        Build quality to install: release, staging, or dev.
        Defaults to release.

        .EXAMPLE
        Install-DotnetAspire -WhatIf

        Shows the intended operation without downloading or running the installer.

        .EXAMPLE
        Install-DotnetAspire -InstallPath 'C:\Tools\Aspire' -VerboseOutput

        Installs to a custom directory with verbose output.

        .EXAMPLE
        Install-DotnetAspire -Quality staging -Confirm

        Requests confirmation before running the staging installer.
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        [Parameter(
            HelpMessage = 'Optional directory for the Aspire CLI installation.'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $InstallPath,

        [Parameter(
            HelpMessage = 'Enable verbose output during installation.'
        )]
        [switch] $VerboseOutput,

        [Parameter(
            HelpMessage = 'Install a specific Aspire CLI version.'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Version,

        [Parameter(
            HelpMessage = 'Build quality: release, staging, or dev.'
        )]
        [ValidateSet('release', 'staging', 'dev')]
        [string] $Quality = 'release'
    )

    $installerUri = 'https://aspire.dev/install.ps1'

    $installerParameters = @{
        Quality = $Quality
    }

    if ($PSBoundParameters.ContainsKey('InstallPath')) {
        $installerParameters.InstallPath = $InstallPath
    }

    if ($PSBoundParameters.ContainsKey('Version')) {
        $installerParameters.Version = $Version
    }

    if ($VerboseOutput -or $PSBoundParameters['Verbose']) {
        $installerParameters.Verbose = $true
    }

    $target = 'Aspire CLI'

    if ($InstallPath) {
        $target += " at '$InstallPath'"
    }

    $action = "Download and run the Aspire installer; quality: $Quality"

    if ($Version) {
        $action += "; version: $Version"
    }

    if (Get-Command -Name aspire -ErrorAction SilentlyContinue) {
        Write-Warning (
            'Aspire CLI is already available in PATH. ' +
            'Continuing will run the installer again.'
        )
    }

    if (-not $PSCmdlet.ShouldProcess($target, $action)) {
        return
    }

    $temporaryDirectory = $null

    try {
        $temporaryDirectory = Join-Path (
            [IO.Path]::GetTempPath()
        ) (
            'aspire-install-' + [guid]::NewGuid().ToString('N')
        )

        $null = New-Item `
            -Path $temporaryDirectory `
            -ItemType Directory `
            -ErrorAction Stop

        $installerPath = Join-Path $temporaryDirectory `
            'aspire-install.ps1'

        Write-Host 'Downloading Aspire CLI installer' `
            -ForegroundColor Cyan

        Invoke-WebRequest `
            -Uri $installerUri `
            -OutFile $installerPath `
            -ErrorAction Stop

        Write-Host 'Running Aspire CLI installer' `
            -ForegroundColor Cyan

        ## Reset the native-command exit status so an unrelated earlier
        #  command does not affect the result checked below.
        $LASTEXITCODE = 0

        & $installerPath @installerParameters -ErrorAction Stop

        if ($LASTEXITCODE -ne 0) {
            throw "Installer returned exit code $LASTEXITCODE."
        }

        Write-Host 'Aspire CLI installer completed.' `
            -ForegroundColor Green
    }
    catch {
        Write-Error (
            'Failed to install Aspire CLI: ' +
            $_.Exception.Message
        )
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
