# DotMaster Current Status

This document outlines the current development status of the DotMaster addon. It's intended to be regularly updated as development progresses.

## Current Version Information

- **Current Version**: 0.4.2
- **Branch Status**:
  - **main**: Contains the latest stable release (v0.4.0)
  - **develop**: Active development branch (v0.4.2)
    - This branch is always used for in-game testing

## Development Progress

| Feature | Status | Notes |
|---------|--------|-------|
| Core Framework | ✅ COMPLETED | Ace3 integration, init sequence, event handling |
| Nameplate Tracking | ✅ COMPLETED | Visual indicators, duration, position |
| Find My Dots | ✅ COMPLETED | Window showing all active DoTs grouped by target |
| Spell Database | ✅ COMPLETED | Pre-defined database of DoT spells for all classes |
| Configuration UI | ✅ COMPLETED | Options panel with profile support |
| Minimap Button | ✅ COMPLETED | Integration with LibDBIcon |
| API Compatibility | ✅ FIXED | Updated API usage with C_Spell.GetSpellInfo() |
| Pre-Game Validation | ✅ COMPLETED | Added dmcheck tool for validation |
| In-game Testing | 🔄 IN PROGRESS | Ongoing testing of all features |
| Performance Optimization | 🔄 PLANNED | Profiling and optimizing critical functions |
| Documentation | 🔄 IN PROGRESS | Creating comprehensive docs for users and devs |

## Current Development Focus

- Extensive in-game testing of all features in various combat scenarios
- Performance profiling to identify and optimize potential bottlenecks
- Validating the spell database for accuracy and completeness
- Preparing documentation for end users
- Enhancing error detection and validation systems

## Known Issues

1. **Performance**: May experience frame drops during combat with many targets
2. **Nameplate Detection**: Occasional issues detecting all nameplates in crowded scenarios
3. **Visual Consistency**: DoT indicators may misalign when nameplate size changes dynamically
4. **Library Path Issues**: Fixed incorrect paths in embeds.xml that were causing loading errors

## Next Development Steps

1. Complete in-game testing of all features in various combat scenarios
2. Optimize performance through code profiling and enhancement
3. Test profile functionality across multiple characters
4. Verify compatibility with other popular addon UI frameworks
5. Ensure proper localization support
6. Validate the spell database against current game data
7. Create comprehensive documentation for end users
8. Prepare for stable release

## Recent Changes

The most significant recent changes include:

- ✅ **Fixed CRITICAL API ISSUE**: Resolved the GetSpellInfo API issue by using C_Spell.GetSpellInfo() throughout the codebase
- ✅ **Added dmcheck Tool**: Created validation tools to catch common errors before in-game testing
- ✅ **Enhanced Development Process**: Improved code validation workflows

Prior to that:
- ✅ **Fixed Find My Dots functionality**: Resolved critical "attempt to call field 'GetAuraDataByUnit'" error
- ✅ **API Compatibility**: Updated aura detection to use AuraUtil.ForEachAura instead of C_UnitAuras.GetAuraDataByUnit
- ✅ **Standardized API Usage**: Ensured consistent API usage across all modules for better stability
- ✅ **Improved Error Handling**: Added better error handling and robustness for API calls

Refer to the [CHANGELOG.md](CHANGELOG.md) for a more detailed list of changes.

## Test Environment

- World of Warcraft Retail Version: 10.2.0
- Development Path: `F:\World of Warcraft\_retail_\Interface\AddOns\DotMaster`
- Testing Environments: Solo play, Dungeons, Raids, World content
- Test Classes: Warlock, Shadow Priest, Affliction Warlock 