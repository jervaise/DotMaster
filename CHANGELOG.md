# DotMaster Changelog

## [1.0.9] - YYYY-MM-DD
### Added
- "Plater Integration" button in DotMaster GUI footer: Appears if the "DotMaster Integration" Plater mod is not detected, allowing users to inject it.
- Functionality for the "Plater Integration" button to inject the pre-defined "DotMaster Integration" Plater mod string into Plater using `Plater.ImportScriptString`.
- Safety check within the "DotMaster Integration" Plater mod: The mod's hooks will now only execute if the DotMaster addon itself is loaded and enabled, preventing errors if DotMaster is removed or disabled. This check is injected when DotMaster updates/installs the Plater mod.

### Changed
- Refined the Plater mod injection process: DotMaster settings are now pushed to the Plater mod after a short delay post-injection, and the GUI footer status is updated more reliably.

### Fixed
- Resolved Lua compilation errors in Plater (`unexpected symbol near 'if'`) that occurred when injecting the DotMaster presence safety check. The check is now correctly placed within the function bodies of the Plater mod's hooks.

## [1.0.8] - PREVIOUS_DATE

### Fixes
- Fixed issue with settings not persisting correctly between UI reloads
- Added proper tracking for enabled/disabled state in the border settings reload popup
- Fixed border thickness control when Border-only mode is disabled - now properly reverts to Plater's settings
- Improved change detection to prevent unnecessary reload UI popups
- Enhanced debug logging for easier troubleshooting
- Fixed false positive change detection that was causing reload UI popups to appear unnecessarily

## 1.0.7 (Previous version)

### New Features:
- **Auto-Save Functionality**: Settings now automatically save when changed without requiring the Save button
- **Instant DotMaster Integration**: Changes are pushed to Plater/DotMaster Integration immediately
- **Border Thickness Reload Prompt**: Added UI popup to prompt for reload when border thickness is changed
- **Direct Save Command**: Added `/dm push` slash command to force push settings to DotMaster Integration

### Improvements:
- Improved border thickness handling with more reliable saving
- Added visual status indicators for auto-save process
- Added debugging output for troubleshooting thickness changes
- Improved reliability of settings when closing the DotMaster window

### Fixes:
- Fixed issue where border thickness changes weren't properly saved
- Fixed potential issue with settings not being pushed to DotMaster Integration
- Ensured thickness changes are properly detected and applied 