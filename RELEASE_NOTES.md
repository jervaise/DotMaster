# DotMaster 2.2.4 Release

## Enhanced Tank Threat Detection & Multi-Tank Support

DotMaster 2.2.4 delivers critical improvements to the Force Threat function, specifically addressing multi-tank scenarios in raid environments. This update ensures proper threat detection and coloring when multiple tanks are present.

## 🛡️ Tank & Threat Improvements

### **Multi-Tank Raid Support**
- **Smart Tank Detection**: Force Threat function now properly recognizes when another tank is legitimately tanking a unit
- **Raid vs Dungeon Logic**: Different behavior for raid environments (checks other tanks) vs dungeons (immediate threat response)
- **Group Composition Awareness**: Threat system adapts based on group type for optimal accuracy

### **Enhanced Threat Logic**
- **Combat State Validation**: Added proper combat and PVP checks before processing threat
- **Tank List Integration**: Uses Plater's tank detection to identify all tanks in the group
- **Target Validation**: Checks unit targeting to determine legitimate tank assignments

### **Improved Accuracy**
- **False Positive Reduction**: Eliminates incorrect "no aggro" alerts when another tank is properly handling the unit
- **Contextual Responses**: Threat coloring now responds appropriately to different group scenarios
- **Professional Standards**: Matches proven Plater scripting patterns for reliable operation

## 🔧 Technical Enhancements

### **Force Threat Function Overhaul**
- **Raid Environment Detection**: Proper `Plater.ZoneInstanceType` checking
- **Tank Player Identification**: Enhanced `Plater.GetTanks()` integration
- **Unit Target Tracking**: Improved `UnitName(unitFrame.targetUnitID)` validation

### **Script Hook Improvements**
- **Nameplate Updated Hook**: Enhanced threat detection in main update loop
- **Nameplate Added Hook**: Improved initial threat assessment on nameplate creation
- **Combat Validation**: Added `Plater.IsInCombat()` and unit combat state checks
- **PVP Protection**: Automatic disabling in PVP environments

## 🚀 System Compatibility

### **WoW 11.2.* Ready**
- **The War Within Season 3**: Full compatibility with upcoming content
- **Interface 110200**: Updated for latest WoW client versions
- **Backward Compatibility**: Maintains support for WoW 11.1.7+

### **Plater Integration**
- **Modern Hook Standards**: Updated to match current Plater scripting best practices
- **Performance Optimized**: Efficient threat checking with minimal performance impact
- **Reliability Enhanced**: Improved error handling and state validation

## 📋 Compatibility & Support

### **Supported WoW Versions**
- **11.2.*** (The War Within Season 3) ✅
- **11.1.7+** (Current Live) ✅
- **Interface Version**: 110200

### **Required Addons**
- **Plater Nameplates**: Latest version recommended
- **No Conflicts**: Cleaned up compatibility issues from previous versions

## 🎯 For Tank Players

This release specifically addresses feedback from tank players experiencing issues with threat detection in multi-tank environments. The Force Threat function now:

- **Accurately identifies** when you should be concerned about threat vs when another tank is handling it
- **Reduces false alarms** in raid scenarios with multiple tanks
- **Provides reliable feedback** for both raid and dungeon environments
- **Maintains quick response** for solo tank situations

## 📥 Download & Installation

**Download DotMaster 2.2.4** from [CurseForge](https://www.curseforge.com/wow/addons/dotmaster), [Wago](https://addons.wago.io/addons/dotmaster), or [GitHub](https://github.com/jervaise/DotMaster/releases)

---

*DotMaster 2.2.4 represents a significant improvement in threat detection accuracy, ensuring that tank players receive reliable and contextually appropriate threat feedback in all group scenarios.* 