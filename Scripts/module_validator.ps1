# DotMaster Module Validator Script
#
# Purpose: Validates that all modules referenced in the dm_loader.lua are properly 
# defined in their respective files and checks for any module initialization issues.
#
# Usage: Run from the addon root directory with: ./Scripts/module_validator.ps1
#
# Author: Jervaise
# Created: 2024-04-01

# Set error action preference
$ErrorActionPreference = "Stop"

# Fix for encoding issues in console output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "`n=== DotMaster Module Validator ===" -ForegroundColor Cyan

# Define paths
$loaderFile = "dm_loader.lua"
$loaderPath = Join-Path (Get-Location) $loaderFile

# Known module name mappings (file prefix -> module name)
$knownModules = @{
  "dm_debug"        = "Debug"
  "dm_settings"     = "Settings"
  "dm_utils"        = "Utils"
  "sp_database"     = "SpellDB"
  "ui_minimap"      = "MinimapButton"
  "ui_main"         = "UIMain"
  "ui_components"   = "UIComponents"
  "gui_colorpicker" = "UIColorPicker"
  "ui_general_tab"  = "UIGeneralTab"
  "ui_spells_tab"   = "UISpellsTab"
  "fmd_core"        = "FindMyDots"
  "fmd_ui"          = "FindMyDotsUI"
  "np_detection"    = "NPDetection"
}

# Check if loader file exists
if (-not (Test-Path $loaderPath)) {
  Write-Host "ERROR: Could not find $loaderFile in the current directory." -ForegroundColor Red
  Write-Host "Make sure you're running this script from the addon root directory." -ForegroundColor Red
  exit 1
}

# Get all Lua files in the addon directory
Write-Host "Scanning Lua files..." -ForegroundColor Yellow
$luaFiles = Get-ChildItem -Path (Get-Location) -Filter "*.lua" -Recurse | 
Where-Object { $_.FullName -notlike "*/Scripts/*" -and $_.FullName -notlike "*/Docs/*" }

# Extract module initializations from loader
Write-Host "Analyzing loader module..." -ForegroundColor Yellow
$loaderContent = Get-Content $loaderPath -Raw

# Find all module references in the loader using regex
$moduleInitializations = [regex]::Matches($loaderContent, "if\s+DM\.(\w+)\s+and\s+DM\.(\w+)\.Initialize") | 
ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

# Find all module definitions in Lua files
$moduleDefinitions = @{}
$potentialIssues = @()

foreach ($file in $luaFiles) {
  $fileContent = Get-Content $file.FullName -Raw
    
  # Extract the module name from the file content
  $moduleMatch = [regex]::Match($fileContent, "local\s+(\w+)\s*=\s*\{\}\s*DM\.(\w+)\s*=\s*\1")
    
  if ($moduleMatch.Success) {
    $moduleName = $moduleMatch.Groups[2].Value
    $moduleDefinitions[$moduleName] = $file.Name
        
    # Check if the file has an Initialize function
    $hasInitialize = [regex]::IsMatch($fileContent, "function\s+\w+:Initialize\(\)")
        
    if (-not $hasInitialize) {
      $potentialIssues += "Module '$moduleName' in file '$($file.Name)' doesn't have an Initialize function but is referenced in the loader."
    }
  }
  else {
    # Try to infer module name from filename and known mappings
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    if ($knownModules.ContainsKey($baseName)) {
      $inferredName = $knownModules[$baseName]
            
      # Check if this module name is used in the loader
      if ($moduleInitializations -contains $inferredName) {
        $moduleDefinitions[$inferredName] = "$($file.Name) (inferred)"
                
        # Check if the file has an Initialize function
        $hasInitialize = [regex]::IsMatch($fileContent, "function\s+\w+:Initialize\(\)")
                
        if (-not $hasInitialize) {
          $potentialIssues += "Module '$inferredName' in file '$($file.Name)' (inferred) doesn't have an Initialize function but is referenced in the loader."
        }
      }
    }
  }
}

# Validate the modules
$missingModules = @()
foreach ($module in $moduleInitializations) {
  if (-not $moduleDefinitions.ContainsKey($module)) {
    $missingModules += $module
  }
}

# Report results
Write-Host "`n=== Results ===" -ForegroundColor Green

Write-Host "Modules initialized in loader: $($moduleInitializations.Count)" -ForegroundColor Cyan
Write-Host "Modules defined in Lua files: $($moduleDefinitions.Count)" -ForegroundColor Cyan

if ($missingModules.Count -eq 0) {
  Write-Host "`n✓ All modules referenced in loader are defined in Lua files!" -ForegroundColor Green
}
else {
  Write-Host "`n✗ Modules referenced in loader but not defined in any Lua file:" -ForegroundColor Red
  foreach ($module in $missingModules) {
    Write-Host "   - $module" -ForegroundColor Red
  }
}

# Check for potential mismatches in module names
$unusedModules = @()
foreach ($moduleName in $moduleDefinitions.Keys) {
  if ($moduleInitializations -notcontains $moduleName) {
    $unusedModules += "$moduleName (in $($moduleDefinitions[$moduleName]))"
  }
}

if ($unusedModules.Count -gt 0) {
  Write-Host "`n⚠ Modules defined in Lua files but not initialized in loader:" -ForegroundColor Yellow
  foreach ($module in $unusedModules) {
    Write-Host "   - $module" -ForegroundColor Yellow
  }
}

if ($potentialIssues.Count -gt 0) {
  Write-Host "`n⚠ Potential module issues:" -ForegroundColor Yellow
  foreach ($issue in $potentialIssues) {
    Write-Host "   - $issue" -ForegroundColor Yellow
  }
}

# Special case check for FindMyDotsUI
$fmdUIContent = Get-Content (Join-Path (Get-Location) "fmd_ui.lua") -Raw -ErrorAction SilentlyContinue
if ($fmdUIContent -and -not ($moduleInitializations -contains "FindMyDotsUI")) {
  Write-Host "`n⚠ Special case - FindMyDotsUI:" -ForegroundColor Yellow
  Write-Host "   - FindMyDotsUI module in fmd_ui.lua may need initialization in the loader" -ForegroundColor Yellow
}

Write-Host "`n=== Module Validation Complete ===" -ForegroundColor Cyan 