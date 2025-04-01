# DotMaster Code Structure

This document provides an overview of DotMaster's code organization and architecture to help developers understand the codebase.

## File Naming Convention

DotMaster uses a prefix-based naming system to organize files by functionality:

| Prefix | Purpose | Examples |
|--------|---------|----------|
| `dm_` | Core functionality | `dm_core.lua`, `dm_debug.lua` |
| `np_` | Nameplate functionality | `np_detection.lua`, `np_coloring.lua` |
| `sp_` | Spell-related functionality | `sp_database.lua`, `sp_utils.lua` |
| `ui_` | User interface components | `ui_main.lua`, `ui_tabs.lua` |
| `fmd_` | Find My Dots feature | `fmd_core.lua`, `fmd_ui.lua` |

## Module System

Each file represents a logical module that extends the main `DotMaster` object. The typical module pattern is:

```lua
-- Establish local reference to addon table
local DM = DotMaster

-- Create module namespace if needed
DM.ModuleName = DM.ModuleName or {}
local MOD = DM.ModuleName

-- Define module functions
function MOD:Initialize()
  -- Initialization code
end

-- Return module to support chaining
return MOD
```

## Loading Order

Files load in the order defined in the TOC file. The general sequence is:

1. Core systems (dm_* files)
2. Spell functionality (sp_* files)
3. Nameplate functionality (np_* files)
4. UI components (ui_* files)
5. Feature modules (fmd_* files)
6. Final loader (`dm_loader.lua`)

## Key Modules

### Core System

- **dm_core.lua**: Main initialization and frame setup
- **dm_debug.lua**: Debugging utilities
- **dm_utils.lua**: Helper functions
- **dm_settings.lua**: Settings management

### Spell System

- **sp_database.lua**: Spell database definition and management
- **sp_utils.lua**: Spell-related helper functions

### Nameplate System

- **np_core.lua**: Base nameplate functionality
- **np_detection.lua**: Nameplate detection logic
- **np_coloring.lua**: Nameplate coloring implementation

### UI System

- **ui_main.lua**: Main UI framework
- **ui_tabs.lua**: Tab system for configuration
- **ui_components.lua**: Reusable UI components

### Find My Dots Feature

- **fmd_core.lua**: Core functionality for Find My Dots
- **fmd_ui.lua**: UI components for Find My Dots

## Development Workflow

DotMaster uses a two-branch system for development:

- **main**: Contains the stable, production version
- **develop**: Active development occurs here

Features should be developed in feature branches off of develop, then merged back once complete.

## Event System

DotMaster uses WoW's event system with these key events:

- `NAME_PLATE_UNIT_ADDED`: Triggered when a nameplate appears
- `NAME_PLATE_UNIT_REMOVED`: Triggered when a nameplate disappears
- `UNIT_AURA`: Triggered when unit auras change
- `PLAYER_ENTERING_WORLD`: Triggered on zone changes and login

## Data Flow

1. **Spell Detection**:
   - Player casts spells on targets
   - UNIT_AURA events fire
   - Spell detection logic matches auras against configured spells

2. **Nameplate Coloring**:
   - When a matching aura is found, the nameplate color is modified
   - Original colors are stored for restoration
   - When auras expire, nameplate colors are restored

3. **Find My Dots**:
   - When enabled, targets with player's DoTs are tracked
   - UI provides visual indicators for active DoTs

## Critical API Notes

- Always use `C_Spell.GetSpellInfo()` instead of `GetSpellInfo()`
- The C_Spell implementation returns a table with named fields, not multiple values
 