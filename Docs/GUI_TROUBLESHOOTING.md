# DotMaster GUI Troubleshooting Guide

## Background

DotMaster initially used a simple WoW UI API approach for its GUI, but later transitioned to using the ACE3 framework. If you're experiencing GUI issues, this could be due to several factors:

1. Missing or outdated ACE libraries
2. Incompatible WoW API changes (particularly with BackdropTemplate)
3. Conflicts with other addons
4. Data corruption in the saved variables

## Built-in Diagnostic Tools

We've added several diagnostic tools to help identify and fix GUI issues:

### Slash Commands

- **/dotmasterdebug** - Runs a comprehensive diagnostic check and prints results to chat
- **/dmfix** - Attempts to automatically fix common GUI issues
- **/dm** or **/dotmaster** - Opens settings (will fallback to simplified UI if ACE GUI fails)
- **/dmlibstub** - Diagnoses LibStub-specific issues (helpful with ElvUI)
- **/dmfixlibstub** - Attempts to repair LibStub references (use when LibStub reports as missing)

### Diagnostic Process

When you run `/dotmasterdebug`, the addon will check:

1. All required libraries (LibStub, ACE modules, etc.)
2. GUI state and components
3. Database integrity
4. Basic frame creation capabilities 
5. Backdrop template functionality
6. GUI recreation attempt

This will provide valuable information about what might be wrong.

## Common Issues and Solutions

### 1. Missing Libraries

**Symptoms:**
- GUI doesn't open
- Error messages about missing libraries

**Solution:**
- Make sure all required libraries are present in the `Libs` folder
- Download the latest version of DotMaster which includes all required libraries
- Run `/dmfix` to attempt automatic repair

### 2. BackdropTemplate Issues

**Symptoms:**
- Visual elements appear without backgrounds or borders
- Errors about missing BackdropTemplate

**Solution:**
- The BackdropTemplate API changed in Shadowlands
- DotMaster should now use the BackdropTemplateMixin check
- The fallback UI has these fixes implemented

### 3. Saved Variable Corruption

**Symptoms:**
- GUI opens but appears broken or incomplete
- Settings don't persist between sessions

**Solution:**
- Backup and delete your SavedVariables file (WTF/Account/YOUR_ACCOUNT/SavedVariables/DotMaster.lua)
- Restart WoW to create a fresh configuration
- Run `/dmfix` to reset profile data

### 4. WoW API Version Incompatibility

**Symptoms:**
- Features that worked in previous WoW versions no longer work
- Errors about unknown functions or methods

**Solution:**
- DotMaster should be compatible with the current retail version of WoW
- If you're using an older or beta version, some features may not work
- The fallback UI uses more compatible API calls

### 5. LibStub Conflicts with ElvUI

**Symptoms:**
- LibStub reports as "MISSING" in diagnostics despite other ACE libraries loading correctly
- GUI partially initializes but fails to display correctly
- Using ElvUI alongside DotMaster

**Solution:**
- Type `/dmfixlibstub` to attempt automatic repair of LibStub references
- This will sync LibStub references between ElvUI and DotMaster
- Type `/dmlibstub` to see detailed diagnostics about LibStub status

## Using the Fallback UI

If all else fails, you can use the simplified fallback UI:

1. Type `/dm` which will attempt to use the ACE GUI but fall back to the simplified UI if needed
2. The fallback UI provides core functionality but with fewer advanced options
3. You can still toggle the addon on/off and see your tracked spells

## Advanced Debugging

For addon developers or advanced users who want to investigate further:

1. Enable WoW's error display: `/console scriptErrors 1`
2. Check the actual error messages that appear
3. Look at the Lua errors, particularly for:
   - Missing libraries or functions
   - Nil value errors (often indicate initialization problems)
   - API compatibility issues

## Reporting Issues

When reporting issues, please include:

1. The output from `/dotmasterdebug`
2. Your WoW version
3. Any error messages you see
4. Steps to reproduce the problem

## Complete Reset Procedure

If nothing else works, you can completely reset DotMaster:

1. Exit WoW
2. Delete the DotMaster folder from your AddOns directory
3. Delete DotMaster.lua from WTF/Account/YOUR_ACCOUNT/SavedVariables/
4. Download a fresh copy of DotMaster
5. Start WoW and reconfigure your settings

This should resolve any persistent issues related to addon file corruption or saved variable problems. 