# DotMaster

DotMaster is a World of Warcraft addon that enhances the tracking of damage-over-time spells on enemy nameplates.

## Features

- **DoT Tracking**: Visual indicators on enemy nameplates showing your active DoTs
- **Nameplate Coloring**: Optional coloring of enemy nameplates based on active DoTs
- **Customizable Appearance**: Adjust size, position, and appearance of DoT indicators
- **Spell Management**: Configure which spells to track through an intuitive interface
- **Minimap Button**: Quick access to addon functions

## Installation

1. Download the latest release from [GitHub](https://github.com/YourUsername/DotMaster/releases)
2. Extract the folder to your `World of Warcraft\_retail_\Interface\AddOns` directory
3. Ensure the folder is named exactly `DotMaster`
4. Restart World of Warcraft if it's running

## Usage

- `/dm` - Toggle the main GUI
- `/dm on` - Enable the addon
- `/dm off` - Disable the addon
- `/dm config` - Open configuration window

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

## Requirements

- World of Warcraft Retail (10.2.0+)
- Dependencies (included):
  - LibStub
  - CallbackHandler-1.0
  - LibDataBroker-1.1
  - LibDBIcon-1.0

## For Developers

See the `Docs/Development Guide.md` for detailed information on:
- Project structure and architecture
- Development workflow
- Coding standards
- API documentation
- Release process

The `Docs/Project Scope.md` contains the project vision, feature roadmap, and target audience.

## Version History

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