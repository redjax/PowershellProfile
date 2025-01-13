<#
    .SYNOPSIS
    My custom PowerShell $PROFILE.

    .DESCRIPTION
    Loads my custom ProfileModule PowerShell module. This module has various functions and aliases
    that I want to import when a PowerShell session loads with this profile.
#>

## Start profile initialization timer
$ProfileStartTime = Get-Date

## Set TLS to version 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

## Set default parameters on various commands based on Powershell version
if ($PSVersionTable.PSVersion -ge '3.0') {
    $PSDefaultParameterValues = @{
        'Format-Table:AutoSize' = $True;
        'Send-MailMessage:SmtpServer' = $SMTPserver;
        'Help:ShowWindow' = $True;
    }
    ## Prevents the ActiveDirectory module from auto creating the AD: PSDrive
    $Env:ADPS_LoadDefaultDrive = 0
}

## Alter shell based on environment
if ($host.Name -eq 'ConsoleHost') {
    if ($PSVersionTable.PSVersion -ge '3.0') {
        Import-Module -Name 'PSReadLine' -ErrorAction SilentlyContinue
        Set-PSReadLineKeyHandler -Key Enter -Function AcceptLine
        Set-PSReadLineOption -BellStyle None
    }
} elseif ($host.Name -eq 'Windows PowerShell ISE Host') {
    $host.PrivateData.IntellisenseTimeoutInSeconds = 5
    $ISEModules = 'ISEScriptingGeek','PsISEProjectExplorer'
    Import-Module -Name $ISEModules -ErrorAction SilentlyContinue
} elseif ($host.Name -eq 'Visual Studio Code Host') {
    Import-Module -Name 'EditorServicesCommandSuite' -ErrorAction SilentlyContinue
    Import-EditorCommand -Module 'EditorServicesCommandSuite' -ErrorAction SilentlyContinue
}

## Set to False by default, flip to True if ProfileModule is able to be imported.
$ProfileImported = $False
try {
    Import-Module ProfileModule
    ## Successfully imported ProfileModule, set to True
    $ProfileImported = $True
} catch {
    Write-Error "Error loading ProfileModule. Details: $($_.Exception.Message)"
}

if ($ProfileImported) {
    ## Custom profile was imported successfully.
    #  Functions & aliases are available
} else {
    ## Custom profile failed to import.
    #  Functions & aliases are not available
}

## Initialize Starship shell
if (Get-Command starship -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression (& starship init powershell)
    }
    catch {
        ## Show error when verbose logging is enabled
        #  Write-Verbose "The 'starship' command was not found. Skipping initialization." -Verbose
    }
}

## Clear the screen on fresh sessions
Clear-Host

## End profile initialization timer
$ProfileEndTime = Get-Date
## Calculate profile init time
$ProfileInitTime = $ProfileEndTime - $ProfileStartTime
## Print initialization time
Write-Output "Profile loaded in $($ProfileInitTime.TotalSeconds) second(s)."
