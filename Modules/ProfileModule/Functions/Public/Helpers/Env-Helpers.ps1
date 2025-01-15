function Set-EnvVar {
    <#
        Set an environment variable. If -Target Machine or -Target User, the env variable will persist between sessions.

        Usage:
            Set-EnvVar -Name <name> -Value <value>
            Set-EnvVar -Name <name> -Value <value> -Target Machine
        
        Params:
            Name: The name of the environment variable
            Value: The value of the environment variable
            Target: The scope of the environment variable. Machine, User, or Process

        Example:
            Set-EnvVar -Name "EXAMPLE_VAR" -Value "example value"
            Write-Output $env:EXAMPLE_VAR
    #>
    param(
        [string]$Name,
        [string]$Value,
        [ValidateSet('Machine','User','Process')]
        [string]$Target = 'User'
    )

    Write-Output "Setting [$Target] environment variable " $Name"."

    if ($Target -eq 'Process') {
        Write-Warning "Environment variable [$Target] will not persist between sessions."
    }
    else {
        Write-Information "Environment variable [$Target] will persist between sessions."
    }

    try {
        [System.Environment]::SetEnvironmentVariable($Name,$Value,[System.EnvironmentVariableTarget]::$Target)
    }
    catch {
        Write-Error "Unhandled exception setting environment variable. Details: $($_.Exception.Message)"
    }
}

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
        [ValidateSet('Machine','User','Process')]
        [string]$Target = 'User'
    )

    try {
        [System.Environment]::SetEnvironmentVariable($Name,$null,[System.EnvironmentVariableTarget]::$Target)
    }
    catch {
        Write-Error "Unhandled exception removing environment variable. Details: $($_.Exception.Message)"
    }
}
