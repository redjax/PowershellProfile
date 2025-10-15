# Powershell Profile  <!-- omit in toc -->

<!-- Repo image -->
<p align="center">
  <a href="https://github.com/redjax/PowershellProfile">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://assets.esecurityplanet.com/uploads/2021/05/logo-microsoft-powershell.png">
      <img src="https://assets.esecurityplanet.com/uploads/2021/05/logo-microsoft-powershell.png" height="100">
    </picture>
  </a>
</p>

<!-- Git badges -->
<p align="center">
  <a href="https://github.com/redjax/PowershellProfile">
    <img alt="Created At" src="https://img.shields.io/github/created-at/redjax/PowershellProfile">
  </a>
  <a href="https://github.com/redjax/PowershellProfile/commit">
    <img alt="Last Commit" src="https://img.shields.io/github/last-commit/redjax/PowershellProfile">
  </a>
  <a href="https://github.com/redjax/PowershellProfile/commit">
    <img alt="Commits this year" src="https://img.shields.io/github/commit-activity/y/redjax/PowershellProfile">
  </a>
  <a href="https://github.com/redjax/PowershellProfile">
    <img alt="Repo size" src="https://img.shields.io/github/repo-size/redjax/PowershellProfile">
  </a>
  <!-- ![GitHub Latest Release](https://img.shields.io/github/release-date/redjax/PowershellProfile) -->
  <!-- ![GitHub commits since latest release](https://img.shields.io/github/commits-since/redjax/PowershellProfile/latest) -->
  <!-- ![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/redjax/PowershellProfile/tests.yml) -->
</p>

My Powershell `$PROFILE` module.

[Documentation](./docs/)

**WARNING**: This script overwrites your Powershell `$PROFILE`. Make sure to take a backup of that before running any of the scripts in this repository, especially if you've done any customization previously.

You can backup your current profile with:

```powershell
Copy-Item -Path "$($PROFILE)" -Destination "$($PROFILE).orig"
```

To restore it later, run:
```powershell
Copy-Item -Path "$($PROFILE).orig" -Destination "$($Profile)"
```

## Table of Contents <!-- omit in toc -->

- [Description](#description)
- [Usage](#usage)
- [Custom Modules](#custom-modules)
  - [Remove custom modules](#remove-custom-modules)
- [Developing](#developing)
- [Notes](#notes)
- [Links](#links)

## Description

This repository includes a module named [`ProfileModule`](./Modules/ProfileModule/), which packages custom functions, variables, and aliases for use across PowerShell sessions—effectively turning `$PROFILE` into a module.

Each [custom PowerShell profile](./Profiles/) sources a [shared base template](./docs/Developing.md#base-template), which handles common setup tasks such as importing [custom modules](./Modules/Custom/), configuring environment-specific options (e.g., PS5, PS7, PowerShell ISE), and loading the [`ProfileModule`](./Modules/ProfileModule/).

Custom profiles, like the [`Starship` profile](./Profiles/Starship.ps1), build on top of this base. For example, the Starship profile automatically initializes [Starship](https://starship.rs) if it is installed.

The [`ProfileModule`](./Modules/ProfileModule/) adds helpful aliases and functions to every session it's imported into. List the imported aliases with `Show-ProfileModuleAliases` and  the functions with `Show-ProfileModuleFunctions`.

You can control which profile is installed by editing the [`config.json` file](./config.example.json). Each selected profile loads the shared base, then layers on its specific functionality.

Additionally, [custom modules](./Modules/Custom/) can be installed using the [`Install-CustomPSModules.ps1` script](./Install-CustomPSModules.ps1). These are modular and optional—just install what you need.

For example, on a work machine, you might want [Azure helpers](./Modules/Custom/AzureHelpers/) and [Active Directory helpers](./Modules/Custom/ActiveDirectoryHelpers/), but skip the [WeatherMod](./Modules/Custom/WeatherMod/), which wraps [`wttr.in`](https://wttr.in). To skip a module, simply answer `n` when prompted during installation.

## Usage

- Clone the repository
- Copy [`config.example.json`](./config.example.json) to `config.json`
  - Edit the file if you want to install a profile other than [the default profile](./Profiles/Default.ps1)
  - You can also control which [custom modules](./Modules/Custom/) are installed by editing the `custom_modules` list in the `config.json` file
    - Add only the module name, for example if you want to install the [`DatetimeHelpers` modules](./Modules/Custom/DatetimeHelpers/), just add `"DatetimeHelpers"` to the `custom_modules` list
- Install the profile
  - Automatic (scripted install)
    - Run `Install-CustomProfile.ps1`
    - This script will:
      - Import the [`PowershellProfileSetup` module](./scripts/setup/PowershellProfileSetup/)
      - Create a backup of your existing `$PROFILE` at `$($PROFILE).bak`.
        - You may still want to copy your old `$PROFILE`, like: `cp $PROFILE "$($PROFILE).orig"`. This will prevent accidentally nuking any customizations you've made to your `$PROFILE`
      - Update the module's [manifest file](./Modules/ProfileModule/ProfileModule.psd1), ensuring all functions & aliases are exported properly.
      - Copy the [shared base profile](./Profiles/_Base.ps1) to your Powershell path
      - Copy the [`ProfileModule`](./Modules/ProfileModule/) directory (the custom profile module) to your `CustomModules/` directory in the same path as your `$PROFILE`.
      - Copy/update a [custom profile](./Profiles/) (default: [`Default.ps1`](./Profiles/Default.ps1)) to your machine's `$PROFILE` location.
        - Each [custom profile](./Profiles/) imports the [`_Base.ps1` profile](./Profiles/_Base.ps1), which loads the [`ProfileModule`](./Modules/ProfileModule/) and any custom modules defined in the `config.json`'s `custom_modules` key.
        - To use a different profile, pass a `-ProfileName <profilename>`, where `<profilename>` is the name of a file in the [`Profiles/`](./Profiles/) directory without the `.ps1` file extension.
          - i.e. `-ProfileName Default` would use [`./Profiles/Default.ps1`](./Profiles/Default.ps1)
  - Manual install
    - Open your Powershell profile path (get profile path with: `split-path $PROFILE -parent`)
      - For Powershell 5, it should be `C:\Users\<your-username>\Documents\WindowsPowerShell`
      - For Powershell 7 on Windows, it should be `C:\Users\<you-username>\Documents\PowerShell`
    - Copy the [`_Base.ps1` profile](./Profiles/_Base.ps1) to your Powershell path
      - Also copy the [profile](./Profiles/) (use the [default profile](./Profiles/Default.ps1) if you are unsure).
    - (Optional) Install [custom modules](./Modules/Custom/)
      - Create a directory named `CustomModules/` in your Powershell profile path
      - Copy any custom modules you want to use into this path.

After first setup, restart your terminal by closing & reopening it, or reload it in-place by running:

```powershell
## Powershell 5
& "$PSHOME\powershell.exe" -NoExit -Command "Set-Location -Path '$PWD'"

## Powershell 7
& "$PSHOME\pwsh.exe" -NoExit -Command "Set-Location -Path '$PWD'"
```

To see a full list of the functions exported by this module, run: `Get-Command -Module ProfileModule -Commandtype Function`.

To see a full list of the aliases exported by this module, run: `Get-Command -Module ProfileModule -CommandType Alias`.

## Custom Modules

This repository includes a number of custom modules in the [Modules/Custom](./Modules/Custom/) path. These modules can add additional functionality to your `$PROFILE`. The [`_Base.ps1`](./Profiles/_Base.ps1) profile detects a folder `CustomModules/` at the `$PROFILE` path on your host; if present, it will import any modules within, adding extra functionality to your `$PROFILE`. Keeping modules in this separate `CustomModules/` directory prevents them from being auto-initialized by Powershell, allowing you to control module imports with the selected profile.

You can control which modules are installed automatically by the [`Install-CustomProfile.ps1` script](./Install-CustomProfile.ps1) by editing the `custom_modules: []` key in your [`config.json`](./config.example.json). This key is a list of module names you want to install with your profile, corresponding to a directory in the [custom modules path of this repository](./Modules/Custom/).

### Remove custom modules

Run the [`Remove-CustomModulesDir.ps1` script](./scripts/Remove-CustomModulesDir.ps1) to uninstall all custom modules. This does not affect your custom profile, only the modules in the profile path's `CustomModules/` directory.

## Developing

*See the [Developing docs](./docs/Developing.md)*

## Notes

*See the [Notes documentation pages](./docs/Notes.md)*

## Links

*Check the [docs for useful links](./docs/Useful-Links.md)*
