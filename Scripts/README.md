# DotMaster Scripts

This folder contains utility scripts used for the DotMaster addon development and maintenance.

## 🔍 Quick Start for AI Coders

When working with AI assistance, use the `dmcheck` command to validate your code and catch common errors before in-game testing:

```
# Simply type 'dmcheck' in the command prompt from the addon root folder
dmcheck
```

This command checks for:
- ⚠️ **Critical API Issues** - Including the required use of `C_Spell.GetSpellInfo()` instead of `GetSpellInfo()`
- 📄 **TOC File Verification** - Ensuring all needed files are referenced

For more advanced validation, run the individual scripts as needed.

## Scripts List

- `dmcheck.ps1` - **Main validation command** (simplified version for direct use)
- `dmcheck.bat` - Windows batch file wrapper to easily run the check command

## Usage

Scripts should be run from the addon root directory.

### Pre-Game Test Suite

The simplest way to test your addon code before in-game testing:

```
# From the command prompt (Windows)
dmcheck

# From PowerShell
./Scripts/dmcheck.ps1
```

## Important Notes for AI Coders

When working with an AI coder, remember these critical requirements:

1. **Always use `C_Spell.GetSpellInfo()` instead of `GetSpellInfo()`**
   - The global `GetSpellInfo()` function is unreliable in current WoW versions
   - Using `C_Spell.GetSpellInfo()` is required for DotMaster to function correctly
   - Remember that `C_Spell.GetSpellInfo()` returns a table with named fields, not multiple values

2. Run `dmcheck` regularly during development to catch these issues early

## Script Development Guidelines

When creating new scripts:
1. Include a descriptive header with purpose and usage instructions
2. Use consistent naming with the prefix indicating the script type
3. Keep scripts focused on a single task
4. Add the script to this README

## Requirements

- The basic API check functionality works without any external dependencies 