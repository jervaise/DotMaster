# DotMaster Code Structure

This document outlines the modular structure of the DotMaster addon codebase. The addon has been organized into a prefix-based file structure for improved development and debugging.

## File Naming Conventions

Files are named using a prefix that indicates their functional area:

- `dm_` - Core addon functionality
- `np_` - Nameplate-related functionality
- `sp_` - Spell-related functionality
- `ui_` - User interface components
- `fmd_` - Find My Dots feature

## Module Organization

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

### User Interface (`ui_` prefix)

- **ui_core.lua** - Main UI framework
- **ui_colorpicker.lua** - Color picker component
- **ui_common.lua** - Common UI elements and functions
- **ui_general.lua** - General settings panel
- **ui_spells.lua** - Spells configuration panel
- **ui_spell_selection.lua** - Spell selection dialog
- **ui_spell_row.lua** - Spell row UI component

### Find My Dots Feature (`fmd_` prefix)

- **fmd_core.lua** - Find My Dots feature implementation

## Module Pattern

Each file follows a consistent module pattern:

```lua
--[[
  DotMaster - Module Name
  
  File: filename.lua
  Purpose: Brief description of the module's purpose
  
  Functions:
  - Function1(): Description
  - Function2(): Description
  
  Dependencies: 
  - List of dependencies
  
  Author: Jervaise
  Last Updated: YYYY-MM-DD
]]

local DM = DotMaster -- reference to main addon
local ModuleName = {} -- local table for module functions
DM.ModuleName = ModuleName -- expose to addon namespace

-- Local variables
local privateVar = {}

-- Local helper functions (private)
local function helperFunction()
  -- implementation
end

-- Public functions
function ModuleName:PublicFunction()
  -- implementation
end

-- Debug message function with module name
function ModuleName:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[ModuleName] " .. message)
  end
end

-- Initialize the module
function ModuleName:Initialize()
  -- initialization code
end

-- Return the module
return ModuleName
```

## Loading Order

Files are loaded in the order specified in the DotMaster.toc file, with dependencies loaded before the modules that require them:

1. Core systems first
2. Spell functionality 
3. Nameplate functionality
4. UI Components
5. Features
6. Final loader (dm_loader.lua)

## Performance Considerations

- Functions are properly namespaced to avoid conflicts
- Local functions are used for private implementation details
- Initialization is performed in a controlled sequence
- Event handling is properly managed

## Debugging

The debug system allows for module-specific debug messages, making it easier to trace issues to a specific component. Debug messages are prefixed with the module name for easy identification.

## Development Workflow

When developing or fixing issues:

1. Identify the component you need to work with
2. Files are organized by prefix for easy location
3. Each file contains clear documentation on its purpose and dependencies
4. Module initialization is handled in a consistent way

This structure makes it easy to understand, maintain, and extend the addon while keeping the code organized and focused. 