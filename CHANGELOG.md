# DotMaster Changelog

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

## [2.0.1] - YYYY-MM-DD
### Fixed
- Resolved an issue where the border color on nameplates would not correctly revert to Plater's default when "Use Borders for DoT Tracking" was enabled and a tracked DoT/combination expired. This involved ensuring DotMaster explicitly set the border to opaque black before Plater's refresh to clear any lingering color states.
- Corrected a UI bug in the main settings panel where previously selected tabs would not visually unhighlight (return to their inactive color) when a new tab was clicked. This was fixed by properly targeting the tab's background texture for color changes.

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

## [1.0.9] - YYYY-MM-DD
### Added
- "Plater Integration" button in DotMaster GUI footer: Appears if the "DotMaster Integration" Plater mod is not detected, allowing users to inject it.
- Functionality for the "Plater Integration" button to inject the pre-defined "DotMaster Integration" Plater mod string into Plater using `Plater.ImportScriptString`.
- Safety check within the "DotMaster Integration" Plater mod: The mod's hooks will now only execute if the DotMaster addon itself is loaded and enabled, preventing errors if DotMaster is removed or disabled. This check is injected when DotMaster updates/installs the Plater mod.

### Changed
- Refined the Plater mod injection process: DotMaster settings are now pushed to the Plater mod after a short delay post-injection, and the GUI footer status is updated more reliably.

### Fixed
- Resolved Lua compilation errors in Plater (`unexpected symbol near 'if'`) that occurred when injecting the DotMaster presence safety check. The check is now correctly placed within the function bodies of the Plater mod's hooks.

## [1.0.8] - PREVIOUS_DATE

### Fixes
- Fixed issue with settings not persisting correctly between UI reloads
- Added proper tracking for enabled/disabled state in the border settings reload popup
- Fixed border thickness control when Border-only mode is disabled - now properly reverts to Plater's settings
- Improved change detection to prevent unnecessary reload UI popups
- Enhanced debug logging for easier troubleshooting
- Fixed false positive change detection that was causing reload UI popups to appear unnecessarily

## 1.0.7 (Previous version)

### New Features:
- **Auto-Save Functionality**: Settings now automatically save when changed without requiring the Save button
- **Instant DotMaster Integration**: Changes are pushed to Plater/DotMaster Integration immediately
- **Border Thickness Reload Prompt**: Added UI popup to prompt for reload when border thickness is changed
- **Direct Save Command**: Added `/dm push` slash command to force push settings to DotMaster Integration

### Improvements:
- Improved border thickness handling with more reliable saving
- Added visual status indicators for auto-save process
- Added debugging output for troubleshooting thickness changes
- Improved reliability of settings when closing the DotMaster window

### Fixes:
- Fixed issue where border thickness changes weren't properly saved
- Fixed potential issue with settings not being pushed to DotMaster Integration
- Ensured thickness changes are properly detected and applied

## 2.1 (Stable Release - 2023-10-05)

### Added
- Support for combination colors (track multiple DoTs and show a unique color when all are present)
- New UI for creating and managing combinations
- Added proper type conversion for enabled/disabled and tracked/untracked status

### Fixed
- Fixed critical issue with reorder arrows causing spells to disappear
- Enhanced Plater integration reliability
- Fixed issues with the coloration of DoTs in Plater 