# DotMaster Project Scope

## Overview

DotMaster is a World of Warcraft addon that enhances tracking of damage-over-time (DoT) spells on enemy targets. It provides visualization tools and management features to help players optimize their damage rotation.

## Core Features

- Tracking DoT spells on enemy nameplates with visual indicators
- Customizable appearance for DoT indicators including size, position, and colors
- "Find My Dots" window showing all active DoTs grouped by target
- Comprehensive spell database with pre-defined DoT spells for all classes
- Configuration UI with profile support

## Technical Requirements

- **Platform**: World of Warcraft Retail
- **Compatible with World of Warcraft Retail (Current version: 10.2.5)**
- Minimal performance impact, especially during combat
- Ace3 framework integration for stability and maintainability
- Support for all character classes and their DoT spells

## Project Structure

The addon is structured with a modular approach to ensure maintainability and future extensibility:

```
DotMaster/
├── init.lua - Main initialization
├── utils.lua - Utility functions
├── settings.lua - Settings management
├── core.lua - Core functionality
├── Debug.lua - Debug system
│
├── nameplate_core.lua - Nameplate handling core
├── nameplate_detection.lua - Finding nameplates
├── nameplate_coloring.lua - Coloring of nameplates
│
├── spell_database.lua - Database of DoT spells
├── spell_utils.lua - Spell utility functions
├── find_my_dots.lua - DoT detection functionality
│
├── gui_common.lua - Common UI components
├── gui_colorpicker.lua - Color picker functionality
├── gui.lua - Main GUI framework
├── gui_general_tab.lua - General settings tab
├── gui_spells_tab.lua - Spell list tab
├── gui_spell_row.lua - Spell row components
├── gui_spell_selection.lua - DoT selection dialog
│
├── Libs/ - External libraries (Ace3 framework)
├── Docs/ - Project documentation
│
├── embeds.xml - Library embedding
├── DotMaster.toc - Table of Contents for WoW
└── README.md - Basic project information
```

## Minimum Viable Product (MVP)

The MVP version includes:
- DoT tracking on enemy nameplates
- Pre-defined database of common DoT spells for all classes
- Configuration options via UI
- Simple "Find My Dots" feature
- Basic profile management

## Future Development

Potential future enhancements include:
- Enhanced performance optimizations
- Expanded spell database with more specialization-specific options
- Integration with other combat addons
- Additional visualization options for DoT indicators
- Built-in timer and alert system for DoT refreshing
- Boss-specific DoT tracking features

## Development Environment

- World of Warcraft Retail Version: 10.2.0
- Development Path: `F:\World of Warcraft\_retail_\Interface\AddOns\DotMaster`
- GitHub Repository: [jervaise/DotMaster](https://github.com/jervaise/DotMaster)

## Library Dependencies

The addon uses the following libraries:
- LibStub
- CallbackHandler-1.0
- AceAddon-3.0
- AceEvent-3.0
- AceDB-3.0
- AceConsole-3.0
- AceTimer-3.0
- LibDataBroker-1.1
- LibDBIcon-1.0 