$ConfirmPreference = "High"
function Invoke-GitPrune {
    <#
        .SYNOPSIS
        Deletes (prunes) any local branches that still exist after being deleted on the remote.

        .DESCRIPTION
        This script checks out the main branch, fetches from the remote, then
        deletes (prunes) any local branches that still exist after being deleted
        on the remote.

        WARNING: This is a destructive script. Make sure you don't need the local
        copy of your branch before pruning.

        .EXAMPLE
        Prune-GitBranches -MainBranch "main"
    #>
    [CmdletBinding(
        ## Support -WhatIf and -Confirm
        SupportsShouldProcess = $True,
        ## Set ConfirmPreference above function definitions
        #  to automatically prompt on specified level
        ConfirmImpact = "High"
    )]
    param(
        # [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$MainBranch = "main"
    )

    Set-LoggingLevel -Verbose:$Verbose -Debug:$Debug

    if ( -Not ( Test-Path -Path ./.git -ErrorAction SilentlyContinue ) ) {
        Write-Warning "Path '$($PWD)' is not a git repository."
        return
    }

    if ( -Not $PSCmdlet.ShouldProcess($MainBranch) ) {
        Write-Warning "Skipping git branch prune operation."
        return
    }

    try {
        git checkout $($MainBranch); `
            git remote update origin --prune; `
            git branch -vv `
        | Select-String -Pattern ": gone]" `
        | ForEach-Object {
            $_.ToString().Trim().Split(" ")[0]
        } `
        | ForEach-Object {
            If ( $PSCmdlet.ShouldProcess(($_)) ) {
                Write-Output "Deleting branch: $($_)"

                try {
                    git branch -D $_
                }
                catch {
                    Write-Error "Error deleting branch '$($_)'. Details: $($_.Exception.Message)"
                    continue
                }
            }
            else {
                Write-Information "Skipping deletion of branch: $($_)"
                continue
            }
        }

        Write-Host "Local branches pruned." -ForegroundColor Green

        exit 0
    }
    catch {
        Write-Warning "Error pruning local branches. Details: $($_.Exception.Message)"
        exit 1
    }
}