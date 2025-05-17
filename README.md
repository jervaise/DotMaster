# DotMaster

## Version 2.1.10

DotMaster is a powerful World of Warcraft addon that enhances DoT/HoT tracking through seamless integration with Plater Nameplates. It provides a fully customizable visual system for tracking your damage-over-time and healing-over-time effects directly on enemy nameplates.

![DotMaster Main Interface](Media/dotmaster-main-icon.tga)

## Features

### Core Functionality
- **Advanced DoT Tracking**: Visually track all DoTs and HoTs on enemy nameplates with custom colors
- **Class & Spec Awareness**: Automatically adapts to your current specialization with unique settings per spec
- **Combinations Tracking**: Create custom spell combinations with unique colors when multiple specific DoTs are active
- **Smart Border System**: Choose between full nameplate coloring or border-only mode for cleaner UI
- **Enhanced Expiry Warnings**: Configurable flashing with adjustable threshold, interval, and brightness

### Visual Customization
- **Border Thickness Control**: Adjust nameplate border thickness to your preference
- **Priority System**: Set display priority between multiple active DoTs
- **M+ Profile Integration**: Preserves important Mythic+ mob indicators when using custom Plater profiles

### User Experience
- **Find My DoTs**: Quickly detect and add all your active DoTs on targets in combat
- **Drag & Drop Priority**: Easily rearrange spells with drag-and-drop priority system
- **Minimap Access**: Convenient minimap button with customizable position
- **Per-Character Settings**: Maintain different configurations for different characters and specs

## Installation

1. Download the latest version from [CurseForge](https://www.curseforge.com/wow/addons/dotmaster), [Wago](https://addons.wago.io/addons/dotmaster), or [GitHub](https://github.com/jervaise/DotMaster/releases)
2. Extract to your World of Warcraft\_retail_\Interface\AddOns folder
3. Ensure [Plater Nameplates](https://www.curseforge.com/wow/addons/plater-nameplates) is installed and enabled
4. Restart WoW or reload your UI (/reload)

## Quick Start Guide

### Basic Setup
1. Open DotMaster with `/dm` or click the minimap icon
2. Go to the "General" tab and ensure "Enable DotMaster" is checked
3. For best results, click "Install Plater Integration" if prompted

### Tracking Your First DoT
1. Cast a spell you want to track
2. Open the "Tracked Spells" tab
3. Click "Add New" and select your spell
4. Choose a custom color for the spell
5. Adjust priority if tracking multiple spells (lower number = higher priority)

### Creating a Combination
1. Open the "Combinations" tab
2. Click "New Combination"
3. Select multiple spells to include in the combination
4. Choose a color to show when all selected spells are active on a target
5. Set priority to determine which combination/DoT displays when multiple are active

## Advanced Configuration

### Expiry Flash Options
- **Expiry Flash**: Enable/disable the flashing effect when DoTs are about to expire
- **Seconds**: Set how many seconds before expiration the flashing begins
- **Interval**: Control how quickly the nameplate flashes (lower = faster flashing)
- **Brightness**: Adjust the intensity of the flashing effect

### Border Options
- **Extend Plater Colors to Borders**: Maintains Plater's color coding for important/caster mobs while showing DoT status
- **Use Borders for DoT Tracking**: Shows DoT status in nameplate borders only, preserving health bar colors
- **Border Thickness**: Customize border size from 1-5 pixels (requires UI reload)

### Finding & Managing DoTs
- Use the **Find My Dots** feature in the Database tab to automatically detect your DoTs
- Set color-coding by importance (bright colors for high-priority DoTs, subtle colors for maintenance DoTs)
- Create combinations for your core DoT sets to easily track targets with complete DoT coverage

### Compatibility
DotMaster works with:
- All retail WoW classes and specializations
- All versions of Plater Nameplates (required)
- WoW versions 11.1.5 and 11.1.7

## Commands

- `/dm` or `/dotmaster` - Toggle the main interface
- `/dm minimap` - Toggle minimap icon
- `/dm reset` - Reset to default settings
- `/dm version` - Display current version

## Troubleshooting

- **Colors Not Showing**: Ensure DotMaster is enabled and Plater integration is installed
- **Missing Spells**: Use the Database tab's "Find My Dots" feature to detect your spells
- **UI Reload Prompt**: Some settings (like border thickness) require a UI reload to take effect
- **After Plater Updates**: You may need to reinstall the DotMaster integration

## Support

For issues, feature requests, or questions:
- Report issues on [GitHub](https://github.com/jervaise/DotMaster/issues)
- Download the latest version from [CurseForge](https://www.curseforge.com/wow/addons/dotmaster)

## Credits

- Created and maintained by Jervaise
- Thanks to all testers and contributors

---

*"Track your DoTs, maximize your damage. DotMaster - your DoT tracking companion."* 