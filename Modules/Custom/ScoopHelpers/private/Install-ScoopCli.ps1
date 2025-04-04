function Install-ScoopCli {
    <#
        .SYNOPSIS
        Install the scoop CLI from https://scoop.sh
    #>
    Write-Information "Install scoop from https://get.scoop.sh"
    
    if ( -not ( Get-Command scoop ) ) {
        Write-Output "Download & install scoop CLI"
        try {
            Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        }
        catch {
            Write-Error "Failed to install scoop."
            Write-Error "Exception details: $($exc.Message)"
            exit 1
        }
    }
}