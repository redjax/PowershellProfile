function New-SelfSignedCert {
    <#
        .SYNOPSIS
        Creates a self-signed certificate and exports its public certificate.

        .DESCRIPTION
        Creates a certificate in the selected Windows certificate store
        and exports the public certificate to a .cer file.

        Does not export the private key.

        Requires Windows.

        Supports -WhatIf and -Confirm.

        .PARAMETER CertName
        Certificate common name and exported filename.

        .PARAMETER CertStorePath
        Certificate store in which to create the certificate.

        .PARAMETER CertKeyLength
        Key length passed to New-SelfSignedCertificate.
        Must be suitable for the selected algorithm and provider.

        .PARAMETER CertAlgorithm
        Key algorithm passed to New-SelfSignedCertificate.

        .PARAMETER CertHashAlgorithm
        Hash algorithm used to sign the certificate.

        .PARAMETER CertOutputDir
        Directory for the exported .cer file.

        .EXAMPLE
        New-SelfSignedCert -CertName 'DevelopmentCert' -WhatIf

        .EXAMPLE
        New-SelfSignedCert -CertName 'DevelopmentCert' -Confirm
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $CertName,

        [ValidateNotNullOrEmpty()]
        [string] $CertStorePath = 'Cert:\CurrentUser\My',

        [ValidateRange(1, [int]::MaxValue)]
        [int] $CertKeyLength = 4096,

        [ValidateNotNullOrEmpty()]
        [string] $CertAlgorithm = 'RSA',

        [ValidateNotNullOrEmpty()]
        [string] $CertHashAlgorithm = 'SHA256',

        [ValidateNotNullOrEmpty()]
        [string] $CertOutputDir = 'C:\Temp'
    )

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'New-SelfSignedCert is supported only on Windows.'
        }

        if ([string]::IsNullOrWhiteSpace($CertName)) {
            throw 'CertName cannot be empty or whitespace.'
        }

        if (
            $CertName.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0
        ) {
            throw 'CertName contains characters that cannot be used in a filename.'
        }

        if (Test-Path -LiteralPath $CertOutputDir) {
            if (-not (
                    Test-Path -LiteralPath $CertOutputDir -PathType Container
                )) {
                throw "Certificate output path is not a directory: $CertOutputDir"
            }
        }

        $certFile = Join-Path $CertOutputDir "$CertName.cer"

        if (Test-Path -LiteralPath $certFile) {
            throw "Certificate export already exists: $certFile"
        }

        $action = (
            "Create certificate 'CN=$CertName' in '$CertStorePath' " +
            "and export its public certificate to '$certFile'"
        )

        if (-not $PSCmdlet.ShouldProcess($CertName, $action)) {
            return
        }

        if (-not (
                Test-Path -LiteralPath $CertOutputDir -PathType Container
            )) {
            $null = New-Item `
                -ItemType Directory `
                -Path $CertOutputDir `
                -Force `
                -ErrorAction Stop
        }

        $certificateParameters = @{
            Subject           = "CN=$CertName"
            CertStoreLocation = $CertStorePath
            KeyExportPolicy   = 'Exportable'
            KeySpec           = 'Signature'
            KeyLength         = $CertKeyLength
            KeyAlgorithm      = $CertAlgorithm
            HashAlgorithm     = $CertHashAlgorithm
            ErrorAction       = 'Stop'
        }

        $certificate = New-SelfSignedCertificate @certificateParameters

        try {
            $null = Export-Certificate `
                -Cert $certificate `
                -FilePath $certFile `
                -NoClobber `
                -ErrorAction Stop
        }
        catch {
            Write-Warning (
                'Certificate creation succeeded, but export failed. ' +
                "The certificate remains in '$CertStorePath' " +
                "with thumbprint '$($certificate.Thumbprint)'."
            )

            throw
        }

        Write-Host "Public certificate saved to: $certFile" `
            -ForegroundColor Green

        return $certificate
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
