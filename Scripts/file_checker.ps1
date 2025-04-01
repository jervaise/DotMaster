# DotMaster File Checker Script
#
# Purpose: Validates that all files referenced in the DotMaster.toc file exist 
# and checks for files in the addon directory that are not referenced in the TOC.
#
# Usage: Run from the addon root directory with: ./Scripts/file_checker.ps1
#
# Author: Jervaise
# Created: 2024-04-01

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "`n=== DotMaster File Checker ===" -ForegroundColor Cyan

# Define paths
$tocFile = "DotMaster.toc"
$tocPath = Join-Path (Get-Location) $tocFile
$excludeFolders = @("Scripts", "Docs", ".vscode", ".git")
$excludeFiles = @("embeds.xml", "README.md", ".gitignore")

# Check if TOC file exists
if (-not (Test-Path $tocPath)) {
  Write-Host "ERROR: Could not find $tocFile in the current directory." -ForegroundColor Red
  Write-Host "Make sure you're running this script from the addon root directory." -ForegroundColor Red
  exit 1
}

# Extract file references from TOC file
Write-Host "Reading TOC file..." -ForegroundColor Yellow
$tocContent = Get-Content $tocPath -Raw
$tocReferences = [regex]::Matches($tocContent, "(?m)^(?!##|#\s)[^#\s][^\n]+$") | ForEach-Object { $_.Value.Trim() }

# Get actual files
Write-Host "Scanning addon directory..." -ForegroundColor Yellow
$allFiles = Get-ChildItem -Recurse -File | Where-Object {
  $include = $true
  foreach ($folder in $excludeFolders) {
    if ($_.FullName -like "*\$folder\*") {
      $include = $false
      break
    }
  }
  if ($include) {
    foreach ($file in $excludeFiles) {
      if ($_.Name -eq $file) {
        $include = $false
        break
      }
    }
  }
  return $include
} | ForEach-Object { 
  $relativePath = $_.FullName.Substring((Get-Location).Path.Length + 1).Replace("\", "/")
  # Filter to only include Lua files and embeds.xml
  if ($relativePath -match "\.lua$" -or $relativePath -eq "embeds.xml") {
    return $relativePath
  }
}

# Check TOC references against actual files
$missingFiles = @()
foreach ($reference in $tocReferences) {
  if (-not (Test-Path (Join-Path (Get-Location) $reference))) {
    $missingFiles += $reference
  }
}

# Check for files not referenced in TOC
$unreferencedFiles = @()
foreach ($file in $allFiles) {
  # Skip embeds.xml since it's referenced differently
  if (($file -ne "embeds.xml") -and ($tocReferences -notcontains $file) -and ($file -match "\.lua$")) {
    $unreferencedFiles += $file
  }
}

# Report results
Write-Host "`n=== Results ===" -ForegroundColor Green

Write-Host "Files referenced in TOC: $($tocReferences.Count)" -ForegroundColor Cyan
Write-Host "Actual Lua files in addon: $(($allFiles | Where-Object { $_ -match '\.lua$' }).Count)" -ForegroundColor Cyan

if ($missingFiles.Count -eq 0) {
  Write-Host "`n✅ All files referenced in TOC exist!" -ForegroundColor Green
}
else {
  Write-Host "`n❌ Missing files referenced in TOC:" -ForegroundColor Red
  foreach ($file in $missingFiles) {
    Write-Host "   - $file" -ForegroundColor Red
  }
}

if ($unreferencedFiles.Count -eq 0) {
  Write-Host "`n✅ All Lua files are referenced in TOC!" -ForegroundColor Green
}
else {
  Write-Host "`n⚠️ Lua files not referenced in TOC:" -ForegroundColor Yellow
  foreach ($file in $unreferencedFiles) {
    Write-Host "   - $file" -ForegroundColor Yellow
  }
}

Write-Host "`n=== File Check Complete ===" -ForegroundColor Cyan 