function Start-SystInstall {
    & ([scriptblock]::Create((Invoke-RestMethod https://raw.githubusercontent.com/redjax/syst/refs/heads/main/scripts/install-syst.ps1))) -Auto
}