# CRITICAL API NOTES

## IMPORTANT: GetSpellInfo vs C_Spell.GetSpellInfo

⚠️ **CRITICAL API REQUIREMENT** ⚠️

> **ALWAYS use `C_Spell.GetSpellInfo()` instead of the global `GetSpellInfo()` function.**

The global `GetSpellInfo()` function has become unreliable in current WoW versions and may fail to return information for many spells, particularly those not directly available to the player's current class/spec. This issue critically impacts DotMaster's ability to:

1. Display spell names and icons for DoTs from other classes
2. Track DoTs on nameplates
3. Show information in the configuration UI

### Correct Usage:

```lua
-- INCORRECT - Do not use:
local name, _, icon = GetSpellInfo(spellID)

-- CORRECT - Always use:
local spellInfo = C_Spell.GetSpellInfo(spellID)
local name = spellInfo and spellInfo.name
local icon = spellInfo and spellInfo.iconFileID
```

### Current Issues in Codebase:

The codebase currently uses `GetSpellInfo()` in multiple files:
- spell_utils.lua
- gui_spell_selection.lua
- gui_spell_row.lua
- gui_spells_tab.lua
- find_my_dots.lua

These must all be updated to use `C_Spell.GetSpellInfo()` before the next release.

### Implementation Note:

When transitioning from `GetSpellInfo()` to `C_Spell.GetSpellInfo()`, be aware of the different return structure:

- `GetSpellInfo(spellID)` returns multiple values directly (name, rank, icon, etc.)
- `C_Spell.GetSpellInfo(spellID)` returns a table with named fields (name, iconFileID, etc.)

This requires changing not only the function call but also how the return values are handled.

Any code written for DotMaster MUST follow this guideline without exception. 