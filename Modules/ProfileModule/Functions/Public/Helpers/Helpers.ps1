function Test-IsAdmin {
    ## Check if the current process is running with elevated privileges (admin rights)
    $isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    return $isAdmin
}

function Lock-Machine {
    ## Set computer state to Locked

    try {
        rundll32.exe user32.dll, LockWorkStation
    }
    catch {
        Write-Error "Unhandled exception locking machine. Details: $($_.Exception.Message)"
    }

}

function Restart-ShellSession {
    <#
        .SYNOPSIS
        Functions like the unix 'exec $SHELL' command. Reload a terminal session to refresh
        $PROFILE, modules, env vars, etc.
    #>

    ## Determine the correct executable based on PowerShell version
    $PowerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') {
        ## PowerShell 7+ uses pwsh.exe
        "$PSHOME\pwsh.exe"
    }
    else {
        ## Windows PowerShell uses powershell.exe
        "$PSHOME\powershell.exe"
    }

    ## Restart the shell and set the current working directory
    & $PowerShellExe -NoExit -Command "Set-Location -Path '$PWD'"

    ## Exit the current session
    exit
}

function Test-PendingReboot {
    <#
        .SYNOPSIS
        Check if the system requires a reboot.
    #>
    
    try {
        $PendingReboot = @{
            ComponentBasedServicing = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
            WindowsUpdate           = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
            PendingFileRename       = Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations'
            ClusterReboot           = Test-Path 'HKLM:\Cluster\Nodes'
        }

        [PSCustomObject]$PendingReboot
    }
    catch {
        Write-Error "Error checking pending reboot status."
    }
}
