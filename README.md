# DotMaster

DotMaster is a World of Warcraft addon that colors nameplates based on player debuffs, making it easier to track your DoTs (Damage over Time spells) on multiple targets.

**Current Version: 0.6.6**

## Features

- **Nameplate Coloring**: Visually track your DoTs on enemy nameplates
- **Find My Dots**: Window showing all active DoTs grouped by target
- **Spell Database**: Pre-defined database of DoT spells for all classes
- **Configuration UI**: Customize colors and tracking settings
- **Profile Support**: Save different configurations for different characters
- **Debug Console**: Comprehensive debug system with filtering options

## Installation

1. Download the latest release
2. Extract the DotMaster folder to your `World of Warcraft\_retail_\Interface\AddOns\` directory
3. Restart World of Warcraft if it's running
4. Verify the addon is enabled in the addon list

## Usage

- Type `/dm` or `/dotmaster` to open the configuration panel
- Type `/dmdebug` to open the debug console or access debug options
- Click the minimap button to quickly toggle the "Find My Dots" window
- Configure which spells to track in the Tracked Spells tab
- Customize colors and visual options in the General tab

## For Developers

### ⚠️ Critical Development Notes

- **CRITICAL API REQUIREMENT**: Always use `C_Spell.GetSpellInfo()` instead of the global `GetSpellInfo()` function
- Run the `dmcheck` validation script before testing to catch common errors

```lua
-- INCORRECT - Do not use:
local name, _, icon = GetSpellInfo(spellID)

-- CORRECT - Always use:
local spellInfo = C_Spell.GetSpellInfo(spellID)
local name = spellInfo and spellInfo.name
local icon = spellInfo and spellInfo.iconFileID
```

### Project Structure

```
DotMaster/
├── Docs/               - Comprehensive documentation
├── Libs/               - Required external libraries
├── Media/              - Icons and textures
├── Scripts/            - Validation and utility scripts
├── DotMaster.toc       - Addon Table of Contents
├── embeds.xml          - Library embedding information
├── *.lua               - Core Lua files (initialization, settings, core logic, GUI, nameplates, spells, utilities)
├── README.md           - This file
└── dmcheck.bat         - Validation script helper (Windows)
```

### Documentation

All detailed documentation is available in the `Docs/` directory:

- **Code Structure**: [Docs/CODE_STRUCTURE.md](Docs/CODE_STRUCTURE.md)
- **Current Files**: [Docs/CURRENT_FILES.md](Docs/CURRENT_FILES.md)
- **Development Process**: [Docs/DEVELOPMENT_PROCESS.md](Docs/DEVELOPMENT_PROCESS.md)
- **Project Scope**: [Docs/PROJECT_SCOPE.md](Docs/PROJECT_SCOPE.md)
- **Critical API Notes**: [Docs/CRITICAL_API_NOTES.md](Docs/CRITICAL_API_NOTES.md)
- **Current Status**: [Docs/CURRENT_STATUS.md](Docs/CURRENT_STATUS.md)
- **Changelog**: [Docs/CHANGELOG.md](Docs/CHANGELOG.md)

### Validation Tools

The `Scripts/` directory contains validation tools to catch common errors before testing in-game. Run the following from the addon root:

```
dmcheck
```

For more information on available scripts, see [Scripts/SCRIPTS_GUIDE.md](Scripts/SCRIPTS_GUIDE.md).

### Required Libraries

DotMaster depends on the following libraries (included in the Libs directory):
- LibStub
- CallbackHandler-1.0
- LibDataBroker-1.1
- LibDBIcon-1.0

## Known Issues

1. **API Compatibility**: Still working on ensuring all parts of the addon use `C_Spell.GetSpellInfo()`
2. **Performance**: May experience frame drops during combat with many targets
3. **Nameplate Detection**: Occasional issues detecting all nameplates in crowded scenarios

## Contributing

Please review the [Development Process](Docs/DEVELOPMENT_PROCESS.md) document before making any contributions to the project.

## License

All rights reserved.

## Acknowledgements

Thanks to all contributors and testers who have helped improve DotMaster. 