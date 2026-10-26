function Get-PlatformProcesses {
    <#
        .SYNOPSIS
        Returns running process information for the local Windows computer.

        .DESCRIPTION
        Queries Win32_Process using Get-CimInstance.

        Requires Windows.

        .EXAMPLE
        Get-PlatformProcesses

        .EXAMPLE
        Get-PlatformProcesses |
            Select-Object ProcessId, Name, CommandLine
    #>

    [CmdletBinding()]
    param()

    try {
        if (
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw 'Get-PlatformProcesses is supported only on Windows.'
        }

        $properties = @(
            'ProcessId'
            'ParentProcessId'
            'Name'
            'Description'
            'CreationDate'
            'CommandLine'
            'ExecutablePath'
            'WorkingSetSize'
            'VirtualSize'
            'PageFaults'
            'PageFileUsage'
            'Priority'
            'ThreadCount'
            'HandleCount'
        )

        Get-CimInstance `
            -ClassName Win32_Process `
            -ErrorAction Stop |
        Select-Object -Property $properties
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
