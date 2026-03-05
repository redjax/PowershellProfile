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

📖 [Documentation](./docs/)

---

> [!WARNING]
> This script overwrites your Powershell `$PROFILE`. Make sure to take a backup of that
> before running any of the scripts in this repository, especially if you've done
> any customization previously.

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
- [Install](#install)
  - [Option 1: Clone the repository](#option-1-clone-the-repository)
  - [Option 2: Download a release](#option-2-download-a-release)
- [Usage](#usage)
- [Custom Modules](#custom-modules)
  - [Remove custom modules](#remove-custom-modules)
- [Developing](#developing)
- [Notes](#notes)
- [Links](#links)

## Description

My [PowerShell `$PROFILE`](./Profiles/Monolith/Monolith.ps1) is [modular](./Modules/Custom/) and [component based](./Profiles/Monolith/ProfileComponents/). It will intelligently load functionality based on what is currently installed/configured on a machine, and the options used when running [the install script](./Install-MonoProfile.ps1).

By default the profile customizes the [`$PROMPT`](./Profiles/Monolith/ProfileComponents/prompt.ps1) and adds [custom functions](./Profiles/Monolith/ProfileComponents/functions/), [aliases](./Profiles/Monolith/ProfileComponents/aliases.ps1), and handles [third-party software initialization](./Profiles/Monolith/ProfileComponents/software-init.ps1) and [shell completions](./Profiles/Monolith/ProfileComponents/shell-completions.ps1).

This profile is highly specific to my preferences and tooling. It supports [Oh-My-Posh](https://ohmyposh.dev/docs/) and [Starship](https://starship.rs) shells, and has custom [PowerShell readline handlers](./Profiles/Monolith/ProfileComponents/psreadline-handlers.ps1) to improve efficiency and make PowerShell a little more pleasant to use.

The [profiling script](./scripts/Measure-ProfileStartup.ps1) shows the initialization steps the profile takes, enabling troubleshooting when the profile takes a long time to load.

The profile starts in ~530ms on a machine with antivirus installed. It is nearly instant on machines with no antivirus. I have spent a lot of time profiling and optimizing the startup sequence for the profile so I'm not waiting at my prompt for things to finish initializing.

## Install

> [!NOTE]
> These instructions assume you are installing the [monolith profile](./Profiles/Monolith/).

### Option 1: Clone the repository

- Clone the repository with `git clone https://github.com/redjax/PowershellProfile.git` (or via SSH with `git clone git@github.com:redjax/PowershellProfile.git`)
- `cd` into the `PowershellProfile\` directory
- Run `.\Install-MonoProfile.ps1 -Prompt default -Force`
  - See usage/help menu with `Get-Help .\Install-MonoProfile.ps1 -Detailed`

### Option 2: Download a release

- Download a release from [the releases page](https://github.com/redjax/PowershellProfile/releases)
- Extract the archive somewhere on your machine
- Run the included `Install-MonoProfile.ps1` script
  - To see install script usage, run `Get-Help .\Install-MonoProfile.ps1 -Detailed`

## Usage

To see a unified list of both functions and aliases exported by this profile, run: `Show-ProfileFunctions`.

To see a full list of the functions exported by this profile, run: `Show-ProfileModuleFunctions`.

To see a full list of the aliases exported by this profile, run: `Show-ProfileModuleAliases`.

## Custom Modules

This repository includes a number of custom modules in the [Modules/Custom](./Modules/Custom/) path. These modules can add additional functionality to your `$PROFILE`, like providing [Unix-like aliases (i.e. `which` -> `where`)](./Modules/Custom/UnixAliases/), [networking utility functions](./Modules/Custom/NetworkHelpers/), and some fun ones like [a module for checking the weather](./Modules/Custom/WeatherMod/).

### Remove custom modules

Run the [`Remove-CustomModulesDir.ps1` script](./scripts/Remove-CustomModulesDir.ps1) to uninstall all custom modules. This does not affect your custom profile, only the modules in the profile path's `CustomModules/` directory.

## Developing

*See the [Developing docs](./docs/Developing.md)*

## Notes

*See the [Notes documentation pages](./docs/Notes.md)*

## Links

*Check the [docs for useful links](./docs/Useful-Links.md)*
