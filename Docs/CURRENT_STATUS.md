# DotMaster Current Status

## Project Overview

The DotMaster addon is a tool for tracking damage-over-time (DoT) effects on enemy nameplates and providing visual feedback to the player.

- **Release Status**: Beta
- **Current Version**: 1.0.0 (Beta)
- **Compatibility**: World of Warcraft: The War Within (11.1.0)

## Branches

- **main**: Stable release (v1.0.0)
- **beta**: Current beta release (v1.0.0)
- **develop**: Active development branch (v1.0.0)
- **feature/X**: Various feature branches for specific components

## Project Status

### Current Status
- **Project**: DotMaster
- **Current Version**: 1.0.0 (Beta)
- **Status**: Beta Testing
- **Last Updated**: April 4, 2024
- **WoW Compatibility**: World of Warcraft: The War Within (11.1.0)

## Current Version Information

- **Current Version**: 1.0.0 (Beta)
- **Branch Status**:
  - **main**: Contains the latest stable release (v1.0.0)
  - **beta**: Current beta release (v1.0.0)
  - **develop**: Active development branch (v1.0.0)
    - This branch is always used for in-game testing

## Development Progress

| Feature | Status | Notes |
|---------|--------|-------|
| Core Framework | ✅ STABLE | Reverted to v0.4.0 stable codebase |
| Nameplate Tracking | ✅ STABLE | Visual indicators, duration, position |
| Border-only Coloring | ✅ STABLE | Option to color just the nameplate border |
| Find My Dots | ✅ STABLE | Window showing all active DoTs grouped by target |
| Spell Database | ✅ STABLE | Pre-defined database of DoT spells for all classes |
| Configuration UI | ✅ STABLE | Options panel with profile support |
| Minimap Button | ✅ STABLE | Integration with LibDBIcon |
| Debug System | ✅ STABLE | Comprehensive logging with category-based filtering |
| API Compatibility | ⚠️ NEEDS REVIEW | Critical API changes still need implementation |
| Pre-Game Validation | ✅ MAINTAINED | Preserved dmcheck tool for validation |
| Documentation | ✅ UPDATED | Consolidated documentation structure |
| Plater Integration | ✅ ENHANCED | Added border-only coloring with thickness control |

## Current Development Focus

- Gathering feedback from beta testers on version 1.0.0
- Ensuring compatibility with World of Warcraft 11.1.0 (The War Within)
- Fixing any issues reported during beta testing
- Preparing for release candidate after beta period

## Known Issues

1. **API Compatibility**: Still need to ensure all parts of the addon use `C_Spell.GetSpellInfo()`
2. **Performance**: May experience frame drops during combat with many targets
3. **Nameplate Detection**: Occasional issues detecting all nameplates in crowded scenarios

## Next Development Steps

1. Address beta feedback and fix reported issues
2. Optimize nameplate processing for improved framerates
3. Enhance UI responsiveness in high-stress scenarios
4. Add more comprehensive error recovery mechanisms
5. Implement more user-requested quality of life features
6. Prepare for release candidate and final release

## Recent Changes

The most significant recent changes include:

- ✅ **Beta Release**: Released version 1.0.0 as beta on April 4, 2024
- ✅ **Release Documentation**: Added comprehensive release documentation
- ✅ **Border-only Coloring**: Added option to color just the nameplate border instead of the entire nameplate
- ✅ **Configurable Border Thickness**: Added control for border thickness when using border-only coloring
- ✅ **Improved Plater Integration**: Enhanced compatibility with Plater's border system
- ✅ **Nameplate Coloring Fixes**: Eliminated color flicker when leaving combat and fixed non-combat coloring
- ✅ **Minimap Icon**: Added minimap icon functionality for quick access to DotMaster and Find My Dots
- ✅ **UI Improvements**: Redesigned General tab with better layout, spacing, and center-aligned elements
- ✅ **Player Class Coloring**: Main UI now uses player's class color for border and title text
- ✅ **Enhanced Search**: Improved database tab search to include class and spec names
- ✅ **Development Features**: Added auto-opening debug console option in development environment

Refer to the [CHANGELOG.md](CHANGELOG.md) for a more detailed list of changes.

## Test Environment

- World of Warcraft Retail Version: 11.1.0
- Development Path: `F:\World of Warcraft\_retail_\Interface\AddOns\DotMaster`
- Testing Environments: Solo play, Dungeons, Raids, World content
- Test Classes: Warlock, Shadow Priest, Affliction Warlock

## Beta Testing Program

The beta testing phase for version 1.0.0 runs from April 4, 2024 to May 1, 2024. During this period:

1. Beta testers can access the addon via the beta branch
2. Feedback and bug reports should be submitted via GitHub issues
3. Weekly updates will be provided based on beta feedback
4. A release candidate will be prepared after the beta period

For more information on the beta testing program, see [RELEASE.md](RELEASE.md).

## Upcoming Tasks

- Address beta feedback and fix reported issues
- Continue enhancing the Find My Dots window UI
- Implement spell auto-detection improvements
- Add additional spell database entries
- Performance optimizations for nameplate coloring
- Expand documentation for API usage

## Known Issues

1. **API Compatibility**: Still working on ensuring all parts of the addon use `C_Spell.GetSpellInfo()`
2. **Performance**: May experience frame drops during combat with many targets
3. **Nameplate Detection**: Occasional issues detecting all nameplates in crowded scenarios 