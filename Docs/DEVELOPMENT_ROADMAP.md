# DotMaster Development Roadmap

This document outlines the planned development roadmap for DotMaster beyond version 0.4.1.

## Current Version: 0.4.1

Successfully fixed critical API issues with Find My Dots functionality and standardized aura detection methods across all modules.

## Near-Term Priorities (v0.4.2)

1. ⚠️ **[URGENT]** Update all instances of `GetSpellInfo()` to use `C_Spell.GetSpellInfo()`
   - Files to update:
     - spell_utils.lua
     - gui_spell_selection.lua
     - gui_spell_row.lua
     - gui_spells_tab.lua
     - find_my_dots.lua

2. **Performance Optimization**
   - Profile code execution during raid scenarios
   - Optimize aura scanning in high-density combat
   - Reduce memory usage for dot indicators
   - Implement caching for frequently accessed data

3. **Testing and Quality Assurance**
   - Complete in-game testing across all class specs
   - Test in different combat scenarios (solo, dungeon, raid, PvP)
   - Verify compatibility with popular nameplate addons

## Mid-Term Goals (v0.5.0)

1. **Enhanced Spell Database**
   - Add missing spells from recent content
   - Implement automatic spell detection for each class
   - Create specialized DoT categorization by effect type
   - Add support for tracking beneficial buffs (optional feature)

2. **Visual Improvements**
   - Add options for different dot shapes/styles
   - Implement variable size/opacity based on remaining duration
   - Add optional pulse effect for DoTs about to expire
   - Provide better text indicators for important statuses

3. **Configuration Enhancements**
   - Implement profiles system for multiple characters
   - Create preset configurations for different content types
   - Add import/export functionality for sharing settings
   - Develop class-specific default configurations

## Long-Term Vision (v1.0.0)

1. **Advanced Tracking Features**
   - Track enemy cooldowns with optional indicators
   - Monitor enemy buffs relevant to the player's class
   - Calculate and display optimal DoT refresh windows
   - Implement specialized tracking for PvP environments

2. **Integration**
   - Develop WeakAuras-style condition system for custom tracking rules
   - Create API for other addons to utilize DotMaster's tracking capabilities
   - Implement optional BigWigs/DBM timer integration
   - Plater script integration for advanced users

3. **Quality of Life**
   - Add comprehensive localization support
   - Create detailed documentation and video tutorials
   - Implement automatic configuration backup
   - Develop analytics for DoT uptime and efficiency

## Development Process

1. **Feature Implementation**
   - Each feature should be developed in its own feature branch
   - Branches should be named `feature/[feature-name]`
   - Pull requests should include comprehensive testing

2. **Testing Requirements**
   - All new features must be tested in-game before merging
   - Changes to core functionality require testing across multiple classes
   - UI changes should be verified on different UI scales

3. **Version Control**
   - `main` branch contains only stable releases
   - `develop` branch for active development
   - Feature branches for individual features
   - Tagged releases follow semantic versioning

4. **Documentation**
   - Update CHANGELOG.md with each release
   - Create/update patch notes for each version
   - Maintain current development status in CURRENT_STATUS.md
   - Document all API changes in API_NOTES.md

## Immediate Next Steps

1. Create a `feature/spell-info-api-update` branch to update all `GetSpellInfo()` calls
2. Begin profiling code performance in raid scenarios
3. Set up comprehensive testing for all class specializations
4. Document the current architecture for future contributors 