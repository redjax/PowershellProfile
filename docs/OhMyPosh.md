# Oh My Posh

[OhMyPosh](https://ohmyposh.dev) is a Go utility for enhancing Powershell prompts.

## Overview

The Oh My Posh integration follows a "snapshot" model where the installed profile is completely independent of the repository after installation.

## File Locations

### Repository (Template/Source)

These files exist in the repository and serve as templates:

```
PowershellProfile/
├── config/
│   └── ohmyposh/
│       ├── theme-name.omp.json      # Template theme (copied during install)
│       └── README.md                # Documentation
├── Profiles/
│   └── OhMyPosh.ps1                 # Profile script (copied to $PROFILE during install)
└── Modules/
    └── Setup/
        └── PowershellProfileSetup/
            ├── public/
            │   └── Invoke-OhMyPoshSetup.ps1          # Orchestrates setup
            └── internal/
                └── functions/
                    ├── Install-OhMyPosh.ps1          # Installs oh-my-posh executable
                    └── Initialize-OhMyPoshTheme.ps1  # Installs theme config
```

### Installed (Runtime/Host)

These files exist on the user's system after installation:

```
$HOME/
├── .config/
│   └── ohmyposh/
│       └── theme-name.omp.json               # INSTALLED theme (independent copy)
└── Documents/
    └── PowerShell/
        ├── Microsoft.PowerShell_profile.ps1  # The actual $PROFILE
        ├── _Base.ps1                         # Base profile functionality
        └── CustomModules/                    # Custom modules
            └── ...
```
