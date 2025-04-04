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

This repository includes a module named [`ProfileModule`](./Modules/ProfileModule/), which is a package of custom functions, variables, & aliases I set in my scripts, effectively turning my `$PROFILE` into a module. This repository includes swappable [Powershell profiles](./Profiles/).

All Profiles load from a [common base profile](./docs/Developing.md#base-template).

**WARNING**: This script overwrites your Powershell `$PROFILE`. Make sure to take a backup of that before running any of the scripts in this repository, especially if you've done any customization previously. You can backup your current profile with: `Copy-Item -Path "$($PROFILE)" -Destination "$($PROFILE).orig"`. To restore it later, run `Copy-Item -Path "$($PROFILE).orig" -Destination "$($Profile)`.

## Table of Contents <!-- omit in toc -->

- [Usage](#usage)
- [Developing](#developing)
- [Notes](#notes)
- [Links](#links)

## Usage

- Clone the repository
- Copy [`config.example.json`](./config.example.json) to `config.json`
  - Edit the file if you want to install a profile other than [the default profile](./Profiles/Default.ps1)
- Run `Install-CustomProfile.ps1`
  - This script will:
    - Import the [`PowershellProfileSetup` module](./scripts/setup/PowershellProfileSetup/)
    - Create a backup of your existing `$PROFILE` at `$($PROFILE).bak`.
      - You may still want to copy your old `$PROFILE`, like:
        - `cp $PROFILE "$($PROFILE).orig"`
        - This will prevent accidentally nuking any customizations you've made to your `$PROFILE`
    - Update the module's [manifest file](./Modules/ProfileModule/ProfileModule.psd1), ensuring all functions & aliases are exported properly.
    - Copy the [`ProfileModule`](./Modules/ProfileModule/) directory (the custom profile module) to your Modules/ directory in the same path as your `$PROFILE`.
    - Copy/update a [custom profile](./Profiles/) (default: [`Default.ps1`](./Profiles/Default.ps1)) to your machine's `$PROFILE` location.
      - The [default custom profile](./Profiles/Default.ps1) imports the `ProfileModule`, loading all custom functions and setting the shell's session to my custom profile module.
      - To use a different profile, pass a `-ProfileName <profilename>`, where `<profilename>` is the name of a file in the [`Profiles/`](./Profiles/) directory without the `.ps1` file extension.
        - i.e. `-ProfileName Default` would use [`./Profiles/Default.ps1`](./Profiles/Default.ps1)
- Restart your shell

To see a full list of the functions exported by this module, run: `Get-Command -Module ProfileModule -Commandtype Function`.

To see a ful list of the aliases exported by this module, run: `Get-Command -Module ProfileModule -CommandType Alias`.

## Developing

*See the [Developing docs](./docs/Developing.md)*

## Notes

*See the [Notes documentation pages](./docs/Notes.md)*

## Links

*Check the [docs for useful links](./docs/Useful-Links.md)*
