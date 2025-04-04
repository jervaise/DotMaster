# DotMaster

An advanced addon for World of Warcraft that tracks Damage over Time (DoT) effects on enemy nameplates and provides comprehensive visual feedback.

**Current Version: 1.0.1**
**Compatible with World of Warcraft: The War Within (11.1.0)**

## Key Features

- **Dynamic Nameplate Coloring**: Customize colors for all your DoTs on enemy nameplates
  - **Border-Only Mode**: Option to color just the nameplate border for subtle indication
  - **Force Threat Color**: Automatically prioritize threat colors for tanks and DPS when needed
  - **Expiration Flashing**: Visual warning when DoTs are about to expire

- **DoT Combinations**: Create and track custom combinations of multiple DoTs
  - **Custom Thresholds**: Set specific requirements for how many DoTs trigger a combination
  - **Priority System**: Higher priority combinations override lower ones
  - **Class-Specific**: Combinations are filtered by your current class for relevance

- **Find My DoTs Window**: Real-time view of all your active DoTs grouped by target
  - **Target Sorting**: Organizes targets by distance and relationship
  - **Time Remaining**: Shows exact time left on each DoT
  - **Stack Count**: Displays number of stacks for applicable DoTs

- **Comprehensive Database**: Pre-defined database covering all classes and specs
  - **Class Filtering**: Only shows spells relevant to your current class
  - **Priority System**: Set custom priorities for which DoTs take visual precedence
  - **Customization**: Personalize colors, tracking settings, and more

- **User-Friendly Interface**:
  - **Class-Colored UI**: Interface adapts to your character's class colors
  - **Minimap Button**: Quick access to all features
  - **Debug Console**: In-depth troubleshooting tools when needed

## Requirements

- **[Plater Nameplates](https://www.curseforge.com/wow/addons/plater-nameplates)**: This addon requires Plater to function

## Installation

1. Download the latest release from [CurseForge](https://www.curseforge.com/wow/addons/dotmaster) or [Wago.io](https://addons.wago.io/addons/dotmaster)
2. Extract the DotMaster folder to your `World of Warcraft\_retail_\Interface\AddOns\` directory
3. Restart World of Warcraft if it's running
4. Ensure both Plater and DotMaster are enabled in your addon list

## Usage

- Type `/dm` or `/dotmaster` to open the configuration panel
- Type `/dmdebug` to open the Debug Console
- Click the minimap button to toggle the "Find My DoTs" window

### Quick Start

1. Open the configuration panel with `/dm`
2. Visit the "Database" tab to add spells you want to track
3. Customize colors and priorities in the "Tracked Spells" tab
4. Create DoT combinations in the "Combinations" tab if desired
5. Configure visual options in the "General" tab

## Features In-Depth

### Nameplate Coloring

DotMaster changes the color of enemy nameplates based on your active DoTs:
- Choose between full nameplate coloring or border-only mode
- Set custom priorities to determine which DoT's color takes precedence
- Configure border thickness when using border-only mode
- Enable flashing when DoTs are about to expire with customizable thresholds

### DoT Combinations

Create powerful visual indicators when specific combinations of DoTs are active:
- Set up a combination of multiple DoTs that changes nameplate color when active
- Choose between "All" spells or a specific number of spells required
- Assign custom colors and priorities to combinations
- Combinations are class-specific for better organization

### Find My DoTs Window

A dedicated window that shows all your active DoTs across all targets:
- Groups DoTs by target for easy tracking
- Shows remaining time on each DoT
- Updates in real-time as DoTs are applied or expire
- Sortable by various criteria

## Known Issues

1. In rare cases, nameplates may not update immediately when DoTs are applied
2. Performance impact may be noticeable in very crowded scenarios with many nameplates
3. Custom border coloring may not be visible with some Plater profiles

## License

All rights reserved.

## Acknowledgements

- Thanks to the Plater Nameplates team for creating an excellent nameplate addon
- Special thanks to all beta testers and contributors 