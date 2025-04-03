# DotMaster Current Status

This document outlines the current development status of the DotMaster addon. It's intended to be regularly updated as development progresses.

## Project Status

### Current Status
- **Project**: DotMaster
- **Current Version**: 0.7.0
- **Status**: Active Development
- **Last Updated**: April 3, 2024
- **WoW Compatibility**: World of Warcraft: The War Within (11.1.0)

## Current Version Information

- **Current Version**: 0.7.0
- **Branch Status**:
  - **main**: Contains the latest stable release (v0.6.9)
  - **develop**: Active development branch (v0.7.0)
    - This branch is always used for in-game testing

## Development Progress

| Feature | Status | Notes |
|---------|--------|-------|
| Core Framework | ✅ STABLE | Reverted to v0.4.0 stable codebase |
| Nameplate Tracking | ✅ STABLE | Visual indicators, duration, position |
| Find My Dots | ✅ STABLE | Window showing all active DoTs grouped by target |
| Spell Database | ✅ STABLE | Pre-defined database of DoT spells for all classes |
| Configuration UI | ✅ STABLE | Options panel with profile support |
| Minimap Button | ✅ STABLE | Integration with LibDBIcon |
| Debug System | ✅ STABLE | Comprehensive logging with category-based filtering |
| API Compatibility | ⚠️ NEEDS REVIEW | Critical API changes still need implementation |
| Pre-Game Validation | ✅ MAINTAINED | Preserved dmcheck tool for validation |
| Documentation | ✅ UPDATED | Consolidated documentation structure |

## Current Development Focus

- Ensuring compatibility with World of Warcraft 11.1.0 (The War Within)
- Adapting to UI changes and new nameplate implementation in The War Within
- Improving the addon initialization process and SavedVariables handling
- Testing the new database system with various spell data
- Ensuring proper loading sequence for saved data
- Enhancing debug capabilities for better troubleshooting

## Known Issues

1. **API Compatibility**: Still need to ensure all parts of the addon use `C_Spell.GetSpellInfo()`
2. **Performance**: May experience frame drops during combat with many targets
3. **Nameplate Detection**: Occasional issues detecting all nameplates in crowded scenarios

## Next Development Steps

1. Further refine the database structure for better performance
2. Optimize nameplate processing for improved framerates
3. Enhance UI responsiveness in high-stress scenarios
4. Add more comprehensive error recovery mechanisms
5. Implement more user-requested quality of life features

## Recent Changes

The most significant recent changes include:

- ✅ **Tracked Spells UI Redesign**: Completely redesigned the tracked spells interface with improved usability, better layout, and immediate save functionality
- ✅ **WoW 11.1.0 Update**: Started compatibility updates for The War Within expansion
- ✅ **TOC Update**: Updated Interface version to 110100 for The War Within
- ✅ **Initialization System Refactoring**: Implemented bootstrap.lua for proper SavedVariables loading sequence
- ✅ **Database Handling Enhancement**: Fixed issues with saved database loading and persistence
- ✅ **UI Improvements**: Fixed various UI issues in the database tab
- ✅ **Debug Console Enhancements**: Added database-specific debug categories

Prior to that:
- ✅ **Fixed CRITICAL API ISSUE**: Resolved the GetSpellInfo API issue by using C_Spell.GetSpellInfo() throughout the codebase
- ✅ **Added dmcheck Tool**: Created validation tools to catch common errors before in-game testing
- ✅ **Enhanced Development Process**: Improved code validation workflows

Refer to the [CHANGELOG.md](CHANGELOG.md) for a more detailed list of changes.

## Test Environment

- World of Warcraft Retail Version: 11.1.0
- Development Path: `F:\World of Warcraft\_retail_\Interface\AddOns\DotMaster`
- Testing Environments: Solo play, Dungeons, Raids, World content
- Test Classes: Warlock, Shadow Priest, Affliction Warlock

## Version 0.6.9

The addon has been updated with significant UI improvements to the Tracked Spells tab. The new design addresses issues with scrollbar overlapping, improves element spacing and alignment, and enhances the overall user experience. Key improvements include:

1. **Fixed scrollbar overlap** - Properly accounted for scrollbar width in all calculations
2. **Improved spacing and proportions** - Optimized column widths and spacing for better readability
3. **Clearer terminology** - Renamed elements for better clarity ("Untrack" → "Tracking"/"Remove")
4. **Better alignment** - Centered elements and improved alignment of all UI components
5. **Enhanced spell name display** - Increased the width allocation for spell names to prevent truncation

These improvements follow professional UI/UX design principles, creating a more polished and user-friendly interface.

## Upcoming Tasks

- Continue enhancing the Find My Dots window UI
- Implement spell auto-detection improvements
- Add additional spell database entries
- Performance optimizations for nameplate coloring
- Expand documentation for API usage

## Known Issues

1. **API Compatibility**: Still working on ensuring all parts of the addon use `C_Spell.GetSpellInfo()`
2. **Performance**: May experience frame drops during combat with many targets
3. **Nameplate Detection**: Occasional issues detecting all nameplates in crowded scenarios 