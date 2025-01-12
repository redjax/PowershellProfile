function Test-IsAdmin {
    ## Check if the current process is running with elevated privileges (admin rights)
    $isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    return $isAdmin
}

function Start-AsAdmin {
    <#
        .SYNOPSIS
        Pipe a command through an elevated Powershell prompt.

        .PARAMETER Command
        The Powershell command to run in the elevated shell.
    #>
    param (
        [string]$Command
    )

    # Check if the script is running as admin
    $isAdmin = [bool](New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        # Prompt to run as administrator if not already running as admin
        $arguments = "-Command `"& {$command}`""
        Write-Debug "Running command: Start-Process powershell -ArgumentList $($arguments) -Verb RunAs"

        try {
            Start-Process powershell -ArgumentList $arguments -Verb RunAs
            return $true  # Indicate that the script was elevated and the command will run
        }
        catch {
            Write-Error "Error executing command as admin. Details: $($_.Exception.Message)"
        }
    }
    else {
        # If already running as admin, execute the command
        Invoke-Expression $command
        return $false  # Indicate that the command was run without elevation
    }
}

function Get-PowershellVersion() {
    ## Print Powershell version string
    $PowershellVersion = $PSVersionTable.PSVersion.ToString()

    Write-Host "Powershell version: $PowershellVersion"
}

function Start-StarshipShell() {
    ## Initialize Starship shell
    If ( Get-Command starship ) {
        try {
            Invoke-Expression (&starship init powershell)
        }
        catch {
            ## Show error when verbose logging is enabled
            #  Write-Verbose "The 'starship' command was not found. Skipping initialization." -Verbose
        }
    }
}

## Export functions
# Export-ModuleMember -Function Test-IsAdmin
