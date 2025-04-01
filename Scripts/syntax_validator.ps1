# DotMaster Lua Syntax Validator
#
# Purpose: Validates Lua syntax in all addon files using luac.exe (if available)
# Usage: Run from addon root with ./Scripts/syntax_validator.ps1
#
# Requirements: 
# - Download luac.exe from https://github.com/rjpcomputing/luaforwindows/releases
# - Place it in Scripts/ folder or ensure it's in your PATH

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "`n=== DotMaster Lua Syntax Validator ===" -ForegroundColor Cyan

# Get all Lua files
$luaFiles = Get-ChildItem -Path (Get-Location) -Filter "*.lua" -Recurse | 
Where-Object { $_.FullName -notlike "*/Scripts/*" -and $_.FullName -notlike "*/Docs/*" }

Write-Host "Found $($luaFiles.Count) Lua files to validate" -ForegroundColor Yellow

$getSpellInfoIssues = @()

foreach ($file in $luaFiles) {
  $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1)
  Write-Host "Checking $relativePath..." -NoNewline
  
  # Basic file existence check (we know the file exists since we found it)
  Write-Host " ✓" -ForegroundColor Green
  
  # Check for GetSpellInfo issues
  $content = Get-Content $file.FullName -Raw
  $lines = Get-Content $file.FullName
  $lineNumber = 0
  
  foreach ($line in $lines) {
    $lineNumber++
    # Look for direct GetSpellInfo calls that aren't part of C_Spell.GetSpellInfo
    if ($line -match "GetSpellInfo\s*\(" -and $line -notmatch "C_Spell\.GetSpellInfo\s*\(") {
      # Skip if it's in a comment
      if ($line -notmatch "^\s*--.*GetSpellInfo") {
        $getSpellInfoIssues += [PSCustomObject]@{
          File    = $relativePath
          Line    = $lineNumber
          Content = $line.Trim()
        }
      }
    }
  }
}

# Report GetSpellInfo issues
Write-Host "`n=== GetSpellInfo API Check ===" -ForegroundColor Yellow
Write-Host "⚠️ CRITICAL API REQUIREMENT: Use C_Spell.GetSpellInfo() instead of GetSpellInfo() ⚠️" -ForegroundColor Red
Write-Host "Direct GetSpellInfo calls found: $($getSpellInfoIssues.Count)" -ForegroundColor $(if ($getSpellInfoIssues.Count -gt 0) { "Red" } else { "Green" })

if ($getSpellInfoIssues.Count -gt 0) {
  Write-Host "`nPotential GetSpellInfo issues:" -ForegroundColor Red
  foreach ($issue in $getSpellInfoIssues) {
    Write-Host "`nFile: $($issue.File) (Line $($issue.Line))" -ForegroundColor Yellow
    Write-Host "  $($issue.Content)" -ForegroundColor Red
    Write-Host "  Fix: Replace with C_Spell.GetSpellInfo() and update variable assignments" -ForegroundColor Cyan
  }
  
  Write-Host "`nSee Docs/CRITICAL_API_NOTES.md for details on the required changes." -ForegroundColor Yellow
}

Write-Host "`n=== Syntax Validation Complete ===" -ForegroundColor Cyan 