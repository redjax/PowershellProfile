# Developing <!-- omit in toc -->

These docs are for adding new features/modules/profiles to this repository.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Base template](#base-template)
- [Add new functions and aliases](#add-new-functions-and-aliases)
- [Add a new custom module](#add-a-new-custom-module)
- [Update the manifest](#update-the-manifest)
- [Linting and analyzing](#linting-and-analyzing)

## Base template

Powershell profiles in the [Profiles/](../Profiles/) path all load from a common [`_Base.ps1`](../Profiles/_Base.ps1). Any code placed in `_Base.ps1` will be available to a profile that "sources" the base profile:

```powershell
$BaseProfile = "$($PSScriptRoot)\_Base.ps1"

If ( -Not ( Test-Path -Path "$($BaseProfile)" ) ) {
    Write-Warning "Could not find base profile '$($BaseProfile)'."
} else {
  ## Source base profile
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

Keep the base template minimal. This template loads the [`ProfileModule`](../Modules/ProfileModule/) before initializing the rest of the Powershell profile. For an example of what this looks like, check the [`Default.ps1` profile](../Profiles/Default.ps1).

## Add new functions and aliases

Before adding to the `ProfileModule`, consider if the new code warrants a custom module. If you are adding simple scripts, or aliases/functions you want to have available in every profile, you can add directly to the `ProfileModule`. For 3rd party applications (like [Bitwarden](../Modules/Custom/BitwardenHelpers/) or [the Azure CLI](../Modules/Custom/AzureHelpers/)), it is usually best to [create a new custom module](#add-a-new-custom-module) and keep the code contained to a module. Your profile can be modular this way, importing only the modules you need for programs you have installed, by editing the `custom_modules: []` key of [your config](../config.example.json).

---

To add new functions to the module, consider if the function is meant to be used internally in the module (functions & aliases you do not need/want to expose to the user), or exported to the session & made available to the user.

If the script/file is meant to be accessible only from within the module, create the file in [`Functions/Private`](./Modules/ProfileModule/Functions/Private/).

If you are writing a custom function or setting an alias meant to be accessible by the user when this module is imported, the file belongs in [`Functions/Public`](./Modules/ProfileModule/Functions/Public/). These files are sourced by the [module's `.psm1` file](./Modules/ProfileModule/ProfileModule.psm1), and exported with the module.

You can use subdirectories in the `Public` and `Private` directories to keep code together based on logical groupings; the [manifest script](../Modules/ProfileModule/ProfileModule.psm1) sources these paths recursively.

If you are setting an alias, i.e. `Set-Alias -Name tn -Value Test-NetConnection`, edit the [`Aliases.ps1`](./Modules/ProfileModule/Aliases.ps1) file.

You can see all exported functions & aliases by using `Get-Module ProfileModule` after installing it (or the `Show-ProfileModuleFunctions`/`Show-ProfileModuleAliases` functions imported by the `ProfileModule`).

## Add a new custom module

Run the [`New-ModuleTemplate.ps1` script](../scripts/New-ModuleTemplate.ps1), which standardizes module creation. You can pass a module name with the `-Name` param, but if you run the script without any parameters, you will be prompted for a name & description. The script then calls the [`Invoke-PSMDTemplate` function](https://psframework.org/documentation/commands/PSModuleDevelopment/Invoke-PSMDTemplate.html) to generate scaffolding for your new module. `Invoke-PSMDTemplate` is part of the [`PowerShell Framework` project](https://psframework.org).

Find your new module in the [`Modules/Custom` path](../Modules/Custom/). Use the `readme.md` files in each path to learn more about the structure of a module created with `Invoke-PSMDTemplate`. Generally, the structure of a new module can be understood as:

| Module Path           | Purpose                                                                                                                                                                                                                                                                                                                                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `internal/functions/` | Functions placed in this path (or subdirectories in this path) are available to other functions in the same module, but are not exported to the user. This path is useful for internal helper functions like elevating a command prompt or testing if a path exists & taking an action. Functions in this path are not exported to the user, but can be used accross sub-modules/paths in the same module. |
| `internal/scripts/`   | Scripts or code blocks that serve an internal purpose, like initialization scripts or setup routines.                                                                                                                                                                                                                                                                                                      |
| `private/`            | Similar to the `internal/` path, except they are not intended for broader use and are not avaiable to sub-components/submodules.                                                                                                                                                                                                                                                                           |
| `public/`             | Code in this path will be exported to the user. Functions defined here are available to sessions where the module is imported, as are variables & aliases. The `Show-ProfileModuleFunctions` command will detect all imported custom modules and show the functions they provide to the current session.                                                                                                   |

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
