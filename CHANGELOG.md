# DotMaster Changelog

## [2.2.5] - 2025-01-27

### Fixed
- **Force Threat Color for Tanks**: Improved threat detection logic to properly handle multiple tanks in raid environments
  - Tanks no longer receive "no aggro" colors when another tank is legitimately tanking a mob
  - Added proper raid environment detection using `Plater.ZoneInstanceType == "raid"`
  - Enhanced logic to check if other tanks in the group are tanking before applying threat colors
  - Fixed early return statements that were preventing DoT coloring from working when threat conditions weren't met
  - DoT coloring now functions correctly regardless of threat detection state

### Technical
- Restructured threat detection logic to match Plater's best practices
- Added proper combat state validation (player in combat, unit in combat, non-PVP)
- Improved code flow to ensure DoT coloring always executes after threat checks
- Enhanced raid tank coordination using `Plater.GetTanks()` and unit target detection

## [2.2.4] - 2025-01-27

### Removed
- **Castbar Border Integration**: Completely removed the automatic castbar border system added in v2.2.2 due to compatibility issues
- **Castbar Width Synchronization**: Removed automatic castbar width matching to prevent conflicts with other addons
- **Castbar Positioning Logic**: Removed scale-aware positioning that was causing display problems

### Changed
- **WoW Version Compatibility**: Updated addon to support WoW 11.2.* and The War Within Season 3
- **Interface Version**: Updated to 110200 for compatibility with upcoming patches
- **Compatibility Matrix**: Now supports WoW versions 11.1.7, 11.2.*, and TWW Season 3

### Technical
- Reverted plater_integration.lua to pre-2.2.2 state for castbar handling
- Updated TOC file interface version to 110200
- Updated compatibility declarations for future-proofing
- Maintained backward compatibility with WoW 11.1.7

## [2.2.2] - 2024-12-19

### Added
- **Automatic Castbar Border Integration**: Castbars now automatically receive borders when nameplate border options are enabled
- **Castbar Width Synchronization**: Enemy castbars automatically resize to match healthbar width exactly
- **Target Scale Awareness**: Castbar borders and positioning automatically adapt to Plater's target scale settings
- **Shared Border Visual**: Castbars positioned to share nameplate bottom border as their "top border"

### Technical
- Lightweight implementation with zero performance overhead
- Automatic activation with existing border settings (no new user options required)
- Integrated into existing Plater nameplate update cycle
- Dynamic scaling support for consistent appearance during targeting
- Non-intrusive border system that doesn't interfere with castbar content

## [2.2.1] - 2024-12-19

### Added
- **Expressway Font Integration**: Complete font system overhaul with modern Expressway font
  - All UI elements now use the Expressway font for a consistent, modern appearance
  - Proper font sizing and styling across all interface components
  - Improved readability with outline effects for better contrast

### Changed
- **Author Credit Styling**: Footer author/version text now displays in gold color for better visibility
- **Font System**: Comprehensive font mapping system for easy maintenance and extensibility

### Technical
- Added `fonts.lua` with complete font object definitions and helper functions
- Updated all GUI files to use the new font system
- Improved font initialization and error handling

## [2.2.0] - 2024-12-19
### Added
- **Enhanced Color Picker**: Completely redesigned color picker with favorite color slots
- **Favorite Colors System**: Save and reuse up to 10 favorite colors across all characters and specs
- **Global Color Persistence**: Favorite colors are saved globally and shared across all characters
- **Draggable Favorites Panel**: Move the favorites panel by dragging the title area for better positioning
- **Smart Color Picker Positioning**: Color picker now intelligently positions itself relative to open dialogs

### Improved
- **GUI Enhancements**: Improved overall user interface with better visual consistency
- **ESC Key Handling**: Fixed inconsistencies with escape key behavior throughout the interface
- **Color Selection Workflow**: Streamlined color selection process with quick access to favorite colors

### Fixed
- **Color Picker Positioning**: Resolved issues with color picker appearing in incorrect positions
- **Dialog Overlap Prevention**: Color picker now avoids overlapping with important UI elements
- **Interface Consistency**: Improved consistency across all color selection interfaces

## [2.1.12] - 2024-08-14
### Fixed
- Fixed an issue where nameplate border colors would not properly reset to Plater defaults when DoTs expire in border-only mode
- Improved integration with Plater's border color system for more consistent behavior
- Border colors now correctly revert without requiring opening the Plater UI

## [2.1.11] - 2024-08-13
### Fixed
- Resolved issue where ESC key would close DotMaster window AND open the game menu; ESC now only closes the DM window if it's open, requiring a second press to open the game menu.
- Changed GUI auto-close trigger from general zone changes to `LOADING_SCREEN_ENABLED` event, so it only closes during actual loading screens (e.g., entering instances, teleporting).
- Addressed an `ADDON_ACTION_BLOCKED` error related to `SetPropagateKeyboardInput` by removing the problematic `HookScript`. The primary `SetPropagateKeyboardInput(true)` and `OnKeyDown` for ESCAPE should maintain desired behavior.

### Removed
- Removed the 'B' key functionality for closing the DotMaster window to simplify keybindings.
- Removed a debug message: "DotMaster window closed due to ZONE_CHANGED. Reopen with /dm or the minimap icon."

## [2.1.10] - 2024-08-12
### Fixed
- Greatly improved ESC key handling - ESC now correctly closes the main window without opening the game menu
- Fixed issue with tabs becoming uninteractive after zone changes 
- Added automatic GUI closure during loading screens to prevent UI issues
- Fixed minimap icon click behavior creating duplicate GUI windows
- Added more robust key event handling and tab system stability

### Added
- Improved tab system with direct frame references for better reliability
- Enhanced error handling throughout the GUI for better stability
- Added support for closing the GUI with B key (Blizzard standard)

## [2.1.9] - 2024-08-01
### Fixed
- Fixed color picker cancel functionality in the tracked spells tab
- Improved error handling for color swatch updates
- Enhanced color picker with safer original value storage

## [2.1.8] - 2024-07-31
### Added
- Always visible interval and brightness sliders for better configuration experience
- Improved UI for expiry flash settings for more intuitive control

### Changed
- Enhanced UI with persistent sliders regardless of feature toggle state
- Improved usability by allowing pre-configuration of settings before enabling features

### Fixed
- Fixed sliders not always appearing in the General tab
- Refined GUI layout for better visual balance and spacing

## [2.1.7] - 2024-07-30
### Added
- Enhanced user guide with more comprehensive information
- Improved Expiry Flash settings with separate interval and brightness controls
- Better CurseForge integration with automatic packaging support

### Changed
- Refined UI layout with better spacing and cleaner visual organization
- Improved settings display and section spacing in the General tab
- Updated documentation with more detailed usage instructions

### Fixed
- Fixed issue with flash settings not persisting after UI reload
- Improved error handling and settings persistence
- Fixed UI spacing inconsistencies

## [2.1.6] - 2024-07-29
### Changed
- Updated CurseForge packaging configuration with proper changelog integration
- Added auto-packaging support through GitHub integration
- Improved distribution workflow with better version control

## [2.1.5] - 2024-07-28
### Fixed
- Fixed flashing issues in Plater integration by optimizing color handling to prevent flickering
- Improved color memory system to ensure consistent display on nameplates
- Fixed reload UI prompt for border thickness and border only mode changes
- Added prompt to reload UI when critical Plater settings are changed

### Changed
- Optimized nameplate color updates to only refresh when actually needed
- Added per-session tracking for border settings changes
- Improved cleanup of stale state when colors are no longer applied

## [2.1.4] - 2024-07-25
### Added
- Added tooltips to all checkboxes in the General tab UI for better usability
- Improved minimap icon click handling for consistent behavior
- Updated tooltip for "Extend Plater Colors to Borders" option to better explain M+ functionality

### Changed
- Updated documentation for a more comprehensive overview of features
- Updated TOC file with compatibility information for WoW 11.1.5 and 11.1.7
- Improved user-facing messages in Plater integration for better clarity

### Fixed
- Fixed click handling on minimap icon for more consistent behavior

## [2.1.3] - 2024-07-05
### Fixed
- Fixed "for limit must be a number" error when using Find My Dots feature
- Added safety checks for numTabs property to prevent errors
- Improved error handling in tab switching functionality
- Enhanced Find My Dots section with additional safety checks

### Added
- UI Enhancement: Close all child windows when main DotMaster window is closed
  - Improves user experience by ensuring all dialog windows close together
  - Prevents orphaned windows when closing the main interface
  - Includes help window, combination dialogs, spell selection and Find My Dots UI

### Fixed
- Fixed issue where the DotMaster guide window would remain open when closing the main window

## [2.1.2] - 2024-07-05
### Fixed
- Fixed "for limit must be a number" error when using Find My Dots feature
- Added safety checks for numTabs property to prevent errors
- Improved error handling in tab switching functionality
- Enhanced Find My Dots section with additional safety checks

### Added
- UI Enhancement: Close all child windows when main DotMaster window is closed
  - Improves user experience by ensuring all dialog windows close together
  - Prevents orphaned windows when closing the main interface
  - Includes help window, combination dialogs, spell selection and Find My Dots UI

### Fixed
- Fixed issue where the DotMaster guide window would remain open when closing the main window

## [2.1.1] - 2023-10-08
### Fixed
- Fixed combinations persistence issue across UI reloads
- Added backward compatibility for legacy data structures where combinations were saved as 'combos'
- Improved database handling and stability for combinations

## [2.1] - 2024-06-20
### Added
- Enhanced database reset functionality with complete wipe and fresh state initialization
- Added support for all classes and specializations in database reset
- Improved debug messages for reset operations

### Fixed
- Fixed spell priority implementation in Plater integration - lower numbers now correctly represent higher priority
- Added proper normalization for enabled/disabled and tracked/untracked values (0/1 to true/false)
- Resolved tab selection issue causing Lua errors (`'for' limit must be a number`)
- Fixed database tab and tracked spells tab refresh after database reset
- Enhanced spell selection UI to properly filter based on tracked status

### Changed
- Improved color handling for nameplates with optimized priority sorting
- Enhanced error handling throughout the addon
- Updated documentation for v2.1 release

## [2.0.2] - 2023-12-15
### Added
- Show spec icons next to spec names in the database tab
- Updated tracked spells tab to only load and modify data from the current specialization's array
- Updated combinations tab to work with the current specialization's array
- Resolved an issue where the "save combination" button in the New Combination dialog would delete the entire spell database
- Fixed a critical bug where clicking reorder arrows would cause all spells to disappear
- Improved error handling and debug messages throughout

## [2.0.1] - 2023-11-25
### Fixed
- Resolved an issue where the border color on nameplates would not correctly revert to Plater's default when "Use Borders for DoT Tracking" was enabled and a tracked DoT/combination expired
- Corrected a UI bug in the main settings panel where previously selected tabs would not visually unhighlight when a new tab was clicked

## [2.0.0] - 2023-11-22
### Added
- Major version release with complete feature set
- Enhanced Plater integration with improved border handling
- Comprehensive GUI for all addon settings
- Full class and specialization support
- Advanced DoT combination tracking
- Customizable expiry flash functionality

### Changed
- Code architecture refactored for improved performance
- Simplified user experience with better defaults
- Improved settings management
- Updated documentation 