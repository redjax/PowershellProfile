function Search-KVSecret {
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromRemainingArguments = $false)]
        [string]$Vault,
        [Parameter(Position = 1, Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string]$SecretName
    )

    Write-Host "Searching '$Vault' for secret '$SecretName' ..." -ForegroundColor Cyan

    $result = az keyvault secret show --vault-name "$Vault" --name "$SecretName" --query "value" -o tsv 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host $result -ForegroundColor DarkYellow -NoNewline
        Set-Clipboard -Value $result
        Write-Host " - Value copied to clipboard" -ForegroundColor Green
        return
    }
    else {
        Write-Host "No secret found in '$Vault' that matches '$SecretName' exactly - beginning search." -ForegroundColor Cyan
    } 

    $results = az keyvault secret list --vault-name $Vault --query "[?contains(name, '$SecretName')].name" -o tsv
    $secretList = $results -split "`r`n"

    if ($secretList.Length -eq 0) {
        Write-Host "No secrets found with name containing '$SecretName'. The 'Name' field is case sensitive unless an exact name is used" -ForegroundColor Red
        return
    }
    elseif ($secretList.Length -eq 1) {
        Write-Host "Only one secret found matching - pulling value for '$($secretList[0])' from '$Vault'" -ForegroundColor Green
        $value = $(az keyvault secret show --vault-name "$Vault" --name "$($secretList[0])" --query "value" -o tsv)
        Write-Host $value -ForegroundColor DarkYellow -NoNewline
        Set-Clipboard -Value $value
        Write-Host " - Value copied to clipboard" -ForegroundColor Green
        return
    }

 
    Write-Host "Matching Secrets:"
    for ($i = 0; $i -lt $secretList.Count; $i++) {
        Write-Host "[$i] $($secretList[$i])"
    }

    $choice = Read-Host "Enter the number of the secret to view its value"
    [int]$choiceInt = -1
    if ([int]::TryParse($choice, [ref]$choiceInt) -and $choiceInt -ge 0 -and $choiceInt -lt $secretList.Count) {
        Write-Host "Pulling value for $($secretList[$choiceInt]) from $Vault" -ForegroundColor Green
        $value = $(az keyvault secret show --vault-name "$Vault" --name "$($secretList[$choiceInt])" --query "value" -o tsv)
        Write-Host $value -ForegroundColor DarkYellow -NoNewline
        Set-Clipboard -Value $value
        Write-Host " - Value copied to clipboard" -ForegroundColor Green
    }
    else {
        Write-Host "Invalid choice. No app will be opened."
    }
}
