function Invoke-Cli {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "High"
    )]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("prune-branches")]
        [string]$Operation,
        [Parameter(Mandatory = $false)]
        [string[]]$Args
    )

    Write-Debug "CLI operation: $($Operation)"
    Write-Debug "Got ($($Args.Count)) args"

}