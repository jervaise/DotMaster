# DotMaster Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
- Performance optimizations for combat situations
- Additional spell database entries
- Enhanced nameplate detection for edge cases

## [0.4.1] - 2024-07-01 (Beta Release)

### Fixed
- Resolved critical "attempt to call field 'GetAuraDataByUnit' (a nil value)" error in Find My Dots feature
- Updated aura detection methods to use AuraUtil.ForEachAura instead of C_UnitAuras.GetAuraDataByUnit for compatibility
- Fixed aura scanning in nameplate detection module
- Ensured consistent API usage across all aura detection points in the addon
- Improved code organization in restructured modules

### Changed
- Standardized aura detection methods across all modules
- Added better error handling and robustness for API calls

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