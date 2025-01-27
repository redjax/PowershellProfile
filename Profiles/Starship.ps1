<#
    .SYNOPSIS
    My custom PowerShell $PROFILE.

    .DESCRIPTION
    Loads my custom ProfileModule PowerShell module. This module has various functions and aliases
    that I want to import when a PowerShell session loads with this profile.

    Includes the Starship prompt.
#>

## Uncomment to enable profile tracing
# Set-PSDebug -Trace 1

## Manually set this to $false to keep profile outputs on-screen after initializing
$ClearOnInit = $true

## Start profile initialization timer
$ProfileStartTime = Get-Date

## Create a ManualResetEvent object for the ProfileModule import state
$Global:ProfileModuleImported = New-Object System.Threading.ManualResetEvent $false

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

## Wrap slow code to run asynchronously later
#  https://matt.kotsenas.com/posts/pwsh-profiling-async-startup
@(
    {
        ## Alter shell based on environment
        if ( $host.Name -eq 'ConsoleHost' ) {
            ## Powershell console/Windows Terminal

            if ( $PSVersionTable.PSVersion -ge '3.0' ) {
                ## Import PSReadLine interactive terminal
                Import-Module -Name 'PSReadLine' -ErrorAction SilentlyContinue
                ## Set keyboard key for accepting suggestions
                Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
                ## Set Enter to its normal/expected behavior
                Set-PSReadLineKeyHandler -Key Enter -Function AcceptLine
                ## Disable audio bells
                Set-PSReadLineOption -BellStyle None
            }
        }
        ElseIf ( $host.Name -eq 'Windows PowerShell ISE Host' ) {
            ## Powershell ISE
            $host.PrivateData.IntellisenseTimeoutInSeconds = 5
            ## Import ISE modules for more interactive sessions
            $ISEModules = 'ISEScriptingGeek', 'PsISEProjectExplorer'
            Import-Module -Name $ISEModules -ErrorAction SilentlyContinue
        }
        ElseIf ( $host.Name -eq 'Visual Studio Code Host' ) {
            ## Load VSCode modules for Powershell for debugging & other integrations
            Import-Module -Name 'EditorServicesCommandSuite' -ErrorAction SilentlyContinue
            Import-EditorCommand -Module 'EditorServicesCommandSuite' -ErrorAction SilentlyContinue
        }
    },
    {
        try {
            Import-Module ProfileModule
            ## Indicate to the script that the ProfileModule was imported successfully
            $Global:ProfileModuleImported = $true
            ## Signal that the module was successfully imported
            $Global:ProfileModuleImported.Set()

            ## reload -> Restart-Shell
            Set-Alias -Name reload -Value Restart-Shell
        }
        catch {
            Write-Error "Error loading ProfileModule. Details: $($_.Exception.Message)"
            ## Signal even if there's an error
            $Global:ProfileModuleImported.Set()
        }
    },
    {
        ## Initialize Starship shell
        if (Get-Command starship -ErrorAction SilentlyContinue) {
            Invoke-Expression (& starship init powershell)
        }
    }
) | ForEach-Object {
    Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $_
} | Out-Null

if ($ClearOnInit) {
    Clear-Host
}

## End profile initialization timer
$ProfileEndTime = Get-Date
## Calculate profile init time
$ProfileInitTime = $ProfileEndTime - $ProfileStartTime
## Print initialization time
Write-Output "Profile loaded in $($ProfileInitTime.TotalSeconds) second(s)."

## Disable profile tracing
Set-PSDebug -Trace 0
