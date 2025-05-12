# DotMaster Project Scope

## Overview

DotMaster is a World of Warcraft addon designed to enhance tracking of damage-over-time (DoT) spells on enemy targets. It provides visual indicators on nameplates and management tools to help players optimize their damage rotation, particularly for classes that rely heavily on DoT spells.

## Core Features

- **DoT Tracking**: Track DoT spells on enemy nameplates with customizable visual indicators
- **Nameplate Coloring**: Color enemy nameplates based on active DoTs
- **Flash Warnings**: Visual warnings when DoTs are about to expire
- **Spell Management**: UI for managing which spells to track
- **Spell Combinations**: Group DoT spells into meaningful combinations
- **Minimap Button**: Quick access to addon functions

## Technical Requirements

- **Game Version**: World of Warcraft Retail (10.2.0+)
- **Performance**: Minimal impact on game performance, especially during combat
- **Libraries**: 
  - LibStub
  - CallbackHandler-1.0
  - LibDataBroker-1.1
  - LibDBIcon-1.0

## Architecture

DotMaster is structured with a clean separation between the GUI and backend:

- **API Layer**: Interface between GUI and backend implementation
- **GUI Components**: User interface elements
- **Core System**: Addon initialization and core functionality
- **Settings Management**: Configuration and SavedVariables handling

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

## User Experience

DotMaster focuses on providing a seamless user experience:

1. **Intuitive UI**: Clear and easy-to-use configuration interface
2. **Minimal Setup**: Pre-configured tracking for common DoT spells
3. **Customizability**: Extensive options for appearance and behavior
4. **Performance**: Smooth performance even in demanding raid environments

## Target Users

- **Primary**: Players of DoT-focused classes (Warlocks, Shadow Priests, etc.)
- **Secondary**: Any player wanting to track their DoT abilities more effectively

## Future Development

Potential future enhancements include:

- Enhanced performance optimizations
- Additional visualization options
- Boss-specific DoT tracking features
- Integration with other combat addons
- "Find My Dots" window showing all active DoTs grouped by target

## Development Phases

1. **Phase 1 (Complete)**: Core functionality and basic UI
2. **Phase 2 (Current)**: GUI isolation and API refinement
3. **Phase 3 (Planned)**: Performance optimization and feature enhancements
4. **Phase 4 (Future)**: Integration with other addons and additional features

## Success Criteria

The addon will be considered successful when it:

1. Reliably tracks and displays DoT information on nameplates
2. Provides a responsive and intuitive user interface
3. Performs efficiently even in intensive combat situations
4. Receives positive user feedback and adoption 