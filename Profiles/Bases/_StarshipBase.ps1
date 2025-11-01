<#
    .SYNOPSIS
    My custom PowerShell $PROFILE with Starship prompt.

    .DESCRIPTION
    Loads my custom ProfileModule PowerShell module with Starship shell prompt.

    Uses Register-EventEngine to run slower parts of scripts as background tasks, allowing prompt input
    immediately and loading things like the Starship prompt in the background.

    When background tasks finish, the next time the user hits Enter, CTRL-C, or anything else that produces
    a newline the prompt will reload.
#>

## Uncomment to enable profile tracing
# Set-PSDebug -Trace 1

## Uncomment to enable debug logging
# $DebugPreference = "Continue"

## Manually set this to $false to keep profile outputs on-screen after initializing
$ClearOnInit = $false

## Start profile initialization timer
$ProfileStartTime = Get-Date

## Use UTF-8 encoding for both input and output
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding
## Pass outputs through console to avoid converting to ASCII.
$OutputEncoding = [Console]::OutputEncoding

## Create a ManualResetEvent object for the ProfileModule import state
$Global:ProfileModuleImported = New-Object System.Threading.ManualResetEvent $false

## Set TLS to 1.2 on Powershell 5 prompts
if ($PSVersionTable.PSVersion.Major -eq 5) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

## Add custom modules directory to module path for auto-discovery
## Path structure: ~/Documents/PowerShell/Modules/Custom
$ProfileDir = Split-Path -Path $PROFILE -Parent
$CustomModulesPath = Join-Path $ProfileDir "Modules\Custom"

## Add to PSModulePath if directory exists - enables auto-discovery
if (Test-Path $CustomModulesPath) {
    $env:PSModulePath = "$CustomModulesPath;$env:PSModulePath"
}

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

## Note: Starship prompt will be initialized by the profile that sources this base
## No custom prompt defined here since Starship will override it

## Load PSReadLine SYNCHRONOUSLY for immediate terminal input
## Only defer custom handlers to background for speed
if ($host.Name -eq 'ConsoleHost') {
    if ($PSVersionTable.PSVersion -ge '3.0') {
        Import-Module -Name 'PSReadLine' -ErrorAction SilentlyContinue
        ## Basic configuration - fast enough to run synchronously
        Set-PSReadLineOption -BellStyle None
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle InlineView
    }
}
elseif ($host.Name -eq 'Windows PowerShell ISE Host') {
    $host.PrivateData.IntellisenseTimeoutInSeconds = 5
    Import-Module -Name 'ISEScriptingGeek', 'PsISEProjectExplorer' -ErrorAction SilentlyContinue
}
elseif ($host.Name -eq 'Visual Studio Code Host') {
    Import-Module -Name 'EditorServicesCommandSuite' -ErrorAction SilentlyContinue
    Import-EditorCommand -Module 'EditorServicesCommandSuite' -ErrorAction SilentlyContinue
}

## Wrap slow code to run asynchronously later
#  https://matt.kotsenas.com/posts/pwsh-profiling-async-startup
@(
    {
        try {
            Import-Module ProfileModule
            ## Signal that the module was successfully imported
            $Global:ProfileModuleImported.Set()
        }
        catch {
            Write-Error "Error loading ProfileModule. Details: $($_.Exception.Message)"
            ## Signal even if there's an error
            $Global:ProfileModuleImported.Set()
        }
    }
    {
        ## Configure PSReadLine key handlers in background
        if ($host.Name -eq 'ConsoleHost' -and $PSVersionTable.PSVersion -ge '3.0') {
            try {
                Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
                Set-PSReadLineKeyHandler -Key Enter -Function AcceptLine
            }
            catch {
                Write-Warning "Failed to configure PSReadLine key handlers: $($_.Exception.Message)"
            }
        }
    }
    {
        ## Third-party software initializations
        try {
            $SoftwareInitsPath = Join-Path (Split-Path -Path $PROFILE -Parent) "software_inits.ps1"
            if (Test-Path -Path $SoftwareInitsPath) {
                . $SoftwareInitsPath
            }
        }
        catch {
            Write-Warning "Failed to load software initializations: $($_.Exception.Message)"
        }
    }
    {
        ## 1Password shell completions
        try {
            if ( Get-Command "op" -ErrorAction SilentlyContinue ) {
                op completion powershell | Out-String | Invoke-Expression
            }
        }
        catch {
            Write-Warning "Unable to initialize 1Password shell completion. Your execution policy must be set to RemoteSigned."
        }
    }
    {
        ## Azure Developer CLI completions
        try {
            if (Get-Command azd -ErrorAction SilentlyContinue) {
                azd completion powershell | Out-String | Invoke-Expression
            }
        } 
        catch {
            Write-Warning "Failed to import azd CLI completions: $($_.Exception.Message)"
        }
    }
    {
        ## posh-git for Starship git integration
        try {
            if (Get-Module -ListAvailable -Name posh-git) {
                Import-Module posh-git -ErrorAction Stop
                Write-Verbose "posh-git module loaded."
            }
            else {
                Write-Verbose "posh-git not installed. Skipping import."
            }
        }
        catch {
            Write-Warning "Failed to import posh-git: $($_.Exception.Message)"
        }
    }
) | ForEach-Object {
    Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $_
} | Out-Null

## End profile initialization timer
$ProfileEndTime = Get-Date
## Calculate profile init time
$ProfileInitTime = $ProfileEndTime - $ProfileStartTime

## Disable profile tracing
Set-PSDebug -Trace 0

