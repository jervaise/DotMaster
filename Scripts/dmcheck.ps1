# DotMaster Check Command (Simplified)
#
# Purpose: Validate code and catch common errors before in-game testing
# Usage: Run from addon root with ./Scripts/dmcheck.ps1

Write-Host "`n=== DOTMASTER CHECK COMMAND ===`n" -ForegroundColor Cyan

# Check if we're in the addon root directory
$tocFile = Get-ChildItem -Path . -Filter "*.toc" | Select-Object -First 1
if (-not $tocFile) {
  Write-Host "ERROR: Could not find a .toc file in the current directory." -ForegroundColor Red
  Write-Host "Make sure you're running this script from the addon root directory." -ForegroundColor Red
  exit 1
}

Write-Host "Checking addon: $($tocFile.BaseName)" -ForegroundColor Green

# Check for GetSpellInfo issues
Write-Host "`n>> Running GetSpellInfo API Check" -ForegroundColor Yellow

$luaFiles = Get-ChildItem -Path (Get-Location) -Filter "*.lua" -Recurse | 
Where-Object { $_.FullName -notlike "*/Scripts/*" -and $_.FullName -notlike "*/Docs/*" }

Write-Host "Found $($luaFiles.Count) Lua files to check" -ForegroundColor Gray
$getSpellInfoIssues = @()

foreach ($file in $luaFiles) {
  $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1)
  Write-Host "Checking $relativePath" -ForegroundColor Gray -NoNewline
  
  # Check for GetSpellInfo issues
  $content = Get-Content $file.FullName -Raw
  $hasIssue = $false
  
  if ($content -match "GetSpellInfo\s*\(" -and $content -notmatch "C_Spell\.GetSpellInfo\s*\(") {
    # Check if GetSpellInfo isn't in a comment
    $lines = Get-Content $file.FullName
    $lineNum = 0
    
    foreach ($line in $lines) {
      $lineNum++
      if ($line -match "GetSpellInfo\s*\(" -and $line -notmatch "C_Spell\.GetSpellInfo\s*\(" -and $line -notmatch "^\s*--") {
        $getSpellInfoIssues += [PSCustomObject]@{
          File    = $relativePath
          Line    = $lineNum
          Content = $line.Trim()
        }
        $hasIssue = $true
      }
    }
  }
  
  if ($hasIssue) {
    Write-Host " - Issue Found!" -ForegroundColor Red
  }
  else {
    Write-Host " - OK" -ForegroundColor Green
  }
}

# Report GetSpellInfo issues
Write-Host "`n=== GetSpellInfo API Check Results ===" -ForegroundColor Yellow
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

# Check TOC file references
Write-Host "`n>> Running TOC File Verification" -ForegroundColor Yellow

# Extract file references from TOC file
$tocContent = Get-Content $tocFile.FullName -Raw
$tocReferences = [regex]::Matches($tocContent, "(?m)^(?!##|#\s)[^#\s][^\n]+$") | ForEach-Object { $_.Value.Trim() }

# Check TOC references against actual files
$missingFiles = @()
foreach ($reference in $tocReferences) {
  if (-not (Test-Path (Join-Path (Get-Location) $reference))) {
    $missingFiles += $reference
  }
}

# Report TOC results
Write-Host "Files referenced in TOC: $($tocReferences.Count)" -ForegroundColor Gray

if ($missingFiles.Count -eq 0) {
  Write-Host "All files referenced in TOC exist!" -ForegroundColor Green
}
else {
  Write-Host "Missing files referenced in TOC:" -ForegroundColor Red
  foreach ($file in $missingFiles) {
    Write-Host "   - $file" -ForegroundColor Red
  }
}

# Final summary
Write-Host "`n=== CHECK COMPLETE ===" -ForegroundColor Cyan
Write-Host "Review any warnings or errors above before in-game testing" -ForegroundColor Yellow

if ($getSpellInfoIssues.Count -eq 0 -and $missingFiles.Count -eq 0) {
  Write-Host "✅ No critical issues found!" -ForegroundColor Green
} 