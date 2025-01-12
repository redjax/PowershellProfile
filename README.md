# Powershell Profile  <!-- omit in toc -->

My Powershell `$PROFILE` module.

This repository includes a module named [`ProfileModule`](./ProfileModule/), which is a package of custom functions, variables, & aliases I set in my scripts, effectively turning my `$PROFILE` into a module. This repository includes swappable [Powershell profiles](./Profiles/).

**WARNING**: This script overwrites your Powershell `$PROFILE`. Make sure to take a backup of that before running any of the scripts in this repository, especially if you've done any customization previously. You can backup your current profile with: `Copy-Item -Path "$($PROFILE)" -Destination "$($PROFILE).orig"`.

## Table of Contents <!-- omit in toc -->

- [Usage](#usage)
- [Developing](#developing)
  - [Add new functions and aliases](#add-new-functions-and-aliases)
  - [Update the manifest](#update-the-manifest)
  - [Linting \& analyzing](#linting--analyzing)
- [Notes](#notes)
  - [Automatic updates to module's manifest](#automatic-updates-to-modules-manifest)
  - [Generate profile GUID](#generate-profile-guid)
  - [Pass -Verbose and -Debug to other scripts](#pass--verbose-and--debug-to-other-scripts)
- [Links](#links)

## Usage

- Clone the repository
- Run `Install-CustomProfile.ps1`
  - This script will:
    - create a backup of your existing `$PROFILE` at `$($PROFILE).bak`.
      - You may still want to copy your old `$PROFILE`, like:
        - `cp $PROFILE "$($PROFILE).orig"`
        - This will prevent accidentally nuking any customizations you've made to your `$PROFILE`
    - Update the module's [manifest file](./ProfileModule/ProfileModule.psd1), ensuring all functions & aliases are exported properly.
    - Copy the [`ProfileModule`](./ProfileModule/) directory (the custom profile module) to your Modules/ directory in the same path as your `$PROFILE`.
    - Copy/update a [custom profile](./Profiles/) (default: [`DefaultProfile.ps1`](./Profiles/DefaultProfile.ps1)) to your machine's `$PROFILE` location.
      - The [default custom profile](./Profiles/DefaultProfile.ps1) imports the `ProfileModule`, loading all custom functions and setting the shell's session to my custom profile module.
      - To use a different profile, pass a `-ProfileName <profilename>`, where `<profilename>` is the name of a file in the [`Profiles/`](./Profiles/) directory without the `.ps1` file extension.
        - i.e. `-ProfileName DefaultProfile` would use [`./Profiles/DefaultProfile.ps1`](./Profiles/DefaultProfile.ps1)
- Restart your shell

To see a full list of the functions exported by this module, run: `Get-Command -Module ProfileModule -Commandtype Function`.

To see a ful list of the aliases exported by this module, run: `Get-Command -Module ProfileModule -CommandType Alias`.

## Developing

### Add new functions and aliases

To add new functions to the module, consider if the function is meant to be used internally in the module (functions & aliases you do not need/want to expose to the user), or exported to the session.

If the script/file is meant to be accessible only from within the module, create the file in [`Functions/Private`](./ProfileModule/Functions/Private/).

If you are writing a custom function or setting an alias meant to be accessible by the user when this module is imported, the file belongs in [`Functions/Public`](./ProfileModule/Functions/Public/). These files are sourced by the [module's `.psm1` file](./ProfileModule/ProfileModule.psm1), and exported with the module.

If you are setting an alias, i.e. `Set-Alias -Name tn -Value Test-NetConnection`, edit the [`Aliases.ps1`](./ProfileModule/Aliases.ps1) file.

You can see all exported functions & aliases by using `Get-Module ProfileModule` after installing it.

### Update the manifest

Each time you run [`Install-CustomProfile.ps1`](./Install-CustomProfile.ps1), the module's [manifest](./ProfileModule/ProfileModule.psd1) file is updated automatically. The script scans the `ProfileModule`'s `Functions/` directory and `Aliases.ps1` file, exporting any public functions & aliases and updating the `FunctionsToExport=@()` and `AliasesToExport=@()` arrays in the manifest.

The script also installs the module and custom profile. If you just want to update the manifest, you can run the [`Update-ProfileModuleManifest.ps1`](./scripts/Update-ProfileModuleManifest.ps1) script.

### Linting & analyzing

Using the [`PSScriptAnalyzer`](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview?view=ps-modules) module can help write cleaner, more maintainable scripts.

To install the tool for the current user, run:

```powershell
Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -AllowClobber
```

To install for all users, run this in an elevated/admin prompt:

```powershell
Install-Module PSScriptAnalyzer -Force -Scope AllUsers -AllowClobber
```

Call the analyzer with `Invoke-ScriptAnalyzer -Path path/to/script.ps1` to analyze a specific script. Call `Invoke-ScriptAnalyzer` without a path to start an interactive prompt.

You can also provide a directory with `-Path`, and pass the `-Recurse` parameter, to scan all `.ps1` files in a given path.

## Notes

### Automatic updates to module's manifest

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

### Generate profile GUID

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

### Pass -Verbose and -Debug to other scripts

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

## Links

- [VirtualizationHowTo.com: PSScriptAnalyzer the ultimate Powershell script analyzer & linter](https://www.virtualizationhowto.com/2024/03/psscriptanalyzer-the-ultimate-powershell-script-analyzer-and-linter/)
- [SumTips: Powershell Beautifier free tool to prettify `.ps1` scripts](https://sumtips.com/software/powershell-beautifier-free-tool-to-pretty-print-ps1-script-files/)
- [Powershell Magazine](https://powershellmagazine.com)
- [Microsoft Learn: Using PSScriptAnalyzer](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules)
- [Microsoft Learn: Invoke-ScriptAnalyzer](https://learn.microsoft.com/en-us/powershell/module/psscriptanalyzer/invoke-scriptanalyzer?view=ps-modules)
- [PowershellIsFun.com: Using PSScriptAnalyzer to optimize your Powershell scripts](https://powershellisfun.com/2022/10/17/using-psscriptanalyzer-to-optimize-your-powershell-scripts/)
