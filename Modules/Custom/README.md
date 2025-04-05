# Custom Powershell Modules

Modules in this path enhance the [`_Base.ps1` Powershell profile](../../Profiles/_Base.ps1). Any modules installed to your host's `CustomModules/` directory in the `$PROFILE` path will be sourced by the base profile and added to your session.

Use the [`Install-CustomPSModules.ps1` script](../../Install-CustomPSModules.ps1) to be offered a list of modules from this path to install. This script ensures a clean transfer of modules to the host's `CustomModules` directory.

## Removing Custom Modules

To find where your custom modules are installed, run this:

```powershell
Join-Path -Path ( Split-Path $PROFILE -Parent ) -ChildPath "CustomModules"
```

You can remove individual files by deleting them from this path and reloading your session.

To remove all installed custom modules, run the [`Remove-CustomModulesDir.ps1` script](../../scripts/Remove-CustomModulesDir.ps1). This will delete the `CustomModules/` directory from your Powershell `$PROFILE` path, removing all installed custom modules.
