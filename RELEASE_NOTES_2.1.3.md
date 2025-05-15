# DotMaster 2.1.3 Release Notes

This is a maintenance release that fixes a critical error that could occur when using the "Find My Dots" feature.

## What's Fixed
- Fixed "'for' limit must be a number" error when using Find My Dots feature and switching to the Database tab
- Added safety checks for the frame.numTabs property to prevent Lua errors
- Improved error handling in tab switching functionality 
- Enhanced Find My Dots section with additional safety checks

## Installation
1. Extract the DotMaster folder to your World of Warcraft `_retail_/Interface/AddOns` directory
2. Enable DotMaster in your addon list
3. Use `/dm` to open the configuration panel

## Reporting Issues
If you encounter any issues with this release, please report them on our GitHub issue tracker with detailed information about what you were doing when the error occurred.

Thank you for using DotMaster! 