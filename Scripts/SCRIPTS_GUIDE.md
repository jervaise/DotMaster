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
- `file_checker.ps1` - Checks file references in TOC against actual files
- `syntax_validator.ps1` - Checks for syntax issues and GetSpellInfo API usage
- `module_validator.ps1` - Validates module initialization in loader
- `ui_check.ps1` - Validates UI component structure and initialization
- `dependency_checker.ps1` - Validates module dependencies and load order
- `event_validator.ps1` - Checks for proper event registration and handlers
- `globals_validator.ps1` - Identifies potential global variable issues
- `cleanup.ps1` - PowerShell script to remove old files after restructuring
- `cleanup_script.txt` - Documentation on the cleanup process

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

### Individual Scripts

```powershell
# Check TOC file references
./Scripts/file_checker.ps1

# Validate module initialization
./Scripts/module_validator.ps1

# Check UI components
./Scripts/ui_check.ps1

# Validate Lua syntax
./Scripts/syntax_validator.ps1

# Check module dependencies
./Scripts/dependency_checker.ps1

# Validate event handlers
./Scripts/event_validator.ps1

# Check for global variable issues
./Scripts/globals_validator.ps1
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
4. Add the script to this SCRIPTS_GUIDE.md

## Requirements

- Some validation scripts may require additional tools which are not yet fully installed
- The basic API check functionality works without any external dependencies 