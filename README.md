# DotMaster

## Version 2.1.2 (Stable Release)

DotMaster is a World of Warcraft addon that enhances your DoT/HoT management experience through integration with the Plater Nameplates addon. It provides clear, customizable visualization of your damage-over-time and healing-over-time effects directly on enemy nameplates.

### Key Features
- Track DoTs and other auras on nameplates with customizable colors
- Create combinations of spells with unique colors
- Customize border thickness and opacity
- Per-class and per-specialization settings
- Import/Export system for sharing configurations
- Compatible with all classes

### New in 2.1.2
- Fixed "for limit must be a number" error when using Find My Dots feature
- Added safety checks for numTabs property to prevent errors
- Improved error handling in tab switching functionality

### Previous Updates (2.1.1)
- Fixed combinations persistence issue across UI reloads
- Added backward compatibility for legacy data structures
- Improved database handling and stability

### Previous Updates (2.1)
- Added proper type conversion for enabled/disabled and tracked/untracked status
- Fixed issue with reorder arrows causing spells to disappear
- Enhanced Plater integration reliability
- Added support for border-only mode for cleaner nameplates
- Added color flashing for expiring DoTs
- Added combination support for advanced aura tracking
- User interface improvements and bug fixes

## Installation
1. Download the addon
2. Extract to your World of Warcraft\_retail_\Interface\AddOns folder
3. Make sure Plater addon is installed and enabled
4. Restart WoW or reload your UI (/reload)

## Usage
Access the main interface by typing '/dm' or '/dotmaster' in chat or click the minimap icon.

### Adding Spells to Track
1. Cast a spell you want to track
2. Open DotMaster (/dm)
3. Click on "Add New" in the "Tracked Spells" tab
4. Select your spell from the list
5. Customize its color

### Creating Combinations
1. Go to the "Combinations" tab
2. Click "New Combination"
3. Select which spells should be part of the combination
4. Choose a color for when all selected spells are active

## Requirements
- World of Warcraft (Retail)
- [Plater Nameplates](https://www.curseforge.com/wow/addons/plater-nameplates)

## Support
If you encounter issues or have suggestions:
- Report issues on [GitHub](https://github.com/yourusername/DotMaster/issues)
- Join our [Discord server](https://discord.gg/yourserver)

## Version History
- **2.1.2**: Fixed "for limit must be a number" error, added safety checks, improved error handling
- **2.1.1**: Fixed combinations persistence, backward compatibility, stability improvements
- **2.1**: Type conversion fixes, enhanced Plater integration, combinations support
- **2.0**: Complete rewrite with enhanced features and UI
- **1.0.4**: Update with version 1.0.4 changes

## Credits
- Created by Jervaise

## Features

- Customize border colors for different DoTs on enemy nameplates
- Border-only mode to show only colored borders without affecting nameplate colors
- Expiry flash functionality to alert you when DoTs are about to expire
- Create combinations of multiple DoTs with unique colors
- Class and specialization specific profiles
- Full Plater integration
- Proper priority sorting for spell colors (new in 2.1)
- Improved database reset functionality (new in 2.1)

## Installation

1. Download the latest release from [GitHub](https://github.com/yourusername/DotMaster/releases)
2. Extract the DotMaster folder to your World of Warcraft `_retail_/Interface/AddOns` directory
3. Ensure Plater Nameplates addon is installed and enabled
4. Enable DotMaster in your addon list
5. Use `/dm` to open the configuration panel

## Commands

- `/dm` - Toggle the configuration panel
- `/dm on` - Enable the addon
- `/dm off` - Disable the addon
- `/dm show` - Show the configuration panel
- `/dm push` - Force push settings to Plater
- `/dm reset` - Reset to default settings
- `/dm reload` - Reload UI

## Recent Changes

### Version 2.1.2 (Stable Release)
- Fixed "for limit must be a number" error when using Find My Dots feature
- Added safety checks for numTabs property to prevent errors
- Improved error handling in tab switching functionality

### Version 2.1.1 (Stable Release)
- Fixed combinations persistence issue across UI reloads
- Added backward compatibility for legacy data structures
- Improved database handling and stability for combinations

### Version 2.1 (Stable Release)
- Fixed spell priority sorting in Plater integration (lower number = higher priority)
- Added proper type conversion for enabled/disabled and tracked/untracked status
- Improved database reset functionality with complete wipe and class reinitialization
- Fixed UI error in tabs handling
- Enhanced Plater color integration with better priority system
- Various bug fixes and stability improvements

See the [CHANGELOG.md](CHANGELOG.md) file for detailed information about recent changes.

## Requirements

- World of Warcraft: Retail
- Plater Nameplates addon

## Architecture

DotMaster uses a clean separation between the GUI and backend:

- **API Layer**: Interface between GUI and backend implementation
- **GUI Components**: User interface elements
- **Core System**: Addon initialization and core functionality
- **Settings Management**: Configuration and saved variables

## File Structure

```
DotMaster/
├── api.lua            # API contract between GUI and backend
├── bootstrap.lua      # Initialization sequence
├── core.lua           # Core structures
├── DotMaster.toc      # Addon manifest
├── gui.lua            # Main GUI framework
├── gui_*.lua          # GUI components
├── init.lua           # Final initialization
├── minimap.lua        # Minimap icon functionality
├── settings.lua       # Settings management
├── Docs/              # Documentation
├── Libs/              # External libraries
└── Media/             # Icons and textures
```

## For Developers

See the `Docs/Development Guide.md` for detailed information on:
- Project structure and architecture
- Development workflow
- Coding standards
- API documentation
- Release process

The `Docs/Project Scope.md` contains the project vision, feature roadmap, and target audience.

## Version History

- **1.0.7**: Added auto-save functionality, instant DotMaster Integration, UI reload prompts for border thickness changes
- **1.0.6**: Improved Plater integration with direct config embedding that ensures consistent nameplate coloring
- **1.0.5**: Fixed color refresh handling for combinations to ensure proper display after color changes
- **1.0.4**: Update with version 1.0.4 changes
- **1.0.3**: GUI isolation from backend with API layer implementation
- **1.0.2**: Added spell combination tracking
- **1.0.1**: Performance improvements and bug fixes
- **1.0.0**: Initial release with core functionality

## License

All Rights Reserved - DotMaster Development Team

## Support

For issues, feature requests, or questions, please contact us through GitHub issues 