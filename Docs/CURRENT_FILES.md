# Current File Structure - DotMaster v0.5.0

This document tracks the current file structure of the DotMaster addon. It is updated with each version to serve as a reference for developers.

## Active Files (v0.5.0)

### Core Files
- **init.lua** - Main initialization
- **utils.lua** - Utility functions
- **settings.lua** - Settings management
- **core.lua** - Final initialization sequence

### Spell System
- **spell_database.lua** - Spell database and management
- **spell_utils.lua** - Spell-specific utility functions

### Nameplate System
- **nameplate_core.lua** - Core nameplate functionality
- **nameplate_detection.lua** - Nameplate detection and tracking
- **nameplate_coloring.lua** - Nameplate coloring and visual effects

### User Interface
- **gui.lua** - Main UI framework
- **gui_common.lua** - Common UI components
- **gui_colorpicker.lua** - Color picker component
- **gui_general_tab.lua** - General settings panel
- **gui_spells_tab.lua** - Spells configuration panel
- **gui_spell_row.lua** - Spell row UI component
- **gui_spell_selection.lua** - Spell selection dialog

### Find My Dots Feature
- **find_my_dots.lua** - Find My Dots feature implementation

### Support Files
- **embeds.xml** - Library embedding file
- **DotMaster.toc** - Table of Contents file for WoW
- **dmcheck.bat** - Validation utility launcher

## Changed in v0.5.0
The file structure has been reverted to the v0.4.0 structure for stability, while preserving the Scripts directory and all documentation from later versions.

### Preserved from Later Versions

#### Scripts Directory
- **dmcheck.ps1** - Main validation command
- **file_checker.ps1** - Checks file references in TOC against actual files
- **syntax_validator.ps1** - Checks for syntax issues and GetSpellInfo API usage
- **module_validator.ps1** - Validates module initialization in loader
- **simple_check.ps1** - Simplified validation
- **cleanup.ps1** - PowerShell script to remove old files after restructuring
- **cleanup_script.txt** - Documentation on the cleanup process
- **README.md** - Documentation for scripts

#### Documentation
All documentation files in the Docs directory have been preserved, including:
- README.md
- CHANGELOG.md
- CODE_STRUCTURE.md
- CURRENT_FILES.md
- CURRENT_STATUS.md
- CRITICAL_API_NOTES.md
- DEVELOPMENT_PROCESS.md
- GUI_TROUBLESHOOTING.md
- MISSING_LIBRARIES.md
- PROJECT_SCOPE.md
- All patch notes

## Removed Files from v0.4.1/v0.4.2
The following files from the prefix-based restructuring have been removed in favor of the original v0.4.0 structure:

- **dm_core.lua** - Replaced by init.lua
- **dm_debug.lua** - Functionality in core files
- **dm_loader.lua** - Replaced by core.lua
- **dm_settings.lua** - Replaced by settings.lua
- **dm_utils.lua** - Replaced by utils.lua
- **fmd_core.lua** - Replaced by find_my_dots.lua
- **fmd_ui.lua** - UI functionality in find_my_dots.lua
- **np_coloring.lua** - Replaced by nameplate_coloring.lua
- **np_core.lua** - Replaced by nameplate_core.lua
- **np_detection.lua** - Replaced by nameplate_detection.lua
- **sp_database.lua** - Replaced by spell_database.lua
- **sp_utils.lua** - Replaced by spell_utils.lua
- **ui_components.lua** - Replaced by gui_common.lua
- **ui_general_tab.lua** - Replaced by gui_general_tab.lua
- **ui_main.lua** - Replaced by gui.lua
- **ui_minimap.lua** - Minimap functionality in gui.lua
- **ui_spells_tab.lua** - Replaced by gui_spells_tab.lua
- **ui_tabs.lua** - Tab functionality in gui.lua

## File Structure Diagram
```
DotMaster/
├── .git/
├── .vscode/
├── Docs/
│   ├── CHANGELOG.md
│   ├── CODE_STRUCTURE.md
│   ├── CRITICAL_API_NOTES.md
│   ├── CURRENT_FILES.md
│   ├── CURRENT_STATUS.md
│   ├── DEVELOPMENT_PROCESS.md
│   ├── DEVELOPMENT_ROADMAP.md
│   ├── GUI_TROUBLESHOOTING.md
│   ├── MISSING_LIBRARIES.md
│   ├── PROJECT_SCOPE.md
│   ├── README.md
│   ├── RESTRUCTURING_SUMMARY.md
│   ├── rename_plan.md
│   └── PatchNotes/
│       ├── v0.1.1.md
│       ├── v0.3.0.md
│       ├── v0.4.0.md
│       └── v0.5.0.md
├── Libs/
│   ├── CallbackHandler-1.0/
│   ├── LibDBIcon-1.0/
│   ├── LibDataBroker-1.1/
│   └── LibStub/
├── Media/
├── Scripts/
│   ├── README.md
│   ├── cleanup.ps1
│   ├── cleanup_script.txt
│   ├── dmcheck.ps1
│   ├── file_checker.ps1
│   ├── module_validator.ps1
│   ├── simple_check.ps1
│   └── syntax_validator.ps1
├── core.lua
├── dmcheck.bat
├── DotMaster.toc
├── embeds.xml
├── find_my_dots.lua
├── gui.lua
├── gui_colorpicker.lua
├── gui_common.lua
├── gui_general_tab.lua
├── gui_spell_row.lua
├── gui_spell_selection.lua
├── gui_spells_tab.lua
├── init.lua
├── nameplate_coloring.lua
├── nameplate_core.lua
├── nameplate_detection.lua
├── settings.lua
├── spell_database.lua
├── spell_utils.lua
└── utils.lua
```

## Recommended Actions

1. Test the restored file structure in-game to verify functionality
2. Review for any missing files from the v0.4.0 restore
3. Plan for carefully reintroducing critical API updates from v0.4.2
4. Ensure all scripts and validation tools work with the restored file structure
``` 