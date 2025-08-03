# 🚀 DotMaster v2.2.7 - Font System Overhaul & Critical Tank Fix

**Release Date:** December 28, 2024  
**WoW Compatibility:** 11.1.7 and 11.2.0  
**Interface Version:** 110200

---

## ✨ What's New in v2.2.7

### 🎨 **Complete Expressway Font Integration**
- **Modern Typography**: All UI elements now use the sleek Expressway font for a contemporary look
- **Consistent Styling**: Unified font appearance across all tabs, dialogs, and interface components  
- **Enhanced Readability**: Improved text clarity with proper outline effects and sizing
- **Professional Appearance**: Clean, modern font that matches current UI design trends
- **Gold Author Credits**: Footer author/version text now displays in elegant gold color

### 🛡️ **CRITICAL FIX: Raid Tank Threat Detection**
- **Fixed False "Lost Aggro" Colors**: Tanks no longer see incorrect threat colors when another tank has aggro in raids
- **Smart Raid Detection**: Added intelligent detection of other tanks in raid environments using Plater's tank roster
- **Context-Aware Behavior**: Different threat logic for raids vs dungeons vs solo content
- **Enhanced Validation**: Improved combat state and PVP checks for more reliable threat coloring
- **Preserved Functionality**: All existing Force Threat Color settings work exactly as before

---

## 🔧 Technical Improvements

### **Font System Architecture**
- Complete font object definitions for all sizes and styles
- Centralized font management with `fonts.lua`
- Improved error handling and initialization
- Easy-to-maintain font mapping system

### **Enhanced Threat Logic**
- Restructured threat detection to preserve DoT coloring functionality
- Added proper combat state validation for players and units
- PVP protection prevents conflicts in player vs player scenarios
- Raid-aware logic uses Plater's `GetTanks()` and `ZoneInstanceType` detection

### **WoW Compatibility**
- Updated interface version to 110200 for WoW 11.2.0
- Minimum supported version: WoW 11.1.7 (interface 110107)
- Full compatibility with both current WoW versions

---

## 🎯 Who Benefits from This Update

### **Tank Players**
- ✅ No more false "lost threat" indicators in raids when other tanks are doing their job
- ✅ Accurate threat colors that understand multi-tank scenarios
- ✅ Better situational awareness in complex raid encounters

### **All Players**
- ✅ Modern, professional UI that's easier to read
- ✅ Consistent visual experience across all DotMaster interfaces
- ✅ Enhanced compatibility with latest WoW versions

### **Addon Users**
- ✅ Automatic fixes - no configuration required
- ✅ All existing settings and tracked spells preserved
- ✅ Better performance with optimized threat detection

---

## 📥 Installation & Updates

### **Download Options**
- **CurseForge**: [DotMaster on CurseForge](https://www.curseforge.com/wow/addons/dotmaster)
- **Wago**: [DotMaster on Wago](https://addons.wago.io/addons/dotmaster)
- **GitHub**: [Direct Download v2.2.7](https://github.com/jervaise/DotMaster/releases/tag/v2.2.7)

### **Update Notes**
- ✅ **No configuration changes required** - All improvements are automatic
- ✅ **Font upgrades applied instantly** - No settings to adjust
- ✅ **Tank threat fix activates automatically** when Force Threat Color is enabled
- ✅ **Complete backward compatibility** - All your settings and tracked spells are preserved

---

## 💡 What This Fixes

**Before v2.2.7:** Tank players would see "lost threat" red colors on mobs that another tank was legitimately tanking in raids, causing confusion and unnecessary concern.

**After v2.2.7:** The addon intelligently detects when other tanks in your raid are handling specific mobs and doesn't show false threat warnings, while still alerting you when you actually lose threat to DPS or when no tank has aggro.

---

## 🔄 Full Changelog

### Added
- **Expressway Font Integration**: Complete font system overhaul with modern Expressway font
- **Professional Typography**: All UI elements now use consistent, modern font styling
- **Enhanced Readability**: Proper outline effects and sizing across all components
- **WoW 11.2.0 Support**: Updated interface version to 110200

### Fixed
- **Raid Tank Threat Colors**: Fixed incorrect "lost threat" colors when another tank has aggro in raids
- **DoT Coloring Logic**: Restructured threat detection to preserve regular DoT coloring functionality
- **Combat State Validation**: Added proper checks for combat status and PVP scenarios

### Technical
- Added `fonts.lua` with complete font object definitions and helper functions
- Improved font initialization with proper error handling
- Enhanced raid detection using Plater's tank roster system
- Restructured threat logic to prevent interference with DoT tracking

---

## 🎮 Perfect For

- **Raid Tanks**: Get accurate threat information without false alarms
- **M+ Players**: Clean, professional UI for high-stakes content  
- **DoT Classes**: Reliable visual tracking with enhanced coloring logic
- **All Players**: Modern, readable interface that works seamlessly with WoW 11.2.0

---

*DotMaster v2.2.7 represents both a significant visual upgrade and a critical functionality fix. The new Expressway font system provides a modern, professional appearance, while the improved raid tank threat detection ensures accurate threat coloring in all environments.*

**Ready to upgrade your DoT tracking experience? Download v2.2.7 today!** 