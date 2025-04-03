# DotMaster Developer Guide

## Development Commands

- `/dmdebug` - Toggle the debug console window
- `/dmdebug category <name> [on|off]` - Control specific debug categories
- `/dmdebug status` - Show current debug status
- `/dmdebug help` - Show debug command help

## Development Principles

- **Baby Steps**: Make small, focused changes and test thoroughly before proceeding
- **Debug First**: Add debug statements before and after key operations
- **Verify State**: Use the debug console to verify data state before/after changes
- **Test Everything**: Every change should be tested in-game before proceeding

## Debug System 

### Overview

DotMaster has a sophisticated debug system designed to:
1. Capture debug messages by category
2. Display messages in a dedicated debug console
3. Filter messages by category
4. Persist through game sessions

### Debug Categories

The system has six predefined categories:
- `general`: For general debug messages (purple)
- `spell`: For spell-related messages (pink)
- `nameplate`: For nameplate-related messages (blue)
- `gui`: For interface-related messages (gold)
- `performance`: For performance measurements (green)
- `database`: For database operations (orange)

### Debug Functions

Each category has a dedicated debug function:
```lua
DM:DebugMsg("message")         -- General messages
DM:SpellDebug("message")       -- Spell-related
DM:NameplateDebug("message")   -- Nameplate-related
DM:GUIDebug("message")         -- UI-related 
DM:PerformanceDebug("message") -- Performance-related
DM:DatabaseDebug("message")    -- Database-related
```

### Debug Workflow

For effective development, follow this debug workflow:

1. Add debug messages at key points:
   ```lua
   DM:DatabaseDebug("Before changing tracked status for spell " .. spellID)
   DM:DatabaseDebug("Current value: " .. tostring(DM.dmspellsdb[spellID].tracked))
   
   -- Make changes here
   
   DM:DatabaseDebug("After changing tracked status for spell " .. spellID)
   DM:DatabaseDebug("New value: " .. tostring(DM.dmspellsdb[spellID].tracked))
   ```

2. Test in-game by:
   - Opening debug console with `/dmdebug`
   - Enabling relevant categories
   - Performing the action that triggers the code
   - Reviewing debug output

3. Verify success through debug console messages

## Code Standards

### ⚠️ Critical API Requirements

- **ALWAYS use `C_Spell.GetSpellInfo()` instead of the global `GetSpellInfo()` function**

```lua
-- INCORRECT - Do not use:
local name, _, icon = GetSpellInfo(spellID)

-- CORRECT - Always use:
local spellInfo = C_Spell.GetSpellInfo(spellID)
local name = spellInfo and spellInfo.name
local icon = spellInfo and spellInfo.iconFileID
```

### Coding Style

- Use camelCase for variables and functions
- Use PascalCase for classes and namespaces
- Limit line length to 100-120 characters
- Add comments for complex logic
- Follow existing code patterns and naming conventions
- Don't add unnecessary comments to code unless it's complex or requires explanation

### Error Handling

- Check for nil values before accessing table fields
- Use pcall for critical operations that might error
- Add debug messages for unexpected conditions

## Version Management

### Versioning Policy

- Version numbers follow Semantic Versioning (MAJOR.MINOR.PATCH):
  - **MAJOR** version (X.0.0): Incompatible API changes
  - **MINOR** version (0.X.0): New functionality in a backward-compatible manner
  - **PATCH** version (0.0.X): Backward-compatible bug fixes

### Automated Versioning

When the prompt "increment, success" is received, this triggers an automated version increment process:
1. Increment the PATCH version (the third decimal place)
2. Update version numbers in all relevant files (DotMaster.toc, etc.)
3. Add documentation notes about the changes
4. Commit and push changes to the GitHub develop branch
5. Ensure the local environment is set to the develop branch

**IMPORTANT**: Do not commit or push any changes before receiving the explicit "increment, success" command. All changes should be thoroughly tested in-game and validated before this command is issued.

Example process:
- Make code changes
- Test changes in-game
- When testing confirms everything works correctly, wait for the "increment, success" command
- Only then perform the version increment and commit/push

## Development Process

### Local Development Environment

- **The local repository directory MUST always be on the `develop` branch**
  - This is critical as the local directory is directly loaded by WoW for in-game testing
  - After merging changes to `main` or other branches, always switch back to `develop`

### Pre-Testing Verification

- **ALWAYS verify the following before asking users to test in-game:**
  - Check TOC file references match actual files in the directory
  - Verify all renamed files have been properly updated and old files removed
  - Check initialization code in core files
  - Run the `dmcheck` validation script to catch common errors
  - Document all file structure changes in CURRENT_FILES.md

### Git Workflow

- Regular development should happen on the `develop` branch
- The `main` branch should only contain stable, working versions
- Create feature branches for major changes
- Merge completed features back to `develop`
- Create release branches when preparing for a release
- Tag all versions with appropriate version numbers

## Project Organization

### Project Structure

```
DotMaster/
├── Docs/               - Comprehensive documentation
├── Libs/               - Required external libraries
├── Media/              - Icons and textures
├── Scripts/            - Validation and utility scripts
├── DotMaster.toc       - Addon Table of Contents
├── embeds.xml          - Library embedding information
├── *.lua               - Core Lua files
└── README.md           - Project overview
```

### Required Libraries

DotMaster depends on the following libraries:
- LibStub
- CallbackHandler-1.0
- LibDataBroker-1.1
- LibDBIcon-1.0

## System Architecture

### Database Structure

The `dmspellsdb` is the main data structure with fields:
- `spellid`: Unique identifier for each spell
- `spellname`: Name of the spell
- `spellicon`: Icon associated with the spell
- `wowclass`: WoW class the spell belongs to
- `wowspec`: Specialization within the class
- `color`: Color for nameplate coloring (RGB table)
- `priority`: Order in the tracked spells window
- `tracked`: Whether to show in tracked spells window (1/0)
- `enabled`: Whether to use for coloring nameplates (1/0)

### Module Structure

- `bootstrap.lua`: Initialization entry point
- `core.lua`: Final initialization steps
- `settings.lua`: Settings management
- `gui_*.lua`: UI components 
- `nameplate_*.lua`: Nameplate handling
- `spell_*.lua`: Spell data handling
- `find_my_dots.lua`: DoT detection feature

## Feature Implementation Guide

When implementing new features:

1. **Plan**: Add debug statements and review existing code patterns
2. **Implement**: Make small, incremental changes
3. **Test**: Verify each change with in-game testing
4. **Document**: Update relevant documentation
5. **Commit**: Commit changes with descriptive messages

## Documentation Standards

- Keep documentation up-to-date with code changes
- Use markdown for all documentation
- Include code examples for complex functionality
- Update CHANGELOG.md for all significant changes
- Document new or modified files in CURRENT_FILES.md 