# DotMaster Changelog

## Version 1.0.7
Released: July 2023

### New Features:
- **Auto-Save Functionality**: Settings now automatically save when changed without requiring the Save button
- **Instant Bokmaster Integration**: Changes are pushed to Plater/bokmaster immediately
- **Border Thickness Reload Prompt**: Added UI popup to prompt for reload when border thickness is changed
- **Direct Save Command**: Added `/dm push` slash command to force push settings to bokmaster

### Improvements:
- Improved border thickness handling with more reliable saving
- Added visual status indicators for auto-save process
- Added debugging output for troubleshooting thickness changes
- Improved reliability of settings when closing the DotMaster window

### Fixes:
- Fixed issue where border thickness changes weren't properly saved
- Fixed potential issue with settings not being pushed to bokmaster
- Ensured thickness changes are properly detected and applied 