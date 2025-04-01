# Known Issues and Workarounds

This document tracks current known issues in DotMaster and provides workarounds where available.

## API Compatibility Issues

### ✅ GetSpellInfo() Deprecation (FIXED in v0.4.2)
- **Issue**: Direct GetSpellInfo() calls no longer work in recent WoW client updates
- **Fix**: All instances replaced with C_Spell.GetSpellInfo() in version 0.4.2
- **Workaround for older versions**: None - update to the latest version

### Nameplate Detection Edge Cases
- **Issue**: Some nameplate modifications from other addons can interfere with dot tracking
- **Status**: Under investigation for v0.4.3
- **Workaround**: Disable nameplate modifications from other addons when running DotMaster

## Performance Issues

### High Combat CPU Usage
- **Issue**: In 25+ player raids with many targets, CPU usage can spike
- **Status**: Performance optimizations planned for v0.4.3
- **Workaround**: Reduce scan frequency in settings or disable during large raids

### Memory Usage Growth
- **Issue**: Memory usage can increase during extended play sessions
- **Status**: Memory optimization scheduled for v0.4.3
- **Workaround**: Reload UI (/reload) after extended raiding sessions

## Feature Limitations

### Multiple DoT Class Support
- **Issue**: When playing multiple DoT classes, profile switching doesn't retain all settings
- **Status**: Improved profile system planned for v0.5.0
- **Workaround**: Manually reconfigure settings when switching characters

### Find My Dots Range Limitations
- **Issue**: Find My Dots visual indicators don't work beyond 40 yards
- **Status**: Working as designed due to WoW API limitations
- **Workaround**: None available - this is a fundamental API limitation

## UI Issues

### Settings Panel Scale
- **Issue**: Settings panel may appear too small on high-resolution displays
- **Status**: UI scaling improvements planned for v0.4.3
- **Workaround**: Use WoW's UI scale setting to increase overall UI size

### Minimap Button Conflicts
- **Issue**: Minimap button can overlap with other addon buttons
- **Status**: Improved positioning system planned for v0.5.0
- **Workaround**: Use a minimap button addon like Broker_MicroMenu to manage placement

## Addon Conflicts

### Known Conflicts
1. **ElvUI Nameplate Modifications** - Can interfere with dot coloring
   - **Workaround**: Disable ElvUI nameplate coloring features
   
2. **Plater Deep Configuration** - Custom Plater scripts can override DotMaster coloring
   - **Workaround**: Check Plater scripts for nameplate color modifications

3. **WeakAuras Nameplate Auras** - Can create visual conflicts
   - **Workaround**: Adjust WeakAuras positioning or disable overlapping features

## Reporting New Issues

If you encounter an issue not listed here, please report it on our GitHub issue tracker with:

1. Detailed description of the problem
2. Steps to reproduce
3. Your addon version
4. List of other installed addons
5. Any error messages (exact text is helpful)
6. Screenshots if applicable

The development team will investigate all properly reported issues for future releases.

---

Last updated: July 15, 2024 