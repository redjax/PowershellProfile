# Notes <!-- omit in toc -->

Things I've learned building this repository.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Check Powershell version](#check-powershell-version)
  - [Use Powershell version as a conditional](#use-powershell-version-as-a-conditional)
- [Automatic updates to module's manifest](#automatic-updates-to-modules-manifest)
- [Generate profile GUID](#generate-profile-guid)
- [Pass -Verbose and -Debug to other scripts](#pass--verbose-and--debug-to-other-scripts)

## Check Powershell version

You can use the `$PSVersionTable.PSVersion` variable to get the current shell's version. Below are examples of what you will see when you run this command:

Powershell 5:

```powershell
$ $PSVersionTable.PSVersion

Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      26100  2161
```

Powershell 7:

```powershell
$PSVersionTable.PSVersion

Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
7      5      0
```

You can also select only the major/minor version:

```powershell
## Select the major version
$PSVersionTable.PSVersion.Major.ToString()

## Select the minor version:
$PSVersionTable.PSVersion.Minor.ToString()
```

Or get the whole version as a string:

```powershell
$PSVersionTable.PSVersion.ToString()
```

### Use Powershell version as a conditional

You can use the Powershell version's major (or major/minor) release string in a conditional statement. To write a conditional check using the shell's version, use:

```powershell
## Store Powershell major and minor versions in variables
$PowershellMajorVersion = $PSVersionTable.PSVersion.Major.ToString()
$PowershellMinorVersion = $PSVersionTable.PSVersion.Minor.ToString()

## Check if Powershell major version is 7
if ( $PowershellMajorVersion -eq "7" ) {
    ## Do something when shell is Powershell 7/Core
    ...
} elseif ( $PowershellMajorVersion -eq "5" ) {
    ## Do something when shell is Powershell 5
    ...
}
```

An example of when you might want to conditionally check the shell's version is when setting TLS with `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12`. This step is unnecessary on Powershell 7, and will slow the shell down. To ensure this command only runs on Powershell 5:

```powershell
## Set TLS to 1.2 on Powershell 5 prompts
if ($PSVersionTable.PSVersion.Major -eq 5) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
```

## Automatic updates to module's manifest

In your module's `<module-name>.psm1` file, you can scan the module's functions & aliases and automatically export them when the module is imported. Paste this into a `.psm1` module entrypoint:

```powershell
## Set directory separator character, i.e. '\' on Windows
$DirectorySeparator = [System.IO.Path]::DirectorySeparatorChar

## Set name of module from $PSScriptRoot
$ModuleName = $PSScriptRoot.Split($DirectorySeparator)[-1]

## Define paths to public and private function directories
$PublicFunctionsPath = $PSScriptRoot + $DirectorySeparator + 'Functions' + $DirectorySeparator + 'Public' + $DirectorySeparator
$PrivateFunctionsPath = $PSScriptRoot + $DirectorySeparator + 'Functions' + $DirectorySeparator + 'Private' + $DirectorySeparator

## Path to Aliases.ps1
$AliasesFilePath = $PSScriptRoot + $DirectorySeparator + 'Aliases.ps1'

## Regular expression to match function definitions
$functionRegex = 'function\s+([^\s{]+)\s*\{'

## Get list of .ps1 files in Public/ recursively
$PublicFunctions = Get-ChildItem -Path $PublicFunctionsPath -Recurse -Filter *.ps1

## Get list of .ps1 files in Private/ recursively
$PrivateFunctions = Get-ChildItem -Path $PrivateFunctionsPath -Recurse -Filter *.ps1

## Load all private/internal PowerShell functions from script files
$PrivateFunctions | ForEach-Object { 
    . $_.FullName 
}

$PublicFunctions | ForEach-Object { 
    . $_.FullName 
}

## Gather function names from each script in the Public folder
$PublicFunctionNames = @()

foreach ($script in $PublicFunctions) {
    $scriptContent = Get-Content -Path $script.FullName -Raw
    $SearchMatches = [regex]::Matches($scriptContent, $functionRegex)
    
    foreach ($match in $SearchMatches) {
        $functionName = $match.Groups[1].Value
        $PublicFunctionNames += $functionName
    }
}

## Export each public function individually
$PublicFunctionNames | ForEach-Object {
    Export-ModuleMember -Function $_
}

## Source the Aliases.ps1 file if it exists
if (Test-Path -Path $AliasesFilePath) {
    . $AliasesFilePath

    ## Export aliases after sourcing the Aliases.ps1
    $Aliases = Get-Command -CommandType Alias | Where-Object { $_.Source -eq $ModuleName }

    $Aliases | ForEach-Object {
        Export-ModuleMember -Alias $_.Name
    }
}

```

## Generate profile GUID

Each Powershell module requires a unique GUID. You can generate a GUID with:

```powershell
[guid]::NewGuid()
```

If you have a script to update your module automatically, you can use this function to generate & save a GUID to a file in the module, or load from that file if it exists.

```powershell
## Generate GUID if it doesn't exist
if ( -Not ( Test-Path -Path $GUIDFilePath ) ) {
    Write-Debug "GUID file '$($GUIDFilePath)' does not exist. Generating GUID and saving to file."
    $guid = [guid]::NewGuid().ToString()
    Set-Content -Path $GUIDFilePath -Value $guid
} else {
    Write-Debug "Loading GUID from file: $($GUIDFilePath)"
    $guid = Get-Content -Path $GUIDFilePath
}
```

## Pass -Verbose and -Debug to other scripts

When calling a script from within a script that receives `-Debug` and/or `-Verbose` switch params, you pass them a bit differently.

For example, `script1.ps1` calls `script2.ps1`. Both scripts accept a `[switch]$Debug` and `[switch]$Verbose` parameter. To pass the values of `$Debug` and `$Verbose` to `script2.ps1`, use:

```powershell
## script1.ps1
Param(
  [switch]$Verbose,
  [switch]$Debug
)

If ( $Debug ) {
  $DebugPreference = "Continue"
}

If ( $Verbose ) {
  $VerbosePreference = "Continue"
}

& .\script2.ps1 -Verbose:$Verbose -Debug:$Debug
```

Passing switches as parameters uses this syntax: `-SwitchParam:$SwitchParam`.