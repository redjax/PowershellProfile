function Start-AsAdmin {
    <#
        .SYNOPSIS
        Runs PowerShell code with administrator privileges on Windows.

        .DESCRIPTION
        Runs the supplied script block directly when the current process
        is already elevated.

        Otherwise, starts an elevated PowerShell process using the same
        PowerShell installation as the current session.

        The elevated process does not load a PowerShell profile.

        Supports -WhatIf and -Confirm.

        .PARAMETER Command
        Script block containing the PowerShell code to run.

        When elevation starts a new process, the code must be self-contained.
        Local variables, functions, and imported modules are not transferred.

        .PARAMETER ArgumentList
        Positional arguments supplied to the script block.

        Arguments are serialized when starting an elevated process.
        Simple values such as strings, numbers, and arrays are suitable.
        Complex objects may be deserialized copies rather than live objects.

        .PARAMETER Wait
        Waits for a newly elevated process to finish and reports a nonzero
        process exit code as an error.

        .EXAMPLE
        Start-AsAdmin -Command {
            Get-Service
        }

        .EXAMPLE
        Start-AsAdmin -Command {
            Restart-Service -Name Spooler -ErrorAction Stop
        } -Wait -Confirm

        .EXAMPLE
        Start-AsAdmin -Command {
            Restart-Service -Name Spooler
        } -WhatIf
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [scriptblock] $Command,
        [object[]] $ArgumentList = @(),
        [switch] $Wait
    )

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw (
                'Start-AsAdmin supports Windows elevation only. ' +
                'On Linux or macOS, use the appropriate sudo command.'
            )
        }

        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()

        try {
            $principal = [Security.Principal.WindowsPrincipal]::new(
                $identity
            )

            $isAdmin = $principal.IsInRole(
                [Security.Principal.WindowsBuiltInRole]::Administrator
            )
        }
        finally {
            $identity.Dispose()
        }

        if (-not $PSCmdlet.ShouldProcess(
                'Administrator PowerShell session',
                'Execute the supplied script block'
            )) {
            return
        }

        if ($isAdmin) {
            Write-Verbose 'Already elevated; running in the current session.'

            & $Command @ArgumentList
            return
        }

        $executableName = if ($PSVersionTable.PSEdition -eq 'Core') {
            'pwsh.exe'
        }
        else {
            'powershell.exe'
        }

        $powerShellExe = Join-Path $PSHOME $executableName

        if (-not (
                Test-Path -LiteralPath $powerShellExe -PathType Leaf
            )) {
            throw "PowerShell executable not found: $powerShellExe"
        }

        ## Serialize arguments separately from executable code.
        #  Wrapping the array preserves zero, one, and multiple arguments.
        $argumentPayload = @{
            Arguments = [object[]] $ArgumentList
        }

        $argumentXml = [System.Management.Automation.PSSerializer]::Serialize(
            $argumentPayload,
            10
        )

        $encodedArguments = [Convert]::ToBase64String(
            [Text.Encoding]::UTF8.GetBytes($argumentXml)
        )

        $childCommand = @'
$ErrorActionPreference = 'Stop'

try {
    $argumentXml = [Text.Encoding]::UTF8.GetString(
        [Convert]::FromBase64String('__ARGUMENTS__')
    )

    $payload = [System.Management.Automation.PSSerializer]::Deserialize(
        $argumentXml
    )

    $commandArguments = @($payload.Arguments)

    & {
__COMMAND__
    } @commandArguments

    exit 0
}
catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
'@

        ## Replace the data placeholder first, then insert the caller's code.
        $childCommand = $childCommand.Replace(
            '__ARGUMENTS__',
            $encodedArguments
        )

        $childCommand = $childCommand.Replace(
            '__COMMAND__',
            $Command.ToString()
        )

        $encodedCommand = [Convert]::ToBase64String(
            [Text.Encoding]::Unicode.GetBytes($childCommand)
        )

        $startParameters = @{
            FilePath     = $powerShellExe
            Verb         = 'RunAs'
            ArgumentList = (
                '-NoLogo -NoProfile -EncodedCommand ' +
                $encodedCommand
            )
            PassThru     = $true
            ErrorAction  = 'Stop'
        }

        ## Preserve a normal file-system working directory when possible.
        if ($PWD.Provider.Name -eq 'FileSystem') {
            $startParameters.WorkingDirectory = $PWD.ProviderPath
        }

        if ($Wait) {
            $startParameters.Wait = $true
        }

        $process = Start-Process @startParameters

        if ($Wait) {
            $process.Refresh()

            if ($process.ExitCode -ne 0) {
                throw (
                    'Elevated PowerShell process returned exit code ' +
                    $process.ExitCode
                )
            }
        }

        return $process
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
