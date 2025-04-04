# Current File Structure - DotMaster v1.0.1

This document provides an overview of all files in the DotMaster addon and their purpose.

## Active Files (v1.0.1)

### Core Files
1. **bootstrap.lua** - Initial addon setup and core variable initialization
2. **core.lua** - Main addon functionality, event handling
3. **settings.lua** - Settings management, SavedVariables handling
4. **utils.lua** - General utility functions
5. **minimap.lua** - Minimap icon functionality
6. **gui_debug.lua** - Debug console implementation

### Database Files
7. **spell_database.lua** - Default spell database and management
8. **spell_utils.lua** - Spell utility functions
9. **combinations_db.lua** - DoT combinations database and functions

### GUI Files
10. **gui.lua** - Core GUI functions
11. **gui_common.lua** - Shared GUI components
12. **gui_general_tab.lua** - General tab interface
13. **gui_tracked_spells_tab.lua** - Tracked spells tab interface
14. **gui_combinations_tab.lua** - Dot combinations tab interface
15. **gui_database_tab.lua** - Database management tab interface
16. **gui_colorpicker.lua** - Color picker functionality
17. **gui_spell_row.lua** - Spell list row component
18. **gui_spell_selection.lua** - Spell selection interface

### Nameplate Files
19. **nameplate_core.lua** - Core nameplate functionality
20. **nameplate_detection.lua** - Nameplate detection and tracking
21. **nameplate_coloring.lua** - Nameplate color manipulation

### Feature Files
22. **find_my_dots.lua** - Implementation of "Find My Dots" feature
23. **minimap.lua** - Minimap button functionality

### Asset Files
24. **Media/dotmaster-icon.tga** - Addon icon
25. **Media/dotmaster-main-icon.tga** - Main interface icon

### Library Files (in Libs/ directory)
26. **LibStub** - Library management
27. **CallbackHandler-1.0** - Event handling
28. **LibDataBroker-1.1** - Data broker functionality
29. **LibDBIcon-1.0** - Minimap icon support

### Documentation Files (in Docs/ directory)
30. **CHANGELOG.md** - Version changelog
31. **CODE_STRUCTURE.md** - Code organization overview
32. **CURRENT_FILES.md** - This file
33. **CURRENT_STATUS.md** - Development status
34. **DEBUG_SYSTEM.md** - Debug system documentation
35. **DEVELOPER_GUIDE.md** - Guide for developers
36. **PROJECT_SCOPE.md** - Project scope and goals

## Changed in v0.5.1
- Restructured documentation to be more user-friendly
- Added a new Docs/DOCUMENTATION_GUIDE.md file to guide developers through documentation
- Enhanced and consolidated information in the main README.md
- Updated version references in all documentation files

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
- CHANGELOG.md
- CODE_STRUCTURE.md
- CURRENT_FILES.md
- CURRENT_STATUS.md
- CRITICAL_API_NOTES.md
- DEVELOPMENT_PROCESS.md
- GUI_TROUBLESHOOTING.md
- MISSING_LIBRARIES.md
- PROJECT_SCOPE.md
- README.md (new in v0.5.1)
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
│   ├── RESTRUCTURING_SUMMARY.md
│   ├── FILE_RENAMING.md
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