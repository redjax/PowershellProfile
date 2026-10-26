function Set-OutlookOOO {
    <#
        .SYNOPSIS
        Previews or configures Exchange Online automatic replies.

        .DESCRIPTION
        Reads internal and external automatic-reply messages from plain-text files and configures the selected mailbox through Exchange Online.

        By default, displays the proposed configuration without connecting to Exchange or changing mailbox settings.

        Pass -Apply to apply the configuration. Supports -WhatIf and -Confirm.

        Message files are treated as plain text, not raw HTML.

        .PARAMETER Identity
        The mailbox to configure, such as user@example.com.

        Defaults to the value supplied through -UPN.

        .PARAMETER UPN
        The user principal name used to sign in to Exchange Online.

        This can differ from Identity when the signed-in user has permission to configure another mailbox.

        .PARAMETER AutoReplyState
        Automatic-reply state: Scheduled, Enabled, or Disabled.

        Defaults to Scheduled.

        .PARAMETER StartTime
        Start of the automatic-reply schedule.

        Required when AutoReplyState is Scheduled.

        .PARAMETER EndTime
        End of the automatic-reply schedule.

        Required when AutoReplyState is Scheduled.

        When supplied, also provides the date used to replace the '[date of your return]' placeholder in the message files.

        .PARAMETER InternalMessageFile
        Plain-text file containing the internal automatic-reply message.

        Defaults to messages/internal-default.txt beside this function's source file.

        Not used when AutoReplyState is Disabled.

        .PARAMETER ExternalMessageFile
        Plain-text file containing the external automatic-reply message.

        Defaults to messages/external-default.txt beside this function's source file.

        Not used when AutoReplyState is Disabled.

        .PARAMETER Apply
        Applies the proposed configuration.

        Without this switch, only displays a preview.

        .EXAMPLE
        Set-OutlookOOO `
            -UPN 'you@example.com' `
            -StartTime '2026-11-02T08:00:00' `
            -EndTime '2026-11-06T17:00:00'

        Displays the proposed scheduled replies without applying them.

        .EXAMPLE
        Set-OutlookOOO `
            -UPN 'you@example.com' `
            -StartTime '2026-11-02T08:00:00' `
            -EndTime '2026-11-06T17:00:00' `
            -Apply `
            -WhatIf

        Displays the proposal and the intended operation without connecting to Exchange or applying changes.

        .EXAMPLE
        Set-OutlookOOO `
            -UPN 'you@example.com' `
            -StartTime '2026-11-02T08:00:00' `
            -EndTime '2026-11-06T17:00:00' `
            -InternalMessageFile './messages/internal.txt' `
            -ExternalMessageFile './messages/external.txt' `
            -Apply `
            -Confirm

        Requests confirmation before connecting and applying the replies.

        .EXAMPLE
        Set-OutlookOOO `
            -UPN 'admin@example.com' `
            -Identity 'shared@example.com' `
            -AutoReplyState Disabled `
            -Apply `
            -Confirm

        Disables automatic replies for another mailbox, subject to the signed-in user's permissions.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(
            HelpMessage = 'Mailbox to configure. Defaults to UPN.'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Identity,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'User principal name used to sign in to Exchange Online.'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $UPN,

        [Parameter(
            HelpMessage = 'Automatic-reply state.'
        )]
        [ValidateSet('Scheduled', 'Enabled', 'Disabled')]
        [string] $AutoReplyState = 'Scheduled',

        [Parameter(
            HelpMessage = 'Start date and time for scheduled replies.'
        )]
        [datetime] $StartTime,

        [Parameter(
            HelpMessage = 'End date and time for scheduled replies.'
        )]
        [datetime] $EndTime,

        [Parameter(
            HelpMessage = 'Plain-text file containing the internal reply.'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $InternalMessageFile,

        [Parameter(
            HelpMessage = 'Plain-text file containing the external reply.'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $ExternalMessageFile,

        [Parameter(
            HelpMessage = 'Apply the configuration instead of only displaying it.'
        )]
        [switch] $Apply
    )

    $ErrorActionPreference = 'Stop'

    try {
        if ([string]::IsNullOrWhiteSpace($UPN)) {
            throw 'UPN cannot be empty or whitespace.'
        }

        if (-not $PSBoundParameters.ContainsKey('Identity')) {
            $Identity = $UPN
        }

        if ([string]::IsNullOrWhiteSpace($Identity)) {
            throw 'Identity cannot be empty or whitespace.'
        }

        $hasStartTime = $PSBoundParameters.ContainsKey('StartTime')
        $hasEndTime = $PSBoundParameters.ContainsKey('EndTime')

        if ($AutoReplyState -eq 'Scheduled') {
            if (-not $hasStartTime -or -not $hasEndTime) {
                throw (
                    'StartTime and EndTime are required when ' +
                    'AutoReplyState is Scheduled.'
                )
            }

            if ($EndTime -le $StartTime) {
                throw 'EndTime must be later than StartTime.'
            }
        }

        $mailboxParameters = @{
            Identity       = $Identity
            AutoReplyState = $AutoReplyState
            ErrorAction    = 'Stop'
        }

        if ($AutoReplyState -eq 'Scheduled') {
            $mailboxParameters.StartTime = $StartTime
            $mailboxParameters.EndTime = $EndTime
        }

        if ($AutoReplyState -ne 'Disabled') {
            if (-not $InternalMessageFile) {
                $InternalMessageFile = Join-Path `
                    -Path $PSScriptRoot `
                    -ChildPath 'messages/internal-default.txt'
            }

            if (-not $ExternalMessageFile) {
                $ExternalMessageFile = Join-Path `
                    -Path $PSScriptRoot `
                    -ChildPath 'messages/external-default.txt'
            }

            if (-not (
                    Test-Path -LiteralPath $InternalMessageFile -PathType Leaf
                )) {
                throw (
                    "Internal message file does not exist: " +
                    $InternalMessageFile
                )
            }

            if (-not (
                    Test-Path -LiteralPath $ExternalMessageFile -PathType Leaf
                )) {
                throw (
                    "External message file does not exist: " +
                    $ExternalMessageFile
                )
            }

            $messageDefinitions = @(
                @{
                    Label     = 'Internal'
                    Path      = $InternalMessageFile
                    Parameter = 'InternalMessage'
                }
                @{
                    Label     = 'External'
                    Path      = $ExternalMessageFile
                    Parameter = 'ExternalMessage'
                }
            )

            $placeholder = '[date of your return]'

            foreach ($definition in $messageDefinitions) {
                $text = Get-Content `
                    -LiteralPath $definition.Path `
                    -Raw `
                    -Encoding UTF8 `
                    -ErrorAction Stop

                if ([string]::IsNullOrWhiteSpace($text)) {
                    throw (
                        "$($definition.Label) message file is empty: " +
                        $definition.Path
                    )
                }

                if ($text.Contains($placeholder)) {
                    if (-not $hasEndTime) {
                        throw (
                            "$($definition.Label) message contains " +
                            "'$placeholder', but EndTime was not supplied."
                        )
                    }

                    $text = $text.Replace(
                        $placeholder,
                        $EndTime.ToString('MM/dd/yy')
                    )
                }
                else {
                    Write-Verbose (
                        "$($definition.Label) message does not contain " +
                        "'$placeholder'."
                    )
                }

                Write-Host "`n$($definition.Label) message:" `
                    -ForegroundColor Cyan

                Write-Host $text

                ## Encode plain text before adding HTML line breaks.
                $encodedText = [System.Net.WebUtility]::HtmlEncode($text)

                $htmlBody = [regex]::Replace(
                    $encodedText,
                    '\r\n|\r|\n',
                    '<br>'
                )

                $mailboxParameters[$definition.Parameter] = (
                    '<html><body>' +
                    $htmlBody +
                    '</body></html>'
                )
            }
        }

        Write-Host "`nAutomatic-reply configuration:" `
            -ForegroundColor Cyan

        Write-Host "  Sign-in user: $UPN"
        Write-Host "  Mailbox: $Identity"
        Write-Host "  State: $AutoReplyState"

        if ($AutoReplyState -eq 'Scheduled') {
            Write-Host "  Start: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
            Write-Host "  End:   $($EndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        }

        if (-not $Apply) {
            Write-Warning (
                'Preview only. Pass -Apply to apply this configuration.'
            )

            return
        }

        $target = "mailbox '$Identity'"
        $action = "Set automatic replies to '$AutoReplyState'"

        if (-not $PSCmdlet.ShouldProcess($target, $action)) {
            return
        }

        if (-not (
                Get-Module -ListAvailable -Name ExchangeOnlineManagement
            )) {
            throw (
                'ExchangeOnlineManagement is not installed. Run: ' +
                'Install-Module -Name ExchangeOnlineManagement ' +
                '-Scope CurrentUser'
            )
        }

        Import-Module ExchangeOnlineManagement -ErrorAction Stop

        Write-Host "`nConnecting to Exchange Online..." `
            -ForegroundColor Cyan

        Connect-ExchangeOnline `
            -UserPrincipalName $UPN `
            -ShowProgress $true `
            -ErrorAction Stop

        Write-Host 'Applying automatic-reply configuration...' `
            -ForegroundColor Cyan

        Set-MailboxAutoReplyConfiguration @mailboxParameters

        Write-Host 'Automatic-reply configuration applied successfully.' `
            -ForegroundColor Green
    }
    catch {
        ## Preserve the original error and let the caller decide whether
        #  it should terminate their calling script.
        $PSCmdlet.WriteError($_)
    }
}
