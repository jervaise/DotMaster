# DotMaster Development Guide

## Overview

This guide provides comprehensive information for developers working on the DotMaster addon. It covers code organization, development processes, and best practices to ensure consistent, high-quality contributions.

## Code Structure

DotMaster follows a modular architecture with clear separation of concerns:

### File Organization

Files are organized by their functional areas with a prefix-based naming convention:

- **Core Files**: Core functionality and initialization 
  - `bootstrap.lua` - Initial setup and event registration
  - `core.lua` - Core structures and functionality
  - `api.lua` - API layer between GUI and backend
  - `settings.lua` - Settings management
  - `init.lua` - Final initialization sequence
  - `debug.lua` - Debug console functionality

- **GUI Files**: User interface components
  - `gui.lua` - Main GUI framework
  - `gui_common.lua` - Shared UI elements
  - `gui_general_tab.lua` - General settings tab
  - `gui_tracked_spells_tab.lua` - DoT spell configuration
  - `gui_combinations_tab.lua` - DoT combinations management
  - `gui_colorpicker.lua` - Color selection interface
  - `gui_spell_row.lua` - Individual spell row component
  - `gui_spell_selection.lua` - Spell selection dialog
  - `gui_debug_console.lua` - Debug console interface

- **Utility Files**:
  - `minimap.lua` - Minimap button functionality

### Module Pattern

Each module follows a consistent pattern:

```lua
local DM = DotMaster -- reference to main addon
local Module = {} -- local table for module functions
DM.Module = Module -- expose to addon namespace

-- Local variables
local privateVar = {}

-- Local helper functions (private)
local function helperFunction()
  -- implementation
end

-- Public functions
function Module:PublicFunction()
  -- implementation
end

-- Initialize the module
function Module:Initialize()
  -- initialization code
end

-- Return the module
return Module
```

## Development Environment

### Setup

1. Clone the repository to your WoW addons directory:
   - `[WoW Install]\_retail_\Interface\AddOns\DotMaster`

2. Ensure you have all required dependencies:
   - LibStub
   - CallbackHandler-1.0
   - LibDataBroker-1.1
   - LibDBIcon-1.0

### Branch Management

- **develop**: Active development branch (always work on this locally)
- **main**: Stable release branch (never work directly on main)
- For features, create feature branches from develop

## Development Process

### Feature Development Workflow

1. **Plan**: Document the feature scope and design
2. **Branch**: Create a feature branch from develop
3. **Implement**: Make focused, incremental changes
4. **Test**: Test thoroughly in-game before proceeding
5. **Document**: Update documentation as needed
6. **Merge**: Merge feature branch back to develop

### Code Standards

- Use camelCase for variables and functions
- Use PascalCase for classes and namespaces
- Add comments for complex logic, avoiding unnecessary comments
- Follow existing patterns in the codebase
- Maximum line length of 120 characters

### Error Handling

- Always check for nil values before accessing table fields
- Use pcall for operations that might error
- Validate all user inputs
- Use the PrintMessage function for user-facing messages:
  ```lua
  DM:PrintMessage("Your message here")
  ```

### Testing

Always test changes thoroughly in-game:

1. Verify all UI elements work as expected
2. Test across multiple character classes when relevant
3. Check console for errors using `/script print(GetLastError())`
4. Test edge cases (empty data, large data sets, etc.)

## Debug System

DotMaster includes a comprehensive debug system that provides categorized, 
filterable logging for development and troubleshooting.

### Debug Categories

The debug system organizes messages into the following categories:

- **General**: General information
- **Database**: Database access/modifications
- **Performance**: Performance metrics and timing
- **UI Events**: User interface events
- **Loading/Init**: Loading and initialization
- **API Calls**: API layer interactions
- **Combat**: Combat-related events
- **Errors**: Error messages and exceptions

### Using the Debug System

To log messages, use the Debug module's logging functions:

```lua
-- Standard logging with a category
DM.Debug:Log(DM.Debug.CATEGORY.GENERAL, "Simple message")

-- Formatted logging with parameters
DM.Debug:Log(DM.Debug.CATEGORY.DATABASE, "Saving spell %d with priority %d", spellID, priority)

-- Category-specific convenience functions
DM.Debug:General("Simple general message")
DM.Debug:Database("Loaded %d spells", #spells)
DM.Debug:Performance("Operation took %.2fms", timing)
DM.Debug:UI("Button %s clicked", buttonName)
DM.Debug:Loading("Module %s initialized", moduleName)
DM.Debug:API("API call: %s", functionName)
DM.Debug:Combat("Processing combat event: %s", eventName)
DM.Debug:Error("Failed to load spell data: %s", errorMsg)

-- Throttled logging (only logs once every X seconds for a given key)
DM.Debug:LogThrottled("key_name", 5, DM.Debug.CATEGORY.PERFORMANCE, "Frequent event throttled to once per 5 seconds")

-- Performance measurement
DM.Debug:LogPerformance("Operation name", function()
  -- Code to measure
  return result
end)
```

### Accessing the Debug Console

The debug console interface can be accessed through:

1. The Developer Mode checkbox in the General tab
2. The Debug Console button at the bottom of the interface
3. Directly from code with `DM.debugFrame:Toggle()`

### Debug Console Features

- **Message Filtering**: Filter by text or category
- **Copy to Clipboard**: Export logs for sharing
- **Category Toggles**: Enable/disable categories
- **Timestamps**: View when events occurred
- **Auto-scroll**: Follow newest messages

### Performance Considerations

The debug system is designed with performance in mind:

- Messages for disabled categories are ignored completely
- Throttling prevents log flooding
- Message processing is batched for minimal impact
- Developer Mode limits debug UI availability to developers

### Integration Guidelines

When implementing new features:

1. Add appropriate debug logging for important operations
2. Use the correct category for each type of message
3. Include relevant data in log messages
4. Use throttling for frequent events
5. Measure performance of critical operations

## Release Process

### Versioning

DotMaster follows semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Incompatible API changes
- **MINOR**: New backwards-compatible functionality
- **PATCH**: Backwards-compatible bug fixes

### Release Steps

1. Ensure all tests pass and functionality works as expected
2. Update version numbers in:
   - DotMaster.toc (## Version field)
   - Any other version references
3. Update README.md with new features/changes
4. Create a tagged release on GitHub

## API Integration

### Core API

The `api.lua` file provides a clean contract between the GUI and backend:

```lua
-- Example API usage
local settings = DM.API:GetSettings()
DM.API:SaveSettings(settings)
DM.API:TrackSpell(spellID, spellName, spellIcon, color, priority)
```

All GUI components should interact with the backend exclusively through the API layer.

## Architecture Considerations

### Performance

- Cache results of expensive operations
- Minimize processing during combat
- Use throttling for frequent events
- Profile performance-critical functions

### Memory Usage

- Avoid creating large tables unnecessarily
- Release memory when objects are no longer needed
- Use localized references to global functions

## Advanced Topics

### SavedVariables

DotMaster uses a single SavedVariables entry:

```
## SavedVariables: DotMasterDB
```

The settings structure is managed through:
- `settings.lua` - Loading/saving settings
- Access via `DM.API:GetSettings()` and `DM.API:SaveSettings()`

### Event Handling

Event registration is centralized in `bootstrap.lua` with event handling following a consistent pattern:

```lua
DM:RegisterEvent("EVENT_NAME")
DM:SetScript("OnEvent", function(self, event, ...)
  -- Handle event
end)
``` 