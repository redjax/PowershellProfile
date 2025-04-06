# ProfileModule

This module is part of the PowerShell monorepo.

## Installation

```powershell
Import-Module (Join-Path $(PSScriptRoot) ProfileModule.psm1)
```

## Description

My custom Powershell `$PROFILE` module. Importing this module into your Powershell session adds custom [functions](./Functions/Public/) and [aliases](./Aliases/) to the session.

Some functionality has been split into [custom modules](../Custom/) to allow for more modular imports.
