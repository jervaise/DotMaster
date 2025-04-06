# DotMaster

DotMaster is a World of Warcraft addon that enhances the tracking of damage-over-time spells on enemy nameplates.

## Version 1.0.3 - GUI Isolation

This version introduces a clean separation between the GUI and backend, allowing for easier development and maintenance.

### Architecture

- **API Layer**: Provides a clean contract between the GUI and backend
- **GUI Components**: Maintain the original UI layout and functionality
- **Old_Backend**: Contains the original backend code for reference

### File Structure

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
└── Old_Backend/       # Original backend code (for reference)
```

### Development Notes

1. The GUI is fully preserved with the original visual appearance
2. All backend functionality is accessed through the API layer
3. New backend implementations should implement the API contract

## Requirements

- World of Warcraft Retail (10.2+)
- Plater Nameplates addon

## Usage

- Use `/dm` to toggle the main GUI
- Use `/dm on` or `/dm off` to enable/disable the addon
- Use `/dmdebug` to toggle debug mode

## License

All Rights Reserved - DM Dev Team 