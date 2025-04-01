# DotMaster Current Status

This document outlines the current development status of the DotMaster addon. It's intended to be regularly updated as development progresses.

## Current Version Information

- **Current Version**: 0.4.0
- **Branch Status**:
  - **main**: Contains the latest stable release (v0.4.0)
  - **develop**: Active development branch (v0.4.0)
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
| In-game Testing | 🔄 IN PROGRESS | Ongoing testing of all features |
| Performance Optimization | 🔄 PLANNED | Profiling and optimizing critical functions |
| Documentation | 🔄 IN PROGRESS | Creating comprehensive docs for users and devs |

## Current Development Focus

- Extensive in-game testing of all features in various combat scenarios
- Performance profiling to identify and optimize potential bottlenecks
- Validating the spell database for accuracy and completeness
- Preparing documentation for end users
- ⚠️ **[CRITICAL]** Updating all GetSpellInfo() calls to use C_Spell.GetSpellInfo() instead

## Known Issues

1. **Performance**: May experience frame drops during combat with many targets
2. **Nameplate Detection**: Occasional issues detecting all nameplates in crowded scenarios
3. **Visual Consistency**: DoT indicators may misalign when nameplate size changes dynamically
4. **Library Path Issues**: Fixed incorrect paths in embeds.xml that were causing loading errors
5. ⚠️ **CRITICAL API ISSUE**: The addon uses the deprecated GetSpellInfo() function in multiple files, which fails to retrieve spell information for many spells not available to the current character class/spec. This must be updated to use C_Spell.GetSpellInfo() before the next release. See [CRITICAL_API_NOTES.md](CRITICAL_API_NOTES.md) for details.

## Next Development Steps

1. ⚠️ **[URGENT]** Update all instances of GetSpellInfo() to use C_Spell.GetSpellInfo() as described in [CRITICAL_API_NOTES.md](CRITICAL_API_NOTES.md)
2. Complete in-game testing of all features in various combat scenarios
3. Optimize performance through code profiling and enhancement
4. Test profile functionality across multiple characters
5. Verify compatibility with other popular addon UI frameworks
6. Ensure proper localization support
7. Validate the spell database against current game data
8. Create comprehensive documentation for end users
9. Prepare for stable release

## Recent Changes

The most significant recent change has been the complete architectural rebuild in version 0.3.0, which includes:

- Full integration with the Ace3 framework
- Complete modular file organization
- Enhanced debug system
- Improved "Find My Dots" feature
- Robust color management system for nameplates
- Comprehensive spell database with classification by class/spec
- Advanced GUI system with tabs, sections, and configuration options
- ✅ **Fixed missing libraries**: Added LibDataBroker-1.1 and LibDBIcon-1.0 for minimap button functionality

Refer to the [CHANGELOG.md](CHANGELOG.md) for a more detailed list of changes.

## Test Environment

- World of Warcraft Retail Version: 10.2.0
- Development Path: `F:\World of Warcraft\_retail_\Interface\AddOns\DotMaster`
- Testing Environments: Solo play, Dungeons, Raids, World content
- Test Classes: Warlock, Shadow Priest, Affliction Warlock 