## Manually set this to $false to keep profile outputs on-screen after initializing
$ClearOnInit = $true

## Uncomment to enable profile tracing during load
# Set-PSDebug -Trace 1

## Start profile initialization timer
$ProfileStartTime = Get-Date

## Create a ManualResetEvent object for the ProfileModule import state
$Global:ProfileModuleImported = New-Object System.Threading.ManualResetEvent $false

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
    },
    {
        
        try {
            Import-Module ProfileModule
            ## Indicate to the script that the ProfileModule was imported successfully
            $Global:ProfileImported = $true
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
            try {
                Invoke-Expression (& starship init powershell)
            }
            catch {
                ## Show error when verbose logging is enabled
                #  Write-Verbose "The 'starship' command was not found. Skipping initialization." -Verbose
            }
        }
    }
) | ForEach-Object {
    Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $_ 
} | Out-Null

If ( $ClearOnInit ) {
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
