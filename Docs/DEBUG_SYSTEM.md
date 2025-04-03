# DotMaster Debug System Guide

## Quick Reference

- `/dmdebug` - Toggle the debug console window
- `/dmdebug category <name> [on|off]` - Enable/disable debug categories
- `/dmdebug status` - Show current debug status
- `/dmdebug help` - Show debug command help

## Debug Categories

- `general`: General messages (purple)
- `spell`: Spell-related messages (pink)
- `nameplate`: Nameplate-related messages (blue)
- `gui`: UI-related messages (gold) 
- `performance`: Performance measurements (green)
- `database`: Database operations (orange)

## Debug Functions

```lua
-- Use these functions for all debugging:
DM:DebugMsg("message")         -- General messages
DM:SpellDebug("message")       -- Spell-related
DM:NameplateDebug("message")   -- Nameplate-related
DM:GUIDebug("message")         -- UI-related 
DM:PerformanceDebug("message") -- Performance-related
DM:DatabaseDebug("message")    -- Database-related

-- Format strings are supported:
DM:DatabaseDebug("Spell %d (%s) tracked status: %d", spellID, spellName, tracked)
```

## Debug Console Features

The debug console window provides:

- Category checkboxes to enable/disable specific categories
- Button to view initialization messages
- Button to clear the console
- Button to export messages
- Option to send debug output to chat

## Development Workflow with Debug System

1. **Plan Debug Points**: Identify key places to add debug messages
2. **Add Debug Messages**: Add debug statements before and after key operations
3. **Open Debug Console**: Use `/dmdebug` to open the console
4. **Enable Categories**: Enable only the categories you need
5. **Perform Action**: Trigger the action in-game
6. **Check Console**: Review the debug output to verify behavior
7. **Fix Issues**: Make changes based on debug information

## Example: Debugging Database Changes

```lua
-- Before changing data
DM:DatabaseDebug("Before updating spell %d:", spellID)
DM:DatabaseDebug("  name: %s", DM.dmspellsdb[spellID].spellname)
DM:DatabaseDebug("  tracked: %d", DM.dmspellsdb[spellID].tracked)

-- Make the change
DM.dmspellsdb[spellID].tracked = 1

-- After changing data
DM:DatabaseDebug("After updating spell %d:", spellID)
DM:DatabaseDebug("  tracked: %d", DM.dmspellsdb[spellID].tracked)
```

## Example: Debugging UI Operations

```lua
-- Before creating row
DM:GUIDebug("Creating row for spell %d at y-offset %d", spellID, yOffset)

-- After creating row
DM:GUIDebug("Row created, width: %d, visible: %s", 
  row:GetWidth(), 
  tostring(row:IsVisible())
)
```

## Best Practices

1. **Use the Right Category**: Choose the appropriate debug category for your message
2. **Be Specific**: Include relevant IDs, names, and values in your messages
3. **Before/After**: Add messages before and after operations to track changes
4. **Format Properly**: Use string formatting for clean, readable output
5. **Check State**: Add messages that verify current state of important variables
6. **Performance**: Add timing messages for performance-critical sections

## Adding Custom Debug Commands

You can add temporary debug commands to help with specific tasks:

```lua
-- Example: Add a command to show tracked spells
SLASH_DMLISTTRACKED1 = "/dmtracked"
SlashCmdList["DMLISTTRACKED"] = function()
  DM:DatabaseDebug("Listing all tracked spells:")
  local count = 0
  
  for id, data in pairs(DM.dmspellsdb) do
    if data.tracked == 1 then
      DM:DatabaseDebug("  %s: %s", id, data.spellname or "Unknown")
      count = count + 1
    end
  end
  
  DM:DatabaseDebug("Total tracked spells: %d", count)
end
``` 