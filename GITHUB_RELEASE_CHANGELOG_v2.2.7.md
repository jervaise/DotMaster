# 🚀 DotMaster v2.2.8 - Minimap Icon Toggle Reliability

**Release Date:** August 17, 2025  
**WoW Compatibility:** 11.1.7 and 11.2.0  
**Interface Version:** 110200

---

## ✨ What's New in v2.2.8

### 🛠️ Minimap Icon Toggle Fix
- The minimap icon now correctly shows/hides from both the General tab checkbox and the `/dm minimap` command
- Eliminated duplicate `/dm` registrations that caused repeated chat messages
- Centralized initialization to prevent conflicting or delayed re-initialization
- Preserved LibDBIcon’s internal reference by updating the saved variables in-place

---

## 🔧 Technical Improvements
- `DM:ToggleMinimapIcon()` now applies visibility from `DotMasterDB.minimap.hide`
- `DM.API:SaveSettings()` updates `DotMasterDB.minimap` fields without replacing the table
- `DM.LDBIcon` reference is created during initialization for safe reuse

---

## 📥 Installation & Updates

### Download Options
- **CurseForge**: [DotMaster on CurseForge](https://www.curseforge.com/wow/addons/dotmaster)
- **Wago**: [DotMaster on Wago](https://addons.wago.io/addons/dotmaster)
- **GitHub**: Direct Download v2.2.8 (tagged release)

### Update Notes
- No configuration changes required
- Toggle should work instantly and persist across reloads/login

---

## 🔄 Full Changelog

### Fixed
- Minimap icon toggle works from UI and slash command
- Removed duplicate `/dm` registrations and delayed init hooks

### Technical
- In-place updates for `DotMasterDB.minimap` to maintain LibDBIcon binding

---

Ready to enjoy a reliable minimap toggle? Update to v2.2.8 today!  
For issues or feedback, please open an issue on GitHub. 