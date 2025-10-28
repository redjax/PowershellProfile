<#
    .SYNOPSIS
    Monolithic PowerShell $PROFILE - single file with no external dependencies.

    .DESCRIPTION
    A self-contained PowerShell profile that doesn't rely on external modules or base files.
    Everything needed for the profile is in this single file.
#>

## Import namespaces so later you can just type
#  i.e. StringExpandableToken instead of System.Management.Automation.Language.StringExpandableToken
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

$ProfileStartTime = Get-Date

## Winget completions
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
	[Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
	$Local:word = $wordToComplete.Replace('"', '""')
	$Local:ast = $commandAst.ToString().Replace('"', '""')
	winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}

###########################
# PSReadline Key Handlers #
###########################

## Smart quote insertion
Set-PSReadLineKeyHandler -Key '"', "'" `
	-BriefDescription SmartInsertQuote `
	-LongDescription "Insert paired quotes if not already on a quote" `
	-ScriptBlock {
	param($key, $arg)

	$quote = $key.KeyChar

	$selectionStart = $null
	$selectionLength = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	# If text is selected, just quote it without any smarts
	if ($selectionStart -ne -1) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
		return
	}

	$ast = $null
	$tokens = $null
	$parseErrors = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

	function FindToken {
		param($tokens, $cursor)

		foreach ($token in $tokens) {
			if ($cursor -lt $token.Extent.StartOffset) { continue }
			if ($cursor -lt $token.Extent.EndOffset) {
				$result = $token
				$token = $token -as [StringExpandableToken]
				if ($token) {
					$nested = FindToken $token.NestedTokens $cursor
					if ($nested) { $result = $nested }
				}

				return $result
			}
		}
		return $null
	}

	$token = FindToken $tokens $cursor

	# If we're on or inside a **quoted** string token (so not generic), we need to be smarter
	if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
		# If we're at the start of the string, assume we're inserting a new string
		if ($token.Extent.StartOffset -eq $cursor) {
			[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote ")
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
			return
		}

		# If we're at the end of the string, move over the closing quote if present.
		if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
			return
		}
	}

	if ($null -eq $token -or
		$token.Kind -eq [TokenKind]::RParen -or $token.Kind -eq [TokenKind]::RCurly -or $token.Kind -eq [TokenKind]::RBracket) {
		if ($line[0..$cursor].Where{ $_ -eq $quote }.Count % 2 -eq 1) {
			# Odd number of quotes before the cursor, insert a single quote
			[Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
		}
		else {
			# Insert matching quotes, move cursor to be in between the quotes
			[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
		}
		return
	}

	# If cursor is at the start of a token, enclose it in quotes.
	if ($token.Extent.StartOffset -eq $cursor) {
		if ($token.Kind -eq [TokenKind]::Generic -or $token.Kind -eq [TokenKind]::Identifier -or 
			$token.Kind -eq [TokenKind]::Variable -or $token.TokenFlags.hasFlag([TokenFlags]::Keyword)) {
			$end = $token.Extent.EndOffset
			$len = $end - $cursor
			[Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.SubString($cursor, $len) + $quote)
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
			return
		}
	}

	# We failed to be smart, so just insert a single quote
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
}

## Smart brace insertion
Set-PSReadLineKeyHandler -Key '(', '{', '[' `
	-BriefDescription InsertPairedBraces `
	-LongDescription "Insert matching braces" `
	-ScriptBlock {
	param($key, $arg)

	$closeChar = switch ($key.KeyChar) {
		<#case#> '(' { [char]')'; break }
		<#case#> '{' { [char]'}'; break }
		<#case#> '[' { [char]']'; break }
	}

	$selectionStart = $null
	$selectionLength = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    
	if ($selectionStart -ne -1) {
		# Text is selected, wrap it in brackets
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
	}
 else {
		# No text is selected, insert a pair
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
	}
}

## Smart closing brace handling
Set-PSReadLineKeyHandler -Key ')', ']', '}' `
	-BriefDescription SmartCloseBraces `
	-LongDescription "Insert closing brace or skip" `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($line[$cursor] -eq $key.KeyChar) {
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
	}
	else {
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
	}
}

## Smart backspace handling
Set-PSReadLineKeyHandler -Key Backspace `
	-BriefDescription SmartBackspace `
	-LongDescription "Delete previous character or matching quotes/parens/braces" `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($cursor -gt 0) {
		$toMatch = $null
		if ($cursor -lt $line.Length) {
			switch ($line[$cursor]) {
				<#case#> '"' { $toMatch = '"'; break }
				<#case#> "'" { $toMatch = "'"; break }
				<#case#> ')' { $toMatch = '('; break }
				<#case#> ']' { $toMatch = '['; break }
				<#case#> '}' { $toMatch = '{'; break }
			}
		}

		if ($toMatch -ne $null -and $line[$cursor - 1] -eq $toMatch) {
			[Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
		}
		else {
			[Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
		}
	}
}

## Save current line in history without executing it
Set-PSReadLineKeyHandler -Key Alt+w `
	-BriefDescription SaveInHistory `
	-LongDescription "Save current line in history but do not execute" `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
	[Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
	[Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
}

## Insert text from the clipboard as a here string
Set-PSReadLineKeyHandler -Key Ctrl+V `
	-BriefDescription PasteAsHereString `
	-LongDescription "Paste the clipboard text as a here string" `
	-ScriptBlock {
	param($key, $arg)

	Add-Type -Assembly PresentationCore
	if ([System.Windows.Clipboard]::ContainsText()) {
		# Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
		$text = ([System.Windows.Clipboard]::GetText() -replace "\p{ Zs }*`r?`n", "`n").TrimEnd()
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert("@'`n$text`n'@")
	}
	else {
		[Microsoft.PowerShell.PSConsoleReadLine]::Ding()
	}
}

## Put parenthesis around the selection or entire line
Set-PSReadLineKeyHandler -Key 'Alt+(' `
	-BriefDescription ParenthesizeSelection `
	-LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
	-ScriptBlock {
	param($key, $arg)

	$selectionStart = $null
	$selectionLength = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
	if ($selectionStart -ne -1) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
	}
	else {
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
		[Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
	}
}

## Toggle quotes on the argument under the cursor with Alt+'
Set-PSReadLineKeyHandler -Key "Alt+'" `
	-BriefDescription ToggleQuoteArgument `
	-LongDescription "Toggle quotes on the argument under the cursor" `
	-ScriptBlock {
	param($key, $arg)

	$ast = $null
	$tokens = $null
	$errors = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

	$tokenToChange = $null
	foreach ($token in $tokens) {
		$extent = $token.Extent
		if ($extent.StartOffset -le $cursor -and $extent.EndOffset -ge $cursor) {
			$tokenToChange = $token

			# If the cursor is at the end (it's really 1 past the end) of the previous token,
			# we only want to change the previous token if there is no token under the cursor
			if ($extent.EndOffset -eq $cursor -and $foreach.MoveNext()) {
				$nextToken = $foreach.Current
				if ($nextToken.Extent.StartOffset -eq $cursor) {
					$tokenToChange = $nextToken
				}
			}
			break
		}
	}

	if ($tokenToChange -ne $null) {
		$extent = $tokenToChange.Extent
		$tokenText = $extent.Text
		if ($tokenText[0] -eq '"' -and $tokenText[-1] -eq '"') {
			# Switch to no quotes
			$replacement = $tokenText.Substring(1, $tokenText.Length - 2)
		}
		elseif ($tokenText[0] -eq "'" -and $tokenText[-1] -eq "'") {
			# Switch to double quotes
			$replacement = '"' + $tokenText.Substring(1, $tokenText.Length - 2) + '"'
		}
		else {
			# Add single quotes
			$replacement = "'" + $tokenText + "'"
		}

		[Microsoft.PowerShell.PSConsoleReadLine]::Replace(
			$extent.StartOffset,
			$tokenText.Length,
			$replacement)
	}
}

## Expand all aliases on the command line with Alt+%
Set-PSReadLineKeyHandler -Key "Alt+%" `
	-BriefDescription ExpandAliases `
	-LongDescription "Replace all aliases with the full command" `
	-ScriptBlock {
	param($key, $arg)

	$ast = $null
	$tokens = $null
	$errors = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

	$startAdjustment = 0
	foreach ($token in $tokens) {
		if ($token.TokenFlags -band [TokenFlags]::CommandName) {
			$alias = $ExecutionContext.InvokeCommand.GetCommand($token.Extent.Text, 'Alias')
			if ($alias -ne $null) {
				$resolvedCommand = $alias.ResolvedCommandName
				if ($resolvedCommand -ne $null) {
					$extent = $token.Extent
					$length = $extent.EndOffset - $extent.StartOffset
					[Microsoft.PowerShell.PSConsoleReadLine]::Replace(
						$extent.StartOffset + $startAdjustment,
						$length,
						$resolvedCommand)

					# Our copy of the tokens won't have been updated, so we need to
					# adjust by the difference in length
					$startAdjustment += ($resolvedCommand.Length - $length)
				}
			}
		}
	}
}

## Show help for the current command with F1
Set-PSReadLineKeyHandler -Key F1 `
	-BriefDescription CommandHelp `
	-LongDescription "Open the help window for the current command" `
	-ScriptBlock {
	param($key, $arg)

	$ast = $null
	$tokens = $null
	$errors = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

	$commandAst = $ast.FindAll( {
			$node = $args[0]
			$node -is [CommandAst] -and
			$node.Extent.StartOffset -le $cursor -and
			$node.Extent.EndOffset -ge $cursor
		}, $true) | Select-Object -Last 1

	if ($commandAst -ne $null) {
		$commandName = $commandAst.GetCommandName()
		if ($commandName -ne $null) {
			$command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
			if ($command -is [AliasInfo]) {
				$commandName = $command.ResolvedCommandName
			}

			if ($commandName -ne $null) {
				Get-Help $commandName -ShowWindow
			}
		}
	}
}

$global:PSReadLineMarks = @{}

## Mark the current directory with Ctrl+J
Set-PSReadLineKeyHandler -Key Ctrl+J `
	-BriefDescription MarkDirectory `
	-LongDescription "Mark the current directory" `
	-ScriptBlock {
	param($key, $arg)

	$key = [Console]::ReadKey($true)
	$global:PSReadLineMarks[$key.KeyChar] = $pwd
}

## Goto the marked directory with Ctrl+j
Set-PSReadLineKeyHandler -Key Ctrl+j `
	-BriefDescription JumpDirectory `
	-LongDescription "Goto the marked directory" `
	-ScriptBlock {
	param($key, $arg)
	$key = [Console]::ReadKey()
	$dir = $global:PSReadLineMarks[$key.KeyChar]
	if ($dir) {
		Set-Location $dir
		[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
	}
}

## Show the currently marked directories with Alt+j
Set-PSReadLineKeyHandler -Key Alt+j `
	-BriefDescription ShowDirectoryMarks `
	-LongDescription "Show the currently marked directories" `
	-ScriptBlock {
	param($key, $arg)

	$global:PSReadLineMarks.GetEnumerator() | ForEach-Object {
		[PSCustomObject]@{Key = $_.Key; Dir = $_.Value } } |
	Format-Table -AutoSize | Out-Host

	[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

## Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line
Set-PSReadLineKeyHandler -Key RightArrow `
	-BriefDescription ForwardCharAndAcceptNextSuggestionWord `
	-LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($cursor -lt $line.Length) {
		[Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg)
	}
 else {
		[Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
	}
}

## Select the next command argument in the command line with Alt+a
Set-PSReadLineKeyHandler -Key Alt+a `
	-BriefDescription SelectCommandArguments `
	-LongDescription "Set current selection to next command argument in the command line. Use of digit argument selects argument by position" `
	-ScriptBlock {
	param($key, $arg)
  
	$ast = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$null, [ref]$null, [ref]$cursor)
  
	$asts = $ast.FindAll( {
			$args[0] -is [System.Management.Automation.Language.ExpressionAst] -and
			$args[0].Parent -is [System.Management.Automation.Language.CommandAst] -and
			$args[0].Extent.StartOffset -ne $args[0].Parent.Extent.StartOffset
		}, $true)
  
	if ($asts.Count -eq 0) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Ding()
		return
	}
    
	$nextAst = $null

	if ($null -ne $arg) {
		$nextAst = $asts[$arg - 1]
	}
	else {
		foreach ($ast in $asts) {
			if ($ast.Extent.StartOffset -ge $cursor) {
				$nextAst = $ast
				break
			}
		} 
        
		if ($null -eq $nextAst) {
			$nextAst = $asts[0]
		}
	}

	$startOffsetAdjustment = 0
	$endOffsetAdjustment = 0

	if ($nextAst -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
		$nextAst.StringConstantType -ne [System.Management.Automation.Language.StringConstantType]::BareWord) {
		$startOffsetAdjustment = 1
		$endOffsetAdjustment = 2
	}
  
	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($nextAst.Extent.StartOffset + $startOffsetAdjustment)
	[Microsoft.PowerShell.PSConsoleReadLine]::SetMark($null, $null)
	[Microsoft.PowerShell.PSConsoleReadLine]::SelectForwardChar($null, ($nextAst.Extent.EndOffset - $nextAst.Extent.StartOffset) - $endOffsetAdjustment)
}

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

#####################
# Shell Completions #
#####################

## Azure CLI completions
try {
	if (Get-Command az -ErrorAction SilentlyContinue) {
		# Use Azure CLI's native PowerShell completion (much faster than argcomplete)
		if (Test-Path "$env:USERPROFILE\.azure\az.completion.ps1") {
			. "$env:USERPROFILE\.azure\az.completion.ps1"
			Write-Verbose "Azure CLI completions loaded (native method)."
		}
		else {
			# Generate the completion file if it doesn't exist
			Write-Verbose "Generating Azure CLI completion file..."
			az completion --shell powershell | Out-File -FilePath "$env:USERPROFILE\.azure\az.completion.ps1" -Encoding utf8
			. "$env:USERPROFILE\.azure\az.completion.ps1"
		}
	}
	else {
		Write-Verbose "Azure CLI is not installed. Skipping completions."
	}
}
catch {
	Write-Warning "Failed to load Azure CLI completions: $($_.Exception.Message)"
}

## Azure Developer CLI completions
try {
	if (Get-Command azd -ErrorAction SilentlyContinue) {
		azd completion powershell | Out-String | Invoke-Expression
		Write-Host "Imported azd CLI completions." -ForegroundColor Green
	}
 else {
		Write-Verbose "azd CLI is not installed. Skipping import."
	}
}
catch {
	Write-Warning "Failed to import azd CLI completions: $($_.Exception.Message)"
}

###########
# Aliases #
###########

## Unix-like 'ls'
Remove-Item Alias:ls
function Enable-TerminalIcons {
	if (-not (Get-Module Terminal-Icons)) {
		Import-Module Terminal-Icons -ErrorAction SilentlyContinue
	}
}

function ls {
	Enable-TerminalIcons
	Get-ChildItem @args
}

## Unix-like 'dir'
Remove-Item Alias:dir
function dir {
	Enable-TerminalIcons
	Get-ChildItem @args
}

## Unix-like 'll' (long listing)
Function ll { Get-ChildItem -Force | Format-List }
Set-Alias pwd Get-Location

## Unix-like 'touch'
Function touch { param($f); New-Item -ItemType File -Path $f -Force }

## File Viewing and Editing
Set-Alias cat Get-Content
Function tac { param($f); $c = Get-Content $f; [array]::Reverse($c); $c }
Function tail { param($f); Get-Content -Tail 10 -Path $f }
Function tailf { param($f); Get-Content -Wait -Path $f }
Function head { param($f, $n = 10); Get-Content $f | Select-Object -First $n }

## System/Process
Set-Alias ps Get-Process
Set-Alias kill Stop-Process
Set-Alias clear Clear-Host
Set-Alias history Get-History

## File Management
Set-Alias rm Remove-Item
Set-Alias mv Move-Item
Set-Alias man Get-Help

## End profile initialization timer
$ProfileEndTime = Get-Date
## Calculate profile init time
$ProfileInitTime = $ProfileEndTime - $ProfileStartTime
## Print initialization time
Write-Output "$($ProfileInitTime.TotalSeconds)s"

###########################
# Software Initialization #
###########################

# IntelliShell
$env:INTELLI_HOME = "$env:APPDATA\IntelliShell\Intelli-Shell\data"
# $env:INTELLI_SEARCH_HOTKEY = 'Ctrl+Spacebar'
# $env:INTELLI_VARIABLE_HOTKEY = 'Ctrl+l'
# $env:INTELLI_BOOKMARK_HOTKEY = 'Ctrl+b'
# $env:INTELLI_FIX_HOTKEY = 'Ctrl+x'
# Set-Alias -Name 'is' -Value 'intelli-shell'
intelli-shell.exe init powershell | Out-String | Invoke-Expression
