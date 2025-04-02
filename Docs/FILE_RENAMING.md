# File Rename Plan

## Original Files to New Names

| Original File | New File |
|--------------|----------|
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
| gui.lua | ui_core.lua |
| gui_colorpicker.lua | ui_colorpicker.lua |
| gui_common.lua | ui_common.lua |
| gui_general_tab.lua | ui_general.lua |
| gui_spells_tab.lua | ui_spells.lua |
| gui_spell_selection.lua | ui_spell_selection.lua |
| gui_spell_row.lua | ui_spell_row.lua |

## New Files to Create

| New File | Purpose |
|----------|---------|
| dm_debug.lua | Debug and logging module |

## Implementation Steps

1. Create the new files first (dm_core.lua, dm_debug.lua, etc.)
2. Update the .toc file to reference the new files
3. Commit the changes with a message about the restructuring
4. Test in-game to ensure everything works correctly
5. Remove the old files once everything is working

## Documentation Updates

1. Add CODE_STRUCTURE.md to explain the new organization
2. Update README.md to reference the new structure document
3. Update CHANGELOG.md with details about the restructuring 