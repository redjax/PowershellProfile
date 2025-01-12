function Install-ScoopCli {
    <#
        .SYNOPSIS
        Install the scoop CLI from https://scoop.sh
    #>
    Write-Information "Install scoop from https://get.scoop.sh"
    Write-Output "Download & install scoop"
    
    If ( -Not (Get-Command scoop) ) {
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

function Initialize-ScoopCli {
    <#
        .SYNOPSIS
        Initialize the Scoop CLI.

        .DESCRIPTION
        Installs aria2 & git, enables buckets.

        .PARAMETER ScoopBuckets
        Array of strings representing scoop buckets that should be enabled.

        .EXAMPLE
        Initialize-ScoopCli -ScoopBuckets @("extras", "nerd-fonts")
    #>
    Param(
        [string[]]$ScoopBuckets = @("extras", "nerd-fonts")
    )
    Write-Output "Installing aria2 for accelerated downloads"

    try {
        scoop install aria2
        if ( -Not $(scoop config aria2-enabled) -eq $True) {
            scoop config aria2-enabled true
        }
    }
    catch {
        Write-Error "Failed to install aria2."
        Write-Error "Exception details: $($exc.Message)"
    }

    Write-Output "Enable scoop buckets"
    foreach ($Bucket in $ScoopBuckets) {
        try {
            scoop bucket add $Bucket
            Write-Output "Successfully added bucket: $Bucket"
        }
        catch {
            Write-Error "Failed to add bucket: $Bucket."
            Write-Error "Exception details: $($_.Exception.Message)"
        }
    }
    
    Write-Output "Disable scoop warning when using aria2 for downloads"
    try {
        scoop config aria2-warning-enabled false
    }
    catch {
        Write-Error "Failed to disable aria2 warning."
        Write-Error "Exception details: $($exc.Message)"
    }

    Write-Output "Install git"
    try {
        scoop install git
    }
    catch {
        Write-Error "Failed to install git."
        Write-Error "Exception details: $($exc.Message)"
    }
}
