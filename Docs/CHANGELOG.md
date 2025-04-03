# DotMaster Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
- Performance optimizations for combat situations
- Additional spell database entries
- Enhanced nameplate detection for edge cases
- Improved Tracked Spells interface:
  - Redesigned spell row layout with combined spell icon, name, and ID
  - Swapped order buttons (down on left, up on right) with visual indicators for first/last spells
  - Added responsive untrack button with better visibility
  - Fixed scrollbar overlap issues
  - Increased window width for better usability
  - Improved save behavior (all changes now trigger immediate database save)

## [0.5.3] - 2024-08-30 (GUI Fix)

### Fixed
- Removed duplicate GUI creation code to prevent conflicts
- Ensured the proper resizable frame implementation is used
- Improved GUI initialization reliability
- Enhanced window resizing functionality

## [0.5.2] - 2024-08-22 (Debug System Update)

### Added
- Comprehensive debug console with category-based filtering
- Dedicated `/dmdebug` command for all debugging options
- Color-coded debug messages by category (general, spell, nameplate, gui, performance)
- Debug message export and copy functionality
- Console output toggle for debug messages
- Debug category filtering through UI and slash commands

### Changed
- Improved error handling in all debug functions
- Better WoW API compatibility with fallbacks for different client versions
- Enhanced debug message formatting with timestamps and categories
- More user-friendly debug options in the General tab

### Fixed
- Improved stability with defensive coding patterns for error handling
- Added backward compatibility for existing debug functions
- Better scrolling behavior in the debug console
- Consolidated all debug-related settings in one place

## [0.5.1] - 2024-08-15 (Documentation Update)

### Changed
- Consolidated README files into a clearer structure
- Enhanced main README.md with user-focused information
- Added Docs/DOCUMENTATION_GUIDE.md as a guide to all documentation
- Updated CURRENT_STATUS.md to reflect current state
- Improved navigation between documentation files
- Ensured all links between files work correctly

## [0.5.0] - 2024-08-01 (Stability Release)

### Changed
- Restored codebase to version 0.4.0 for improved stability
- Returned to pre-restructuring file naming for better compatibility
- Preserved all validation scripts and documentation from later versions
- Updated TOC file to reference the restored file structure

### Added
- Preserved the `dmcheck` validation tools for pre-game testing
- Maintained full documentation from 0.4.2
- Proper version tracking in CHANGELOG and TOC

### Fixed
- Addressed stability issues in the 0.4.x development branch
- Simplified codebase while maintaining core functionality

## [0.4.2] - 2024-07-15 (Development Build)

### Added
- New `dmcheck` validation tool for pre-game testing
- Automated verification of critical API usage

### Fixed
- ✅ **Fixed CRITICAL API ISSUE**: Resolved the GetSpellInfo API issue by using C_Spell.GetSpellInfo() throughout the codebase
- Enhanced development workflow with better error detection
- Improved code validation process to prevent common errors

## [0.4.1] - 2024-06-19 (Development Build)

### Changed
- Complete code restructuring with prefix-based file organization:
  - Core files (dm_*): Core functionality, debug, utils, settings
  - Nameplate files (np_*): Nameplate detection and coloring
  - Spell files (sp_*): Spell database and utilities
  - UI files (ui_*): User interface components
  - Find My Dots (fmd_*): Find My Dots feature
- Improved module pattern with better encapsulation
- Enhanced debugging with module-specific messages
- More consistent function naming and organization
- Added comprehensive CODE_STRUCTURE.md documentation

### Fixed
- Improved error handling throughout the codebase
- Better module initialization sequence
- More robust dependency management

## [0.4.0] - 2024-06-19 (Stable Release)

### Changed
- Restored a previously working version of the addon 
- Realigned version numbering to match development milestones
- This version provides stable functionality without the critical API issues

### Fixed
- Resolved compatibility issues with recent WoW client versions
- Fixed nameplate detection and coloring functionality
- Ensured stable "Find My Dots" feature operation

## [0.3.0] - 2024-03-31 (Development Build)

### Added
- Complete architectural rebuild with Ace3 framework
- Enhanced debugging system with categorized logging
- Full modular file organization for better maintainability
- Comprehensive spell database with classification by class/spec
- "Find My Dots" feature with visual target tracking
- Advanced GUI system with tabs and sections
- Profile support via AceDB-3.0
- Minimap button for quick access

### Fixed
- Invalid function calls in nameplate detection
- Performance issues when tracking multiple targets
- Color persistence issues when nameplates refresh
- Installed missing libraries (LibDataBroker-1.1 and LibDBIcon-1.0) for minimap button functionality
- Corrected paths in embeds.xml for all libraries

### Changed
- Completely overhauled configuration UI
- Improved visual appearance of dot indicators
- Enhanced color management system
- More efficient event handling

## [0.2.1] - 2024-03-15

### Fixed
- Critical bug with nameplate coloring in raids
- Lua error when entering dungeons

### Changed
- Improved performance of aura scanning

## [0.2.0] - 2024-03-10

### Added
- Basic configuration panel
- Color customization for each spell
- Class-specific spell detection
- Simple profile system

### Fixed
- Nameplate detection in group scenarios
- Memory leak in aura tracking

## [0.1.1] - 2024-03-01

### Fixed
- Initial compatibility issues with other nameplate addons
- Error when targeting neutral NPCs

## [0.1.0] - 2024-02-25

### Added
- Initial release
- Basic nameplate coloring functionality
- Spell detection for major DoT classes
- Simple commands for enabling/disabling features

## [0.2.0-beta4] - 2023-03-15
### Fixed
- Added SafePrint function to both Core/Init.lua and DotMaster.lua to safely handle logging before Debug is initialized
- Restructured initialization sequence to ensure Debug is properly initialized before calling SetupEvents
- Fixed "attempt to call method 'Debug' (a nil value)" error in Core/Init.lua
- Made extensive improvements to null checking throughout initialization code
- Added validation for database and profile structures before attempting to use them
- Commented out auto-execution of SetupEvents at the end of Init.lua
- Fixed call sequence to ensure SetupEvents is called at the right time from OnInitialize
- Updated Debug.lua to add safety checks ensuring database is properly initialized
- Added additional safeguards for database structure and profile initialization

## [0.2.0-beta3] - 2023-03-01
### Fixed
- Fixed critical "attempt to index local 'options' (a function value)" error in Options UI
- Fixed "Attempting to rehook already active hook" error in NameplateTracker module
- Fixed "attempt to call method 'Debug' (a nil value)" error in initialization sequence
- Improved error handling throughout to make the addon more robust
- Added safety checks for Debug, SpellDB, and UI modules to prevent errors
- Updated RefreshDatabaseList and RefreshTrackingList to properly handle options table
- Added safeguards for missing or invalid module functions
- Improved minimap button creation with enhanced error checking
- Fixed potential nil reference errors in SaveState and ApplySettings
- Added pcall protection for potentially unstable UI functions
- Enhanced library dependency checking
- Added module registration tracking to prevent duplicate initialization
- Fixed initialization sequence to ensure Debug is available before use

## [0.2.0-beta2] - 2023-02-15
### Fixed
- Fixed InterfaceOptionsFrame_OpenToCategory error by updating configuration UI to use the modern Settings API
- Added compatibility with the WoW Dragonflight UI
- Added fallback for older client versions

## [0.2.0-beta1] - 2023-02-01
### Added
- Implemented hybrid approach to nameplate tracking combining direct WoW API with Ace3
- Added dedicated nameplate event frame with proper event handling
- Implemented color tracking and restoration for nameplates
- Added default spell configurations for common DoT spells
### Fixed
- Fixed critical frame initialization issues
- Optimized ScanUnitAuras function based on working implementation
- Fixed updateNameplates function to work reliably
- Updated configuration UI to use the modern Settings API instead of deprecated InterfaceOptionsFrame

## [0.1.1] - 2023-01-15
### Fixed
- Fixed missing UI loading and debug commands functionality
- Added version property to DotMaster table
- Improved debug log export with version information
- Ensured version consistency across all files

## [0.1.0] - 2023-01-01
### Added
- Initial release
- Basic DoT tracking on enemy nameplates
- Simple "Find My Dots" window
- Configuration UI
- Support for common DoT spells

## Version 0.6.9
- UI Improvements for the Tracked Spells tab:
  - Fixed scrollbar overlap issue by properly accounting for scrollbar width
  - Improved column spacing and alignments throughout the interface
  - Renamed "Untrack" to "Tracking" in the header and "Remove" in the button for clarity
  - Increased name field width to prevent spell name truncation
  - Improved button positioning and alignments for better visual harmony
  - Better centered checkboxes and order arrows for a cleaner layout
  - Adjusted spacing between UI elements for optimal readability

## Version 0.6.8
## UI Improvements (Tracked Spells Tab)

- Enhanced visibility of the table with proper spacing and borders
- Fixed the scrollbar to appear only when needed
- Adjusted background margins to create perfect symmetry
- Improved layout with optimized column widths for better readability
- Fixed Remove button positioning and alignment
- Optimized content layout for visual balance
- Added collapsible class-based grouping for spells with class-colored headers
- Implemented expand/collapse functionality for each class group
- Added class icons for better visual identification
- Maintained ordering by priority within each class group

// ... existing code ... 