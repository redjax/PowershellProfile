<#
    .SYNOPSIS
    My custom PowerShell $PROFILE.

    .DESCRIPTION
    Loads my custom ProfileModule PowerShell module. This module has various functions and aliases
    that I want to import when a PowerShell session loads with this profile.

    Uses Register-EventEngine to run slower parts of scripts as background tasks, allowing prompt input
    immediately and loading things like the Starship prompt in the background.

    When background tasks finish, the next time the user hits Enter, CTRL-C, or anything else that produces
    a newline the prompt will reload.
#>

## Uncomment to enable profile tracing
# Set-PSDebug -Trace 1

## Manually set this to $false to keep profile outputs on-screen after initializing
$ClearOnInit = $false

## Start profile initialization timer
$ProfileStartTime = Get-Date

## Create a ManualResetEvent object for the ProfileModule import state
$Global:ProfileModuleImported = New-Object System.Threading.ManualResetEvent $false

## Set default parameters on various commands based on Powershell version
if ($PSVersionTable.PSVersion -ge '3.0') {
    $PSDefaultParameterValues = @{
        'Format-Table:AutoSize'       = $True;
        'Send-MailMessage:SmtpServer' = $SMTPserver;
        'Help:ShowWindow'             = $True;
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
Write-Output "Some commands may be unavailable for 1-3 seconds while background imports finish."

## Disable profile tracing
Set-PSDebug -Trace 0
