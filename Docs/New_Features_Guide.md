# DotMaster 1.0.7 - New Features Guide

## Auto-Save

In version 1.0.7, DotMaster now automatically saves your settings as soon as you change them. There's no need to click the "Save Settings" button anymore - changes take effect immediately!

When a setting is changed:
1. The status message at the bottom of the window will show "Auto-saving: Pending..."
2. After saving, it will briefly display "Auto-saved & Pushed to Plater"
3. Settings are automatically pushed to bokmaster without requiring additional steps

## Border Thickness Changes

The border thickness setting now has additional safeguards:

1. When you change the border thickness, it is immediately saved to your settings
2. When you close the DotMaster window after changing border thickness, a popup will appear asking if you want to reload your UI
3. Reloading the UI is recommended to ensure the thickness change is fully applied to all nameplates

## New Slash Commands

A new slash command has been added:

- `/dm push` - Force push your current settings to bokmaster
- (Can also be used as `/dm bokmaster`)

This command is useful if you want to make sure your latest settings are applied to the Plater mod without opening the DotMaster interface.

## Force Push on Close

When you close the DotMaster window, your settings are now automatically pushed to bokmaster to ensure changes take effect immediately.

## Troubleshooting

If you experience any issues with settings not being saved:

1. Try using the `/dm push` command to force push settings to bokmaster
2. Check the chat window for any error messages (debugging information is printed there)
3. If border thickness changes aren't applying, try reloading your UI with `/reload` 