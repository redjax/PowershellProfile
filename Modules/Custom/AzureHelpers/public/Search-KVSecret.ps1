function Search-KVSecret {
    <#
        .SYNOPSIS
        Searches for a secret in an Azure Key Vault and retrieves its value.

        .DESCRIPTION
        This function connects to an Azure Key Vault, searches for a secret by name, and retrieves its value. If an exact match is not found, it lists all secrets that contain the specified name and allows the user to select one to retrieve its value.
        
        The az CLI will use the sign-in user's credentials, and that user must have the necessary permissions to access the Key Vault and its secrets (Key Vault Secrets User or Key Vault Secrets Officer).
        
        .NOTES
        The following Azure permissions are required for the user running this script:
            - Key Vault Secrets User (sufficient for read-only access)
            - Key Vault Secrets Officer (required for read/write access)

        .PARAMETER Vault
        The name of the Azure Key Vault to search in.

        .PARAMETER SecretName
        The name of the secret to search for. If an exact match is not found, it will search for secrets that contain this name.

        .EXAMPLE
        Search-KVSecret -Vault "MyKeyVault" -SecretName "MySecret"
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromRemainingArguments = $false)]
        [string]$Vault,
        [Parameter(Position = 1, Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string]$SecretName
    )

    ## Check if az cli is installed
    if ( -not ( Get-Command az -ErrorAction SilentlyContinue ) ) {
        Write-Error "Azure CLI is not installed or not found in the system PATH." -ForegroundColor Red
        return
    }

    Write-Host "Searching '$Vault' for secret '$SecretName' ..." -ForegroundColor Magenta

    ## Connect to Keyvault and search for secret
    try {
        $Result = az keyvault secret show --vault-name $Vault --name $SecretName --query "value" -o tsv 2>$null
    } catch {
        Write-Error "Error accessing Key Vault: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    ## Check status of last command, retry with a wider search if it failed
    if ( $LASTEXITCODE -eq 0 ) {
        Write-Host $Result -ForegroundColor DarkYellow -NoNewline
        try {
            Set-Clipboard -Value $Result

            Write-Host " - Value copied to clipboard" -ForegroundColor Green
            return
        } catch {
            Write-Error "Failed to copy value to clipboard. Please check your clipboard settings." -ForegroundColor Red
            Write-Host "Secret value: $Result" -ForegroundColor Yellow
            return
        }
    }
    else {
        Write-Warning "No secret found in '$Vault' that matches '$SecretName' exactly - beginning wider search."
    } 

    try {
        $Results = az keyvault secret list --vault-name $Vault --query "[?contains(name, '$SecretName')].name" -o tsv
    } catch {
        Write-Error "Error listing secrets in Key Vault: $($_.Exception.Message)"
        return
    }
    $SecretList = $Results -split "`r`n"

    if ( $SecretList.Length -eq 0 ) {
        Write-Host "No secrets found with name containing '$SecretName'. The 'SecretName' field is case sensitive unless an exact name is used. Also make sure the vault '$($Vault)' exists." -ForegroundColor Red
        return
    }
    elseif ($SecretList.Length -eq 1) {
        Write-Host "Only one secret found matching - pulling value for '$($SecretList[0])' from '$Vault'" -ForegroundColor Green
        $Value = $(az keyvault secret show --vault-name "$Vault" --name "$($SecretList[0])" --query "value" -o tsv)
        Write-Host $Value -ForegroundColor DarkYellow -NoNewline
        try {
            Set-Clipboard -Value $Value

            Write-Host " - Value copied to clipboard" -ForegroundColor Green
            return
        } catch {
            Write-Error "Failed to copy value to clipboard. Please check your clipboard settings." -ForegroundColor Red
            Write-Host "Secret value: $Value" -ForegroundColor Yellow
            return
        }
    }

 
    Write-Host "Matching Secrets:"
    for ($i = 0; $i -lt $SecretList.Count; $i++) {
        Write-Host "[$i] $($SecretList[$i])"
    }

    $Choice = Read-Host "Enter the number of the secret to view its value"
    [int]$ChoiceInt = -1
    if ([int]::TryParse($Choice, [ref]$ChoiceInt) -and $ChoiceInt -ge 0 -and $ChoiceInt -lt $SecretList.Count) {
        Write-Host "Pulling value for $($SecretList[$ChoiceInt]) from $Vault" -ForegroundColor Green
        $Value = $(az keyvault secret show --vault-name "$Vault" --name "$($SecretList[$ChoiceInt])" --query "value" -o tsv)
        Write-Host $Value -ForegroundColor DarkYellow -NoNewline
        Set-Clipboard -Value $Value
        Write-Host " - Value copied to clipboard" -ForegroundColor Green
    }
    else {
        Write-Host "Invalid choice. No app will be opened."
    }
}
