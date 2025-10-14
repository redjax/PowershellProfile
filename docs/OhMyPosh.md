# Oh My Posh Integration - Repository Structure

I've reorganized the Oh My Posh setup to fit your repository's structure properly.

## ✅ Correct Structure

```
PowershellProfile/
├── config/
│   └── ohmyposh/
│       ├── README.md          # Documentation
│       └── theme.omp.json     # Your Oh My Posh theme
├── Profiles/
│   └── OhMyPosh.ps1          # Profile script (becomes $PROFILE)
└── config.json               # Set "profile": { "name": "OhMyPosh" }
```

## How It Works

1. **`Profiles/OhMyPosh.ps1`** - Simple profile script that:
   - Loads your `_Base.ps1` (so all modules/functions work)
   - Initializes Oh My Posh with theme from `config/ohmyposh/theme.omp.json`
   - No setup code, no configuration files - just the profile

2. **`config/ohmyposh/`** - Configuration directory:
   - `theme.omp.json` - Your customizable theme (version controlled)
   - `README.md` - Documentation on usage and customization

3. **Your workflow stays the same**:
   ```powershell
   # Edit config.json to set profile
   { "profile": { "name": "OhMyPosh" } }
   
   # Install profile as always
   .\Install-CustomProfile.ps1
   
   # Done!
   ```

## Why This Structure?

- **`Profiles/`** = PowerShell scripts that become `$PROFILE`
- **`config/`** = Configuration files for tools (theme files, settings, etc.)
- **`Modules/`** = Your custom PowerShell modules
- **`docs/`** = General documentation
- **`scripts/`** = Utility/helper scripts

This matches how you'd typically store:
- Starship config: `config/starship/starship.toml` (if you had one)
- Tool configs: `config/<tool>/...`

## Quick Start

1. **Install Oh My Posh**:
   ```powershell
   winget install JanDeDobbeleer.OhMyPosh
   oh-my-posh font install
   ```

2. **Configure terminal to use Nerd Font**

3. **Set profile**:
   ```json
   // config.json
   { "profile": { "name": "OhMyPosh" } }
   ```

4. **Install**:
   ```powershell
   .\Install-CustomProfile.ps1
   ```

5. **Restart terminal**

## Customizing

Edit `config/ohmyposh/theme.omp.json` and commit changes to your repo!

Test themes live:
```powershell
oh-my-posh init pwsh --config .\config\ohmyposh\theme.omp.json | Invoke-Expression
```

---

**The key difference from before**: Configuration and documentation go in `config/ohmyposh/`, NOT in `Profiles/`. The `Profiles/` directory is only for the actual PowerShell profile scripts.
