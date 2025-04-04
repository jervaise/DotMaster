# DotMaster: Smarter DoT Tracking for WoW

**Tired of losing track of your Damage over Time effects in the heat of battle? DotMaster enhances your awareness by intelligently coloring enemy nameplates based on *your* active DoTs!**

**Current Version:** 1.0.1
**Compatible with:** World of Warcraft 10.2.x (Likely compatible with future versions, adjust Interface version in `.toc` if needed)

<p align="center">
  <!-- Optional: Add a cool banner/logo image here later -->
  <!-- <img src="Media/dotmaster_banner.png" alt="DotMaster Banner"> -->
</p>

## Why DotMaster?

DotMaster goes beyond simple icon tracking. It integrates directly with enemy nameplates to provide instant visual feedback:

*   **Know Your DoTs:** See at a glance which targets have your DoTs active.
*   **Prioritize Targets:** Easily identify targets missing key debuffs.
*   **Class Agnostic:** Works seamlessly for any class and spec that uses DoTs.
*   **Highly Customizable:** Configure colors, priorities, and even track specific spell combinations.

## Key Features

*   **Dynamic Nameplate Coloring:** Enemy health bars change color based on your active DoTs and their configured priority.
*   **Plater Integration:** Works alongside the popular **Plater Nameplates** addon. DotMaster cleverly injects its logic to control nameplate colors without conflicting with Plater's core functionality. *(Note: Disable other Plater scripts/mods that modify health bar colors for best results).*
*   **Border-Only Mode:** Optionally color only the nameplate *border* for a less intrusive visual style.
*   **Expiry Flash:** Make nameplates (or their borders) flash when your highest priority DoT is about to expire, customizable threshold.
*   **DoT Combinations:** Define specific combinations of DoTs and assign unique colors/priorities when multiple effects are active.
*   **"Find My Dots" Window:** Get a clear overview of all active DoTs across multiple targets.
*   **Minimap Button:** Quick access to settings and the "Find My Dots" window.
*   **Comprehensive Settings:** Fine-tune tracked spells, colors, priorities, flashing options, and more via the in-game panel (`/dm`).
*   **Spell Database:** Includes a database of common DoT effects, easily extendable.

## Installation

1.  Download the latest release zip file.
2.  Extract the `DotMaster` folder from the zip file.
3.  Place the `DotMaster` folder into your `World of Warcraft\_retail_\Interface\AddOns\` directory.
4.  Restart World of Warcraft.
5.  Ensure "DotMaster" is enabled in the AddOns list at the character selection screen.

## Usage

*   `/dm` or `/dotmaster`: Opens the main configuration window.
*   `/fmd`: Toggles the "Find My Dots" window.
*   **Minimap Icon:** Left-click to toggle the main window, Right-click to toggle "Find My Dots".
*   Explore the tabs in the configuration window (`/dm`):
    *   **General:** Enable/disable the addon, toggle minimap icon, configure border mode, expiry flash, and force threat color options.
    *   **Tracked Spells:** Select which of your class's spells DotMaster should track and set their individual colors and priorities.
    *   **Combinations:** Define and manage multi-DoT combinations.
    *   **Database:** View and manage the underlying spell database (mainly for debugging/advanced use).

## Contributing & Development

Interested in contributing? Check out the documentation in the `Docs/` folder!

*   **Developer Guide:** [Docs/DEVELOPER_GUIDE.md](Docs/DEVELOPER_GUIDE.md)
*   **Code Structure:** [Docs/CODE_STRUCTURE.md](Docs/CODE_STRUCTURE.md)
*   **Changelog:** [Docs/CHANGELOG.md](Docs/CHANGELOG.md)

*(Developer-specific notes regarding versioning, testing, and API usage have been retained in the DEVELOPER_GUIDE.md)*

## License

All rights reserved. 