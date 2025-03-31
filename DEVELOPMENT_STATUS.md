# DotMaster Development Status

This document outlines the development status of the DotMaster addon, including the initial requirements, structure, and progress through development milestones.

## Project Description

DotMaster is a World of Warcraft addon focused on tracking damage-over-time (DoT) spells. It provides enhanced visualization and management of DoTs on enemy targets, helping players optimize their damage rotation.

### Core Features

- Tracking DoT spells on enemy nameplates with visual indicators
- Customizable appearance for DoT indicators including size, position, and colors
- "Find My Dots" window showing all active DoTs grouped by target
- Comprehensive spell database with pre-defined DoT spells for all classes
- Configuration UI with profile support

## Project Structure

The addon is structured with a modular approach to ensure maintainability and future extensibility:

```
DotMaster/
├── Core/
│   ├── Constants.lua - Constants and utility functions
│   ├── Debug.lua - Comprehensive debug system
│   └── Init.lua - Initialization logic
│
├── Database/
│   └── SpellDB.lua - Database of DoT spells
│
├── Features/
│   ├── NameplateTracker.lua - Core DoT tracking on nameplates
│   └── FindMyDots.lua - Window showing all active DoTs
│
├── UI/
│   └── ConfigUI.lua - Configuration interface
│
├── Libs/ - External libraries (Ace3 framework)
│
├── DotMaster.lua - Main addon file
├── DotMaster.toc - Table of Contents for WoW
└── README.md - Documentation
```

## Minimum Viable Product (MVP)

The MVP version includes:
- Basic DoT tracking on enemy nameplates
- Pre-defined database of common DoT spells
- Simple configuration options
- Support for all classes with DoT spells

## Development Steps and Progress

| Step | Description | Status |
|------|-------------|--------|
| 1 | Project setup and repository initialization | ✅ COMPLETED |
| 2 | Basic addon structure creation | ✅ COMPLETED |
| 3 | Core module implementation | ✅ COMPLETED |
| 4 | Spell Database implementation | ✅ COMPLETED |
| 5 | Nameplate tracker feature | ✅ COMPLETED |
| 6 | Find My Dots feature | ✅ COMPLETED |
| 7 | Configuration UI | ✅ COMPLETED |
| 8 | External library integration (Ace3) | ✅ COMPLETED |
| 9 | Version control setup with tagging | ✅ COMPLETED |
| 10 | Branching strategy implementation | ✅ COMPLETED |
| 11 | In-game testing and bug fixing | 🔄 PENDING |
| 12 | Performance optimization | 🔄 PENDING |
| 13 | Advanced features beyond MVP | 🔄 PENDING |
| 14 | Documentation finalization | 🔄 PENDING |
| 15 | Release preparation | 🔄 PENDING |

## Development Environment

- World of Warcraft Retail Version: 10.2.0
- Development Path: `F:\World of Warcraft\_retail_\Interface\AddOns\DotMaster`
- GitHub Repository: [jervaise/DotMaster](https://github.com/jervaise/DotMaster)

## Versioning

- Current Version: 0.1.0 (MVP)
- Versioning Scheme: Semantic Versioning (MAJOR.MINOR.PATCH)
- See CONTRIBUTING.md for detailed versioning and branching strategy

## Implementation Details

### Completed Components

1. **Core System**
   - Initialization logic
   - Event handling
   - Debug system for development

2. **Database**
   - Predefined database of DoT spells
   - Categorized by class and spell type
   - Configurable per-spell settings

3. **Nameplate Tracking**
   - Custom frame creation on nameplates
   - Timer visualizations
   - Position and size customization

4. **Find My Dots Window**
   - Sortable list of all active DoTs
   - Grouping by target
   - Filtering capabilities

5. **Configuration UI**
   - Settings for visual appearance
   - Spell management
   - Profile system

### Next Development Focus

- In-game testing under different scenarios
- Performance optimization for raid environments
- Additional quality-of-life features
- Enhancement of visual customization options

## Notes for Other Developers/Assistants

- The project follows a modular pattern where each feature is self-contained
- Development occurs in feature branches from the `develop` branch
- The `main` branch always contains stable, releasable code
- All external dependencies are in the `Libs` folder
- See CONTRIBUTING.md for the full development workflow 