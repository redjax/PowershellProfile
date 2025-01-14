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
    param(
        [string]$Command
    )

    # Check if the script is running as admin
    $isAdmin = [bool](New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        # Prompt to run as administrator if not already running as admin
        $arguments = "-Command `"& {$command}`""
        Write-Debug "Running command: Start-Process powershell -ArgumentList $($arguments) -Verb RunAs"

        try {
            Start-Process powershell -ArgumentList $arguments -Verb RunAs
            return $true # Indicate that the script was elevated and the command will run
        }
        catch {
            Write-Error "Error executing command as admin. Details: $($_.Exception.Message)"
        }
    }
    else {
        # If already running as admin, execute the command
        Invoke-Expression $command
        return $false # Indicate that the command was run without elevation
    }
}

function New-PSProfile {
    if (!(Test-Path -Path $PROFILE)) {
        Write-Warning "A Powershell profile was not found at path '$($PROFILE)'. Initializing new `$PROFILE."
        try {
            New-Item -ItemType File -Path $PROFILE -Force
            Write-Output "Profile initialized at path: $($PROFILE)"
            return
        } catch {
            Write-Error "Failed to initialize Powershell profile at path '$($PROFILE)'. Details: $($_.Exception.Message)"
            return $_.Exception
        }
    } else {
        Write-Output "A `$PROFILE .ps1 file already exists at path '$($PROFILE)'."
        return
    }
}

function Get-PowershellVersion () {
    ## Print Powershell version string
    $PowershellVersion = $PSVersionTable.PSVersion.ToString()

    Write-Output "Powershell version: $PowershellVersion"
}

function Start-StarshipShell () {
    ## Initialize Starship shell
    if (Get-Command starship) {
        try {
            Invoke-Expression (& starship init powershell)
        }
        catch {
            ## Show error when verbose logging is enabled
            #  Write-Verbose "The 'starship' command was not found. Skipping initialization." -Verbose
        }
    }
}

function Get-CommandInfo {
    param(
        [string]$CommandInput
    )

    try {
        $CommandOutput = $(Get-Command $CommandInput)
        return $CommandOutput
    }
    catch {
        Write-Error "Error running Get-Command '$($CommandInput)'. Details: $($_.Exception.message)"
        return
    }
}

function Show-ApprovedVerbs {
    # Get all approved verbs
    $verbs = Get-Verb

    # Format and display the verbs in a table
    $verbs | Sort-Object Verb | Format-Table -Property Verb,Group-Object -AutoSize
}

function Write-PSVersionTable {
    Write-Output 'Powershell Version Info'
    $PSVersionTable
}

function Show-TermColors {
    # [Enum]::GetValues([ConsoleColor])

    $colors = [enum]::GetValues([System.ConsoleColor])
    foreach ($bgcolor in $colors) {
        foreach ($fgcolor in $colors) { Write-Output "$fgcolor|" -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewline }
        Write-Output " on $bgcolor"
    }
}

function Lock-Machine {
    ## Set computer state to Locked

    try {
        rundll32.exe user32.dll,LockWorkStation
    }
    catch {
        Write-Error "Unhandled exception locking machine. Details: $($_.Exception.Message)"
    }

}

function Show-ProfileModuleFunctions {
    try {
        Get-Command -Module ProfileModule -CommandType Function
    } catch {
        Write-Error "Unable to show ProfileModule functions. Details: $($_.Exception.Message)"
        exit 1
    }
}

function Show-ProfileModuleAliases {
    try {
        Get-Command -Module ProfileModule -CommandType Alias
    } catch {
        Write-Error "Unable to show ProfileModule aliases. Details: $($_.Exception.Message)"
        exit 1
    }
}

function Restart-Shell {
    <#
        .SYNOPSIS
        Functions like the unix 'exec $SHELL' command. Reload a terminal session to refresh
        $PROFILE, modules, env vars, etc.
    #>

    ## Determine the correct executable name based on the PowerShell version
    $ShellExecutable = if ($PSVersionTable.PSEdition -eq 'Core') {
        ## PowerShell 7+ uses pwsh.exe
        "$PSHOME\pwsh.exe"
    } else {
        ## Windows PowerShell uses powershell.exe
        "$PSHOME\powershell.exe"
    }

    & $ShellExecutable -NoExit -Command "Set-Location -Path '$PWD'"
    exit
}

function Show-PSProfilePaths {
    <#
        .SYNOPSIS
        Show all $PROFILE paths.
    #>

    # $profile | Get-Member -MemberType NoteProperty
    $PROFILE | Get-Member -MemberType NoteProperty | ForEach-Object {
        [pscustomobject]@{
            Name = $_.Name
            Path = $PROFILE.PSObject.Properties[$_.Name].Value
        }
    } | Format-Table -AutoSize
}
