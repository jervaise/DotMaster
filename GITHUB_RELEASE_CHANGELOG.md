# DotMaster v2.2.5 Release Notes

## 🛠️ Fixed Issues

### Force Threat Color for Tanks - Multi-Tank Raid Support

The Force Threat Color feature has been significantly improved to properly handle multi-tank raid environments. This was a critical issue where tanks would incorrectly see "no aggro" colors on mobs that were being legitimately tanked by other tanks in the raid.

**What Was Fixed:**
- ✅ **Incorrect "No Aggro" Colors**: Tanks no longer receive false "no aggro" warnings when another tank is properly tanking a mob
- ✅ **Raid Environment Detection**: Added proper detection for raid vs non-raid environments 
- ✅ **DoT Coloring Interference**: Fixed early return statements that were preventing DoT coloring from working
- ✅ **Combat State Validation**: Enhanced checks for player combat, unit combat, and PVP situations

**How It Works Now:**
1. **In Raids**: System checks if any tank in the raid is tanking the mob before applying "no aggro" colors
2. **Outside Raids**: Uses original logic (dungeons, solo content typically have one tank)
3. **DoT Colors**: Always processes DoT coloring regardless of threat detection state
4. **Combat Awareness**: Only processes threat when all conditions are met (in combat, non-PVP, etc.)

## 🔧 Technical Improvements

- **Enhanced Threat Detection Logic**: Restructured to match Plater's recommended best practices
- **Raid Tank Coordination**: Uses `Plater.GetTanks()` and `UnitName(unitFrame.targetUnitID)` for proper tank detection
- **Combat State Validation**: Added proper checks for `Plater.IsInCombat()`, `unitFrame.InCombat`, and `UnitPlayerControlled(unitId)`
- **Code Quality**: Eliminated early return statements that blocked DoT functionality

## 📋 Migration Notes

✅ **Fully Backward Compatible** - No configuration changes required. The improvements will automatically take effect for users with Force Threat Color enabled.

## 🎯 Impact

This fix primarily benefits:
- **🛡️ Raid Tanks**: No more false "no aggro" warnings during tank swaps or multi-tank encounters  
- **👥 Multi-Tank Groups**: Proper coordination between tank threat indicators
- **🌟 All Users**: Ensures DoT coloring works reliably in all scenarios

## 💾 Installation

Download `DotMaster-v2.2.5.zip` and extract to your `World of Warcraft\_retail_\Interface\AddOns` directory.

## 🏷️ Compatibility 

- **WoW Version**: 11.1.7, 11.2.*, TWW Season 3
- **Interface**: 110200
- **Dependencies**: Plater (optional but recommended)

---

**Full Changelog**: https://github.com/jervaise/DotMaster/blob/main/CHANGELOG.md 