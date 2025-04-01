# DotMaster File Cleanup Script
# This script removes old files that have been replaced by the new prefixed files

Write-Host "DotMaster File Cleanup Script" -ForegroundColor Green
Write-Host "--------------------------------" -ForegroundColor Green

# Core files
$filesToRemove = @(
  "init.lua",
  "core.lua",
  "utils.lua",
  "settings.lua",
  "nameplate_core.lua",
  "nameplate_detection.lua",
  "nameplate_coloring.lua",
  "spell_utils.lua",
  "gui.lua",
  "gui_common.lua",
  "gui_general_tab.lua",
  "gui_spells_tab.lua",
  "gui_spell_selection.lua",
  "gui_spell_row.lua",
  "find_my_dots.lua",
  "ui_spells.lua"
)

# Remove each file if it exists
foreach ($file in $filesToRemove) {
  if (Test-Path $file) {
    Write-Host "Removing $file..." -ForegroundColor Yellow
    Remove-Item $file
  }
  else {
    Write-Host "File $file not found, skipping..." -ForegroundColor Gray
  }
}

Write-Host "Cleanup complete!" -ForegroundColor Green 