# Developing <!-- omit in toc -->

These docs are for adding new features/modules/profiles to this repository.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Base template](#base-template)
- [Add new functions and aliases](#add-new-functions-and-aliases)
- [Update the manifest](#update-the-manifest)
- [Linting and analyzing](#linting-and-analyzing)

## ToDo <!-- omit in toc -->

- [ ] Add functionality for copying to all `$PROFILE` paths
  - [ ] `$PROFILE.AllUsersAllHosts`
    - Affects all users and all hosts (e.g., PowerShell, VS Code integrated terminal). 
  - [ ] `$PROFILE.AllUsersCurrentHost`
    - Affects all users but only for the current host application (e.g., `powershell.exe`, `pwsh.exe`, or a specific editor). 
  - [ ] `$PROFILE.CurrentUserAllHosts`
    - Affects only the current user but applies to all host applications.
  - [ ] `$PROFILE.CurrentUserCurrentHost`
    - Affects only the current user and the current host application.

## Base template

Powershell profiles in the [Profiles/](../Profiles/) path all load from a common [`_Base.ps1`](../Profiles/_Base.ps1). Any code placed in `_Base.ps1` will be available to a profile that "sources" the base profile:

```powershell
$BaseProfile = "$($PSScriptRoot)\_Base.ps1"

If ( -Not ( Test-Path -Path "$($BaseProfile)" ) ) {
    Write-Warning "Could not find base profile '$($BaseProfile)'."
} else {
  . "$($BaseProfile)"
}
```

To load the base profile asynchronously (allow for immediate command execution, run custom profile imports in the background, re-initialize shell when the next command is executed), 

```powershell
$BaseProfile = "$($PSScriptRoot)\_Base.ps1"

If ( -Not ( Test-Path -Path "$($BaseProfile)" ) ) {
    Write-Warning "Could not find base profile '$($BaseProfile)'."
}
else {
    ## Load from common _Base.ps1
    #  Wrap slow code to run asynchronously later
    #  https://matt.kotsenas.com/posts/pwsh-profiling-async-startup
    @(
        {
            . "$($BaseProfile)"
        }
    ) | ForEach-Object {
        Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $_
    } | Out-Null
}
```

Keep the base template minimal. This template loads my custom [`ProfileModule`](../Modules/ProfileModule/), with all of the functions & aliases & module imports, before initializing the rest of the Powershell profile. For an example of what this looks like, check the [`Default.ps1` profile](../Profiles/Default.ps1).

## Add new functions and aliases

To add new functions to the module, consider if the function is meant to be used internally in the module (functions & aliases you do not need/want to expose to the user), or exported to the session.

If the script/file is meant to be accessible only from within the module, create the file in [`Functions/Private`](./Modules/ProfileModule/Functions/Private/).

If you are writing a custom function or setting an alias meant to be accessible by the user when this module is imported, the file belongs in [`Functions/Public`](./Modules/ProfileModule/Functions/Public/). These files are sourced by the [module's `.psm1` file](./Modules/ProfileModule/ProfileModule.psm1), and exported with the module.

If you are setting an alias, i.e. `Set-Alias -Name tn -Value Test-NetConnection`, edit the [`Aliases.ps1`](./Modules/ProfileModule/Aliases.ps1) file.

You can see all exported functions & aliases by using `Get-Module ProfileModule` after installing it.

## Update the manifest

Each time you run [`Install-CustomProfile.ps1`](./Install-CustomProfile.ps1), the module's [manifest](./Modules/ProfileModule/ProfileModule.psd1) file is updated automatically. The script scans the `ProfileModule`'s `Functions/` directory and `Aliases.ps1` file, exporting any public functions & aliases and updating the `FunctionsToExport=@()` and `AliasesToExport=@()` arrays in the manifest.

The script also installs the module and custom profile. If you just want to update the manifest, you can run the [`Update-ProfileModuleManifest.ps1`](./scripts/Update-ProfileModuleManifest.ps1) script.

## Linting and analyzing

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
