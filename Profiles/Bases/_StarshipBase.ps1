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
## Create  a ManualResetEvent object for the CustomModules import state
$Global:CustomModulesImported = New-Object System.Threading.ManualResetEvent $false

## Set TLS to 1.2 on Powershell 5 prompts
if ($PSVersionTable.PSVersion.Major -eq 5) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

## Path to Powershell profile's CustomModules
$CustomModulesPath = ( Join-Path -Path ( Split-Path -Path $PROFILE -Parent ) -ChildPath "CustomModules" )

function Import-CustomPSModules {
    <#
        .SYNOPSIS
        Import custom Powershell modules from a directory.

        .DESCRIPTION
        Import custom Powershell modules from a directory.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Path to repository's Modules directory")]
        $CustomModules = $CustomModulesPath
    )


    ## Import custom modules
    if ( Test-Path -Path $CustomModules ) {
        Write-Debug "Importing custom Powershell modules from path: $($CustomModules)"

        ## Find all custom modules
        $ModuleDirectories = Get-ChildItem -Path $CustomModules -Directory | Where-Object {
            Test-Path (Join-Path -Path $_.FullName -ChildPath "*.psm1")
        }

        ## Import custom modules
        foreach ($ModuleDir in $ModuleDirectories) {
            $ModuleName = $ModuleDir.Name
            $ModuleFile = Get-ChildItem -Path $ModuleDir.FullName -Filter "*.psm1" | Select-Object -First 1

            if ($ModuleFile) {
                try {
                    Write-Debug "Importing module '$($ModuleName)' from file '$($ModuleFile.FullName)'"
                    Import-Module -Name $ModuleFile.FullName -Force
                    Write-Debug "Successfully imported module: $($ModuleName)"
                }
                catch {
                    Write-Error "Failed to import module: $($ModuleName). Details: $($_.Exception.Message)"
                }
            }
            else {
                Write-Warning "No .psm1 file found in directory: $($ModuleDir.FullName)"
            }
        }
    }
    else {
        Write-Warning "Could not find custom Powershell modules directory at path: $CustomModules"
    }
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

## Alter shell based on environment
if ($host.Name -eq 'ConsoleHost') {
    ## Powershell console/Windows Terminal

    if ($PSVersionTable.PSVersion -ge '3.0') {
        ## Import PSReadLine interactive terminal
        Import-Module -Name 'PSReadLine' -ErrorAction SilentlyContinue
        ## Set keyboard key for accepting suggestions
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        ## Set Enter to its normal/expected behavior
        Set-PSReadLineKeyHandler -Key Enter -Function AcceptLine
        ## Disable audio bells
        Set-PSReadLineOption -BellStyle None
        ## Enable command prediction
        Set-PSReadLineOption -PredictionSource History
        ## Show predictions as a list
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
}
elseif ($host.Name -eq 'Windows PowerShell ISE Host') {
    ## Powershell ISE
    $host.PrivateData.IntellisenseTimeoutInSeconds = 5
    ## Import ISE modules for more interactive sessions
    $ISEModules = 'ISEScriptingGeek', 'PsISEProjectExplorer'
    Import-Module -Name $ISEModules -ErrorAction SilentlyContinue
}
elseif ($host.Name -eq 'Visual Studio Code Host') {
    ## Load VSCode modules for Powershell for debugging & other integrations
    Import-Module -Name 'EditorServicesCommandSuite' -ErrorAction SilentlyContinue
    Import-EditorCommand -Module 'EditorServicesCommandSuite' -ErrorAction SilentlyContinue
}

## Wrap slow code to run asynchronously later
#  https://matt.kotsenas.com/posts/pwsh-profiling-async-startup
@(
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
    }
) | ForEach-Object {
    Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $_
} | Out-Null

## Shell completions

if ( Get-Command "op" -ErrorAction SilentlyContinue ) {
    try {
        op completion powershell | Out-String | Invoke-Expression
    }
    catch {
        Write-Warning "Unable to initialize 1Password shell completion. Your execution policy must be set to RemoteSigned."
    }
}

## Import custom modules
if ( Test-Path -Path $CustomModulesPath -ErrorAction SilentlyContinue ) {

    @(
        {
            try {
                # Import all custom modules from the CustomModules directory
                Get-ChildItem -Path $CustomModulesPath -Directory | ForEach-Object {
                    try {
                        Import-Module -Name $_.FullName -Global -ErrorAction Stop
                        Write-Output "Successfully imported module: $($_.Name)"
                    }
                    catch {
                        Write-Warning "Failed to import module: $($_.Name). Details: $($_.Exception.Message)"
                    }
                }

                ## Signal successful import
                $Global:CustomModulesImported = $true
                $Global:CustomModulesImported.Set()
            }
            catch {
                Write-Error "Error loading custom modules from path: $CustomModulesPath. Details: $($_.Exception.Message)"
                ## Signal even if there's an error
                $Global:CustomModulesImported.Set()
            }
        }
    ) | ForEach-Object {
        Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $_
    } | Out-Null
}

## Source completions in the background
@(
    {
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
    },
    {
        try {
            if (Get-Command azd -ErrorAction SilentlyContinue) {
                azd completion powershell | Out-String | Invoke-Expression
            } else {
                Write-Verbose "azd CLI is not installed. Skipping import."
            }
        } catch {
            Write-Warning "Failed to import azd CLI completions: $($_.Exception.Message)"
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

