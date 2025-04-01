# Current File Structure - DotMaster v0.4.1

This document tracks the current file structure of the DotMaster addon. It is updated with each version to serve as a reference for developers.

## Active Files (v0.4.1)

### Core System (`dm_` prefix)
- **dm_core.lua** - Main initialization and core addon functionality
- **dm_debug.lua** - Debug and logging system
- **dm_utils.lua** - Utility functions used throughout the addon
- **dm_settings.lua** - Settings management and database operations
- **dm_loader.lua** - Final initialization sequence (loaded last)

### Nameplate System (`np_` prefix)
- **np_core.lua** - Core nameplate functionality
- **np_detection.lua** - Nameplate detection and tracking
- **np_coloring.lua** - Nameplate coloring and visual effects

### Spell System (`sp_` prefix)
- **sp_database.lua** - Spell database and management
- **sp_utils.lua** - Spell-specific utility functions

### User Interface (`ui_` prefix and `gui_` prefix)
- **ui_main.lua** - Main UI framework (replaced ui_core.lua)
- **ui_tabs.lua** - Tab handling for the UI
- **ui_components.lua** - Common UI components (replaced ui_common.lua)
- **ui_general_tab.lua** - General settings panel
- **ui_spells_tab.lua** - Spells configuration panel
- **gui_colorpicker.lua** - Color picker component
- **gui_spell_selection.lua** - Spell selection dialog
- **gui_spell_row.lua** - Spell row UI component
- **ui_minimap.lua** - Minimap button and related functionality

### Find My Dots Feature (`fmd_` prefix)
- **fmd_core.lua** - Find My Dots feature implementation

### Support Files
- **embeds.xml** - Library embedding file
- **DotMaster.toc** - Table of Contents file for WoW

## Old Files Pending Removal
The following files from previous versions have been replaced but may still be in the repository:

- **init.lua** - Replaced by dm_core.lua
- **core.lua** - Replaced by dm_loader.lua
- **utils.lua** - Replaced by dm_utils.lua
- **settings.lua** - Replaced by dm_settings.lua
- **nameplate_core.lua** - Replaced by np_core.lua
- **nameplate_detection.lua** - Replaced by np_detection.lua 
- **nameplate_coloring.lua** - Replaced by np_coloring.lua
- **spell_database.lua** - Replaced by sp_database.lua
- **spell_utils.lua** - Replaced by sp_utils.lua
- **find_my_dots.lua** - Replaced by fmd_core.lua
- **gui.lua** - Replaced by ui_main.lua
- **gui_colorpicker.lua** - Replaced by gui_colorpicker.lua
- **gui_common.lua** - Replaced by ui_components.lua
- **gui_general_tab.lua** - Replaced by ui_general_tab.lua
- **gui_spells_tab.lua** - Replaced by ui_spells_tab.lua
- **gui_spell_selection.lua** - Replaced by gui_spell_selection.lua
- **gui_spell_row.lua** - Replaced by gui_spell_row.lua
- **ui_spells.lua** - Replaced by ui_spells_tab.lua

## Restructuring Status
The file renaming process based on rename_plan.md is partially complete. Issues remaining:

1. Several old files are still present in the repository
2. The TOC file has been updated to reference new files
3. Some file renames deviated from the original plan (using gui_ prefix for some UI components)

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
│   ├── MISSING_LIBRARIES.md
│   ├── PROJECT_SCOPE.md
│   ├── README.md
│   └── PatchNotes/
│       ├── v0.1.1.md
│       ├── v0.3.0.md
│       └── v0.4.0.md
├── Libs/
│   └── (Library files)
├── Media/
│   └── (Media files)
├── dm_core.lua
├── dm_debug.lua
├── dm_loader.lua
├── dm_settings.lua
├── dm_utils.lua
├── DotMaster.toc
├── embeds.xml
├── fmd_core.lua
├── gui_colorpicker.lua
├── gui_spell_row.lua
├── gui_spell_selection.lua
├── np_coloring.lua
├── np_core.lua
├── np_detection.lua
├── rename_plan.md
├── sp_database.lua
├── sp_utils.lua
├── ui_components.lua
├── ui_general_tab.lua
├── ui_main.lua
├── ui_minimap.lua
├── ui_spells_tab.lua
└── ui_tabs.lua
```

## Recommended Actions

1. Remove all old files that have been replaced
2. Ensure module initialization code properly references the new file names
3. Update CODE_STRUCTURE.md to reflect the actual naming convention
4. Verify all references to modules use the correct names
``` 