function Search-KVSecret {
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromRemainingArguments = $false)]
        [string]$Vault,
        [Parameter(Position = 1, Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string]$SecretName
    )

    Write-Host "Searching '$Vault' for secret '$SecretName' ..." -ForegroundColor Cyan

    try {
        $Result = az keyvault secret show --vault-name "$Vault" --name "$SecretName" --query "value" -o tsv 2>&1
    } catch {
        Write-Error "Error accessing Key Vault: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    if ( $LASTEXITCODE -eq 0 ) {
        Write-Host $Result -ForegroundColor DarkYellow -NoNewline
        Set-Clipboard -Value $Result
        Write-Host " - Value copied to clipboard" -ForegroundColor Green
        return
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
        Set-Clipboard -Value $Value
        Write-Host " - Value copied to clipboard" -ForegroundColor Green
        return
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
