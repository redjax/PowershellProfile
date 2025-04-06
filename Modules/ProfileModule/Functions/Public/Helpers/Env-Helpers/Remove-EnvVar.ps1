function Remove-EnvVar {
    <#
        Remove/unset an environment variable.

        Usage:
            Remove-EnvVar -Name <name>
            Remove-EnvVar -Name <name> -Target Machine

        Params:
            Name: The name of the environment variable
            Target: The scope of the environment variable. Machine, User, or Process

        Example:
            Remove-EnvVar -Name "EXAMPLE_VAR"
            Write-Output $env:EXAMPLE_VAR
    #>
    param(
        [string]$Name,
        [ValidateSet('Machine', 'User', 'Process')]
        [string]$Target = 'User'
    )

    try {
        [System.Environment]::SetEnvironmentVariable($Name, $null, [System.EnvironmentVariableTarget]::$Target)
    }
    catch {
        Write-Error "Unhandled exception removing environment variable. Details: $($_.Exception.Message)"
    }
}