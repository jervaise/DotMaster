# DotMaster Scripts

This folder contains utility scripts used for the DotMaster addon development and maintenance.

## Scripts List

- `cleanup.ps1` - PowerShell script to remove old files after restructuring
- `cleanup_script.txt` - Documentation on the cleanup process
- `file_checker.ps1` - Checks file references in TOC against actual files
- `module_validator.ps1` - Validates module initialization in loader

## Usage

Scripts should be run from the addon root directory.

### PowerShell Scripts
```powershell
# Clean up old files after restructuring
./Scripts/cleanup.ps1

# Check TOC file references
./Scripts/file_checker.ps1

# Validate module initialization
./Scripts/module_validator.ps1
```

## Script Development Guidelines

When creating new scripts:
1. Include a descriptive header with purpose and usage instructions
2. Use consistent naming with the prefix indicating the script type
3. Keep scripts focused on a single task
4. Add the script to this README 