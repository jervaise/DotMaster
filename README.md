# DotMaster

## Version 1.0.8

DotMaster is a World of Warcraft addon that works with Plater Nameplates to enhance DoT (Damage over Time) tracking.

## Features

- Customize border colors for different DoTs on enemy nameplates
- Border-only mode to show only colored borders without affecting nameplate colors
- Expiry flash functionality to alert you when DoTs are about to expire
- Create combinations of multiple DoTs with unique colors
- Class and specialization specific profiles
- Full Plater integration

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

- **1.0.7**: Added auto-save functionality, instant bokmaster integration, UI reload prompts for border thickness changes
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