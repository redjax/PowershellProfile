function Set-KVSecret {
    <#
        .SYNOPSIS
        Creates or updates a secret in Azure Key Vault.

        .DESCRIPTION
        Uses the Azure CLI and its currently signed-in identity to create or update a secret.

        The signed-in identity must have permission to set secrets in the selected vault.

        Supports -WhatIf and -Confirm. The secret value is not printed by this function.

        .PARAMETER Vault
        The name of the Azure Key Vault.

        .PARAMETER SecretName
        The name of the secret to create or update.

        .PARAMETER SecretValue
        The value to store.

        .PARAMETER DryRun
        Shows the intended operation without changing the vault.
        Retained for compatibility; -WhatIf is the standard alternative.

        .EXAMPLE
        Set-KVSecret -Vault 'MyKeyVault' -SecretName 'MySecret' `
            -SecretValue $value -WhatIf

        Previews the operation without writing the secret.

        .EXAMPLE
        Set-KVSecret -Vault 'MyKeyVault' -SecretName 'MySecret' `
            -SecretValue $value -Confirm

        Requests confirmation before writing the secret.
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Vault,

        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SecretName,

        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SecretValue,

        [switch] $DryRun
    )

    if ([string]::IsNullOrWhiteSpace($SecretValue)) {
        Write-Error 'SecretValue cannot be empty or whitespace.'
        return
    }

    $target = "secret '$SecretName' in vault '$Vault'"
    $action = 'Create or update secret'

    # Compatibility with existing callers.
    if ($DryRun) {
        Write-Host "[DRY RUN] Would create or update $target." `
            -ForegroundColor Yellow

        Write-Host '[DRY RUN] No changes will be made.' `
            -ForegroundColor Yellow

        return
    }

    # Do not call Azure CLI unless ShouldProcess authorizes the operation.
    # -WhatIf returns here without making a change.
    if (-not $PSCmdlet.ShouldProcess($target, $action)) {
        return
    }

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Error 'Azure CLI is not installed or not found in PATH.'
        return
    }

    Write-Host "Setting $target..." -ForegroundColor Cyan

    try {
        $arguments = @(
            'keyvault'
            'secret'
            'set'
            '--vault-name'
            $Vault
            '--name'
            $SecretName
            '--value'
            $SecretValue
            '--query'
            'id'
            '--output'
            'tsv'
            '--only-show-errors'
        )

        $result = & az @arguments
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            throw "Azure CLI returned exit code $exitCode."
        }

        Write-Host "Successfully set $target." -ForegroundColor Green

        $secretId = ($result -join "`n").Trim()

        if ($secretId.StartsWith('https://')) {
            Write-Host "Secret ID: $secretId" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Error (
            "Failed to set secret '$SecretName' in vault '${Vault}': " +
            $_.Exception.Message
        )
    }
}
