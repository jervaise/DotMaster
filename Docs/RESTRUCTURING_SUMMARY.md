# DotMaster File Restructuring Summary

## Overview
This document summarizes the file restructuring effort for DotMaster v0.4.1. The restructuring involved renaming files to follow a consistent prefix-based naming convention and removing obsolete files.

## Restructuring Actions Completed

### 1. Files Renamed
The following files were renamed according to the restructuring plan:

| Old Filename | New Filename |
|-------------|-------------|
| init.lua | dm_core.lua |
| core.lua | dm_loader.lua |
| utils.lua | dm_utils.lua |
| settings.lua | dm_settings.lua |
| nameplate_core.lua | np_core.lua |
| nameplate_detection.lua | np_detection.lua |
| nameplate_coloring.lua | np_coloring.lua |
| spell_database.lua | sp_database.lua |
| spell_utils.lua | sp_utils.lua |
| find_my_dots.lua | fmd_core.lua |
| gui.lua | ui_main.lua |
| gui_common.lua | ui_components.lua |
| gui_general_tab.lua | ui_general_tab.lua |
| gui_spells_tab.lua | ui_spells_tab.lua |

### 2. New Naming Convention
Files are now organized using a prefix-based system:
- `dm_`: Core addon functionality
- `np_`: Nameplate-related functionality
- `sp_`: Spell-related functionality
- `ui_`: User interface framework
- `gui_`: Specialized UI components (some UI files retained this prefix)
- `fmd_`: Find My Dots feature

### 3. Updated References
- All module references in the code were updated to match the new naming convention
- TOC file was updated to reference the correct files
- Module initialization code in dm_loader.lua was updated to use the new module names

### 4. Files Removed
The following old files were removed as they were replaced by the new prefixed files:
- init.lua
- core.lua
- utils.lua
- settings.lua
- nameplate_core.lua
- nameplate_detection.lua
- nameplate_coloring.lua
- spell_database.lua
- spell_utils.lua
- gui.lua
- gui_common.lua
- gui_general_tab.lua
- gui_spells_tab.lua
- find_my_dots.lua
- ui_spells.lua

### 5. Documentation Updated
- Updated CODE_STRUCTURE.md to reflect the new file organization
- Created CURRENT_FILES.md to track the current file structure
- Added pre-testing verification requirements to README.md
- Added file structure management requirements to DEVELOPMENT_PROCESS.md

## Potential Issues to Watch For
After completing the restructuring, be aware of the following potential issues:

1. Module initialization - If any modules fail to initialize, check that their names in dm_loader.lua match the actual module names exposed by each file
2. Inline code references - Some code may still reference old file names in comments or documentation
3. Saved variables - If saved variables use names from the old structure, they might need to be migrated

## Version Update
The version number was updated to 0.4.1 in:
- DotMaster.toc
- dm_core.lua (both VERSION and defaults.version)

## Testing Instructions
After restructuring, perform the following tests:
1. Open the addon in-game
2. Verify all UI components load correctly
3. Test the Find My Dots functionality
4. Verify nameplates color correctly when debuffs are applied
5. Check that the minimap button works

## Next Steps
For future updates:
1. Continue maintaining a consistent naming convention
2. Update CURRENT_FILES.md with any new files
3. Check for old file references when making changes
4. Remove any remaining references to old file names that are found 