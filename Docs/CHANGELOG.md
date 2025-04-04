# DotMaster Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Version History

### Version 0.9.12 (2023-07-25)
- **Added**: Flashing feature for DoTs that are about to expire
- **Added**: Configurable threshold (1-8 seconds) for when to start flashing
- **Enhanced**: Flash animation supports both border-only and full nameplate coloring modes
- **Technical**: Integrated with Plater's flash animation system for smooth visual feedback

### Version 0.9.11 (2023-07-15)
- **Added**: Border-only coloring mode that colors just the nameplate border instead of the entire nameplate
- **Added**: Configurable border thickness when using border-only coloring
- **Enhanced**: Improved integration with Plater's border system
- **Technical**: Added compatibility with Plater's customBorderColor functionality

### Version 0.9.10 (2023-07-10)
- **Fixed**: Nameplate coloring now works outside of combat (removed combat check restriction)
- **Fixed**: Eliminated the color flicker when leaving combat by hooking into Plater's color reset functions
- **Fixed**: Improved integration with Plater's threat system to preserve colors consistently
- **Enhanced**: More robust nameplate color handling for all combat state transitions
- **Technical**: Updated code to properly hook into Plater's core nameplate functions

### Version 0.9.9 (2023-06-18)
- Simplified the "Detected Dots" UI for a cleaner look
- Removed decorative borders, icons and fancy visual elements from dot detection dialogs
- Fixed error with SetBackdrop by adding BackdropTemplate to frame creation
- Improved message clarity when no new dots are found
- Enhanced overall user experience with more straightforward interface

### Version 0.9.8 (2023-06-15)
- Improved General tab UI with accordion-style information panels
- Adjusted combination bars height to 40px for consistency with class headers
- Removed Debug Console button (now only accessible via /dmdebug command)
- Added Find My Dots button to the Tracked Spells tab
- Fixed various UI layout and spacing issues
- Improved warning message visibility

### Version 0.9.7 (2023-04-18)

#### Fixed
- Fixed combinations appearing expanded by default when creating new ones
- Modified the initialization logic to ensure combinations start collapsed
- Updated initialization of row.isExpanded to ensure consistent behavior
- Improved the isExpanded flag handling in dialog for new combinations
- Fixed default expanded state in multiple places to ensure consistent behavior

### Version 0.9.6 (2023-04-17)

#### Added
- Added warning popups when saving combinations with missing name or no spells
- Added click handler for color swatches in the combinations list
- Added reminder in combination tab info text about combination priority

#### Fixed
- Fixed color picker functionality in main combinations tab list
- Fixed color picker compatibility with both standard WoW UI and ElvUI
- Fixed spacing and positioning in combination dialog
- Improved UI consistency across all windows
- Fixed scrollbar issues in combination spell list

#### Changed
- Standardized window dimensions (350x450px) across all dialogs
- Improved window positioning with cascading layout
- Adjusted UI element spacing for visual consistency

### Version 0.9.4 (2023-04-16)

#### Added
- Added addon icon to interface list panel
- Improved dependency handling for Plater requirement
- Added warning system when Plater is not installed
- Added new Combinations tab for managing DoT combinations on targets
- Added database structure for storing and tracking DoT combinations
- Added interface for creating custom combinations of multiple DoTs
- Added priority-based combination system that overrides individual DoT colors

#### Changed
- Updated UI title to highlight Plater integration with colored text
- More robust checkbox text handling for loading screens
- More efficient class-based filtering for DoT detection
- Reorganized tab structure to include the new Combinations feature
- Improved nameplate detection with unified DoT checking function

### Version 0.9.3 (2023-04-15)

#### Added
- Force Threat Color feature for Plater integration
  - Now shows appropriate threat colors for tanks losing aggro or DPS gaining aggro
  - Uses player's Plater profile color settings
- Escape key now properly closes the DotMaster UI
- Improved alignment of checkboxes in the General tab

#### Changed
- Updated General tab with more creative title and bullet point description
- Improved Plater integration for more consistent behavior

### Version 0.9.1 (2023-04-10)

- **New Features:**
  - Added minimap icon for quick access to DotMaster and Find My Dots
  - Implemented class-colored UI borders that match player's class
  - Improved database tab search to include class and spec name searches
  - Auto-opening debug console option for development environment

- **User Interface Improvements:**
  - Redesigned General tab with cleaner layout and improved spacing
  - Added option to toggle minimap icon visibility in General settings
  - Added main addon icon to the General tab
  - Improved spacing between title and description text in all tabs
  - Centered UI elements for better visual consistency

- **Bug Fixes:**
  - Fixed critical issue with Plater nameplate colors not properly returning to Plater's configured threat colors
  - Improved integration with Plater's color system for more reliable behavior
  - Enhanced nameplate color restoration when DoTs expire
  - Added additional debug logging for nameplate color changes

### Version 0.9.0 (2023-04-03)

- **Major Enhancements:**
  - Fixed color picker functionality by properly including gui_colorpicker.lua in TOC file
  - Added debug category for color picker module with dedicated ColorPickerDebug function
  - Updated nameplate detection to use modern C_UnitAuras API with fallbacks for compatibility
  - Improved error handling throughout the addon

- **Bug Fixes:**
  - Fixed bug with color swatch not working in the Tracked Spells tab
  - Fixed initialization error in gui_debug.lua with local DeepCopy implementation
  - Fixed "attempt to call global 'UnitAura'" error by modernizing aura detection code
  - Ensured the color picker functionality is properly accessible from all tabs

- **Code Quality:**
  - Added robust fallbacks for aura detection using AuraUtil.ForEachAura
  - Improved module loading by using _G table for global function exports
  - Enhanced debugging with the new colorpicker category

### Version 0.8.7 (YYYY-MM-DD)

- **Bug Fixes:**
  - Fixed TOC file references to match actual file names
  - Added missing bootstrap.lua to TOC file
  - Fixed debug.lua reference (changed to gui_debug.lua)
  - Added missing utils.lua and gui.lua to TOC file
  - Improved addon load reliability

### Version 0.8.0 (YYYY-MM-DD)

- **Tracked Spells Tab Enhancements:**
  - Redesigned spell rows to include enable checkbox, color picker swatch, and priority arrows.
  - Removed spec grouping; spells now listed directly under class headers.
  - Removed search functionality.
  - Removed indentation for a cleaner look.
  - Implemented mouse wheel scrolling and removed visual scrollbar.
  - Player's current class is now displayed first.
  - Class headers (except player's) default to collapsed state.
  - Adjusted row/header heights and alternating background color contrast.
- **Database Tab:**
  - Mirrored Tracked Spells tab UI changes: removed spec grouping, removed search, removed indentation, implemented mouse wheel scrolling, player class first, initial collapse state.
- **Bug Fixes:**
  - Fixed layout issues causing elements to overflow or disappear.
  - Corrected errors related to color picker integration and nil values.
  - Fixed `OnClick` script errors on non-button frames.
  - Resolved issue where scrolling caused horizontal shifting.
- **Code Quality:**
  - Centralized version number definition.
  - Integrated temporary debug prints into the addon's debug console system.

### Version 0.7.2 (YYYY-MM-DD)

- Added a new "Tracked Spells" tab to the GUI.
- This tab displays only spells marked as tracked in the database.
- Included an "Untrack" button on each spell row in the new tab.
- Updated Database tab logic to refresh Tracked Spells tab on changes.
- Updated spell selection dialog to refresh Tracked Spells tab.
- Fixed class collapsing functionality in Tracked Spells tab.

### Version 0.7.1 (YYYY-MM-DD)

- Initial setup with basic features.
- Nameplate coloring.
- Find My Dots window.
- Spell Database tab.
- Configuration UI.
- Debug Console.

### Version 0.7.2
- Fixed UI alignment issues in the tracked spells tab
- Improved header and content alignment in tracked spells list
- Added proper spacing between class headers and spell rows
- Fixed class collapse button functionality
- Enhanced visual consistency across the tracked spells interface
- Ensured perfect alignment of "Tracking" header with Remove buttons
- Centered spell count text with Remove buttons for visual clarity
- Added consistent vertical spacing for better readability

### Version 0.7.1
- Updated documentation structure with consolidated developer guides
- Created comprehensive Debug System documentation
- Improved version management documentation and workflow
- Removed obsolete development diary in favor of structured documentation
- Enhanced development process documentation with clear guidelines

### Version 0.7.0
- Version bump for continued development
- Branch management and repository organization
- Documentation updates

### [Unreleased]
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

### [0.5.3] - 2024-08-30 (GUI Fix)

#### Fixed
- Removed duplicate GUI creation code to prevent conflicts
- Ensured the proper resizable frame implementation is used
- Improved GUI initialization reliability
- Enhanced window resizing functionality

### [0.5.2] - 2024-08-22 (Debug System Update)

#### Added
- Comprehensive debug console with category-based filtering
- Dedicated `/dmdebug` command for all debugging options
- Color-coded debug messages by category (general, spell, nameplate, gui, performance)
- Debug message export and copy functionality
- Console output toggle for debug messages
- Debug category filtering through UI and slash commands

#### Changed
- Improved error handling in all debug functions
- Better WoW API compatibility with fallbacks for different client versions
- Enhanced debug message formatting with timestamps and categories
- More user-friendly debug options in the General tab

#### Fixed
- Improved stability with defensive coding patterns for error handling
- Added backward compatibility for existing debug functions
- Better scrolling behavior in the debug console
- Consolidated all debug-related settings in one place

### [0.5.1] - 2024-08-15 (Documentation Update)

#### Changed
- Consolidated README files into a clearer structure
- Enhanced main README.md with user-focused information
- Added Docs/DOCUMENTATION_GUIDE.md as a guide to all documentation
- Updated CURRENT_STATUS.md to reflect current state
- Improved navigation between documentation files
- Ensured all links between files work correctly

### [0.5.0] - 2024-08-01 (Stability Release)

#### Changed
- Restored codebase to version 0.4.0 for improved stability
- Returned to pre-restructuring file naming for better compatibility
- Preserved all validation scripts and documentation from later versions
- Updated TOC file to reference the restored file structure

#### Added
- Preserved the `dmcheck` validation tools for pre-game testing
- Maintained full documentation from 0.4.2
- Proper version tracking in CHANGELOG and TOC

#### Fixed
- Addressed stability issues in the 0.4.x development branch
- Simplified codebase while maintaining core functionality

### [0.4.2] - 2024-07-15 (Development Build)

#### Added
- New `dmcheck` validation tool for pre-game testing
- Automated verification of critical API usage

#### Fixed
- ✅ **Fixed CRITICAL API ISSUE**: Resolved the GetSpellInfo API issue by using C_Spell.GetSpellInfo() throughout the codebase
- Enhanced development workflow with better error detection
- Improved code validation process to prevent common errors

### [0.4.1] - 2024-06-19 (Development Build)

#### Changed
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

#### Fixed
- Improved error handling throughout the codebase
- Better module initialization sequence
- More robust dependency management

### [0.4.0] - 2024-06-19 (Stable Release)

#### Changed
- Restored a previously working version of the addon 
- Realigned version numbering to match development milestones
- This version provides stable functionality without the critical API issues

#### Fixed
- Resolved compatibility issues with recent WoW client versions
- Fixed nameplate detection and coloring functionality
- Ensured stable "Find My Dots" feature operation

### [0.3.0] - 2024-03-31 (Development Build)

#### Added
- Complete architectural rebuild with Ace3 framework
- Enhanced debugging system with categorized logging
- Full modular file organization for better maintainability
- Comprehensive spell database with classification by class/spec
- "Find My Dots" feature with visual target tracking
- Advanced GUI system with tabs and sections
- Profile support via AceDB-3.0
- Minimap button for quick access

#### Fixed
- Invalid function calls in nameplate detection
- Performance issues when tracking multiple targets
- Color persistence issues when nameplates refresh
- Installed missing libraries (LibDataBroker-1.1 and LibDBIcon-1.0) for minimap button functionality
- Corrected paths in embeds.xml for all libraries

#### Changed
- Completely overhauled configuration UI
- Improved visual appearance of dot indicators
- Enhanced color management system
- More efficient event handling

### [0.2.1] - 2024-03-15

#### Fixed
- Critical bug with nameplate coloring in raids
- Lua error when entering dungeons

#### Changed
- Improved performance of aura scanning

### [0.2.0] - 2024-03-10

#### Added
- Basic configuration panel
- Color customization for each spell
- Class-specific spell detection
- Simple profile system

#### Fixed
- Nameplate detection in group scenarios
- Memory leak in aura tracking

### [0.1.1] - 2024-03-01

#### Fixed
- Initial compatibility issues with other nameplate addons
- Error when targeting neutral NPCs

### [0.1.0] - 2024-02-25

#### Added
- Initial release
- Basic nameplate coloring functionality
- Spell detection for major DoT classes
- Simple commands for enabling/disabling features

### [0.2.0-beta4] - 2023-03-15
#### Fixed
- Added SafePrint function to both Core/Init.lua and DotMaster.lua to safely handle logging before Debug is initialized
- Restructured initialization sequence to ensure Debug is properly initialized before calling SetupEvents
- Fixed "attempt to call method 'Debug' (a nil value)" error in Core/Init.lua
- Made extensive improvements to null checking throughout initialization code
- Added validation for database and profile structures before attempting to use them
- Commented out auto-execution of SetupEvents at the end of Init.lua
- Fixed call sequence to ensure SetupEvents is called at the right time from OnInitialize
- Updated Debug.lua to add safety checks ensuring database is properly initialized
- Added additional safeguards for database structure and profile initialization

#### Changed
- Added warning popups when saving combinations with missing name or no spells
- Added click handler for color swatches in the combinations list
- Added reminder in combination tab info text about combination priority

### [0.2.0-beta3] - 2023-03-01
#### Fixed
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

#### Changed
- Standardized window dimensions (350x450px) across all dialogs
- Improved window positioning with cascading layout
- Adjusted UI element spacing for visual consistency

### [0.2.0-beta2] - 2023-02-15
#### Fixed
- Fixed InterfaceOptionsFrame_OpenToCategory error by updating configuration UI to use the modern Settings API
- Added compatibility with the WoW Dragonflight UI
- Added fallback for older client versions

### [0.2.0-beta1] - 2023-02-01
#### Added
- Implemented hybrid approach to nameplate tracking combining direct WoW API with Ace3
- Added dedicated nameplate event frame with proper event handling
- Implemented color tracking and restoration for nameplates
- Added default spell configurations for common DoT spells
#### Fixed
- Fixed critical frame initialization issues
- Optimized ScanUnitAuras function based on working implementation
- Fixed updateNameplates function to work reliably
- Updated configuration UI to use the modern Settings API instead of deprecated InterfaceOptionsFrame

### [0.1.1] - 2023-01-15
#### Fixed
- Fixed missing UI loading and debug commands functionality
- Added version property to DotMaster table
- Improved debug log export with version information
- Ensured version consistency across all files

### [0.1.0] - 2023-01-01
#### Added
- Initial release
- Basic DoT tracking on enemy nameplates
- Simple "Find My Dots" window
- Configuration UI
- Support for common DoT spells

### Version 0.6.9
- UI Improvements for the Tracked Spells tab:
  - Fixed scrollbar overlap issue by properly accounting for scrollbar width
  - Improved column spacing and alignments throughout the interface
  - Renamed "Untrack" to "Tracking" in the header and "Remove" in the button for clarity
  - Increased name field width to prevent spell name truncation
  - Improved button positioning and alignments for better visual harmony
  - Better centered checkboxes and order arrows for a cleaner layout
  - Adjusted spacing between UI elements for optimal readability

### Version 0.6.8
#### UI Improvements (Tracked Spells Tab)

- Enhanced visibility of the table with proper spacing and borders
- Fixed the scrollbar to appear only when needed
- Adjusted background margins to create perfect symmetry
- Improved layout with optimized column widths for better readability
- Fixed Remove button positioning and alignment
- Optimized content layout for visual balance

### [0.8.6] - 2024-04-10 (Database Improvements)

#### Fixed
- Fixed issue requiring multiple clicks to save spells to database
- Fixed friendly message persisting in Database tab when spells are present
- Improved database save and refresh operations
- Enhanced UI state management for Database and Tracked Spells tabs

### [0.8.5] - 2024-04-10 (UI Refinements)

#### Changed
- Improved Database tab UI:
  - Adjusted spacing between table header and class headers to 3px
  - Enhanced search functionality to include class names in search results
  - Fixed search bar placeholder text behavior
  - Standardized info area height to 50px across all tabs
  - Centered info text vertically in info areas
  - Set search bar width to 430px and centered positioning

#### Fixed
- Resolved issues with search bar placeholder text not clearing properly
- Fixed vertical alignment of info text across all tabs
- Corrected spacing and margins in the Tracked Spells tab
- Addressed LAYOUT variable access in RefreshTrackedSpellTabList function

// ... existing code ... 