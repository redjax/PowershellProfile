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

        ## Import all .psm1 files directly - much faster than filtering directories first
        foreach ($moduleFile in [System.IO.Directory]::GetFiles($CustomModules, "*.psm1", [System.IO.SearchOption]::AllDirectories)) {
            try {
                $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($moduleFile)
                Write-Debug "Importing module '$moduleName' from file '$moduleFile'"
                Import-Module -Name $moduleFile -Force
                Write-Debug "Successfully imported module: $moduleName"
            }
            catch {
                Write-Error "Failed to import module: $moduleName. Details: $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Warning "Could not find custom Powershell modules directory at path: $CustomModules"
    }
}

function Get-Prompt {
    <#
        .SYNOPSIS
        Custom Powershell prompt using only built-in tools.

        .DESCRIPTION
        This is the base/default prompt. It can be overridden with oh-my-posh/starship/etc.

        When no other prompt is available, the shell will fall back to this prompt.
    #>

    ## Assign Windows Title Text
    $host.ui.RawUI.WindowTitle = "Current Folder: $pwd"

    #Configure current user, current folder and date outputs
    $CmdPromptCurrentFolder = Split-Path -Path $pwd -Leaf
    $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent();
    $Date = Get-Date -Format 'dddd hh:mm:ss tt'

    # Test for Admin / Elevated
    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    #Calculate execution time of last cmd and convert to milliseconds, seconds or minutes
    $LastCommand = Get-History -Count 1
    if ($lastCommand) { $RunTime = ($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime).TotalSeconds }

    if ($RunTime -ge 60) {
        $ts = [timespan]::fromseconds($RunTime)
        $min, $sec = ($ts.ToString("mm\:ss")).Split(":")
        $ElapsedTime = -join ($min, " min ", $sec, " sec")
    }
    else {
        $ElapsedTime = [math]::Round(($RunTime), 2)
        $ElapsedTime = -join (($ElapsedTime.ToString()), " sec")
    }

    #Decorate the CMD Prompt
    Write-Host ""
    Write-Host " PS$($PSVersionTable.PSVersion.Major) " -BackgroundColor Blue -ForegroundColor White -NoNewline
    Write-Host ($(if ($IsAdmin) { 'Elevated ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host " USER:$($CmdPromptUser.Name.split("\")[1]) " -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    if ($CmdPromptCurrentFolder -like "*:*")
    { Write-Host " $CmdPromptCurrentFolder " -ForegroundColor White -BackgroundColor DarkGray -NoNewline }
    else { Write-Host ".\$CmdPromptCurrentFolder\ " -ForegroundColor White -BackgroundColor DarkGray -NoNewline }

    Write-Host " $date " -ForegroundColor White
    Write-Host "[$elapsedTime] " -NoNewline -ForegroundColor Green
    return "> "
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

if ((Get-Command Get-Prompt -ErrorAction SilentlyContinue)) {
    function prompt {
        <#
            .SYNOPSIS
            Override the built-in Powershell prompt with the profile's custom prompt
        #>

        return Get-Prompt
    }
}
else {
    Write-Warning "No custom Get-Prompt command defined in `$PROFILE. Falling back to default Powershell prompt."
}

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
        ## Show predictions as a list (slower but more visible)
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

## Force initial prompt render BEFORE background tasks
#  This ensures your custom prompt appears immediately
[console]::Write("`r$(prompt)")

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
) | ForEach-Object {
    Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $_
} | Out-Null

## Import custom modules in background
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

## End profile initialization timer
$ProfileEndTime = Get-Date
## Calculate profile init time
$ProfileInitTime = $ProfileEndTime - $ProfileStartTime
## Print initialization time
# Write-Output "Profile loaded in $($ProfileInitTime.TotalSeconds) second(s)."
# Write-Output "Some commands may be unavailable for 1-3 seconds while background imports finish."

## Disable profile tracing
Set-PSDebug -Trace 0

